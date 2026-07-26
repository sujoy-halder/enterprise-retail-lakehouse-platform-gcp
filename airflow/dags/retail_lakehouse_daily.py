from __future__ import annotations

from datetime import timedelta

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.providers.databricks.operators.databricks import DatabricksSubmitRunOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryCheckOperator


ENVIRONMENT = Variable.get("retail_environment", default_var="dev")
GCP_PROJECT_ID = Variable.get("gcp_project_id", default_var="replace-project-id")
DBT_PROJECT_DIR = Variable.get("dbt_project_dir", default_var="/home/airflow/gcs/data/dbt/retail_analytics")
BRONZE_BUCKET = Variable.get("bronze_bucket", default_var="replace-bronze-bucket")
CHECKPOINT_BUCKET = Variable.get("checkpoint_bucket", default_var="replace-checkpoint-bucket")


default_args = {
    "owner": "data-platform",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
}


with DAG(
    dag_id="retail_lakehouse_daily",
    description="Daily retail lakehouse orchestration across Databricks, BigQuery, dbt, and Snowflake.",
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    schedule="0 */2 * * *",
    catchup=False,
    max_active_runs=1,
    default_args=default_args,
    tags=["retail", "lakehouse", ENVIRONMENT],
) as dag:
    start = EmptyOperator(task_id="start")

    databricks_autoload_pos = DatabricksSubmitRunOperator(
        task_id="databricks_autoload_pos",
        databricks_conn_id="databricks_default",
        json={
            "new_cluster": {
                "spark_version": "15.4.x-scala2.12",
                "node_type_id": "n2-standard-4",
                "autoscale": {"min_workers": 1, "max_workers": 4},
                "gcp_attributes": {"availability": "ON_DEMAND_GCP"},
            },
            "spark_python_task": {
                "python_file": "dbfs:/retail/jobs/retail_streaming_autoloader.py",
                "parameters": [
                    "--source",
                    "pos_transactions",
                    "--source-path",
                    f"gs://{BRONZE_BUCKET}/pos_transactions",
                    "--target-table",
                    "retail_bronze.pos_transactions",
                    "--checkpoint-path",
                    f"gs://{CHECKPOINT_BUCKET}/pos_transactions",
                    "--schema-path",
                    f"gs://{CHECKPOINT_BUCKET}/schemas/pos_transactions",
                ],
            },
        },
    )

    dbt_build = BashOperator(
        task_id="dbt_build_bigquery_marts",
        bash_command=(
            "cd {{ var.value.dbt_project_dir }} && "
            "dbt deps && "
            "dbt build --target {{ var.value.retail_environment }} "
            "--select state:modified+ gold+ --profiles-dir ."
        ),
        env={
            "GCP_PROJECT_ID": GCP_PROJECT_ID,
            "DBT_TARGET": ENVIRONMENT,
            "BIGQUERY_LOCATION": Variable.get("bigquery_location", default_var="us-central1"),
            "DBT_BRONZE_DATASET": Variable.get("dbt_bronze_dataset", default_var="retail_lakehouse_dev_bronze"),
            "DBT_SILVER_DATASET": Variable.get("dbt_silver_dataset", default_var="retail_lakehouse_dev_silver"),
        },
    )

    quality_gate = BigQueryCheckOperator(
        task_id="bigquery_quality_gate",
        sql="""
        SELECT COUNTIF(units_sold < 0 OR gross_revenue < 0) = 0
        FROM `{{ var.value.gcp_project_id }}.{{ var.value.dbt_gold_dataset }}.fct_daily_sales`
        """,
        use_legacy_sql=False,
    )

    smoke_tests = BashOperator(
        task_id="smoke_tests",
        bash_command="bash /home/airflow/gcs/data/scripts/smoke_test.sh",
        env={
            "PROJECT_ID": GCP_PROJECT_ID,
            "ENVIRONMENT": ENVIRONMENT,
        },
    )

    end = EmptyOperator(task_id="end")

    start >> databricks_autoload_pos >> dbt_build >> quality_gate >> smoke_tests >> end
