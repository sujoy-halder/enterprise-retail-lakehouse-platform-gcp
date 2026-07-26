from typing import Any

import structlog
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from retail_etl.ingestion import BronzeWriter
from retail_etl.settings import Settings

settings = Settings()
logger = structlog.get_logger()
app = FastAPI(title="Retail ETL Service", version="1.0.0")


class IngestRequest(BaseModel):
    event_id: str = Field(min_length=1)
    event_time: str = Field(min_length=1)
    payload: dict[str, Any]


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok", "service": "retail-etl-service"}


@app.get("/ready")
def ready() -> dict[str, Any]:
    missing = [
        name for name, value in settings.required_runtime_values.items() if not value
    ]
    return {"ready": not missing, "missing": missing}


@app.post("/ingest/{source}")
def ingest(source: str, request: IngestRequest) -> dict[str, str]:
    if not settings.bronze_bucket:
        raise HTTPException(status_code=503, detail="BRONZE_BUCKET is not configured")

    writer = BronzeWriter(settings.bronze_bucket)
    object_uri = writer.write_json(source, request.model_dump())
    logger.info("bronze_event_written", source=source, object_uri=object_uri)
    return {"status": "accepted", "object_uri": object_uri}

