"""PDF text extraction + chunking for RAG ingestion.

Uses pypdfium2 (transitive dep via crewai) for text extraction. Chunks
are character-based sliding windows — cheap and good enough for the
demo. Each chunk carries page span info so the agent can cite it.
"""
from dataclasses import dataclass
from typing import List

import pypdfium2 as pdfium


# Characters, not tokens. ~2000 chars ≈ 500 English tokens. Overlap of
# 200 chars keeps semantic continuity across chunk boundaries.
CHUNK_SIZE = 2000
CHUNK_OVERLAP = 200


@dataclass
class PageText:
    page: int  # 1-indexed
    text: str


@dataclass
class Chunk:
    text: str
    page_start: int  # 1-indexed
    page_end: int  # inclusive
    chunk_index: int  # 0-indexed position within the source document


def extract_pages(pdf_bytes: bytes) -> List[PageText]:
    """Return text per page, 1-indexed. Empty pages are kept as ``""``."""
    pdf = pdfium.PdfDocument(pdf_bytes)
    pages: List[PageText] = []
    for i in range(len(pdf)):
        page = pdf[i]
        textpage = page.get_textpage()
        try:
            text = textpage.get_text_range() or ""
        finally:
            textpage.close()
            page.close()
        pages.append(PageText(page=i + 1, text=text))
    pdf.close()
    return pages


def chunk_pages(pages: List[PageText]) -> List[Chunk]:
    """Slide a window across the concatenated text, tracking page spans.

    The output preserves which page(s) each chunk came from so we can
    cite specific pages back to the user.
    """
    if not pages:
        return []

    # Build a flat text + per-character page-number index
    flat_chars: List[str] = []
    char_pages: List[int] = []
    for p in pages:
        for ch in p.text:
            flat_chars.append(ch)
            char_pages.append(p.page)
        # Add a separator between pages so chunks don't blur page boundaries
        flat_chars.append("\n")
        char_pages.append(p.page)

    full_text = "".join(flat_chars)
    if not full_text.strip():
        return []

    chunks: List[Chunk] = []
    start = 0
    idx = 0
    n = len(full_text)
    while start < n:
        end = min(start + CHUNK_SIZE, n)
        chunk_text = full_text[start:end].strip()
        if chunk_text:
            page_start = char_pages[start] if start < len(char_pages) else char_pages[-1]
            page_end_idx = end - 1 if end - 1 < len(char_pages) else len(char_pages) - 1
            page_end = char_pages[page_end_idx]
            chunks.append(
                Chunk(
                    text=chunk_text,
                    page_start=page_start,
                    page_end=page_end,
                    chunk_index=idx,
                )
            )
            idx += 1
        if end == n:
            break
        start = end - CHUNK_OVERLAP
    return chunks


def extract_and_chunk(pdf_bytes: bytes) -> List[Chunk]:
    """Convenience: extract pages and produce chunks in one call."""
    return chunk_pages(extract_pages(pdf_bytes))
