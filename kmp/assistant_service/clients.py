"""Bounded adapters for the scanner, model, and paired retailer device."""
import asyncio
import json
from pathlib import Path

import httpx
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


class UpstreamUnavailable(Exception):
    pass


class OpenRouterClient:
    def __init__(self, api_key: str, model: str):
        self.api_key = api_key
        self.model = model
        self.http = httpx.AsyncClient(base_url="https://openrouter.ai/api/v1", timeout=httpx.Timeout(60, connect=10))

    async def close(self) -> None:
        await self.http.aclose()

    async def complete(self, messages: list[dict], tools: list[dict]) -> dict:
        if not self.api_key or not self.model:
            raise UpstreamUnavailable("model_not_configured")
        try:
            body = {
                "model": self.model, "messages": messages,
                "response_format": {"type": "json_object"},
                # The selected model supports tools and JSON, but OpenRouter's strict
                # provider metadata currently reports no endpoint when combined with
                # data_collection=deny. Validate the actual response instead.
                "provider": {"data_collection": "deny"},
                "temperature": 0.3, "max_tokens": 1200,
            }
            if tools:
                body.update({"tools": tools, "tool_choice": "auto", "parallel_tool_calls": False})
            response = await self.http.post(
                "/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json=body,
            )
            response.raise_for_status()
            payload = response.json()
            choice = payload["choices"][0]
            if choice.get("finish_reason") in ("length", "content_filter", "error"):
                raise UpstreamUnavailable("model_incomplete")
            message = choice["message"]
            if not isinstance(message, dict):
                raise UpstreamUnavailable("model_invalid_response")
            return message
        except (httpx.HTTPError, ValueError, KeyError, IndexError, TypeError) as exc:
            raise UpstreamUnavailable("model_unavailable") from exc


class RetailClient:
    """One stdio MCP session owns the local device bridge. Never expose its HTTP port."""

    def __init__(self, script: Path, python: str):
        self.script = script
        self.python = python
        self._queue: asyncio.Queue | None = None
        self._worker_task: asyncio.Task | None = None
        self._lock = asyncio.Lock()

    async def close(self) -> None:
        if self._worker_task and not self._worker_task.done():
            self._worker_task.cancel()
            try:
                await self._worker_task
            except asyncio.CancelledError:
                pass
        self._worker_task = None
        self._queue = None

    async def _run(self, queue: asyncio.Queue) -> None:
        active_future = None
        try:
            async with stdio_client(StdioServerParameters(command=self.python, args=[str(self.script)])) as (reader, writer):
                async with ClientSession(reader, writer) as session:
                    await session.initialize()
                    while True:
                        name, args, future = await queue.get()
                        active_future = future
                        if future.cancelled():
                            continue
                        try:
                            if name in ("search_products", "get_product"):
                                for _ in range(8):
                                    status = await session.call_tool("session_status", arguments={})
                                    connected = any(item.type == "text" and json.loads(item.text).get("connected") is True for item in status.content)
                                    if connected:
                                        break
                                    await asyncio.sleep(0.5)
                            response = await asyncio.wait_for(session.call_tool(name, arguments=args), timeout=30)
                            if response.isError:
                                raise UpstreamUnavailable("retailer_tool_error")
                            result = None
                            for item in response.content:
                                if item.type == "text":
                                    result = json.loads(item.text)
                                    break
                            if result is None:
                                result = response.structuredContent
                            if not isinstance(result, dict):
                                raise UpstreamUnavailable("retailer_invalid_response")
                            if not future.done():
                                future.set_result(result)
                        except Exception as exc:
                            if not future.done():
                                future.set_exception(UpstreamUnavailable("retailer_bridge_unavailable") if not isinstance(exc, UpstreamUnavailable) else exc)
                        finally:
                            active_future = None
        except asyncio.CancelledError:
            raise
        except Exception:
            pass
        finally:
            if active_future is not None and not active_future.done():
                active_future.set_exception(UpstreamUnavailable("retailer_bridge_unavailable"))
            while not queue.empty():
                _, _, future = queue.get_nowait()
                if not future.done():
                    future.set_exception(UpstreamUnavailable("retailer_bridge_unavailable"))

    async def call(self, name: str, args: dict) -> dict:
        if not self.script.is_file():
            raise UpstreamUnavailable("retailer_mcp_missing")
        async with self._lock:
            if self._worker_task is None or self._worker_task.done():
                self._queue = asyncio.Queue()
                self._worker_task = asyncio.create_task(self._run(self._queue))
            assert self._queue is not None
            future = asyncio.get_running_loop().create_future()
            await self._queue.put((name, args, future))
            try:
                return await asyncio.wait_for(future, timeout=40)
            except asyncio.TimeoutError as exc:
                await self.close()
                raise UpstreamUnavailable("retailer_bridge_unavailable") from exc
