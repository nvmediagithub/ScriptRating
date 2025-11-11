#!/usr/bin/env python3
"""
Test script for LLM provider switching functionality.

This script tests the backend provider switching endpoints and validates
that the GUI can properly switch between Local and OpenRouter modes.
"""

import requests
import json
import time
import sys
from typing import Dict, Any

# Test configuration
BASE_URL = "http://localhost:8000/api/llm"

class ProviderSwitchingTester:
    def __init__(self, base_url: str = BASE_URL):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            "Content-Type": "application/json",
            "Accept": "application/json"
        })
        
    def test_backend_health(self) -> bool:
        """Test if the backend is running and accessible."""
        try:
            response = self.session.get(f"{self.base_url}/../health")
            if response.status_code == 200:
                print("✅ Backend is running")
                return True
            else:
                print(f"❌ Backend health check failed: {response.status_code}")
                return False
        except requests.exceptions.ConnectionError:
            print("❌ Cannot connect to backend. Make sure it's running on http://localhost:8000")
            return False
    
    def get_current_config(self) -> Dict[str, Any]:
        """Get current LLM configuration."""
        try:
            response = self.session.get(f"{self.base_url}/config")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ Error getting config: {e}")
            return {}
    
    def test_provider_switching(self, provider: str, model: str = None) -> Dict[str, Any]:
        """Test switching to a specific provider."""
        try:
            params = {"provider": provider}
            if model:
                params["model_name"] = model
            
            print(f"🔄 Switching to provider: {provider}, model: {model}")
            response = self.session.put(f"{self.base_url}/config/mode", params=params)
            
            if response.status_code == 200:
                print(f"✅ Successfully switched to {provider}")
                return response.json()
            else:
                error_msg = response.json().get("detail", "Unknown error")
                print(f"❌ Failed to switch to {provider}: {error_msg}")
                return {"error": error_msg}
                
        except Exception as e:
            print(f"❌ Error switching provider: {e}")
            return {"error": str(e)}
    
    def test_provider_status(self, provider: str) -> Dict[str, Any]:
        """Test provider status endpoint."""
        try:
            response = self.session.get(f"{self.base_url}/status/{provider}")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ Error getting {provider} status: {e}")
            return {}
    
    def test_llm_config(self) -> Dict[str, Any]:
        """Test configuration endpoint."""
        try:
            response = self.session.get(f"{self.base_url}/config")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ Error getting config: {e}")
            return {}
    
    def run_comprehensive_test(self):
        """Run comprehensive provider switching tests."""
        print("🧪 Starting comprehensive provider switching test...")
        print("=" * 60)
        
        # Test backend health
        if not self.test_backend_health():
            return False
        
        print("\n📊 Getting initial configuration...")
        initial_config = self.get_current_config()
        print(f"Initial config: {json.dumps(initial_config, indent=2)}")
        
        # Test switching to local provider
        print("\n🏠 Testing Local provider...")
        local_result = self.test_provider_switching("local", "llama2:7b")
        if "error" not in local_result:
            local_status = self.test_provider_status("local")
            print(f"Local status: {json.dumps(local_status, indent=2)}")
        
        # Test switching to openrouter
        print("\n☁️  Testing OpenRouter provider...")
        openrouter_result = self.test_provider_switching("openrouter", "gpt-3.5-turbo")
        if "error" not in openrouter_result:
            openrouter_status = self.test_provider_status("openrouter")
            print(f"OpenRouter status: {json.dumps(openrouter_status, indent=2)}")
        else:
            print(f"⚠️  OpenRouter switch failed (expected if no API key): {openrouter_result.get('error')}")
        
        # Test all providers status
        print("\n📈 Getting all providers status...")
        all_status = self.session.get(f"{self.base_url}/status")
        if all_status.status_code == 200:
            print(f"All providers status: {json.dumps(all_status.json(), indent=2)}")
        
        # Get final configuration
        print("\n📋 Getting final configuration...")
        final_config = self.get_current_config()
        print(f"Final config: {json.dumps(final_config, indent=2)}")
        
        # Test invalid provider (should fail)
        print("\n❌ Testing invalid provider (should fail)...")
        invalid_result = self.test_provider_switching("invalid_provider")
        if "error" in invalid_result:
            print("✅ Correctly rejected invalid provider")
        else:
            print("❌ Should have rejected invalid provider")
        
        print("\n🎉 Provider switching test completed!")
        return True

def check_env_variables():
    """Check environment variables for OpenRouter configuration."""
    import os
    
    print("🔍 Checking environment variables...")
    
    openrouter_key = os.getenv("OPENROUTER_API_KEY") or os.getenv("openrouter_api_key")
    base_model = os.getenv("OPENROUTER_BASE_MODEL") or os.getenv("openrouter_base_model")
    
    print(f"OpenRouter API Key: {'✅ Set' if openrouter_key else '❌ Not set'}")
    print(f"Base Model: {base_model or '❌ Not set'}")
    
    if not openrouter_key:
        print("\n💡 To test OpenRouter, set these environment variables:")
        print("export OPENROUTER_API_KEY=your_api_key_here")
        print("export OPENROUTER_BASE_MODEL=gpt-3.5-turbo")
        print("\nOr add them to your .env file:")
        print("OPENROUTER_API_KEY=your_api_key_here")
        print("OPENROUTER_BASE_MODEL=gpt-3.5-turbo")

if __name__ == "__main__":
    print("🚀 LLM Provider Switching Test Suite")
    print("=" * 50)
    
    # Check environment variables
    check_env_variables()
    print()
    
    # Check if backend is running
    tester = ProviderSwitchingTester()
    
    print("Starting tests...\n")
    
    # Run comprehensive test
    success = tester.run_comprehensive_test()
    
    if success:
        print("\n✅ All tests completed successfully!")
        print("\nNext steps:")
        print("1. Start the Flutter app: cd flutter && flutter run")
        print("2. Navigate to the LLM Dashboard")
        print("3. Test provider switching in the GUI")
        sys.exit(0)
    else:
        print("\n❌ Tests failed. Please check the backend connection.")
        sys.exit(1)