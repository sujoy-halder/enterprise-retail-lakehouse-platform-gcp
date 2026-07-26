from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def test_required_deployment_assets_exist() -> None:
    required = [
        ".github/workflows/deploy.yml",
        "terraform/envs/dev/main.tf",
        "terraform/envs/prod/main.tf",
        "kubernetes/base/kustomization.yaml",
        "airflow/dags/retail_lakehouse_daily.py",
        "databricks/dlt/retail_bronze_silver_dlt.py",
        "dbt/retail_analytics/dbt_project.yml",
        "snowflake/sql/001_foundation.sql",
        "monitoring/grafana/dashboards/retail-lakehouse-slo.json",
        "scripts/smoke_test.sh",
    ]

    missing = [path for path in required if not (ROOT / path).exists()]
    assert missing == []


def test_real_environment_identity_controls_are_declared() -> None:
    iam = (ROOT / "terraform/modules/iam/main.tf").read_text(encoding="utf-8")
    pubsub = (ROOT / "terraform/modules/pubsub/main.tf").read_text(encoding="utf-8")
    network_policy = (ROOT / "kubernetes/base/networkpolicy.yaml").read_text(
        encoding="utf-8"
    )

    assert "roles/iam.workloadIdentityUser" in iam
    assert "svc.id.goog[retail-lakehouse/retail-workloads]" in iam
    assert "google_bigquery_default_service_account" in iam
    assert "google_storage_project_service_account" in iam
    assert "gcp-sa-pubsub.iam.gserviceaccount.com" in pubsub
    assert "169.254.169.254/32" in network_policy


def test_ci_invokes_scripts_through_bash() -> None:
    deploy = (ROOT / ".github/workflows/deploy.yml").read_text(encoding="utf-8")
    assert "bash scripts/render_k8s.sh" in deploy
    assert "bash scripts/sync_composer.sh" in deploy
    assert "bash scripts/deploy_databricks.sh" in deploy
    assert "bash scripts/smoke_test.sh" in deploy


def test_github_actions_are_sha_pinned() -> None:
    workflow_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (ROOT / ".github/workflows").glob("*.yml")
    )
    action_lines = [
        line.strip()
        for line in workflow_text.splitlines()
        if line.strip().startswith("uses:")
    ]
    unpinned = [
        line for line in action_lines if not line.split("@", 1)[1].split()[0].isalnum()
    ]
    assert unpinned == []


def test_runtime_images_and_egress_are_hardened() -> None:
    dockerfiles = [
        ROOT / "docker/etl-service/Dockerfile",
        ROOT / "docker/recommendation-api/Dockerfile",
    ]
    for dockerfile in dockerfiles:
        content = dockerfile.read_text(encoding="utf-8")
        assert "python:3.12-alpine@sha256:" in content

    network_policy = (ROOT / "kubernetes/base/networkpolicy.yaml").read_text(
        encoding="utf-8"
    )
    assert "0.0.0.0/0" not in network_policy
    assert "199.36.153.8/30" in network_policy


def test_no_committed_secret_literals() -> None:
    text_files = [
        path
        for path in ROOT.rglob("*")
        if path.is_file()
        and ".git" not in path.parts
        and path.suffix.lower() in {".tf", ".yml", ".yaml", ".json", ".py", ".sh", ".sql", ".md"}
    ]
    forbidden = [
        "-----BEGIN " + "PRIVATE KEY-----",
        "AI" + "za",
        "xox" + "b-",
        "DATABRICKS_" + "TOKEN=",
    ]
    offenders: list[str] = []
    for path in text_files:
        content = path.read_text(encoding="utf-8", errors="ignore")
        for marker in forbidden:
            if marker in content and ".example" not in path.name:
                offenders.append(f"{path.relative_to(ROOT)} contains {marker}")
    assert offenders == []
