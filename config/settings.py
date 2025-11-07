import os
from typing import List, Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Application settings
    app_name: str = "Script Rating Backend"
    debug: bool = False
    secret_key: str = "your-secret-key-here"

    # API settings
    api_host: str = "0.0.0.0"
    api_port: int = 8000

    # Database settings
    database_url: str = "sqlite+aiosqlite:///./script_rating.db"

    # CORS settings
    cors_origins: List[str] = [
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8080",
        "http://localhost:4000",
        "http://localhost:5001",
        "http://localhost:8080",
        "http://localhost:9000",
        # Flutter Web specific ports
        "http://localhost:50303",
        "http://localhost:62269",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:4000",
        "http://127.0.0.1:5001",
        "http://127.0.0.1:50303",
        "http://127.0.0.1:62269",
        "http://127.0.0.1:9000",
    ]

    # Logging
    log_level: str = "INFO"

    # File upload settings
    max_upload_size: int = 10 * 1024 * 1024  # 10MB

    # OpenRouter integration
    openrouter_api_key: Optional[str] = None
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    openrouter_referer: Optional[str] = None
    openrouter_app_name: Optional[str] = "ScriptRating"
    openrouter_timeout: int = 30
    storage_root: str = "storage"
    documents_dir: str = "storage/documents"

    class Config:
        env_file = ".env"
        case_sensitive = False


# Create settings instance
settings = Settings()


# Environment-specific configurations
def get_settings() -> Settings:
    """Get settings based on environment"""
    env = os.getenv("ENVIRONMENT", "development")

    if env == "production":
        return Settings(
            debug=False,
            database_url=os.getenv("DATABASE_URL", settings.database_url),
            cors_origins=os.getenv("CORS_ORIGINS", "").split(",") if os.getenv("CORS_ORIGINS") else settings.cors_origins,
        )
    elif env == "testing":
        return Settings(
            debug=False,
            database_url="sqlite+aiosqlite:///./test.db",
            log_level="DEBUG",
        )

    # Default development settings
    return settings
