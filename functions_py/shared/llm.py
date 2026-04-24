"""CrewAI LLM configuration for the Academic Ally AI backend.

Uses Google Gemini (via AI Studio / Generative Language API) through
CrewAI's ``LLM`` class, which routes to litellm under the hood. Gemini
2.5 Flash is the default: fast, smart enough for multi-agent reasoning,
generous free tier.

The API key is read from the ``GEMINI_API_KEY`` environment variable,
which is populated by Firebase Secrets at runtime (see main.py secrets
declaration). The model can be overridden via ``LLM_MODEL``.
"""
import os

from crewai import LLM


_DEFAULT_MODEL = "gemini/gemini-2.0-flash"


def get_llm(temperature: float = 0.3) -> LLM:
    """Build a CrewAI LLM configured for Gemini.

    Args:
        temperature: Sampling temperature. 0.3 is a good balance for
            structured agent tasks. Agents needing more creativity can
            request a higher value.
    """
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError(
            "GEMINI_API_KEY not set. Configure via "
            "'firebase functions:secrets:set GEMINI_API_KEY' and "
            "declare the secret on the function."
        )
    model = os.environ.get("LLM_MODEL", _DEFAULT_MODEL)
    return LLM(
        model=model,
        api_key=api_key,
        temperature=temperature,
    )
