from __future__ import annotations

import json
import logging
from datetime import UTC, datetime
from typing import Any


def emit_lineage_event(dataset: str, operation: str, metadata: dict[str, Any]) -> None:
    payload = {
        "dataset": dataset,
        "operation": operation,
        "metadata": metadata,
        "event_time": datetime.now(UTC).isoformat(),
    }
    logging.info("lineage_event=%s", json.dumps(payload, sort_keys=True))

