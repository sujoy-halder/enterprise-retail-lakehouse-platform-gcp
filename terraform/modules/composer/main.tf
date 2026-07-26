resource "google_composer_environment" "lakehouse" {
  project = var.project_id
  name    = "${var.name_prefix}-composer"
  region  = var.region
  labels  = var.labels

  config {
    environment_size = var.environment_size

    node_config {
      network         = var.network_id
      subnetwork      = var.subnetwork_id
      service_account = var.composer_service_account_email
    }

    software_config {
      env_variables = {
        RETAIL_ENVIRONMENT = lookup(var.labels, "environment", "unknown")
        RETAIL_PLATFORM    = "lakehouse"
      }

      pypi_packages = {
        "apache-airflow-providers-databricks" = ""
        "apache-airflow-providers-snowflake"  = ""
        "astronomer-cosmos"                   = ">=1.8.0"
        "dbt-bigquery"                        = ">=1.8.0,<2.0.0"
      }
    }
  }
}
