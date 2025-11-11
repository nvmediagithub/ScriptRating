"""
Database session management for the application.

This module provides SQLAlchemy session management and database
initialization for the chat functionality and other features.
"""
import logging
from contextlib import contextmanager
from typing import Generator, Optional

from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool

from app.config import settings
from app.models.chat_models import Base as ChatBase

logger = logging.getLogger(__name__)

# SQLAlchemy engine configuration
engine = None
SessionLocal = None


def get_database_url() -> str:
    """Get database URL with proper configuration."""
    url = settings.database_url
    
    # Add SQLite-specific configuration
    if url.startswith("sqlite"):
        # For SQLite, add configuration for better performance and concurrency
        if "?" in url:
            url += "&"
        else:
            url += "?"
        url += "check_same_thread=false&timeout=30"
    
    return url


def create_engine_config() -> dict:
    """Create engine configuration dictionary."""
    config = {
        "poolclass": StaticPool if settings.database_url.startswith("sqlite") else None,
        "pool_pre_ping": True,
        "pool_recycle": 3600,  # 1 hour
        "echo": settings.debug,  # Log SQL queries in debug mode
    }
    
    # SQLite-specific configuration
    if settings.database_url.startswith("sqlite"):
        config.update({
            "connect_args": {
                "check_same_thread": False,
                "timeout": 30,
            }
        })
    
    return config


def initialize_database():
    """Initialize database engine and session factory."""
    global engine, SessionLocal
    
    try:
        database_url = get_database_url()
        engine_config = create_engine_config()
        
        # Create engine
        engine = create_engine(database_url, **engine_config)
        
        # Create session factory
        SessionLocal = sessionmaker(
            autocommit=False, 
            autoflush=False, 
            bind=engine
        )
        
        logger.info(f"Database engine created for URL: {database_url}")
        
        # Set up event listeners
        setup_event_listeners(engine)
        
        # Create all tables
        create_tables()
        
        return engine
        
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise


def create_tables():
    """Create all database tables."""
    try:
        # Only create chat models for this test
        # Chat models are already imported above
        
        # Create tables
        ChatBase.metadata.create_all(bind=engine)
        
        logger.info("Chat database tables created successfully")
        
    except Exception as e:
        logger.error(f"Failed to create database tables: {e}")
        raise


def get_db() -> Generator[Session, None, None]:
    """
    Dependency function to get database session.
    
    This function is used as a FastAPI dependency to provide
    database sessions for API endpoints.
    """
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        db.rollback()
        logger.error(f"Database session error: {e}")
        raise
    finally:
        db.close()


@contextmanager
def get_db_session() -> Generator[Session, None, None]:
    """
    Context manager for database sessions.
    
    Provides automatic session management with commit/rollback.
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception as e:
        db.rollback()
        logger.error(f"Database session error: {e}")
        raise
    finally:
        db.close()


def get_db_dependency():
    """
    Return a dependency function for FastAPI that can be imported.
    
    This allows the chat routes to import the get_db dependency
    without circular imports.
    """
    return get_db


# Database event listeners
def setup_event_listeners(db_engine):
    """Set up database event listeners for the engine."""
    @event.listens_for(db_engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        """Set SQLite-specific settings on connection."""
        if settings.database_url.startswith("sqlite"):
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.execute("PRAGMA journal_mode=WAL")
            cursor.execute("PRAGMA synchronous=NORMAL")
            cursor.execute("PRAGMA temp_store=MEMORY")
            cursor.execute("PRAGMA mmap_size=268435456")  # 256MB
            cursor.close()

    @event.listens_for(db_engine, "checkout")
    def ping_connection(dbapi_connection, connection_record, connection_proxy):
        """Ping connection to ensure it's still valid."""
        if settings.database_url.startswith("sqlite"):
            cursor = dbapi_connection.cursor()
            try:
                cursor.execute("SELECT 1")
            except Exception:
                raise Exception("Database connection is not valid")
            finally:
                cursor.close()


# Initialize database on module import
if not engine:
    try:
        engine = initialize_database()
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        # Don't raise here to allow the app to start in development
        # In production, this should be handled differently


# Health check function
def check_database_health() -> dict:
    """
    Check database connectivity and basic health.
    
    Returns:
        Dictionary with health status information
    """
    try:
        with get_db_session() as db:
            # Simple query to test connectivity
            result = db.execute("SELECT 1")
            result.fetchone()
            
        return {
            "status": "healthy",
            "database": "connected",
            "engine": str(engine) if engine else "not_initialized"
        }
        
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }


# Statistics function
def get_database_stats() -> dict:
    """
    Get database statistics.
    
    Returns:
        Dictionary with database statistics
    """
    try:
        with get_db_session() as db:
            stats = {}
            
            # Get table sizes (SQLite-specific)
            if settings.database_url.startswith("sqlite"):
                result = db.execute("""
                    SELECT name, COUNT(*) as count
                    FROM sqlite_master 
                    WHERE type='table' 
                    AND name NOT LIKE 'sqlite_%'
                    GROUP BY name
                """)
                stats["tables"] = {row[0]: row[1] for row in result}
            
            return stats
            
    except Exception as e:
        logger.error(f"Failed to get database stats: {e}")
        return {"error": str(e)}