"""CrewAI LLM configuration.

Uses Google Gemini through CrewAI's ``LLM`` class (litellm under the
hood). ``GEMINI_API_KEY`` is required; ``LLM_MODEL`` overrides the
default model.
"""
import os

from crewai import LLM


_DEFAULT_MODEL = "gemini/gemini-2.5-flash-lite"


def get_llm(temperature: float = 0.3) -> LLM:
    """Build a CrewAI LLM configured for Gemini."""
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set in environment.")
    model = os.environ.get("LLM_MODEL", _DEFAULT_MODEL)
    return LLM(
        model=model,
        api_key=api_key,
        temperature=temperature,
    )
