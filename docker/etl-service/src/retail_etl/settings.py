from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    project_id: str = ""
    region: str = "us-central1"
    environment: str = "dev"
    bronze_bucket: str = ""
    quarantine_bucket: str = ""
    pos_subscription: str = ""
    inventory_subscription: str = ""
    bigquery_dataset_prefix: str = ""
    log_level: str = "INFO"

    @property
    def required_runtime_values(self) -> dict[str, str]:
        return {
            "PROJECT_ID": self.project_id,
            "BRONZE_BUCKET": self.bronze_bucket,
            "QUARANTINE_BUCKET": self.quarantine_bucket,
        }

