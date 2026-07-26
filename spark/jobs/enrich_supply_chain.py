import argparse
import os

from pyspark.sql import SparkSession, functions as F


def default_uri(bucket_env: str, suffix: str) -> str | None:
    bucket = os.environ.get(bucket_env)
    return f"gs://{bucket}/{suffix}" if bucket else None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default=default_uri("BRONZE_BUCKET", "supply_chain_events"),
    )
    parser.add_argument(
        "--output",
        default=default_uri("SILVER_BUCKET", "supply_chain_events"),
    )
    args = parser.parse_args()
    if not args.input or not args.output:
        raise SystemExit(
            "Provide --input and --output or set BRONZE_BUCKET and SILVER_BUCKET."
        )
    return args


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.appName("retail-supply-chain-enrichment").getOrCreate()

    raw = spark.read.json(args.input)
    enriched = (
        raw.withColumn("event_time", F.to_timestamp("event_time"))
        .withColumn("event_date", F.to_date("event_time"))
        .withColumn("carrier", F.upper(F.col("carrier")))
        .withColumn("late_flag", F.col("estimated_delay_minutes") > F.lit(30))
        .withColumn("_processed_time", F.current_timestamp())
        .dropDuplicates(["shipment_id", "event_time"])
    )

    (
        enriched.write.format("delta")
        .mode("append")
        .partitionBy("event_date")
        .option("mergeSchema", "true")
        .save(args.output)
    )


if __name__ == "__main__":
    main()
