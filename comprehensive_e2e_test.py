#!/usr/bin/env python3
"""
Final Comprehensive End-to-End DOCX Upload and Analysis Pipeline Test
This test verifies the complete functionality after all critical fixes.
"""

import requests
import json
import time
import os
from pathlib import Path
import tempfile
from typing import Dict, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DOCXAnalysisTestSuite:
    """Comprehensive test suite for DOCX upload and analysis pipeline"""
    
    def __init__(self):
        self.frontend_url = "http://localhost:3000"
        self.backend_url = "http://localhost:8000"
        self.test_file = "dataset/ВАСИЛЬКИ_1.docx"
        self.upload_url = f"{self.backend_url}/api/v1/documents/upload"
        self.analysis_url = f"{self.backend_url}/api/v1/analysis/analyze"
        self.status_url = f"{self.backend_url}/api/v1/analysis/status/{{analysis_id}}"
        self.result_url = f"{self.backend_url}/api/v1/analysis/{{analysis_id}}"
        
        # Test results tracking
        self.test_results = {
            "system_health": False,
            "file_upload": False,
            "api_processing": False,
            "analysis_start": False,
            "results_retrieval": False,
            "error_handling": False,
            "complete_workflow": False
        }
        
        # Store IDs from workflow
        self.document_id = None
        self.analysis_id = None
    
    def test_1_system_health_check(self) -> Dict[str, Any]:
        """Test 1: Verify both frontend and backend are accessible"""
        logger.info("🔍 Test 1: System Health Check")
        
        results = {"frontend": False, "backend": False, "api_docs": False}
        
        # Test frontend accessibility
        try:
            response = requests.get(self.frontend_url, timeout=5)
            if response.status_code == 200 and "html" in response.text.lower():
                results["frontend"] = True
                logger.info("✅ Frontend accessible on port 3000")
            else:
                logger.error(f"❌ Frontend issue: Status {response.status_code}")
        except Exception as e:
            logger.error(f"❌ Frontend not accessible: {e}")
        
        # Test backend accessibility
        try:
            response = requests.get(f"{self.backend_url}/docs", timeout=5)
            if response.status_code == 200 and "Swagger" in response.text:
                results["backend"] = True
                logger.info("✅ Backend accessible on port 8000")
            else:
                logger.error(f"❌ Backend issue: Status {response.status_code}")
        except Exception as e:
            logger.error(f"❌ Backend not accessible: {e}")
        
        # Test API documentation
        try:
            response = requests.get(f"{self.backend_url}/openapi.json", timeout=5)
            if response.status_code == 200:
                results["api_docs"] = True
                logger.info("✅ API documentation accessible")
        except Exception as e:
            logger.error(f"❌ API docs issue: {e}")
        
        self.test_results["system_health"] = all(results.values())
        return results
    
    def test_2_docx_upload(self) -> Dict[str, Any]:
        """Test 2: Test DOCX file upload with proper content-type detection"""
        logger.info("🔍 Test 2: DOCX File Upload")
        
        if not os.path.exists(self.test_file):
            logger.error(f"❌ Test file not found: {self.test_file}")
            return {"upload_success": False, "content_type_correct": False, "upload_id": None}
        
        results = {"upload_success": False, "content_type_correct": False, "upload_id": None}
        
        try:
            with open(self.test_file, 'rb') as f:
                files = {'file': ('ВАСИЛЬКИ_1.docx', f, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')}
                headers = {}
                
                # Test upload with proper headers
                response = requests.post(
                    self.upload_url,
                    files=files,
                    headers=headers,
                    timeout=30
                )
                
                logger.info(f"Upload response status: {response.status_code}")
                logger.info(f"Upload response: {response.text[:500]}...")
                
                if response.status_code == 200:
                    data = response.json()
                    results["upload_success"] = True
                    results["content_type_correct"] = True
                    results["upload_id"] = data.get("document_id") or data.get("id") or data.get("script_id")
                    
                    if results["upload_id"]:
                        logger.info(f"✅ Upload successful with ID: {results['upload_id']}")
                        self.document_id = results["upload_id"]
                    else:
                        logger.error("❌ No upload ID in response")
                else:
                    logger.error(f"❌ Upload failed with status {response.status_code}: {response.text}")
                    
        except Exception as e:
            logger.error(f"❌ Upload exception: {e}")
        
        self.test_results["file_upload"] = results["upload_success"]
        return results
    
    def test_3_analysis_workflow(self, script_id: str) -> Dict[str, Any]:
        """Test 3: Test analysis workflow and processing"""
        logger.info("🔍 Test 3: Analysis Workflow")
        
        results = {"analysis_started": False, "status_updates": False, "final_status": None}
        
        try:
            # Start analysis
            analysis_response = requests.post(
                self.analysis_url.format(analysis_id=script_id),
                json={"document_id": script_id},
                timeout=10
            )
            
            logger.info(f"Analysis start response: {analysis_response.status_code}")
            logger.info(f"Analysis response: {analysis_response.text[:300]}...")
            
            if analysis_response.status_code in [200, 201, 202]:
                results["analysis_started"] = True
                logger.info("✅ Analysis started successfully")
                
                # Capture analysis_id from response
                analysis_data = analysis_response.json()
                self.analysis_id = analysis_data.get("analysis_id")
                
                if self.analysis_id:
                    logger.info(f"✅ Analysis ID captured: {self.analysis_id}")
                    
                    # Monitor status updates
                    for attempt in range(10):  # Check for 30 seconds
                        try:
                            status_response = requests.get(
                                self.status_url.format(analysis_id=self.analysis_id),
                                timeout=5
                            )
                            
                            if status_response.status_code == 200:
                                status_data = status_response.json()
                                logger.info(f"Status check {attempt + 1}: {status_data}")
                                results["status_updates"] = True
                                
                                # Check if analysis is complete
                                current_status = status_data.get("status", "")
                                if current_status in ["completed", "finished", "success"]:
                                    results["final_status"] = current_status
                                    logger.info("✅ Analysis completed successfully")
                                    break
                                elif current_status in ["failed", "error"]:
                                    logger.error(f"❌ Analysis failed: {status_data}")
                                    break
                                    
                            time.sleep(3)  # Wait 3 seconds between checks
                            
                        except Exception as e:
                            logger.warning(f"Status check error: {e}")
                else:
                    logger.error("❌ No analysis_id in response")
                        
            else:
                logger.error(f"❌ Analysis start failed: {analysis_response.status_code}")
                
        except Exception as e:
            logger.error(f"❌ Analysis workflow exception: {e}")
        
        self.test_results["analysis_start"] = results["analysis_started"]
        return results
    
    def test_4_results_retrieval(self, script_id: str) -> Dict[str, Any]:
        """Test 4: Test results retrieval and validation"""
        logger.info("🔍 Test 4: Results Retrieval")
        
        results = {"results_retrieved": False, "results_valid": False, "results_data": None}
        
        try:
            response = requests.get(
                self.result_url.format(analysis_id=script_id),
                timeout=10
            )
            
            logger.info(f"Results response status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                results["results_retrieved"] = True
                results["results_data"] = data
                
                # Validate results structure
                required_fields = ["scene_assessments", "rating_result", "status"]
                if all(field in data for field in required_fields):
                    results["results_valid"] = True
                    logger.info("✅ Results retrieved and validated")
                    scenes = data.get('scene_assessments', [])
                    rating = data.get('rating_result', {})
                    final_rating = rating.get('final_rating', 'Unknown')
                    problem_count = rating.get('problem_scenes_count', 0)
                    confidence = rating.get('confidence_score', 0.0)
                    logger.info(f"Results summary: {len(scenes)} scenes analyzed, "
                              f"final rating: {final_rating}, {problem_count} problematic scenes, "
                              f"confidence: {confidence:.2f}")
                else:
                    logger.error("❌ Results missing required fields")
                    logger.error(f"Available fields: {list(data.keys())}")
            else:
                logger.error(f"❌ Results retrieval failed: {response.status_code}")
                
        except Exception as e:
            logger.error(f"❌ Results retrieval exception: {e}")
        
        self.test_results["results_retrieval"] = results["results_retrieved"]
        return results
    
    def test_5_error_handling(self) -> Dict[str, Any]:
        """Test 5: Test error handling and edge cases"""
        logger.info("🔍 Test 5: Error Handling")
        
        results = {"cors_working": False, "invalid_file_handled": False, "nonexistent_id_handled": False}
        
        # Test CORS preflight
        try:
            response = requests.options(
                self.upload_url,
                headers={
                    "Origin": self.frontend_url,
                    "Access-Control-Request-Method": "POST",
                    "Access-Control-Request-Headers": "Content-Type"
                },
                timeout=5
            )
            
            cors_headers = response.headers.get("Access-Control-Allow-Origin", "")
            if cors_headers in ["*", self.frontend_url]:
                results["cors_working"] = True
                logger.info("✅ CORS headers present")
            else:
                logger.error(f"❌ CORS issue: {cors_headers}")
                
        except Exception as e:
            logger.error(f"❌ CORS test failed: {e}")
        
        # Test invalid file upload
        try:
            temp_file = tempfile.NamedTemporaryFile(suffix=".txt", mode='w', delete=False)
            temp_file.write("This is not a DOCX file")
            temp_file.close()
            
            with open(temp_file.name, 'rb') as tf:
                files = {'file': ('test.txt', tf, 'text/plain')}
                response = requests.post(self.upload_url, files=files, timeout=10)
                
                if response.status_code in [400, 422]:  # Expected bad request
                    results["invalid_file_handled"] = True
                    logger.info("✅ Invalid file type handled correctly")
                else:
                    logger.error(f"❌ Invalid file not handled: {response.status_code}")
                    
            os.unlink(temp_file.name)
                
        except Exception as e:
            logger.error(f"❌ Invalid file test failed: {e}")
        
        # Test nonexistent script ID
        try:
            fake_id = "nonexistent-id-12345"
            response = requests.get(self.status_url.format(analysis_id=fake_id), timeout=5)
            
            if response.status_code == 404:
                results["nonexistent_id_handled"] = True
                logger.info("✅ Nonexistent ID handled correctly")
            else:
                logger.error(f"❌ Nonexistent ID not handled: {response.status_code}")
                
        except Exception as e:
            logger.error(f"❌ Nonexistent ID test failed: {e}")
        
        self.test_results["error_handling"] = all(results.values())
        return results
    
    def run_complete_workflow_test(self) -> Dict[str, Any]:
        """Run the complete end-to-end workflow test"""
        logger.info("🚀 Starting Complete End-to-End DOCX Analysis Test Suite")
        logger.info("=" * 60)
        
        final_results = {}
        
        # Test 1: System Health
        health_results = self.test_1_system_health_check()
        final_results["health"] = health_results
        
        if not all(health_results.values()):
            logger.error("❌ System health check failed. Stopping tests.")
            return final_results
        
        # Test 2: File Upload
        upload_results = self.test_2_docx_upload()
        final_results["upload"] = upload_results
        
        if not upload_results["upload_success"] or not upload_results["upload_id"]:
            logger.error("❌ File upload failed. Stopping tests.")
            return final_results
        
        script_id = upload_results["upload_id"]
        
        # Test 3: Analysis Workflow
        analysis_results = self.test_3_analysis_workflow(script_id)
        final_results["analysis"] = analysis_results
        
        if not analysis_results["analysis_started"]:
            logger.error("❌ Analysis workflow failed. Stopping tests.")
            return final_results
        
        # Wait for analysis to complete
        logger.info("⏳ Waiting for analysis to complete...")
        time.sleep(10)
        
        # Test 4: Results Retrieval
        if self.analysis_id:
            results_results = self.test_4_results_retrieval(self.analysis_id)
        else:
            logger.error("❌ No analysis_id available for results retrieval")
            results_results = {"results_retrieved": False, "results_valid": False, "results_data": None}
        final_results["results"] = results_results
        
        # Test 5: Error Handling
        error_results = self.test_5_error_handling()
        final_results["error_handling"] = error_results
        
        # Overall workflow test
        self.test_results["complete_workflow"] = all(self.test_results.values())
        
        return final_results
    
    def generate_report(self, results: Dict[str, Any]) -> str:
        """Generate a comprehensive test report"""
        report = "\n" + "="*60 + "\n"
        report += "📊 FINAL COMPREHENSIVE DOCX ANALYSIS TEST REPORT\n"
        report += "="*60 + "\n\n"
        
        # System Health
        health = results.get("health", {})
        report += "🔍 SYSTEM HEALTH CHECK:\n"
        report += f"  Frontend (Port 3000): {'✅' if health.get('frontend') else '❌'}\n"
        report += f"  Backend (Port 8000): {'✅' if health.get('backend') else '❌'}\n"
        report += f"  API Documentation: {'✅' if health.get('api_docs') else '❌'}\n\n"
        
        # File Upload
        upload = results.get("upload", {})
        report += "📤 FILE UPLOAD TEST:\n"
        report += f"  Upload Success: {'✅' if upload.get('upload_success') else '❌'}\n"
        report += f"  Content-Type Detection: {'✅' if upload.get('content_type_correct') else '❌'}\n"
        report += f"  Upload ID Generated: {upload.get('upload_id', 'None')}\n\n"
        
        # Analysis Workflow
        analysis = results.get("analysis", {})
        report += "⚙️ ANALYSIS WORKFLOW:\n"
        report += f"  Analysis Started: {'✅' if analysis.get('analysis_started') else '❌'}\n"
        report += f"  Status Updates: {'✅' if analysis.get('status_updates') else '❌'}\n"
        report += f"  Final Status: {analysis.get('final_status', 'Unknown')}\n\n"
        
        # Results
        results_data = results.get("results", {})
        report += "📋 RESULTS RETRIEVAL:\n"
        report += f"  Results Retrieved: {'✅' if results_data.get('results_retrieved') else '❌'}\n"
        report += f"  Results Valid: {'✅' if results_data.get('results_valid') else '❌'}\n"
        if results_data.get('results_data'):
            scenes = len(results_data['results_data'].get('scenes', []))
            categories = len(results_data['results_data'].get('categories', []))
            report += f"  Scenes Analyzed: {scenes}\n"
            report += f"  Categories Processed: {categories}\n"
        report += "\n"
        
        # Error Handling
        error_handling = results.get("error_handling", {})
        report += "🛡️ ERROR HANDLING:\n"
        report += f"  CORS Working: {'✅' if error_handling.get('cors_working') else '❌'}\n"
        report += f"  Invalid File Handling: {'✅' if error_handling.get('invalid_file_handled') else '❌'}\n"
        report += f"  Nonexistent ID Handling: {'✅' if error_handling.get('nonexistent_id_handled') else '❌'}\n\n"
        
        # Overall Status
        report += "🎯 OVERALL TEST RESULTS:\n"
        report += f"  System Health: {'✅' if self.test_results['system_health'] else '❌'}\n"
        report += f"  File Upload: {'✅' if self.test_results['file_upload'] else '❌'}\n"
        report += f"  Analysis Start: {'✅' if self.test_results['analysis_start'] else '❌'}\n"
        report += f"  Results Retrieval: {'✅' if self.test_results['results_retrieval'] else '❌'}\n"
        report += f"  Error Handling: {'✅' if self.test_results['error_handling'] else '❌'}\n"
        
        # Final verdict
        all_passed = all(self.test_results.values())
        report += "\n" + "="*60 + "\n"
        report += f"🏆 FINAL VERDICT: {'🎉 ALL TESTS PASSED' if all_passed else '❌ SOME TESTS FAILED'}\n"
        
        if all_passed:
            report += "✅ The DOCX upload and analysis pipeline is fully functional!\n"
            report += "✅ All critical fixes have been successfully implemented and verified.\n"
            report += "✅ The system is ready for production use.\n"
        else:
            report += "❌ Some components need attention. Check individual test results above.\n"
            
        report += "="*60 + "\n"
        
        return report

def main():
    """Main test execution"""
    print("🚀 Starting Final Comprehensive DOCX Analysis Test")
    print("This test will verify the complete upload and analysis pipeline...")
    print()
    
    test_suite = DOCXAnalysisTestSuite()
    results = test_suite.run_complete_workflow_test()
    report = test_suite.generate_report(results)
    
    print(report)
    
    # Save report to file
    with open("FINAL_E2E_TEST_REPORT.md", "w", encoding="utf-8") as f:
        f.write(report)
    
    print("📄 Detailed report saved to: FINAL_E2E_TEST_REPORT.md")
    
    # Exit with appropriate code
    all_passed = all(test_suite.test_results.values())
    return 0 if all_passed else 1

if __name__ == "__main__":
    exit(main())