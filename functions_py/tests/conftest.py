"""Shared pytest fixtures for functions_py tests."""
import sys
from pathlib import Path

_ACADEMIC_ALLY_ROOT = Path(__file__).resolve().parent.parent.parent
if str(_ACADEMIC_ALLY_ROOT) not in sys.path:
    sys.path.insert(0, str(_ACADEMIC_ALLY_ROOT))
