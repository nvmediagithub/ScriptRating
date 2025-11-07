#!/usr/bin/env python3
"""
Test script to upload the ВАСИЛЬКИ_1.docx file and verify the age rating fix.
"""
import requests
import json
import os
from pathlib import Path

def upload_document():
    """Upload the test DOCX file."""
    
    # Backend API base URL
    base_url = "http://localhost:8000"
    
    # Path to test file
    test_file_path = "dataset/ВАСИЛЬКИ_1.docx"
    
    if not os.path.exists(test_file_path):
        print(f"❌ Test file not found: {test_file_path}")
        return
    
    print(f"📄 Uploading test file: {test_file_path}")
    
    try:
        # Upload the document
        with open(test_file_path, 'rb') as f:
            files = {'file': ('ВАСИЛЬКИ_1.docx', f, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')}
            response = requests.post(f"{base_url}/api/v1/documents/upload", files=files)
        
        if response.status_code == 200:
            upload_result = response.json()
            document_id = upload_result.get('document_id')
            print(f"✅ Document uploaded successfully!")
            print(f"📋 Document ID: {document_id}")
            
            # Now start analysis
            print("\n🔍 Starting analysis...")
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
            
            if analysis_response.status_code == 200:
                analysis_result = analysis_response.json()
                print(f"✅ Analysis started successfully!")
                print(f"🆔 Analysis ID: {analysis_result.get('analysis_id')}")
                print(f"📊 Status: {analysis_result.get('status')}")
                
                # Check the final rating
                rating_result = analysis_result.get('rating_result', {})
                final_rating = rating_result.get('final_rating')
                print(f"🎯 Final Rating: {final_rating}")
                
                print("\n📋 Scene Assessments:")
                for i, scene in enumerate(analysis_result.get('scene_assessments', []), 1):
                    scene_rating = scene.get('age_rating')
                    heading = scene.get('heading', 'N/A')[:50] + "..."
                    print(f"  Scene {i}: {scene_rating} - {heading}")
                
                return True
            else:
                print(f"❌ Analysis failed: {analysis_response.status_code}")
                print(f"📄 Response: {analysis_response.text}")
                return False
                
        else:
            print(f"❌ Upload failed: {response.status_code}")
            print(f"📄 Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error during test: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Testing DOCX upload with age rating fix...")
    print("=" * 50)
    
    success = upload_document()
    
    print("=" * 50)
    if success:
        print("✅ Test completed successfully! Age rating fix is working.")
    else:
        print("❌ Test failed. Please check the logs for details.")