#!/usr/bin/env python3
"""
Main entry point for the Script Rating Backend API.

This module initializes and runs the FastAPI application using clean architecture principles.
"""
import uvicorn
from app.presentation.api.main import create_app


def main():
    """Main entry point to start the FastAPI server."""
    app = create_app()

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )


if __name__ == "__main__":
    main()