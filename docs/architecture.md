# Architecture

## Platform Flow

```mermaid
flowchart LR
  ERP[ERP Databases] --> INF[Informatica CDC]
  API[Retail APIs] --> PUB[Pub/Sub]
  CSV[Supplier CSV] --> INF
  IOT[Warehouse IoT] --> PUB
  KAFKA[Kafka Streams] --> PUB

  INF --> PUB
  PUB --> GCSB[Cloud Storage Bronze]
  GCSB --> DBX[Databricks Auto Loader and DLT]
  DBX --> DELTA[Delta Lake Silver and Gold]
  DELTA --> BQ[BigQuery Marts]
  BQ --> DBT[dbt Models and Tests]
  DBT --> BI[BI Reporting]
  BQ --> SF[Snowflake Cross-cloud Marts]

  GKE[GKE ETL Services and APIs] --> PUB
  GKE --> BQ
  COMPOSER[Cloud Composer] --> DBX
  COMPOSER --> DBT
  COMPOSER --> SF
  MON[Cloud Monitoring and Grafana] --> COMPOSER
  MON --> GKE
  MON --> PUB
```

## Layers

Bronze stores replayable raw records in Cloud Storage and Delta tables. Silver applies schema enforcement, deduplication, CDC, and enrichment. Gold exposes business marts for sales analytics, inventory forecasting, customer analytics, and supply-chain KPIs.

## Runtime Ownership

- Terraform owns GCP foundations and IAM.
- Kubernetes owns runtime services and SparkApplication specs.
- Databricks owns Auto Loader, DLT, and Delta CDC logic.
- dbt owns BigQuery transformations and data quality tests.
- Snowflake owns cross-cloud marts and executive views.
- Composer owns recurring orchestration.
- GitHub Actions owns deployment ordering and gates.

