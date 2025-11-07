#!/usr/bin/env python3
"""
Edge case testing and API compatibility analysis.
This script tests various edge cases to identify potential runtime issues.
"""
import requests
import json
import time
from datetime import datetime

def test_edge_cases():
    """Test edge cases and potential runtime issues."""
    
    base_url = "http://localhost:8000"
    
    print("🔍 TESTING EDGE CASES AND API COMPATIBILITY")
    print("=" * 60)
    
    test_results = {
        'upload_test': False,
        'analysis_test': False,
        'status_monitoring': False,
        'error_handling': False,
        'data_serialization': False,
        'frontend_compatibility': False,
    }
    
    try:
        # Test 1: Upload and verify response structure
        print("\n1. Testing document upload and response structure...")
        
        with open("dataset/ВАСИЛЬКИ_1.docx", 'rb') as f:
            files = {'file': ('test.docx', f, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')}
            response = requests.post(f"{base_url}/api/v1/documents/upload", files=files)
        
        if response.status_code == 200:
            upload_data = response.json()
            print(f"✅ Upload successful")
            print(f"📋 Response keys: {list(upload_data.keys())}")
            
            # Check required fields
            required_fields = ['document_id', 'filename', 'uploaded_at', 'document_type', 'status']
            missing_fields = [field for field in required_fields if field not in upload_data]
            
            if missing_fields:
                print(f"⚠️  Missing fields in upload response: {missing_fields}")
            else:
                print(f"✅ All required fields present in upload response")
                test_results['upload_test'] = True
            
            document_id = upload_data['document_id']
            
        else:
            print(f"❌ Upload failed: {response.status_code}")
            print(f"Response: {response.text}")
            return test_results
        
        # Test 2: Start analysis and check response structure
        print("\n2. Testing analysis start and response structure...")
        
        analysis_payload = {
            "document_id": document_id,
            "options": {
                "target_rating": None,
                "include_recommendations": True,
                "detailed_scenes": False
            }
        }
        
        response = requests.post(f"{base_url}/api/v1/analysis/analyze", json=analysis_payload)
        
        if response.status_code == 200:
            analysis_data = response.json()
            print(f"✅ Analysis start successful")
            print(f"📋 Response keys: {list(analysis_data.keys())}")
            
            # Check required fields for analysis
            required_fields = ['analysis_id', 'document_id', 'status', 'rating_result', 'scene_assessments', 'created_at']
            missing_fields = [field for field in required_fields if field not in analysis_data]
            
            if missing_fields:
                print(f"⚠️  Missing fields in analysis response: {missing_fields}")
            else:
                print(f"✅ All required fields present in analysis response")
                test_results['analysis_test'] = True
            
            analysis_id = analysis_data['analysis_id']
            
        else:
            print(f"❌ Analysis start failed: {response.status_code}")
            print(f"Response: {response.text}")
            return test_results
        
        # Test 3: Monitor analysis status and check for runtime errors
        print("\n3. Testing analysis status monitoring...")
        
        max_attempts = 10
        for attempt in range(max_attempts):
            time.sleep(1)
            
            response = requests.get(f"{base_url}/api/v1/analysis/status/{analysis_id}")
            
            if response.status_code == 200:
                status_data = response.json()
                current_status = status_data.get('status')
                progress = status_data.get('progress', 0)
                errors = status_data.get('errors')
                
                print(f"  Status check {attempt + 1}: {current_status} ({progress}%)")
                
                if errors:
                    print(f"  ❌ ERRORS DETECTED: {errors}")
                    test_results['error_handling'] = True
                
                if current_status == 'completed':
                    print(f"  ✅ Analysis completed successfully")
                    test_results['status_monitoring'] = True
                    break
                elif current_status == 'failed':
                    print(f"  ❌ Analysis failed")
                    break
            else:
                print(f"  ❌ Status check failed: {response.status_code}")
        
        # Test 4: Get final results and validate data structure
        print("\n4. Testing final results and data structure...")
        
        response = requests.get(f"{base_url}/api/v1/analysis/{analysis_id}")
        
        if response.status_code == 200:
            result_data = response.json()
            print(f"✅ Final results retrieved successfully")
            
            # Validate rating result structure
            rating_result = result_data.get('rating_result', {})
            print(f"📊 Rating result structure:")
            print(f"  - final_rating: {rating_result.get('final_rating')} (type: {type(rating_result.get('final_rating'))})")
            print(f"  - confidence_score: {rating_result.get('confidence_score')}")
            print(f"  - problem_scenes_count: {rating_result.get('problem_scenes_count')}")
            print(f"  - categories_summary: {rating_result.get('categories_summary')}")
            
            # Validate scene assessments structure
            scene_assessments = result_data.get('scene_assessments', [])
            if scene_assessments:
                first_scene = scene_assessments[0]
                print(f"📋 Scene assessment structure (first scene):")
                print(f"  - scene_number: {first_scene.get('scene_number')}")
                print(f"  - age_rating: {first_scene.get('age_rating')} (type: {type(first_scene.get('age_rating'))})")
                print(f"  - categories: {first_scene.get('categories')}")
                print(f"  - references: {len(first_scene.get('references', []))} references")
                
                test_results['data_serialization'] = True
            
        else:
            print(f"❌ Failed to get final results: {response.status_code}")
        
        # Test 5: Frontend compatibility checks
        print("\n5. Testing frontend compatibility...")
        
        # Check for JSON serialization compatibility
        try:
            # Test AgeRating enum compatibility
            final_rating = rating_result.get('final_rating')
            valid_ratings = ['0+', '6+', '12+', '16+', '18+']
            
            if final_rating in valid_ratings:
                print(f"✅ AgeRating '{final_rating}' is valid for frontend")
                test_results['frontend_compatibility'] = True
            else:
                print(f"❌ AgeRating '{final_rating}' is not in valid frontend list: {valid_ratings}")
                
        except Exception as e:
            print(f"❌ Frontend compatibility error: {e}")
        
        # Test empty/null data handling
        print("\n6. Testing empty/null data handling...")
        
        # Test what happens with invalid analysis ID
        invalid_response = requests.get(f"{base_url}/api/v1/analysis/invalid-id")
        if invalid_response.status_code == 404:
            print(f"✅ Proper error handling for invalid analysis ID")
        else:
            print(f"⚠️  Unexpected response for invalid analysis ID: {invalid_response.status_code}")
        
    except Exception as e:
        print(f"❌ Edge case testing failed: {e}")
        import traceback
        print(f"💥 Stack trace: {traceback.format_exc()}")
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 EDGE CASE TESTING RESULTS:")
    
    for test_name, passed in test_results.items():
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"  {test_name}: {status}")
    
    passed_count = sum(test_results.values())
    total_tests = len(test_results)
    
    print(f"\n🎯 SUMMARY: {passed_count}/{total_tests} tests passed")
    
    if passed_count == total_tests:
        print("🎉 ALL EDGE CASE TESTS PASSED - No runtime errors detected!")
    else:
        print("⚠️  Some edge case tests failed - Potential runtime issues found")
    
    return test_results

if __name__ == "__main__":
    test_edge_cases()