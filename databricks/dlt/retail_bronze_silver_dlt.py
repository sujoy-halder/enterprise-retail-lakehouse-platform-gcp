# ruff: noqa: F821
import dlt
from pyspark.sql import functions as F


SOURCE_BASE = spark.conf.get("retail.source_base")
SCHEMA_BASE = spark.conf.get("retail.schema_base")


def autoload(source_name: str):
    return (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "json")
        .option("cloudFiles.schemaLocation", f"{SCHEMA_BASE}/{source_name}")
        .option("cloudFiles.schemaEvolutionMode", "rescue")
        .option("cloudFiles.inferColumnTypes", "true")
        .option("rescuedDataColumn", "_rescued_data")
        .load(f"{SOURCE_BASE}/{source_name}")
        .withColumn("_ingestion_time", F.current_timestamp())
        .withColumn("_source_file", F.input_file_name())
    )


@dlt.table(
    name="bronze_pos_transactions",
    comment="Raw POS transactions from Auto Loader.",
    table_properties={"quality": "bronze", "delta.enableChangeDataFeed": "true"},
)
def bronze_pos_transactions():
    return autoload("pos_transactions")


@dlt.table(
    name="bronze_inventory_cdc",
    comment="Raw inventory CDC events from ERP and warehouse systems.",
    table_properties={"quality": "bronze", "delta.enableChangeDataFeed": "true"},
)
def bronze_inventory_cdc():
    return autoload("inventory")


@dlt.table(
    name="silver_pos_transactions",
    comment="Validated, deduplicated POS transaction stream.",
    table_properties={"quality": "silver"},
)
@dlt.expect_or_drop("valid_transaction_id", "transaction_id IS NOT NULL")
@dlt.expect_or_drop("valid_store", "store_id IS NOT NULL")
@dlt.expect_or_drop("non_negative_quantity", "quantity >= 0")
def silver_pos_transactions():
    return (
        dlt.read_stream("bronze_pos_transactions")
        .select(
            F.col("transaction_id").cast("string"),
            F.col("store_id").cast("string"),
            F.col("customer_id").cast("string"),
            F.col("product_id").cast("string"),
            F.col("quantity").cast("long"),
            F.col("unit_price").cast("decimal(18,2)"),
            F.col("currency").cast("string"),
            F.to_timestamp("event_time").alias("event_time"),
            F.col("_ingestion_time"),
            F.col("_source_file"),
            F.sha2(
                F.concat_ws(
                    "||",
                    F.col("transaction_id"),
                    F.col("store_id"),
                    F.col("product_id"),
                    F.col("event_time"),
                ),
                256,
            ).alias("record_hash"),
        )
        .withWatermark("event_time", "1 day")
        .dropDuplicates(["transaction_id", "record_hash"])
    )


@dlt.view(name="inventory_cdc_clean")
def inventory_cdc_clean():
    return (
        dlt.read_stream("bronze_inventory_cdc")
        .select(
            F.col("inventory_event_id").cast("string"),
            F.col("store_id").cast("string"),
            F.col("sku").cast("string"),
            F.col("operation").cast("string").alias("op"),
            F.col("on_hand_quantity").cast("long"),
            F.col("reserved_quantity").cast("long"),
            F.to_timestamp("event_time").alias("event_time"),
            F.col("_ingestion_time"),
        )
        .filter("sku IS NOT NULL AND store_id IS NOT NULL AND event_time IS NOT NULL")
    )


dlt.create_streaming_table(
    name="silver_inventory_current",
    comment="Current inventory position maintained through CDC.",
    table_properties={"quality": "silver", "delta.enableChangeDataFeed": "true"},
)

dlt.apply_changes(
    target="silver_inventory_current",
    source="inventory_cdc_clean",
    keys=["store_id", "sku"],
    sequence_by=F.col("event_time"),
    apply_as_deletes=F.expr("op = 'DELETE'"),
    except_column_list=["op"],
    stored_as_scd_type=1,
)


@dlt.table(
    name="gold_daily_sales",
    comment="Business-ready daily sales mart.",
    table_properties={"quality": "gold"},
)
def gold_daily_sales():
    return (
        dlt.read("silver_pos_transactions")
        .withColumn("business_date", F.to_date("event_time"))
        .groupBy("business_date", "store_id", "product_id")
        .agg(
            F.sum("quantity").alias("units_sold"),
            F.sum(F.col("quantity") * F.col("unit_price")).alias("gross_revenue"),
            F.current_timestamp().alias("updated_at"),
        )
    )
