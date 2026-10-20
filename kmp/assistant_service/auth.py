"""Server-verified account identity; never trust a client supplied user ID."""
from dataclasses import dataclass
import re
import secrets

import httpx
from fastapi import HTTPException

from .config import Settings


@dataclass(frozen=True)
class Principal:
    subject: str
    account_kind: str


class Authenticator:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.http = httpx.AsyncClient(timeout=httpx.Timeout(5, connect=2), follow_redirects=False)

    async def close(self) -> None:
        await self.http.aclose()

    async def verify(self, authorization: str | None, gateway: str | None = None, proxy_subject: str | None = None) -> Principal:
        if self.settings.auth_mode == "trusted_proxy":
            if not gateway or not secrets.compare_digest(gateway, self.settings.gateway_secret):
                raise HTTPException(401, "unauthorized")
            if not proxy_subject or not re.fullmatch(r"(?:u:[0-9]{1,20}|guest:[A-Za-z0-9_-]{1,128})", proxy_subject):
                raise HTTPException(401, "unauthorized")
            return Principal(proxy_subject, "account" if proxy_subject.startswith("u:") else "guest")
        if not authorization or not authorization.startswith("Bearer ") or len(authorization) > 8192:
            raise HTTPException(401, "unauthorized")
        if self.settings.auth_mode == "legacy_local":
            if not secrets.compare_digest(authorization, "Bearer " + self.settings.access_token):
                raise HTTPException(401, "unauthorized")
            return Principal("legacy", "legacy")
        try:
            response = await self.http.get(self.settings.auth_verify_url, headers={"Authorization": authorization})
        except httpx.HTTPError as exc:
            raise HTTPException(503, "auth_unavailable") from exc
        if response.status_code in (401, 403):
            raise HTTPException(401, "unauthorized")
        if response.status_code != 204:
            raise HTTPException(503, "auth_unavailable")
        subject = response.headers.get("X-Auth-Subject", "")
        if not re.fullmatch(r"(?:u|guest):[A-Za-z0-9_-]{1,128}", subject):
            raise HTTPException(503, "auth_invalid_identity")
        return Principal(subject, "account" if subject.startswith("u:") else "guest")
