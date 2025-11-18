#!/usr/bin/env python3
"""Test Qdrant connection and diagnostics."""

import asyncio
import sys
import os

# Add the app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from qdrant_client import AsyncQdrantClient
from app.config.settings import settings

async def test_qdrant_connection():
    """Test connection to Qdrant database."""
    print("Testing Qdrant connection...")
    print(f"Qdrant URL: {settings.qdrant_url}")
    print(f"Collection: {settings.qdrant_collection}")

    # First, try in-memory mode as fallback
    print("\n--- Testing in-memory mode (fallback) ---")
    client_memory = None
    try:
        client_memory = AsyncQdrantClient(location=":memory:")
        collections = await client_memory.get_collections()
        print("✓ In-memory connection successful!")
        print("Note: Using in-memory mode - data will not persist")
    except Exception as e:
        print(f"✗ In-memory failed: {e}")
    finally:
        if client_memory:
            await client_memory.close()

    print("\n--- Testing configured Qdrant server ---")
    client = None
    try:
        # Try to connect to configured server
        client = AsyncQdrantClient(
            url=settings.qdrant_url,
            timeout=settings.qdrant_timeout
        )

        print("Attempting to get collections...")
        collections = await client.get_collections()
        print("✓ Connection successful!")

        collection_names = [c.name for c in collections.collections]
        print(f"Available collections: {collection_names}")

        if settings.qdrant_collection in collection_names:
            print(f"✓ Collection '{settings.qdrant_collection}' exists")

            # Get collection info
            info = await client.get_collection(settings.qdrant_collection)
            print(f"Collection info:")
            print(f"  - Points count: {info.points_count}")
            print(f"  - Vectors count: {info.vectors_count}")
            print(f"  - Status: {info.status}")
        else:
            print(f"✗ Collection '{settings.qdrant_collection}' does not exist")

    except Exception as e:
        print(f"✗ Connection failed: {e}")
        print(f"Error type: {type(e).__name__}")

        # Check if it's a connection error
        if "connect" in str(e).lower():
            print("\nPossible causes:")
            print("1. Qdrant server is not running")
            print("2. Qdrant is running on a different port")
            print("3. Firewall blocking the connection")
            print("4. URL configuration issue")
            print("\nSolutions:")
            print("- Install Qdrant: docker run -p 6333:6333 qdrant/qdrant")
            print("- Or use in-memory mode for testing (data won't persist)")
        elif "timeout" in str(e).lower():
            print("\nPossible causes:")
            print("1. Qdrant server is slow/unresponsive")
            print("2. Network connectivity issues")
            print("3. Timeout value too low")

    finally:
        if client:
            await client.close()

async def create_test_collection():
    """Create a test collection in memory for immediate testing."""
    print("\n--- Creating test collection ---")
    client = None
    try:
        client = AsyncQdrantClient(location=":memory:")

        from qdrant_client.models import VectorParams, Distance

        # Create collection with same settings as config
        await client.create_collection(
            collection_name=settings.qdrant_collection,
            vectors_config=VectorParams(
                size=settings.qdrant_vector_size,
                distance=Distance.COSINE
            )
        )

        print(f"✓ Created test collection '{settings.qdrant_collection}' in memory")

        # Test basic operations
        from qdrant_client.models import PointStruct
        await client.upsert(
            collection_name=settings.qdrant_collection,
            points=[
                PointStruct(
                    id=1,
                    vector=[0.1] * settings.qdrant_vector_size,
                    payload={"test": True, "text": "This is a test document"}
                )
            ]
        )
        print("✓ Successfully inserted test document")

        # Test search
        results = await client.search(
            collection_name=settings.qdrant_collection,
            query_vector=[0.1] * settings.qdrant_vector_size,
            limit=1
        )
        print(f"✓ Search successful, found {len(results)} results")

        return True

    except Exception as e:
        print(f"✗ Failed to create test collection: {e}")
        return False
    finally:
        if client:
            await client.close()

if __name__ == "__main__":
    async def main():
        await test_qdrant_connection()
        success = await create_test_collection()

        if success:
            print("\n✓ RAG system can work with in-memory Qdrant for testing")
            print("⚠️  For production, install a persistent Qdrant server:")
            print("   docker run -d -p 6333:6333 -v qdrant_data:/qdrant/storage qdrant/qdrant")
        else:
            print("\n✗ Even in-memory mode failed - check your setup")

    asyncio.run(main())