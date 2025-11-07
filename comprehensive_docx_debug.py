#!/usr/bin/env python3
"""
Comprehensive DOCX upload and analysis test with detailed error monitoring.
This script will help identify where exactly the runtime errors occur.
"""
import requests
import json
import os
import time
from pathlib import Path

def detailed_upload_and_analysis_test():
    """Upload and monitor the complete analysis process with detailed logging."""
    
    # Backend API base URL
    base_url = "http://localhost:8000"
    
    # Path to test file
    test_file_path = "dataset/ВАСИЛЬКИ_1.docx"
    
    if not os.path.exists(test_file_path):
        print(f"❌ Test file not found: {test_file_path}")
        return False
    
    print(f"📄 Starting comprehensive DOCX analysis test...")
    print(f"📄 Test file: {test_file_path}")
    print("=" * 60)
    
    try:
        # Step 1: Upload the document
        print("Step 1: Uploading document...")
        with open(test_file_path, 'rb') as f:
            files = {'file': ('ВАСИЛЬКИ_1.docx', f, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')}
            response = requests.post(f"{base_url}/api/v1/documents/upload", files=files)
        
        if response.status_code != 200:
            print(f"❌ Upload failed: {response.status_code}")
            print(f"📄 Response: {response.text}")
            return False
        
        upload_result = response.json()
        document_id = upload_result.get('document_id')
        print(f"✅ Document uploaded successfully!")
        print(f"📋 Document ID: {document_id}")
        print(f"📄 Status: {upload_result.get('status')}")
        
        # Step 2: Start analysis
        print("\nStep 2: Starting analysis...")
        analysis_request = {
            "document_id": document_id,
            "options": {
                "target_rating": None,
                "include_recommendations": True,
                "detailed_scenes": False
            }
        }
        
        analysis_response = requests.post(
            f"{base_url}/api/v1/analysis/analyze",
            json=analysis_request
        )
        
        if analysis_response.status_code != 200:
            print(f"❌ Analysis start failed: {analysis_response.status_code}")
            print(f"📄 Response: {analysis_response.text}")
            return False
        
        analysis_result = analysis_response.json()
        analysis_id = analysis_result.get('analysis_id')
        print(f"✅ Analysis started successfully!")
        print(f"🆔 Analysis ID: {analysis_id}")
        print(f"📊 Initial Status: {analysis_result.get('status')}")
        
        # Step 3: Monitor analysis progress with detailed status checks
        print("\nStep 3: Monitoring analysis progress...")
        max_attempts = 30  # Wait up to 30 attempts
        attempt = 0
        
        while attempt < max_attempts:
            attempt += 1
            print(f"  Status check {attempt}...")
            
            try:
                status_response = requests.get(f"{base_url}/api/v1/analysis/status/{analysis_id}")
                
                if status_response.status_code != 200:
                    print(f"❌ Status check failed: {status_response.status_code}")
                    print(f"📄 Response: {status_response.text}")
                    break
                
                status_result = status_response.json()
                current_status = status_result.get('status')
                progress = status_result.get('progress', 0)
                errors = status_result.get('errors')
                
                print(f"  📊 Status: {current_status}")
                print(f"  📈 Progress: {progress}%")
                
                if errors:
                    print(f"  ❌ ERRORS DETECTED: {errors}")
                    return False
                
                if current_status == 'completed':
                    print(f"✅ Analysis completed successfully!")
                    
                    # Get final results
                    final_response = requests.get(f"{base_url}/api/v1/analysis/{analysis_id}")
                    if final_response.status_code == 200:
                        final_result = final_response.json()
                        rating_result = final_result.get('rating_result', {})
                        final_rating = rating_result.get('final_rating')
                        scene_count = len(final_result.get('scene_assessments', []))
                        
                        print(f"🎯 Final Rating: {final_rating}")
                        print(f"📋 Total Scenes Analyzed: {scene_count}")
                        
                        if scene_count > 0:
                            print(f"\n📋 Scene Details:")
                            for i, scene in enumerate(final_result.get('scene_assessments', []), 1):
                                scene_rating = scene.get('age_rating')
                                heading = scene.get('heading', 'N/A')[:50] + "..."
                                print(f"  Scene {i}: {scene_rating} - {heading}")
                        
                        return True
                    else:
                        print(f"❌ Failed to get final results: {final_response.status_code}")
                        return False
                
                elif current_status == 'failed':
                    print(f"❌ Analysis failed!")
                    if errors:
                        print(f"💥 Error details: {errors}")
                    return False
                
                # Wait before next check
                time.sleep(2)
                
            except Exception as e:
                print(f"❌ Error during status check: {e}")
                return False
        
        print(f"⏰ Analysis timed out after {max_attempts} attempts")
        return False
        
    except Exception as e:
        print(f"❌ Error during comprehensive test: {e}")
        import traceback
        print(f"💥 Stack trace: {traceback.format_exc()}")
        return False

if __name__ == "__main__":
    print("🔍 COMPREHENSIVE DOCX ANALYSIS DEBUG TEST")
    print("=" * 60)
    
    success = detailed_upload_and_analysis_test()
    
    print("=" * 60)
    if success:
        print("✅ COMPREHENSIVE TEST PASSED - No runtime errors detected!")
    else:
        print("❌ COMPREHENSIVE TEST FAILED - Runtime errors detected!")
    
    print("\nThis test monitored:")
    print("  ✓ Document upload process")
    print("  ✓ Analysis initialization")
    print("  ✓ Analysis progress monitoring")
    print("  ✓ Final results retrieval")
    print("  ✓ Error detection and reporting")