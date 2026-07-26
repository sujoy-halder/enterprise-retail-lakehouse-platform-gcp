# ruff: noqa: F821
from delta.tables import DeltaTable
from pyspark.sql import functions as F

source_table = dbutils.widgets.get("source_table")
target_table = dbutils.widgets.get("target_table")

cdc_updates = (
    spark.read.table(source_table)
    .withColumn("sequence_ts", F.to_timestamp("event_time"))
    .withColumn(
        "record_hash",
        F.sha2(
            F.concat_ws(
                "||",
                F.col("store_id"),
                F.col("sku"),
                F.col("on_hand_quantity"),
                F.col("reserved_quantity"),
                F.col("event_time"),
            ),
            256,
        ),
    )
)

target = DeltaTable.forName(spark, target_table)

(
    target.alias("t")
    .merge(
        cdc_updates.alias("s"),
        "t.store_id = s.store_id AND t.sku = s.sku",
    )
    .whenMatchedDelete(condition="s.operation = 'DELETE'")
    .whenMatchedUpdate(
        condition="s.sequence_ts >= t.last_event_time AND s.record_hash <> t.record_hash",
        set={
            "on_hand_quantity": "s.on_hand_quantity",
            "reserved_quantity": "s.reserved_quantity",
            "last_event_time": "s.sequence_ts",
            "record_hash": "s.record_hash",
            "updated_at": "current_timestamp()",
        },
    )
    .whenNotMatchedInsert(
        condition="s.operation <> 'DELETE'",
        values={
            "store_id": "s.store_id",
            "sku": "s.sku",
            "on_hand_quantity": "s.on_hand_quantity",
            "reserved_quantity": "s.reserved_quantity",
            "last_event_time": "s.sequence_ts",
            "record_hash": "s.record_hash",
            "updated_at": "current_timestamp()",
        },
    )
    .execute()
)
