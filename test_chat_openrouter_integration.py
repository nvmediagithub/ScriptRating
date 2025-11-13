#!/usr/bin/env python3
"""
Test script to verify OpenRouter integration in chat backend.

This script tests:
1. Chat session creation
2. Sending messages with real OpenRouter API
3. Receiving actual AI responses (not mock data)
4. Proper token counting and response times
"""
import asyncio
import sys
import os
from datetime import datetime
import json

# Add the project root to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import httpx
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
BASE_URL = "http://localhost:8000/api"
TIMEOUT = 60.0  # Increased timeout for API calls

class Colors:
    """ANSI color codes for terminal output."""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def print_header(text: str):
    """Print a formatted header."""
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'=' * 80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(80)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'=' * 80}{Colors.ENDC}\n")


def print_success(text: str):
    """Print success message."""
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")


def print_error(text: str):
    """Print error message."""
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")


def print_info(text: str):
    """Print info message."""
    print(f"{Colors.OKCYAN}ℹ {text}{Colors.ENDC}")


def print_warning(text: str):
    """Print warning message."""
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")


async def test_health_check(client: httpx.AsyncClient) -> bool:
    """Test if the chat service is healthy."""
    print_info("Testing chat service health...")
    try:
        response = await client.get(f"{BASE_URL}/health")
        response.raise_for_status()
        data = response.json()
        
        print_success(f"Chat service is healthy: {data.get('status')}")
        
        if 'openrouter' in data:
            print_info(f"OpenRouter status: {data['openrouter']}")
            if data['openrouter'] == 'connected':
                print_success("OpenRouter is properly connected!")
            else:
                print_warning(f"OpenRouter connection issue: {data['openrouter']}")
        
        return True
    except Exception as e:
        print_error(f"Health check failed: {e}")
        return False


async def test_create_chat_session(client: httpx.AsyncClient) -> str:
    """Create a new chat session with OpenRouter."""
    print_info("Creating new chat session with OpenRouter...")
    
    try:
        # Get the model from environment
        model = os.getenv("OPENROUTER_BASE_MODEL", "minimax/minimax-m2:free")
        
        payload = {
            "title": "OpenRouter Integration Test",
            "llm_provider": "OPENROUTER",
            "llm_model": model,
            "settings": {
                "temperature": 0.7,
                "max_tokens": 2048
            }
        }
        
        response = await client.post(
            f"{BASE_URL}/chats",
            json=payload,
            timeout=TIMEOUT
        )
        response.raise_for_status()
        data = response.json()
        
        chat_id = data.get("id")
        print_success(f"Chat session created: {chat_id}")
        print_info(f"Provider: {data.get('llm_provider')}")
        print_info(f"Model: {data.get('llm_model')}")
        
        return chat_id
    except Exception as e:
        print_error(f"Failed to create chat session: {e}")
        if hasattr(e, 'response'):
            print_error(f"Response: {e.response.text}")
        raise


async def test_send_message(client: httpx.AsyncClient, chat_id: str, message: str) -> dict:
    """Send a message and wait for OpenRouter response."""
    print_info(f"Sending message: '{message}'")
    
    try:
        payload = {
            "role": "user",
            "content": message,
            "metadata": {}
        }
        
        # Send the message
        response = await client.post(
            f"{BASE_URL}/chats/{chat_id}/messages",
            json=payload,
            timeout=TIMEOUT
        )
        response.raise_for_status()
        user_message = response.json()
        
        print_success(f"User message sent: {user_message.get('id')}")
        
        # Wait for assistant response (poll for messages)
        print_info("Waiting for OpenRouter response...")
        max_attempts = 30  # 30 seconds max wait
        attempt = 0
        
        while attempt < max_attempts:
            await asyncio.sleep(1)
            attempt += 1
            
            # Get messages
            messages_response = await client.get(
                f"{BASE_URL}/chats/{chat_id}/messages",
                timeout=TIMEOUT
            )
            messages_response.raise_for_status()
            messages_data = messages_response.json()
            messages = messages_data.get("messages", [])
            
            # Find assistant response
            assistant_messages = [m for m in messages if m.get("role") == "assistant"]
            if assistant_messages:
                latest_assistant = assistant_messages[-1]
                if latest_assistant.get("content") and not latest_assistant.get("is_streaming"):
                    print_success("Received OpenRouter response!")
                    return latest_assistant
        
        print_warning("Timeout waiting for assistant response")
        return None
        
    except Exception as e:
        print_error(f"Failed to send message: {e}")
        if hasattr(e, 'response'):
            print_error(f"Response: {e.response.text}")
        raise


async def verify_real_openrouter_response(response: dict) -> bool:
    """Verify that the response is from real OpenRouter API, not mock data."""
    print_info("Verifying response authenticity...")
    
    content = response.get("content", "")
    tokens_used = response.get("tokens_used", 0)
    response_time_ms = response.get("response_time_ms", 0)
    
    # Check for mock response patterns
    mock_patterns = [
        "I understand your question",
        "As a local AI assistant",
        "Let me help you with that",
        "Thank you for your question about"
    ]
    
    is_mock = any(pattern in content for pattern in mock_patterns)
    
    if is_mock:
        print_error("Response appears to be MOCK data!")
        print_error(f"Content: {content[:100]}...")
        return False
    
    # Real OpenRouter responses should have:
    # 1. Non-zero token count
    # 2. Reasonable response time
    # 3. Substantive content
    
    checks = []
    
    if tokens_used > 0:
        print_success(f"Token count: {tokens_used} (Real API call)")
        checks.append(True)
    else:
        print_warning(f"Token count: {tokens_used} (Suspicious)")
        checks.append(False)
    
    if response_time_ms > 0:
        print_success(f"Response time: {response_time_ms:.2f}ms")
        checks.append(True)
    else:
        print_warning(f"Response time: {response_time_ms}ms (Suspicious)")
        checks.append(False)
    
    if len(content) > 20:
        print_success(f"Content length: {len(content)} characters")
        checks.append(True)
    else:
        print_warning(f"Content length: {len(content)} characters (Too short)")
        checks.append(False)
    
    print_info(f"Response preview: {content[:200]}...")
    
    return all(checks)


async def run_tests():
    """Run all tests."""
    print_header("OpenRouter Chat Backend Integration Test")
    
    # Check environment
    api_key = os.getenv("OPENROUTER_API_KEY")
    model = os.getenv("OPENROUTER_BASE_MODEL")
    
    if not api_key:
        print_error("OPENROUTER_API_KEY not found in environment!")
        return False
    
    print_success(f"API Key found: {api_key[:20]}...")
    print_success(f"Model: {model}")
    
    async with httpx.AsyncClient() as client:
        try:
            # Test 1: Health check
            print_header("Test 1: Health Check")
            if not await test_health_check(client):
                print_error("Health check failed. Is the server running?")
                return False
            
            # Test 2: Create chat session
            print_header("Test 2: Create Chat Session")
            chat_id = await test_create_chat_session(client)
            
            # Test 3: Send simple message
            print_header("Test 3: Send Simple Message")
            test_message = "Hello! Can you tell me a short fun fact about space?"
            response = await test_send_message(client, chat_id, test_message)
            
            if not response:
                print_error("No response received from OpenRouter")
                return False
            
            # Test 4: Verify real API response
            print_header("Test 4: Verify Real OpenRouter Response")
            is_real = await verify_real_openrouter_response(response)
            
            if not is_real:
                print_error("Response verification FAILED - appears to be mock data!")
                return False
            
            print_success("Response verification PASSED - using real OpenRouter API!")
            
            # Test 5: Send follow-up message
            print_header("Test 5: Send Follow-up Message")
            followup_message = "That's interesting! Can you tell me more?"
            followup_response = await test_send_message(client, chat_id, followup_message)
            
            if followup_response:
                print_success("Follow-up message processed successfully!")
                print_info(f"Response: {followup_response.get('content')[:150]}...")
            
            # Summary
            print_header("Test Summary")
            print_success("All tests PASSED!")
            print_success("Chat backend is using REAL OpenRouter API")
            print_success(f"Model: {model}")
            print_success("No mock responses detected")
            
            return True
            
        except Exception as e:
            print_error(f"Test failed with error: {e}")
            import traceback
            traceback.print_exc()
            return False


if __name__ == "__main__":
    print_info("Starting OpenRouter chat integration test...")
    print_info("Make sure the backend server is running on http://localhost:8000")
    
    success = asyncio.run(run_tests())
    
    if success:
        print_success("\n✓ All tests passed! Chat backend is using real OpenRouter API.")
        sys.exit(0)
    else:
        print_error("\n✗ Tests failed! Check the output above for details.")
        sys.exit(1)