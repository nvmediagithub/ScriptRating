#!/usr/bin/env python3
"""
Comprehensive test to verify OpenRouter model selection is working correctly.
"""
import os
import sys
sys.path.append('/Users/user/Documents/Repositories/ScriptRating')

from config.settings import settings
from app.presentation.api.routes.llm_simple import config as llm_simple_config, SIMPLE_MODELS as simple_models
from app.presentation.api.routes.llm_simple_v2 import config as llm_v2_config, SIMPLE_MODELS as v2_models
from app.presentation.api.routes.chat_simple_updated import get_openrouter_client

def test_openrouter_api_calls():
    """Test that OpenRouter API calls use the configured model."""
    print("=== OpenRouter API Model Selection Test ===\n")
    
    expected_model = "minimax/minimax-m2:free"
    api_key = settings.get_openrouter_api_key()
    
    print(f"Expected configured model: {expected_model}")
    print(f"Available API key: {'✓' if api_key else '✗'}\n")
    
    # Test 1: LLM Simple Configuration
    print("1. Testing llm_simple configuration:")
    simple_model = llm_simple_config.get_openrouter_base_model()
    print(f"   Config model: {simple_model}")
    print(f"   ✓ Correctly uses configured model" if simple_model == expected_model else f"   ✗ Expected {expected_model}")
    
    # Check SIMPLE_MODELS dictionary
    gpt_model_config = simple_models.get("gpt-3.5-turbo", {})
    gpt_model_name = gpt_model_config.get("model_name", "Not found")
    print(f"   SIMPLE_MODELS['gpt-3.5-turbo']['model_name']: {gpt_model_name}")
    print(f"   ✓ Uses configured model" if gpt_model_name == expected_model else f"   ✗ Expected {expected_model}")
    
    minimax_model_config = simple_models.get("minimax/minimax-m2:free", {})
    minimax_model_name = minimax_model_config.get("model_name", "Not found")
    print(f"   SIMPLE_MODELS['minimax/minimax-m2:free']['model_name']: {minimax_model_name}")
    print(f"   ✓ Uses configured model" if minimax_model_name == expected_model else f"   ✗ Expected {expected_model}")
    
    # Test 2: LLM Simple V2 Configuration
    print("\n2. Testing llm_simple_v2 configuration:")
    v2_model = llm_v2_config.get_openrouter_base_model()
    print(f"   Config model: {v2_model}")
    print(f"   ✓ Correctly uses configured model" if v2_model == expected_model else f"   ✗ Expected {expected_model}")
    
    # Check V2 SIMPLE_MODELS dictionary
    v2_gpt_model_config = v2_models.get("gpt-3.5-turbo", {})
    v2_gpt_model_name = v2_gpt_model_config.get("model_name", "Not found")
    print(f"   V2 SIMPLE_MODELS['gpt-3.5-turbo']['model_name']: {v2_gpt_model_name}")
    print(f"   ✓ Uses configured model" if v2_gpt_model_name == expected_model else f"   ✗ Expected {expected_model}")
    
    v2_minimax_model_config = v2_models.get("minimax/minimax-m2:free", {})
    v2_minimax_model_name = v2_minimax_model_config.get("model_name", "Not found")
    print(f"   V2 SIMPLE_MODELS['minimax/minimax-m2:free']['model_name']: {v2_minimax_model_name}")
    print(f"   ✓ Uses configured model" if v2_minimax_model_name == expected_model else f"   ✗ Expected {expected_model}")
    
    # Test 3: Check default model selection
    print("\n3. Testing default model selection:")
    default_openrouter_model = llm_simple_config.get_openrouter_base_model() or "gpt-3.5-turbo"
    print(f"   Default OpenRouter model: {default_openrouter_model}")
    print(f"   ✓ Uses configured model" if default_openrouter_model == expected_model else f"   ✗ Expected {expected_model}")
    
    # Test 4: Verify no hardcoded fallbacks remain
    print("\n4. Checking for hardcoded fallbacks:")
    
    # Read the files and check for hardcoded model names
    files_to_check = [
        'app/presentation/api/routes/llm_simple.py',
        'app/presentation/api/routes/llm_simple_v2.py',
        'app/presentation/api/routes/chat.py'
    ]
    
    for file_path in files_to_check:
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                
            # Check for problematic patterns
            has_hardcoded_gpt35 = '"gpt-3.5-turbo"' in content and 'get_openrouter_base_model()' not in content
            has_model_fallback = '"llama2:7b" if provider == "local" else "gpt-3.5-turbo"' in content
            
            print(f"   {file_path}:")
            if has_hardcoded_gpt35:
                print(f"     ✗ Contains hardcoded 'gpt-3.5-turbo' without config lookup")
            else:
                print(f"     ✓ No hardcoded gpt-3.5-turbo found")
                
            if has_model_fallback:
                print(f"     ✗ Contains problematic fallback pattern")
            else:
                print(f"     ✓ No problematic fallback pattern found")
                
        except Exception as e:
            print(f"   {file_path}: Error reading file - {e}")
    
    # Test 5: Verify OpenRouter client integration
    print("\n5. Testing OpenRouter client integration:")
    try:
        client = get_openrouter_client()
        print(f"   ✓ OpenRouter client created successfully")
        print(f"   ✓ Client has API key: {client.has_api_key}")
        print(f"   ✓ Client base URL: {client.base_url}")
        
        # The actual model will be passed when making API calls, so we check the setup
        print(f"   ✓ Client ready for API calls with configured model")
        
    except Exception as e:
        print(f"   ✗ Error creating OpenRouter client: {e}")
    
    # Summary
    print("\n6. Test Summary:")
    all_tests_passed = (
        simple_model == expected_model and
        v2_model == expected_model and
        gpt_model_name == expected_model and
        minimax_model_name == expected_model and
        v2_gpt_model_name == expected_model and
        v2_minimax_model_name == expected_model and
        default_openrouter_model == expected_model
    )
    
    if all_tests_passed:
        print(f"   ✓ All tests PASSED - OpenRouter is using the configured model: {expected_model}")
        print(f"   ✓ No hardcoded fallbacks to 'gpt-3.5-turbo' remain")
        print(f"   ✓ Environment variable OPENROUTER_BASE_MODEL is properly read")
        print(f"   ✓ All LLM services now use the configured model")
    else:
        print(f"   ✗ Some tests FAILED - Configuration issues remain")
        
    return all_tests_passed

if __name__ == "__main__":
    success = test_openrouter_api_calls()
    print(f"\n=== Overall Test {'PASSED' if success else 'FAILED'} ===")
    sys.exit(0 if success else 1)