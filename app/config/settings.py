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
    openrouter_base_model: Optional[str] = None
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    openrouter_referer: Optional[str] = None
    openrouter_app_name: Optional[str] = "ScriptRating"
    openrouter_timeout: int = 30
    
    # Enhanced Embedding Service Configuration
    embedding_primary_provider: str = "openrouter"  # Changed to OpenRouter for free embeddings
    openai_embedding_api_key: Optional[str] = None
    openai_embedding_model: str = "text-embedding-3-large"
    huggingface_api_token: Optional[str] = None
    local_embedding_model: str = "all-MiniLM-L6-v2"  # Removed - no longer used
    embedding_batch_size: int = 50  # Reduced for stability
    embedding_cache_ttl: int = 604800  # 7 days
    embedding_timeout: float = 10.0  # New timeout setting
    
    # Additional environment variables (for GUI compatibility)
    OPENROUTER_API_KEY: Optional[str] = None
    OPENROUTER_BASE_MODEL: Optional[str] = None
    OPENAI_EMBEDDING_API_KEY: Optional[str] = None
    HUGGINGFACE_API_TOKEN: Optional[str] = None
    
    storage_root: str = "storage"
    documents_dir: str = "storage/documents"

    # Qdrant Vector Database Configuration
    qdrant_url: str = "http://localhost:6333"
    qdrant_collection: str = "script_rating_rag"
    qdrant_vector_size: int = 1536  # Default for OpenAI text-embedding-3-large
    qdrant_distance_metric: str = "Cosine"
    qdrant_replication_factor: int = 1
    qdrant_write_consistency_factor: int = 1
    qdrant_on_disk_payload: bool = True
    qdrant_hnsw_config_m: int = 16
    qdrant_hnsw_config_ef_construct: int = 100
    qdrant_timeout: int = 30

    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Allow extra environment variables for RAG system

    def _get_env_var_or_setting(self, env_var: str, setting_value) -> Optional[str]:
        """Get environment variable or use setting value."""
        env_value = os.getenv(env_var)
        if env_value:
            return env_value
        return setting_value

    @property
    def effective_openrouter_api_key(self) -> Optional[str]:
        """Get OpenRouter API key from environment or settings."""
        return self._get_env_var_or_setting("OPENROUTER_API_KEY", self.openrouter_api_key)

    @property  
    def effective_openrouter_base_model(self) -> Optional[str]:
        """Get OpenRouter base model from environment or settings."""
        return self._get_env_var_or_setting("OPENROUTER_BASE_MODEL", self.openrouter_base_model)

    def get_openrouter_api_key(self) -> Optional[str]:
        """Get OpenRouter API key from environment or settings."""
        return self.effective_openrouter_api_key

    def get_openrouter_base_model(self) -> Optional[str]:
        """Get OpenRouter base model from environment or settings."""
        return self.effective_openrouter_base_model

    # Enhanced embedding configuration methods
    @property
    def effective_embedding_provider(self) -> str:
        """Get effective embedding provider."""
        return os.getenv("EMBEDDING_PRIMARY_PROVIDER", self.embedding_primary_provider)

    @property
    def effective_openai_embedding_api_key(self) -> Optional[str]:
        """Get OpenAI embedding API key from environment or settings."""
        return self._get_env_var_or_setting("OPENAI_EMBEDDING_API_KEY", self.openai_embedding_api_key)

    @property
    def effective_huggingface_api_token(self) -> Optional[str]:
        """Get HuggingFace API token from environment or settings."""
        return self._get_env_var_or_setting("HUGGINGFACE_API_TOKEN", self.huggingface_api_token)

    def get_embedding_config(self) -> dict:
        """Get complete embedding configuration with stable settings."""
        return {
            "primary_provider": self.effective_embedding_provider,
            "openai_api_key": self.effective_openai_embedding_api_key,
            "openai_model": self.openai_embedding_model,
            "openrouter_api_key": self.effective_openrouter_api_key,
            "huggingface_token": self.effective_huggingface_api_token,
            "local_model": self.local_embedding_model,  # Kept for backward compatibility
            "batch_size": self.embedding_batch_size,
            "cache_ttl": self.embedding_cache_ttl,
            "embedding_timeout": self.embedding_timeout,
            "stable_mode": True,  # Indicates stable embedding service
            "free_priority": True  # Indicates focus on free solutions
        }


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