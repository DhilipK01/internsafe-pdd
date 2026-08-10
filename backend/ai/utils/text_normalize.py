"""Text normalization for downstream NLP/OCR pipelines."""
import re
import unicodedata


def normalize_text(raw: str | None) -> str:
    if not raw:
        return ""
    text = unicodedata.normalize("NFKC", raw)
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def truncate(text: str, max_chars: int = 50_000) -> str:
    if len(text) <= max_chars:
        return text
    return text[:max_chars] + "\n[truncated]"
