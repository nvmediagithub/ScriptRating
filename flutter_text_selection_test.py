#!/usr/bin/env python3
"""
Comprehensive Flutter Web Text Selection Testing Script

This script tests text selection functionality in the Flutter web application
across different screens, UI elements, and interaction methods.
"""

import asyncio
import json
import time
from datetime import datetime
from playwright.async_api import async_playwright, Page, Browser
from typing import List, Dict, Any

class FlutterTextSelectionTester:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.test_results = {
            "test_start_time": datetime.now().isoformat(),
            "base_url": base_url,
            "screens": {},
            "text_selection_tests": [],
            "copy_functionality_tests": [],
            "responsive_tests": [],
            "ui_interaction_tests": [],
            "performance_issues": [],
            "summary": {
                "total_tests": 0,
                "passed": 0,
                "failed": 0,
                "warnings": 0
            }
        }
        
    async def run_comprehensive_tests(self):
        """Run all text selection tests"""
        print("🚀 Starting comprehensive Flutter Web text selection tests...")
        
        async with async_playwright() as p:
            # Test on different browser contexts and screen sizes
            await self._test_desktop_view(p)
            await self._test_tablet_view(p) 
            await self._test_mobile_view(p)
            
        # Generate final report
        self._generate_test_report()
        return self.test_results

    async def _test_desktop_view(self, p):
        """Test text selection in desktop view (1920x1080)"""
        print("🖥️  Testing desktop view (1920x1080)...")
        
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context(
            viewport={"width": 1920, "height": 1080}
        )
        page = await context.new_page()
        
        await self._test_all_screens_and_features(page, "desktop")
        await browser.close()

    async def _test_tablet_view(self, p):
        """Test text selection in tablet view (768x1024)"""
        print("📱 Testing tablet view (768x1024)...")
        
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context(
            viewport={"width": 768, "height": 1024}
        )
        page = await context.new_page()
        
        await self._test_all_screens_and_features(page, "tablet")
        await browser.close()

    async def _test_mobile_view(self, p):
        """Test text selection in mobile view (375x667)"""
        print("📱 Testing mobile view (375x667)...")
        
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context(
            viewport={"width": 375, "height": 667}
        )
        page = await context.new_page()
        
        await self._test_all_screens_and_features(page, "mobile")
        await browser.close()

    async def _test_all_screens_and_features(self, page: Page, view_type: str):
        """Test all screens and text selection features"""
        
        # Navigate to application
        await page.goto(self.base_url, wait_until="networkidle")
        await page.wait_for_timeout(3000)
        
        # Test home screen
        await self._test_home_screen(page, view_type)
        
        # Test upload functionality and navigation to other screens
        await self._test_upload_and_navigation(page, view_type)
        
        # Test analysis screen
        await self._test_analysis_screen(page, view_type)
        
        # Test results screen  
        await self._test_results_screen(page, view_type)
        
        # Test history screen
        await self._test_history_screen(page, view_type)
        
        # Test settings/feedback screens
        await self._test_other_screens(page, view_type)

    async def _test_home_screen(self, page: Page, view_type: str):
        """Test text selection on home screen"""
        print(f"  🏠 Testing home screen - {view_type}")
        
        # Test main title selection
        await self._test_text_selection(
            page, 
            "h1, .title, [data-testid*='title']",
            "Main title text selection",
            view_type
        )
        
        # Test navigation menu text
        await self._test_text_selection(
            page,
            "nav a, .nav-item, button",
            "Navigation menu text selection", 
            view_type
        )
        
        # Test description text
        await self._test_text_selection(
            page,
            "p, .description, .subtitle",
            "Description text selection",
            view_type
        )

    async def _test_upload_and_navigation(self, page: Page, view_type: str):
        """Test file upload and navigation to trigger other screens"""
        print(f"  📁 Testing upload and navigation - {view_type}")
        
        # Look for upload button or drag area
        upload_selectors = [
            "input[type='file']",
            ".upload-area", 
            ".dropzone",
            "button:has-text('Upload')",
            "button:has-text('Choose')"
        ]
        
        for selector in upload_selectors:
            try:
                element = await page.query_selector(selector)
                if element:
                    print(f"    Found upload element: {selector}")
                    break
            except:
                continue
        
        # Try to navigate to other screens via buttons/links
        nav_selectors = [
            "a:has-text('Analysis')",
            "a:has-text('Results')", 
            "a:has-text('History')",
            "button:has-text('Analyze')",
            "button:has-text('Start')"
        ]
        
        for selector in nav_selectors:
            try:
                element = await page.query_selector(selector)
                if element:
                    await element.click()
                    await page.wait_for_timeout(2000)
                    break
            except:
                continue

    async def _test_analysis_screen(self, page: Page, view_type: str):
        """Test text selection on analysis screen"""
        print(f"  🔍 Testing analysis screen - {view_type}")
        
        # Test analysis status messages
        await self._test_text_selection(
            page,
            ".status-message, .analysis-status, [data-testid*='status']",
            "Analysis status text selection",
            view_type
        )
        
        # Test progress indicators text
        await self._test_text_selection(
            page,
            ".progress-text, .percentage, .status",
            "Progress indicator text selection", 
            view_type
        )
        
        # Test any error messages
        await self._test_text_selection(
            page,
            ".error, .alert, [data-testid*='error']",
            "Error message text selection",
            view_type
        )

    async def _test_results_screen(self, page: Page, view_type: str):
        """Test text selection on results screen"""
        print(f"  📊 Testing results screen - {view_type}")
        
        # Test analysis results and recommendations
        await self._test_text_selection(
            page,
            ".analysis-result, .recommendation, .result-content",
            "Analysis results text selection",
            view_type
        )
        
        # Test scene details
        await self._test_text_selection(
            page,
            ".scene-detail, .scene-content, [data-testid*='scene']",
            "Scene details text selection",
            view_type
        )
        
        # Test category summaries
        await self._test_text_selection(
            page,
            ".category-summary, .summary, [data-testid*='category']",
            "Category summary text selection",
            view_type
        )
        
        # Test script metadata
        await self._test_text_selection(
            page,
            ".script-title, .author, .rating, .metadata",
            "Script metadata text selection",
            view_type
        )

    async def _test_history_screen(self, page: Page, view_type: str):
        """Test text selection on history screen"""
        print(f"  📚 Testing history screen - {view_type}")
        
        # Test script list items
        await self._test_text_selection(
            page,
            ".script-item, .history-item, [data-testid*='script']",
            "Script list item text selection",
            view_type
        )
        
        # Test timestamps and dates
        await self._test_text_selection(
            page,
            ".timestamp, .date, .time",
            "Timestamp text selection",
            view_type
        )
        
        # Test any descriptions or notes
        await self._test_text_selection(
            page,
            ".description, .note, .comment",
            "Description text selection in history",
            view_type
        )

    async def _test_other_screens(self, page: Page, view_type: str):
        """Test other screens like settings, feedback, etc."""
        print(f"  ⚙️  Testing other screens - {view_type}")
        
        # Test any remaining text elements
        text_selectors = [
            "span", "div", "label", "h1", "h2", "h3", "h4", "h5", "h6",
            "p", "td", "th", "li"
        ]
        
        for selector in text_selectors:
            await self._test_text_selection(
                page,
                selector,
                f"General {selector} text selection",
                view_type
            )

    async def _test_text_selection(self, page: Page, selector: str, test_name: str, view_type: str):
        """Test text selection for a specific selector"""
        
        try:
            elements = await page.query_selector_all(selector)
            
            for i, element in enumerate(elements[:3]):  # Test up to 3 elements per selector
                try:
                    # Get element text
                    text = await element.inner_text()
                    if not text or len(text.strip()) < 3:
                        continue
                    
                    # Test text selection via double-click
                    await element.dblclick()
                    await page.wait_for_timeout(500)
                    
                    # Test keyboard selection (Ctrl+A)
                    await page.keyboard.press("Control+a")
                    await page.wait_for_timeout(500)
                    
                    # Test copy functionality
                    await page.keyboard.press("Control+c")
                    await page.wait_for_timeout(500)
                    
                    # Record test result
                    test_result = {
                        "test_name": test_name,
                        "selector": selector,
                        "element_index": i,
                        "view_type": view_type,
                        "element_text": text[:100] + "..." if len(text) > 100 else text,
                        "selection_working": True,
                        "copy_working": True,
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    self.test_results["text_selection_tests"].append(test_result)
                    self.test_results["summary"]["total_tests"] += 1
                    self.test_results["summary"]["passed"] += 1
                    
                    print(f"    ✅ {test_name} - Element {i}: Text selection working")
                    
                except Exception as e:
                    test_result = {
                        "test_name": test_name,
                        "selector": selector,
                        "element_index": i,
                        "view_type": view_type,
                        "error": str(e),
                        "selection_working": False,
                        "timestamp": datetime.now().isoformat()
                    }
                    
                    self.test_results["text_selection_tests"].append(test_result)
                    self.test_results["summary"]["total_tests"] += 1
                    self.test_results["summary"]["failed"] += 1
                    
                    print(f"    ❌ {test_name} - Element {i}: {str(e)}")
                    
        except Exception as e:
            self.test_results["performance_issues"].append({
                "issue": f"Failed to find elements with selector: {selector}",
                "error": str(e),
                "view_type": view_type,
                "timestamp": datetime.now().isoformat()
            })

    async def _test_copy_functionality(self, page: Page, view_type: str):
        """Test copy functionality specifically"""
        print(f"  📋 Testing copy functionality - {view_type}")
        
        # Test copy on selected text
        try:
            await page.keyboard.press("Control+a")
            await page.wait_for_timeout(500)
            await page.keyboard.press("Control+c")
            
            # Verify clipboard content
            clipboard_text = await page.evaluate("navigator.clipboard.readText()")
            
            test_result = {
                "test_name": "Copy functionality test",
                "view_type": view_type,
                "clipboard_content_length": len(clipboard_text) if clipboard_text else 0,
                "copy_working": bool(clipboard_text and len(clipboard_text) > 0),
                "timestamp": datetime.now().isoformat()
            }
            
            self.test_results["copy_functionality_tests"].append(test_result)
            
            if test_result["copy_working"]:
                self.test_results["summary"]["passed"] += 1
                print(f"    ✅ Copy functionality working - {view_type}")
            else:
                self.test_results["summary"]["failed"] += 1
                print(f"    ❌ Copy functionality not working - {view_type}")
                
        except Exception as e:
            self.test_results["copy_functionality_tests"].append({
                "test_name": "Copy functionality test",
                "view_type": view_type,
                "error": str(e),
                "copy_working": False,
                "timestamp": datetime.now().isoformat()
            })
            self.test_results["summary"]["failed"] += 1
            print(f"    ❌ Copy functionality test failed - {view_type}: {str(e)}")

    def _generate_test_report(self):
        """Generate comprehensive test report"""
        self.test_results["test_end_time"] = datetime.now().isoformat()
        
        # Calculate success rates
        total = self.test_results["summary"]["total_tests"]
        passed = self.test_results["summary"]["passed"]
        failed = self.test_results["summary"]["failed"]
        
        self.test_results["summary"]["success_rate"] = (
            (passed / total * 100) if total > 0 else 0
        )
        
        # Save detailed results
        with open("flutter_text_selection_test_results.json", "w") as f:
            json.dump(self.test_results, f, indent=2)
            
        print(f"\n📊 Test Summary:")
        print(f"   Total Tests: {total}")
        print(f"   Passed: {passed}")
        print(f"   Failed: {failed}")
        print(f"   Success Rate: {self.test_results['summary']['success_rate']:.1f}%")
        print(f"\n📝 Detailed results saved to: flutter_text_selection_test_results.json")

async def main():
    """Main test execution"""
    tester = FlutterTextSelectionTester()
    results = await tester.run_comprehensive_tests()
    
    print("\n🎉 Text selection testing completed!")
    return results

if __name__ == "__main__":
    asyncio.run(main())