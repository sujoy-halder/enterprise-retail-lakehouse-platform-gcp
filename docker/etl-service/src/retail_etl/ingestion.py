import json
from datetime import UTC, datetime
from hashlib import sha256
from typing import Any

from google.cloud import storage


class BronzeWriter:
    def __init__(self, bucket_name: str) -> None:
        self.bucket_name = bucket_name
        self._client: storage.Client | None = None

    @property
    def client(self) -> storage.Client:
        if self._client is None:
            self._client = storage.Client()
        return self._client

    def write_json(self, source: str, payload: dict[str, Any]) -> str:
        now = datetime.now(UTC)
        canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"))
        digest = sha256(canonical.encode("utf-8")).hexdigest()
        object_name = (
            f"{source}/event_date={now.date().isoformat()}/"
            f"hour={now.hour:02d}/{digest}.json"
        )

        enriched = {
            "_ingestion_time": now.isoformat(),
            "_source": source,
            "_event_hash": digest,
            "payload": payload,
        }

        bucket = self.client.bucket(self.bucket_name)
        blob = bucket.blob(object_name)
        blob.upload_from_string(
            json.dumps(enriched, separators=(",", ":")),
            content_type="application/json",
        )
        return f"gs://{self.bucket_name}/{object_name}"

