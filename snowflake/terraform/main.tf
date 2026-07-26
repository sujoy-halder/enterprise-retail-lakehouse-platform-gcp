resource "snowflake_database" "retail" {
  name    = var.database_name
  comment = "Enterprise retail analytics database fed from GCP lakehouse."
}

resource "snowflake_warehouse" "finance" {
  name                = var.finance_warehouse_name
  comment             = "Finance mart warehouse."
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_warehouse" "inventory" {
  name                = var.inventory_warehouse_name
  comment             = "Inventory mart warehouse."
  warehouse_size      = "XSMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}

resource "snowflake_schema" "finance_marts" {
  database = snowflake_database.retail.name
  name     = "FINANCE_MARTS"
  comment  = "Finance-ready retail marts."
}

resource "snowflake_schema" "inventory_marts" {
  database = snowflake_database.retail.name
  name     = "INVENTORY_MARTS"
  comment  = "Inventory and merchandising marts."
}

resource "snowflake_schema" "executive_dashboards" {
  database = snowflake_database.retail.name
  name     = "EXECUTIVE_DASHBOARDS"
  comment  = "Executive KPI dashboard tables and secure views."
}

