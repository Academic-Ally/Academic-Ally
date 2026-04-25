"""Backend configuration loaded from environment / .env."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    gemini_api_key: str
    tavily_api_key: str
    llm_model: str = "gemini/gemini-2.5-flash-lite"
    backend_admin_key: str
    google_application_credentials: str | None = None
    backend_storage_bucket: str = "academic-ally-app.appspot.com"
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


settings = Settings()
