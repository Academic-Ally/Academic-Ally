"""Async embedding via Gemini's GA embedding model through litellm.

Uses ``gemini-embedding-001`` (the GA replacement for the deprecated
``text-embedding-004``). The model defaults to 3072-dim vectors but
supports ``output_dimensionality`` to truncate. We pin to 768 to match
the Firestore vector index dimension our backend was set up for.

Free-tier Gemini embedding API caps at ~100 RPM. To stay polite + survive
transient rate-limit bursts:
- ``BATCH_SLEEP_SEC`` between calls (≈85 RPM target)
- exponential-backoff retry on 429 / RESOURCE_EXHAUSTED
"""
import asyncio
import logging
import os
from typing import List

import litellm


logger = logging.getLogger(__name__)

EMBED_MODEL = "gemini/gemini-embedding-001"
EMBED_DIM = 768  # we truncate the model's 3072-dim output to this
BATCH_SLEEP_SEC = 0.7  # ~85 RPM, safely under 100 RPM free-tier cap
MAX_RETRIES = 5  # 1 → 2 → 4 → 8 → 16 → 32s back-off


def _is_rate_limit(exc: Exception) -> bool:
    """Detect Gemini 429 / RESOURCE_EXHAUSTED across litellm error shapes."""
    if isinstance(exc, litellm.RateLimitError):
        return True
    msg = str(exc).lower()
    return "rate" in msg and "limit" in msg or "resource_exhausted" in msg or "429" in msg


async def _aembed_with_retry(*, model, input, api_key, output_dimensionality):
    """Wrap litellm.aembedding with exponential-backoff retry on 429s."""
    delay = 1.0
    for attempt in range(MAX_RETRIES + 1):
        try:
            return await litellm.aembedding(
                model=model,
                input=input,
                api_key=api_key,
                output_dimensionality=output_dimensionality,
            )
        except Exception as exc:
            if attempt == MAX_RETRIES or not _is_rate_limit(exc):
                raise
            logger.warning(
                "rate-limited embed (attempt %d/%d) — sleeping %.1fs",
                attempt + 1, MAX_RETRIES, delay,
            )
            await asyncio.sleep(delay)
            delay *= 2  # 1, 2, 4, 8, 16


async def embed_one(text: str) -> List[float]:
    """Embed a single string. Returns a 768-dim vector."""
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set; cannot embed.")
    response = await _aembed_with_retry(
        model=EMBED_MODEL,
        input=[text],
        api_key=api_key,
        output_dimensionality=EMBED_DIM,
    )
    return response["data"][0]["embedding"]


async def embed_batch(texts: List[str], batch_size: int = 25) -> List[List[float]]:
    """Embed many strings, throttled to stay under the free-tier RPM cap.

    Sleeps between batches to maintain ~85 RPM. Retries with exponential
    back-off on 429 RESOURCE_EXHAUSTED.
    """
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set; cannot embed.")

    all_vectors: List[List[float]] = []
    total_batches = (len(texts) + batch_size - 1) // batch_size
    for batch_idx, i in enumerate(range(0, len(texts), batch_size)):
        if batch_idx > 0:
            # Throttle BEFORE the next request; first request goes immediately.
            await asyncio.sleep(BATCH_SLEEP_SEC)
        batch = texts[i : i + batch_size]
        response = await _aembed_with_retry(
            model=EMBED_MODEL,
            input=batch,
            api_key=api_key,
            output_dimensionality=EMBED_DIM,
        )
        all_vectors.extend([item["embedding"] for item in response["data"]])
        logger.info(
            "embedded batch %d/%d (%d vectors)",
            batch_idx + 1, total_batches, len(batch),
        )
    return all_vectors
