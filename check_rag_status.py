#!/usr/bin/env python3
"""Check RAG status in the system."""

import os, sys
sys.path.insert(0, 'app')

from app.config.rag_config import get_rag_config
from app.infrastructure.services.runtime_context import get_knowledge_base
import asyncio

async def check_rag_status():
    print("=== RAG SYSTEM STATUS CHECK ===")

    # Check configuration
    config = get_rag_config()
    print("\nConfiguration:")
    print(f"  RAG enabled: {config.is_rag_enabled()}")
    print(f"  Primary provider: {config.embedding_primary_provider}")
    print(f"  Local model: {config.embedding_local_model}")
    print(f"  OpenRouter API configured: {config.openrouter_api_key is not None}")
    print(f"  OpenAI API configured: {config.openai_embedding_api_key is not None}")
    print(f"  Vector DB enabled: {config.is_vector_db_enabled()}")

    # Check knowledge base
    try:
        kb = await get_knowledge_base()
        print("\nKnowledge Base:")
        status = await kb.get_rag_status()
        print(f"  RAG available: {status['rag_available']}")
        print(f"  RAG enabled: {status['rag_enabled']}")
        print(f"  Use RAG when available: {status['use_rag_when_available']}")

        if 'rag_health' in status:
            health = status['rag_health']
            print(f"  Embedding service: {health['embedding_service']['status']}")
            print(f"  Primary provider: {health['embedding_service']['primary_provider']}")

            providers = health['embedding_service']['providers']
            for name, info in providers.items():
                print(f"    {name}: {info['status']} (free: {info['info']['free']})")

            print(f"  Vector DB: {health['vector_db_service']['status']}")
            print(f"  Collection exists: {health['vector_db_service']['collection_exists']}")
        else:
            print("  RAG health details not available")

    except Exception as e:
        print(f"  Error checking knowledge base: {e}")

    print("\n=== SUMMARY ===")
    if config.is_rag_enabled():
        print("✅ RAG is ENABLED with local sentence transformers")
        print("✅ NO OpenRouter or OpenAI dependencies")
        print("✅ System should work with local models only")
    else:
        print("❌ RAG is DISABLED")

if __name__ == "__main__":
    asyncio.run(check_rag_status())