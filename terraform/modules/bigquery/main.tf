locals {
  datasets = {
    bronze     = "Raw landing and replay tables"
    silver     = "Cleaned, validated, and conformed tables"
    gold       = "Business-ready marts"
    reporting  = "BI-serving views and materialized views"
    governance = "Data quality and lineage metadata"
  }
}

resource "google_bigquery_dataset" "datasets" {
  for_each = local.datasets

  project                    = var.project_id
  dataset_id                 = "${var.prefix}_${each.key}"
  friendly_name              = "Retail ${title(each.key)}"
  description                = each.value
  location                   = var.location
  delete_contents_on_destroy = false
  labels                     = merge(var.labels, { data_layer = each.key })

  default_encryption_configuration {
    kms_key_name = var.kms_key_id
  }
}

resource "google_bigquery_table" "bronze_pos_transactions" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.datasets["bronze"].dataset_id
  table_id            = "pos_transactions"
  deletion_protection = true
  labels              = var.labels

  time_partitioning {
    type  = "DAY"
    field = "event_time"
  }

  clustering = ["store_id", "product_id"]

  schema = jsonencode([
    { name = "transaction_id", type = "STRING", mode = "REQUIRED" },
    { name = "store_id", type = "STRING", mode = "REQUIRED" },
    { name = "customer_id", type = "STRING", mode = "NULLABLE" },
    { name = "product_id", type = "STRING", mode = "REQUIRED" },
    { name = "quantity", type = "INT64", mode = "REQUIRED" },
    { name = "unit_price", type = "NUMERIC", mode = "REQUIRED" },
    { name = "currency", type = "STRING", mode = "REQUIRED" },
    { name = "event_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "ingestion_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "_rescued_data", type = "STRING", mode = "NULLABLE" }
  ])
}

resource "google_bigquery_table" "silver_inventory" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.datasets["silver"].dataset_id
  table_id            = "inventory_positions"
  deletion_protection = true
  labels              = var.labels

  time_partitioning {
    type  = "DAY"
    field = "snapshot_time"
  }

  clustering = ["store_id", "sku"]

  schema = jsonencode([
    { name = "inventory_event_id", type = "STRING", mode = "REQUIRED" },
    { name = "store_id", type = "STRING", mode = "REQUIRED" },
    { name = "sku", type = "STRING", mode = "REQUIRED" },
    { name = "on_hand_quantity", type = "INT64", mode = "REQUIRED" },
    { name = "reserved_quantity", type = "INT64", mode = "REQUIRED" },
    { name = "snapshot_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "record_hash", type = "STRING", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "gold_daily_sales" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.datasets["gold"].dataset_id
  table_id            = "daily_sales"
  deletion_protection = true
  labels              = var.labels

  time_partitioning {
    type  = "DAY"
    field = "business_date"
  }

  clustering = ["store_id", "product_id"]

  schema = jsonencode([
    { name = "business_date", type = "DATE", mode = "REQUIRED" },
    { name = "store_id", type = "STRING", mode = "REQUIRED" },
    { name = "product_id", type = "STRING", mode = "REQUIRED" },
    { name = "units_sold", type = "INT64", mode = "REQUIRED" },
    { name = "gross_revenue", type = "NUMERIC", mode = "REQUIRED" },
    { name = "net_revenue", type = "NUMERIC", mode = "NULLABLE" },
    { name = "updated_at", type = "TIMESTAMP", mode = "REQUIRED" }
  ])
}

resource "google_bigquery_table" "reporting_sales_mv" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.datasets["reporting"].dataset_id
  table_id            = "mv_store_sales_daily"
  deletion_protection = true
  labels              = var.labels

  materialized_view {
    enable_refresh      = true
    refresh_interval_ms = 1800000
    query               = <<SQL
SELECT
  business_date,
  store_id,
  product_id,
  SUM(units_sold) AS units_sold,
  SUM(gross_revenue) AS gross_revenue
FROM `${var.project_id}.${google_bigquery_dataset.datasets["gold"].dataset_id}.daily_sales`
GROUP BY business_date, store_id, product_id
SQL
  }

  depends_on = [google_bigquery_table.gold_daily_sales]
}

resource "google_bigquery_table" "governance_quality_events" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.datasets["governance"].dataset_id
  table_id            = "data_quality_events"
  deletion_protection = true
  labels              = var.labels

  time_partitioning {
    type  = "DAY"
    field = "event_time"
  }

  clustering = ["dataset_name", "table_name", "severity"]

  schema = jsonencode([
    { name = "event_id", type = "STRING", mode = "REQUIRED" },
    { name = "dataset_name", type = "STRING", mode = "REQUIRED" },
    { name = "table_name", type = "STRING", mode = "REQUIRED" },
    { name = "check_name", type = "STRING", mode = "REQUIRED" },
    { name = "severity", type = "STRING", mode = "REQUIRED" },
    { name = "failed_records", type = "INT64", mode = "REQUIRED" },
    { name = "event_time", type = "TIMESTAMP", mode = "REQUIRED" }
  ])
}
