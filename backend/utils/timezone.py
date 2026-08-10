"""IST display helpers — store UTC internally, present Asia/Kolkata to users."""
from __future__ import annotations

from datetime import datetime, timezone
from zoneinfo import ZoneInfo

IST = ZoneInfo("Asia/Kolkata")
IST_LABEL = "IST"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def to_ist(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(IST)


def format_ist(dt: datetime | None, *, fallback: str = "") -> str:
    """Example: 16 May 2026, 07:45 PM IST"""
    if dt is None:
        return fallback
    local = to_ist(dt)
    if not local:
        return fallback
    return f"{local.strftime('%d %b %Y, %I:%M %p')} {IST_LABEL}"


def format_ist_from_iso(iso: str | None) -> str:
    if not iso or not str(iso).strip():
        return ""
    raw = str(iso).strip()
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    elif "T" in raw and "+" not in raw and not raw.endswith(IST_LABEL):
        raw = raw + "+00:00"
    try:
        parsed = datetime.fromisoformat(raw.replace(" ", "T") if "T" not in raw and " " in raw else raw)
    except ValueError:
        try:
            parsed = datetime.strptime(raw[:19], "%Y-%m-%d %H:%M:%S").replace(tzinfo=timezone.utc)
        except ValueError:
            return ""
    return format_ist(parsed)


def ist_payload(iso_utc: str | None) -> dict[str, str]:
    display = format_ist_from_iso(iso_utc)
    return {
        "created_at": iso_utc or "",
        "created_at_ist": display,
        "timezone": "Asia/Kolkata",
    }
