"""CrewAI LLM configuration for Minimax.

Minimax exposes an OpenAI-compatible chat-completions endpoint, so we
use CrewAI's built-in ``LLM`` class configured with the OpenAI provider
and point ``base_url`` at Minimax's endpoint.

The API key is read from the ``MINIMAX_API_KEY`` environment variable,
which is populated by Firebase Secrets at runtime (see main.py secrets
declaration).
"""
import os

from crewai import LLM


# Minimax's international OpenAI-compatible endpoint
# Source: https://www.minimaxi.com/en/document/guides/chat-model/pro/api
MINIMAX_BASE_URL = "https://api.minimaxi.chat/v1"

# Default model — tunable via MINIMAX_MODEL env var
_DEFAULT_MODEL = "MiniMax-M2"


def get_minimax_llm(temperature: float = 0.3) -> LLM:
    """Build a CrewAI LLM configured for Minimax.

    Args:
        temperature: Sampling temperature. 0.3 is a good balance for
            structured agent tasks. Agents needing more creativity can
            request a higher value.
    """
    api_key = os.environ.get("MINIMAX_API_KEY")
    if not api_key:
        raise RuntimeError(
            "MINIMAX_API_KEY not set. Configure via "
            "'firebase functions:secrets:set MINIMAX_API_KEY' and "
            "declare the secret on the function."
        )
    model = os.environ.get("MINIMAX_MODEL", _DEFAULT_MODEL)
    return LLM(
        model=f"openai/{model}",
        base_url=MINIMAX_BASE_URL,
        api_key=api_key,
        temperature=temperature,
    )
