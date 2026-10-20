"""Environment-only service configuration."""
from dataclasses import dataclass
import os
from pathlib import Path
import sys


@dataclass(frozen=True)
class Settings:
    access_token: str
    openrouter_key: str
    openrouter_model: str
    database_path: Path
    mcp_script: Path
    mcp_python: str

    auth_verify_url: str = ""
    auth_mode: str = "verify"
    retailer_mode: str = "device"
    gateway_secret: str = ""

    @classmethod
    def from_env(cls) -> "Settings":
        sibling = Path(__file__).resolve().parents[1]
        return cls(
            access_token=os.environ.get("WINE_ASSISTANT_TOKEN", ""),
            openrouter_key=os.environ.get("OPENROUTER_API_KEY", ""),
            openrouter_model=os.environ.get("OPENROUTER_MODEL", ""),
            database_path=Path(os.environ.get("WINE_ASSISTANT_DB", "~/.local/share/winescan-assistant/sessions.sqlite3")).expanduser(),
            mcp_script=Path(os.environ.get("PEREKRESTOK_MCP_SCRIPT", str(sibling / "integrations/perekrestok_device_mcp/server.py"))).expanduser(),
            mcp_python=os.environ.get("PEREKRESTOK_MCP_PYTHON", sys.executable),
            auth_verify_url=os.environ.get("AUTH_VERIFY_URL", ""),
            auth_mode=os.environ.get("WINE_ASSISTANT_AUTH_MODE", "verify"),
            retailer_mode=os.environ.get("WINE_ASSISTANT_RETAILER_MODE", "device"),
            gateway_secret=os.environ.get("WINE_ASSISTANT_GATEWAY_SECRET", ""),
        )
