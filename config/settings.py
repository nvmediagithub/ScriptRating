import os
from typing import List

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
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:4000",
    ]

    # Logging
    log_level: str = "INFO"

    # File upload settings
    max_upload_size: int = 10 * 1024 * 1024  # 10MB

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