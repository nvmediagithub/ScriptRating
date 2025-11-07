#!/usr/bin/env python3
"""
Browser Console and Network Debugging Script
Monitors and simulates browser behavior for DOCX upload errors.
"""
import requests
import json
import time
import sys
from pathlib import Path

class BrowserConsoleDebugger:
    def __init__(self):
        self.base_url = "http://localhost:8000/api/v1"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-origin',
        })
    
    def test_cors_headers(self):
        """Test CORS headers that would be visible in browser"""
        print("🌐 Testing CORS Headers...")
        print("=" * 50)
        
        try:
            # Test preflight request
            response = self.session.options(f"{self.base_url}/documents/upload")
            print(f"✅ CORS Preflight: {response.status_code}")
            
            # Check for CORS headers
            cors_headers = {
                'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
                'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
                'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers'),
                'Access-Control-Allow-Credentials': response.headers.get('Access-Control-Allow-Credentials'),
            }
            
            print("🔍 CORS Headers:")
            for header, value in cors_headers.items():
                if value:
                    print(f"  ✅ {header}: {value}")
                else:
                    print(f"  ❌ {header}: Missing")
            
            return True
        except Exception as e:
            print(f"❌ CORS Test Failed: {e}")
            return False
    
    def simulate_file_upload_errors(self, file_path):
        """Simulate various browser file upload scenarios that could cause JS errors"""
        print("\n📄 Simulating Browser File Upload Scenarios...")
        print("=" * 50)
        
        test_cases = [
            {
                'name': 'Valid DOCX Upload',
                'content_type': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            },
            {
                'name': 'Wrong Content Type',
                'content_type': 'application/octet-stream'
            },
            {
                'name': 'Missing Content Type',
                'content_type': None
            },
            {
                'name': 'Invalid File Extension',
                'content_type': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'filename': 'test.pdf'
            }
        ]
        
        results = {}
        
        for test_case in test_cases:
            print(f"\n🧪 Testing: {test_case['name']}")
            
            try:
                with open(file_path, 'rb') as f:
                    file_data = f.read()
                
                # Prepare files dict
                files = {
                    'file': (test_case.get('filename', 'test.docx'), file_data, test_case['content_type'])
                }
                
                # Make request like browser would
                start_time = time.time()
                response = self.session.post(f"{self.base_url}/documents/upload", files=files)
                end_time = time.time()
                
                response_data = response.json() if response.content else {}
                
                results[test_case['name']] = {
                    'status_code': response.status_code,
                    'response_time': round((end_time - start_time) * 1000, 2),
                    'response_data': response_data,
                    'headers': dict(response.headers)
                }
                
                # Log browser-like response
                print(f"  📊 Status: {response.status_code}")
                print(f"  ⏱️  Response Time: {results[test_case['name']]['response_time']}ms")
                
                if response.status_code == 200:
                    print(f"  ✅ SUCCESS: {response_data.get('document_id', 'N/A')}")
                else:
                    print(f"  ❌ ERROR: {response_data}")
                
            except requests.exceptions.ConnectionError as e:
                print(f"  🚫 CONNECTION ERROR: {e}")
                results[test_case['name']] = {'error': 'Connection failed'}
            except json.JSONDecodeError as e:
                print(f"  📄 JSON ERROR: {e}")
                results[test_case['name']] = {'error': 'Invalid JSON response'}
            except Exception as e:
                print(f"  💥 UNEXPECTED ERROR: {e}")
                results[test_case['name']] = {'error': str(e)}
        
        return results
    
    def analyze_api_response_format(self, file_path):
        """Analyze API response format to identify potential JS parsing errors"""
        print("\n🔍 Analyzing API Response Format for JavaScript Compatibility...")
        print("=" * 50)
        
        try:
            with open(file_path, 'rb') as f:
                files = {
                    'file': ('test.docx', f, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
                }
                response = self.session.post(f"{self.base_url}/documents/upload", files=files)
            
            if response.status_code == 200:
                data = response.json()
                
                print("📋 API Response Structure Analysis:")
                print("  ✅ Response is valid JSON")
                
                # Check for potential JS parsing issues
                issues = []
                
                # Check for complex nested structures
                def check_complexity(obj, path=""):
                    if isinstance(obj, dict):
                        for key, value in obj.items():
                            current_path = f"{path}.{key}" if path else key
                            if isinstance(value, (dict, list)) and len(str(value)) > 1000:
                                issues.append(f"Large {type(value).__name__} at {current_path}")
                            check_complexity(value, current_path)
                    elif isinstance(obj, list) and len(obj) > 100:
                        issues.append(f"Large list at {path}")
                
                check_complexity(data)
                
                if issues:
                    print("  ⚠️  Potential JS Parsing Issues:")
                    for issue in issues:
                        print(f"    - {issue}")
                else:
                    print("  ✅ No complex data structures detected")
                
                # Check for non-serializable values
                try:
                    json.dumps(data)
                    print("  ✅ Response is fully JSON serializable")
                except TypeError as e:
                    print(f"  ❌ JSON Serialization Error: {e}")
                    return False
                
                print(f"  📊 Response size: {len(str(data))} characters")
                return True
            else:
                print(f"  ❌ Upload failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"  ❌ Analysis failed: {e}")
            return False
    
    def test_error_handling(self):
        """Test various error scenarios that might cause JS errors"""
        print("\n🚨 Testing Error Handling Scenarios...")
        print("=" * 50)
        
        error_tests = [
            {
                'name': 'Non-existent endpoint',
                'url': f"{self.base_url}/nonexistent",
                'method': 'GET'
            },
            {
                'name': 'Invalid JSON payload',
                'url': f"{self.base_url}/analysis/analyze",
                'method': 'POST',
                'data': {'invalid': 'json'}
            },
            {
                'name': 'Missing required fields',
                'url': f"{self.base_url}/documents/upload",
                'method': 'POST',
                'files': {}
            }
        ]
        
        for test in error_tests:
            print(f"\n🧪 Testing: {test['name']}")
            
            try:
                if test['method'] == 'GET':
                    response = self.session.get(test['url'])
                elif test['method'] == 'POST':
                    if 'files' in test:
                        response = self.session.post(test['url'], files=test['files'])
                    else:
                        response = self.session.post(test['url'], json=test.get('data', {}))
                
                print(f"  📊 Status: {response.status_code}")
                print(f"  📄 Response: {response.text[:200]}...")
                
                # Check if error response is properly formatted
                try:
                    if response.headers.get('content-type', '').startswith('application/json'):
                        response.json()
                        print("  ✅ Error response is valid JSON")
                    else:
                        print("  ⚠️  Error response is not JSON (could cause JS parsing errors)")
                except json.JSONDecodeError:
                    print("  ❌ Error response is not valid JSON")
                
            except Exception as e:
                print(f"  💥 Error: {e}")
    
    def generate_javascript_error_scenarios(self):
        """Generate JavaScript error scenarios based on API behavior"""
        print("\n🐛 JavaScript Error Scenario Analysis...")
        print("=" * 50)
        
        print("Based on API behavior, potential JS errors could include:")
        
        scenarios = [
            {
                'error_type': 'DioError',
                'scenario': 'CORS Error',
                'cause': 'Missing Access-Control-Allow-Origin header',
                'browser_console': 'Access to XMLHttpRequest at \'http://localhost:8000/api/v1/documents/upload\' from origin \'http://localhost:3000\' has been blocked by CORS policy'
            },
            {
                'error_type': 'TypeError',
                'scenario': 'Null Response',
                'cause': 'API returns empty response',
                'browser_console': 'Cannot read property \'document_id\' of null'
            },
            {
                'error_type': 'SyntaxError',
                'scenario': 'Invalid JSON',
                'cause': 'API returns non-JSON response on error',
                'browser_console': 'Unexpected token < in JSON at position 0'
            },
            {
                'error_type': 'NetworkError',
                'scenario': 'Connection Timeout',
                'cause': 'Request timeout (30s default)',
                'browser_console': 'Network request failed'
            }
        ]
        
        for scenario in scenarios:
            print(f"\n  💥 {scenario['error_type']}: {scenario['scenario']}")
            print(f"     Cause: {scenario['cause']}")
            print(f"     Browser Console: {scenario['browser_console']}")

def main():
    debugger = BrowserConsoleDebugger()
    
    print("🔍 BROWSER CONSOLE DEBUGGING SESSION")
    print("=" * 60)
    print("This script simulates browser behavior to identify JavaScript errors")
    print()
    
    # Test DOCX file
    test_file = "dataset/ВАСИЛЬКИ_1.docx"
    if not Path(test_file).exists():
        print(f"❌ Test file not found: {test_file}")
        return False
    
    # Run all debugging tests
    debugger.test_cors_headers()
    upload_results = debugger.simulate_file_upload_errors(test_file)
    debugger.analyze_api_response_format(test_file)
    debugger.test_error_handling()
    debugger.generate_javascript_error_scenarios()
    
    print("\n" + "=" * 60)
    print("📊 SUMMARY OF POTENTIAL JS ERRORS")
    print("=" * 60)
    
    print("\n1. CORS Issues:")
    print("   - Frontend (Flutter web) runs on different port than backend")
    print("   - Missing CORS headers could block requests in browser")
    
    print("\n2. Response Parsing Issues:")
    print("   - Non-JSON error responses could cause SyntaxError")
    print("   - Null response data could cause TypeError")
    
    print("\n3. Network Issues:")
    print("   - Request timeouts configured to 30 seconds")
    print("   - Connection errors could cause NetworkError")
    
    print("\n4. Flutter Web Specific:")
    print("   - Dio configuration might need web-specific settings")
    print("   - File handling differs between web and native")
    
    return True

if __name__ == "__main__":
    main()