#!/usr/bin/env python3
"""Start Qdrant in-memory server for testing."""

import asyncio
import sys
import os
import subprocess
import time

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

def start_qdrant_server():
    """Start Qdrant server using Docker or in-memory mode."""
    print("Attempting to start Qdrant server...")

    # Try Docker first
    try:
        print("Trying to start Qdrant with Docker...")
        result = subprocess.run([
            "docker", "run", "-d",
            "--name", "qdrant-test",
            "-p", "6333:6333",
            "-p", "6334:6334",
            "-v", f"{os.getcwd()}/storage/qdrant:/qdrant/storage",
            "qdrant/qdrant"
        ], capture_output=True, text=True)

        if result.returncode == 0:
            print("✓ Qdrant started with Docker")
            print("Waiting for server to be ready...")
            time.sleep(5)
            return True
        else:
            print(f"✗ Docker failed: {result.stderr}")

    except FileNotFoundError:
        print("Docker not found, trying alternative methods...")

    # Try using Qdrant binary directly (if installed)
    try:
        print("Trying to start Qdrant binary...")
        result = subprocess.run([
            "qdrant", "--config-path", "config/qdrant.yaml"
        ], capture_output=True, text=True)

        if result.returncode == 0:
            print("✓ Qdrant started with binary")
            return True
        else:
            print(f"✗ Binary failed: {result.stderr}")

    except FileNotFoundError:
        print("Qdrant binary not found")

    # Fallback: Use in-memory Qdrant via Python client for testing
    print("Falling back to in-memory mode for testing...")
    print("Note: In-memory mode will lose data when the script ends")
    print("For production, install Qdrant properly:")
    print("  Docker: docker run -p 6333:6333 qdrant/qdrant")
    print("  Binary: Download from https://github.com/qdrant/qdrant/releases")

    return False

if __name__ == "__main__":
    success = start_qdrant_server()
    if success:
        print("\n✓ Qdrant server started successfully!")
        print("You can now run your RAG tests.")
        print("Press Ctrl+C to stop the server.")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nStopping Qdrant server...")
            subprocess.run(["docker", "stop", "qdrant-test"], capture_output=True)
            subprocess.run(["docker", "rm", "qdrant-test"], capture_output=True)
            print("✓ Server stopped.")
    else:
        print("\n✗ Failed to start Qdrant server.")
        print("Please install Qdrant and try again.")
        sys.exit(1)