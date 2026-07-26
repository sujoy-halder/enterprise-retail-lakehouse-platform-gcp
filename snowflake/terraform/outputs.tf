output "database_name" {
  value = snowflake_database.retail.name
}

output "finance_warehouse" {
  value = snowflake_warehouse.finance.name
}

output "inventory_warehouse" {
  value = snowflake_warehouse.inventory.name
}

