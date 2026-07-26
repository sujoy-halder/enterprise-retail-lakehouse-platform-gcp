#!/usr/bin/env python3
from __future__ import annotations

import json
import os
from datetime import UTC, datetime

from google.cloud import pubsub_v1


def main() -> None:
    project_id = os.environ["PROJECT_ID"]
    topic = os.environ.get("POS_TOPIC", "retail-lakehouse-dev-pos-transactions")
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic)
    now = datetime.now(UTC).isoformat()
    payload = {
        "transaction_id": f"txn-{int(datetime.now(UTC).timestamp())}",
        "store_id": "store-001",
        "customer_id": "cust-001",
        "product_id": "sku-1001",
        "quantity": 2,
        "unit_price": "19.99",
        "currency": "USD",
        "event_time": now,
        "ingestion_time": now,
    }
    future = publisher.publish(
        topic_path,
        json.dumps(payload).encode("utf-8"),
        ordering_key=payload["store_id"],
    )
    print(future.result())


if __name__ == "__main__":
    main()

