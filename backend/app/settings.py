"""Backend configuration loaded from environment / .env."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    gemini_api_key: str
    tavily_api_key: str
    llm_model: str = "gemini/gemini-2.5-flash-lite"
    backend_admin_key: str
    # Firebase service-account credentials. Two equivalent ways:
    #   1. Set FIREBASE_SERVICE_ACCOUNT_JSON to the full service-account.json
    #      content (raw JSON or base64). Friendly for Railway / Render / Fly /
    #      Cloud Run where you can't ship a file alongside the code.
    #   2. Set GOOGLE_APPLICATION_CREDENTIALS to a local file path. Local-dev
    #      friendly since you can keep the file gitignored.
    # If both are set, FIREBASE_SERVICE_ACCOUNT_JSON wins.
    firebase_service_account_json: str | None = None
    google_application_credentials: str | None = None
    backend_storage_bucket: str = "academic-ally-app.appspot.com"
    log_level: str = "INFO"
    demo_fallback_enabled: bool = True

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


settings = Settings()
