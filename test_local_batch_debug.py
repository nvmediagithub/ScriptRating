#!/usr/bin/env python3
"""
Debug test for local provider batch failure.
This will reproduce the exact scenario where batch processing fails.
"""

import asyncio
import logging
import sys
import os

# Add app to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '.'))

from app.infrastructure.services.embedding_service import create_embedding_service

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

async def test_local_batch_debug():
    """Test local provider batch processing with detailed logging."""

    logger.info("🚀 Starting local provider batch debug test")

    # Create service with local as primary
    service = create_embedding_service(
        primary_provider="local",
        local_model="all-MiniLM-L6-v2"
    )

    await service.initialize()

    # Test texts that might cause issues
    test_texts = [
        "Hello world",
        "Simple test text",
        "A longer piece of text to test batch processing capabilities",
        "Another test sentence",
        "Final test text"
    ]

    logger.info(f"📝 Testing with {len(test_texts)} texts")

    try:
        # Test single text first (should work)
        logger.info("🔸 Testing single text embedding...")
        single_result = await service.embed_text("Hello world")
        logger.info(f"✅ Single text worked: provider={single_result.provider}, model={single_result.model}")

        # Test batch processing (this is where it fails)
        logger.info("🔸 Testing batch embedding...")
        batch_results = await service.embed_batch(test_texts)
        logger.info(f"✅ Batch embedding worked: {len(batch_results)} results")

        for i, result in enumerate(batch_results):
            logger.info(f"  Result {i}: provider={result.provider}, model={result.model}")

    except Exception as e:
        logger.error(f"❌ Test failed: {e}")
        raise

    finally:
        await service.close()

if __name__ == "__main__":
    asyncio.run(test_local_batch_debug())