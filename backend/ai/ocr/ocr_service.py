"""OCR & document text extraction — PaddleOCR, PyMuPDF, pdfplumber."""
from __future__ import annotations

import io
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

from backend.ai.utils.text_normalize import normalize_text, truncate
from backend.config import get_settings

logger = logging.getLogger(__name__)

_paddle_ocr: Any = None


def _get_paddle():
    global _paddle_ocr
    settings = get_settings()
    if not settings.enable_paddle_ocr:
        return None
    if _paddle_ocr is None:
        try:
            from paddleocr import PaddleOCR

            _paddle_ocr = PaddleOCR(
                use_angle_cls=True,
                lang="en",
                show_log=False,
            )
        except Exception as exc:
            logger.warning("PaddleOCR unavailable: %s", exc)
            _paddle_ocr = False
    return _paddle_ocr if _paddle_ocr is not False else None


@dataclass
class OcrBlock:
    text: str
    confidence: float
    box: list[list[float]] | None = None


@dataclass
class OcrResult:
    text: str
    method: str
    confidence: float
    page_count: int = 1
    blocks: list[OcrBlock] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)
    low_confidence: bool = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "method": self.method,
            "confidence": self.confidence,
            "page_count": self.page_count,
            "low_confidence": self.low_confidence,
            "metadata": self.metadata,
            "blocks": [
                {"text": b.text, "confidence": b.confidence} for b in self.blocks[:50]
            ],
        }


def _preprocess_image(img: Image.Image) -> np.ndarray:
    """Resize, grayscale-friendly array for OCR."""
    import cv2

    rgb = img.convert("RGB")
    arr = np.array(rgb)
    h, w = arr.shape[:2]
    max_side = 2000
    if max(h, w) > max_side:
        scale = max_side / max(h, w)
        arr = cv2.resize(arr, (int(w * scale), int(h * scale)))
    gray = cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)
    denoised = cv2.fastNlMeansDenoising(gray, h=10)
    return denoised


def ocr_image_bytes(data: bytes, mime: str = "image/png") -> OcrResult:
    settings = get_settings()
    img = Image.open(io.BytesIO(data))
    # EXIF orientation
    try:
        from PIL import ImageOps

        img = ImageOps.exif_transpose(img)
    except Exception:
        pass

    paddle = _get_paddle()
    blocks: list[OcrBlock] = []
    if paddle:
        try:
            arr = _preprocess_image(img)
            result = paddle.ocr(arr, cls=True)
            lines: list[str] = []
            confs: list[float] = []
            if result and result[0]:
                for line in result[0]:
                    box, (txt, conf) = line[0], line[1]
                    if txt.strip():
                        blocks.append(
                            OcrBlock(text=txt.strip(), confidence=float(conf), box=box)
                        )
                        lines.append(txt.strip())
                        confs.append(float(conf))
            text = normalize_text("\n".join(lines))
            avg_conf = sum(confs) / len(confs) if confs else 0.0
            low = avg_conf < settings.ocr_min_confidence or len(text) < 20
            return OcrResult(
                text=truncate(text),
                method="paddleocr",
                confidence=round(avg_conf, 3),
                blocks=blocks,
                low_confidence=low,
            )
        except Exception as exc:
            logger.exception("PaddleOCR failed: %s", exc)

    return OcrResult(
        text="",
        method="none",
        confidence=0.0,
        low_confidence=True,
        metadata={"error": "OCR engine could not extract text from image"},
    )


def _extract_pdf_text_pymupdf(data: bytes) -> tuple[str, float, int]:
    import fitz

    doc = fitz.open(stream=data, filetype="pdf")
    pages: list[str] = []
    for page in doc:
        pages.append(page.get_text("text") or "")
    text = normalize_text("\n\n".join(pages))
    # Native text = high confidence
    conf = 0.95 if len(text.strip()) > 80 else 0.3
    return text, conf, doc.page_count


def _extract_pdf_pdfplumber(data: bytes) -> str:
    import pdfplumber

    parts: list[str] = []
    with pdfplumber.open(io.BytesIO(data)) as pdf:
        for page in pdf.pages:
            t = page.extract_text() or ""
            if t.strip():
                parts.append(t)
    return normalize_text("\n\n".join(parts))


def _ocr_pdf_pages_as_images(data: bytes) -> OcrResult:
    import fitz

    doc = fitz.open(stream=data, filetype="pdf")
    all_blocks: list[OcrBlock] = []
    lines: list[str] = []
    confs: list[float] = []
    for page in doc:
        pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
        img_bytes = pix.tobytes("png")
        page_result = ocr_image_bytes(img_bytes, "image/png")
        lines.append(page_result.text)
        confs.append(page_result.confidence)
        all_blocks.extend(page_result.blocks)
    text = normalize_text("\n\n".join(lines))
    avg = sum(confs) / len(confs) if confs else 0.0
    settings = get_settings()
    return OcrResult(
        text=truncate(text),
        method="paddleocr_pdf",
        confidence=round(avg, 3),
        page_count=doc.page_count,
        blocks=all_blocks,
        low_confidence=avg < settings.ocr_min_confidence,
    )


def extract_from_file(data: bytes, mime_type: str, file_name: str = "") -> OcrResult:
    """Route by MIME / extension — PDF direct text then OCR fallback."""
    mime = (mime_type or "").lower()
    ext = Path(file_name).suffix.lower()

    if mime == "application/pdf" or ext == ".pdf":
        text, conf, pages = _extract_pdf_text_pymupdf(data)
        if len(text.strip()) >= 80:
            return OcrResult(
                text=truncate(text),
                method="pymupdf",
                confidence=conf,
                page_count=pages,
                low_confidence=False,
            )
        alt = _extract_pdf_pdfplumber(data)
        if len(alt.strip()) >= 80:
            return OcrResult(
                text=truncate(alt),
                method="pdfplumber",
                confidence=0.9,
                page_count=pages,
            )
        return _ocr_pdf_pages_as_images(data)

    if mime.startswith("image/") or ext in {".jpg", ".jpeg", ".png", ".webp"}:
        return ocr_image_bytes(data, mime)

    return OcrResult(
        text="",
        method="unsupported",
        confidence=0.0,
        low_confidence=True,
        metadata={"mime": mime_type},
    )
