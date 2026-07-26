import argparse

from pyspark.sql import SparkSession, functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--source-path", required=True)
    parser.add_argument("--target-table", required=True)
    parser.add_argument("--checkpoint-path", required=True)
    parser.add_argument("--schema-path", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.appName(f"retail-autoloader-{args.source}").getOrCreate()
    spark.conf.set("spark.databricks.delta.schema.autoMerge.enabled", "true")

    stream = (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "json")
        .option("cloudFiles.schemaLocation", args.schema_path)
        .option("cloudFiles.schemaEvolutionMode", "rescue")
        .option("cloudFiles.inferColumnTypes", "true")
        .option("rescuedDataColumn", "_rescued_data")
        .load(args.source_path)
        .withColumn("_ingestion_time", F.current_timestamp())
        .withColumn("_source_file", F.input_file_name())
    )

    (
        stream.writeStream.format("delta")
        .option("checkpointLocation", args.checkpoint_path)
        .option("mergeSchema", "true")
        .trigger(availableNow=True)
        .toTable(args.target_table)
    )


if __name__ == "__main__":
    main()

