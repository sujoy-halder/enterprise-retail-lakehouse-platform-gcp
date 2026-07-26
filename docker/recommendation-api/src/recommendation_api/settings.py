from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    project_id: str = ""
    bigquery_dataset_prefix: str = ""
    environment: str = "dev"
    use_bigquery: bool = True

