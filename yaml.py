"""JSON-backed shim with a `yaml`-compatible API.

Config files in this project use the `.yaml` extension but are written and
read as JSON so the engine does not depend on PyYAML. `safe_dump` /
`safe_load` mirror the subset of the PyYAML surface the engine uses. If we
ever need real YAML (anchors, block scalars, comments) swap this module for
PyYAML and keep the function signatures identical.
"""

from __future__ import annotations

import json
from typing import Any


def safe_dump(payload: Any, sort_keys: bool = False) -> str:
    return json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=sort_keys) + "\n"


def safe_load(text: str) -> Any:
    if not text.strip():
        return None
    return json.loads(text)
