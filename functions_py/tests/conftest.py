"""Shared pytest fixtures for functions_py tests."""
import sys
from pathlib import Path

_FUNCTIONS_PY_ROOT = Path(__file__).resolve().parent.parent
if str(_FUNCTIONS_PY_ROOT) not in sys.path:
    sys.path.insert(0, str(_FUNCTIONS_PY_ROOT))
