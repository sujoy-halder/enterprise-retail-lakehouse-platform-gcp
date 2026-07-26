from google.cloud import bigquery
from fastapi import FastAPI

from recommendation_api.settings import Settings

settings = Settings()
app = FastAPI(title="Retail Recommendation API", version="1.0.0")


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok", "service": "retail-recommendation-api"}


@app.get("/ready")
def ready() -> dict[str, bool]:
    return {"ready": bool(settings.project_id and settings.bigquery_dataset_prefix)}


@app.get("/recommendations/{customer_id}")
def recommendations(customer_id: str, limit: int = 10) -> dict[str, object]:
    if not settings.use_bigquery or not settings.project_id:
        return {
            "customer_id": customer_id,
            "recommendations": fallback_recommendations(limit),
            "source": "fallback",
        }

    client = bigquery.Client(project=settings.project_id)
    query = f"""
    SELECT product_id, score
    FROM `{settings.project_id}.{settings.bigquery_dataset_prefix}_gold.customer_recommendations`
    WHERE customer_id = @customer_id
    ORDER BY score DESC
    LIMIT @limit
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("customer_id", "STRING", customer_id),
            bigquery.ScalarQueryParameter("limit", "INT64", limit),
        ]
    )
    rows = client.query(query, job_config=job_config).result()
    return {
        "customer_id": customer_id,
        "recommendations": [
            {"product_id": row.product_id, "score": float(row.score)} for row in rows
        ],
        "source": "bigquery",
    }


def fallback_recommendations(limit: int) -> list[dict[str, object]]:
    products = ["SKU-1001", "SKU-1002", "SKU-1003", "SKU-1004", "SKU-1005"]
    return [
        {"product_id": product_id, "score": round(0.95 - index * 0.03, 4)}
        for index, product_id in enumerate(products[:limit])
    ]

