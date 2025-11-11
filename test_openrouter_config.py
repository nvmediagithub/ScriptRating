#!/usr/bin/env python3
"""
Test script to verify OpenRouter configuration is working correctly.
"""
import os
import sys
sys.path.append('/Users/user/Documents/Repositories/ScriptRating')

from config.settings import settings

def test_openrouter_configuration():
    """Test OpenRouter configuration from environment variables."""
    print("=== OpenRouter Configuration Test ===\n")
    
    # Test environment variable reading
    print("1. Environment Variables:")
    openrouter_api_key = os.getenv("OPENROUTER_API_KEY")
    openrouter_base_model = os.getenv("OPENROUTER_BASE_MODEL")
    openrouter_base_url = os.getenv("OPENROUTER_BASE_URL")
    
    print(f"   OPENROUTER_API_KEY: {'✓ Set' if openrouter_api_key else '✗ Not set'}")
    print(f"   OPENROUTER_BASE_MODEL: {openrouter_base_model or '✗ Not set'}")
    print(f"   OPENROUTER_BASE_URL: {openrouter_base_url or '✗ Not set'}")
    
    print("\n2. Settings Object:")
    print(f"   settings.openrouter_api_key: {'✓ Set' if settings.openrouter_api_key else '✗ Not set'}")
    print(f"   settings.openrouter_base_model: {settings.openrouter_base_model or '✗ Not set'}")
    print(f"   settings.openrouter_base_url: {settings.openrouter_base_url}")
    
    print("\n3. Effective Values (get_openrouter methods):")
    effective_api_key = settings.get_openrouter_api_key()
    effective_base_model = settings.get_openrouter_base_model()
    
    print(f"   settings.get_openrouter_api_key(): {'✓ Set' if effective_api_key else '✗ Not set'}")
    print(f"   settings.get_openrouter_base_model(): {effective_base_model or '✗ Not set'}")
    
    print("\n4. Configuration Summary:")
    if effective_api_key and effective_base_model:
        print(f"   ✓ OpenRouter is properly configured")
        print(f"   ✓ Base model: {effective_base_model}")
        print(f"   ✓ API key: {effective_api_key[:8]}...")
        print(f"   ✓ Base URL: {openrouter_base_url or 'default'}")
    else:
        print(f"   ✗ OpenRouter configuration incomplete")
        if not effective_api_key:
            print(f"     - Missing API key")
        if not effective_base_model:
            print(f"     - Missing base model")
    
    print("\n5. Testing LLM Service Integration:")
    
    # Test that the config objects in LLM routes can access the settings
    try:
        from app.presentation.api.routes.llm_simple import config as llm_simple_config
        simple_base_model = llm_simple_config.get_openrouter_base_model()
        print(f"   ✓ llm_simple config can access base model: {simple_base_model}")
    except Exception as e:
        print(f"   ✗ Error accessing llm_simple config: {e}")
    
    try:
        from app.presentation.api.routes.llm_simple_v2 import config as llm_v2_config
        v2_base_model = llm_v2_config.get_openrouter_base_model()
        print(f"   ✓ llm_simple_v2 config can access base model: {v2_base_model}")
    except Exception as e:
        print(f"   ✗ Error accessing llm_simple_v2 config: {e}")
    
    print("\n6. Expected vs Actual:")
    expected_model = "minimax/minimax-m2:free"
    actual_model = effective_base_model
    
    if actual_model == expected_model:
        print(f"   ✓ Model configuration is correct: {actual_model}")
    else:
        print(f"   ✗ Model configuration mismatch:")
        print(f"     Expected: {expected_model}")
        print(f"     Actual: {actual_model}")
    
    return effective_api_key is not None and effective_base_model is not None

if __name__ == "__main__":
    success = test_openrouter_configuration()
    print(f"\n=== Test {'PASSED' if success else 'FAILED'} ===")
    sys.exit(0 if success else 1)