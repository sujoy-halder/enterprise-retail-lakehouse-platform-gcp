import json
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[2]


def test_json_assets_parse() -> None:
    for path in [
        *ROOT.glob("databricks/**/*.json"),
        *ROOT.glob("informatica/**/*.json"),
        *ROOT.glob("monitoring/**/*.json"),
    ]:
        json.loads(path.read_text(encoding="utf-8"))


def test_yaml_assets_parse() -> None:
    yaml_paths = [
        *ROOT.glob(".github/workflows/*.yml"),
        *ROOT.glob("kubernetes/**/*.yaml"),
        *ROOT.glob("dbt/retail_analytics/**/*.yml"),
        *ROOT.glob("monitoring/**/*.yml"),
    ]
    for path in yaml_paths:
        docs = list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
        assert docs


def test_kubernetes_placeholders_are_known() -> None:
    allowed = {
        "PROJECT_ID",
        "REGION",
        "ENVIRONMENT",
        "ARTIFACT_REGISTRY",
        "IMAGE_TAG",
        "GCP_WORKLOAD_SERVICE_ACCOUNT",
        "BRONZE_BUCKET",
        "SILVER_BUCKET",
        "CHECKPOINT_BUCKET",
        "QUARANTINE_BUCKET",
        "POS_SUBSCRIPTION",
        "INVENTORY_SUBSCRIPTION",
        "BIGQUERY_DATASET_PREFIX",
    }
    text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in ROOT.glob("kubernetes/**/*.yaml")
    )
    placeholders = {
        item.split("}", 1)[0]
        for item in text.split("${")[1:]
    }
    assert placeholders <= allowed
