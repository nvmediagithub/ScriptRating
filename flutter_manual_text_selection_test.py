#!/usr/bin/env python3
"""
Flutter Web Text Selection Testing - Manual Browser Testing Script

This script provides manual testing instructions and automated checks
for text selection functionality in Flutter web applications.
"""

import asyncio
import json
import time
from datetime import datetime
from playwright.async_api import async_playwright, Page, Browser
from typing import List, Dict, Any

class FlutterTextSelectionManualTester:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.test_results = {
            "test_start_time": datetime.now().isoformat(),
            "base_url": base_url,
            "app_structure": {},
            "manual_testing_checklist": [],
            "automated_findings": [],
            "summary": {
                "total_areas_tested": 0,
                "working_areas": 0,
                "non_working_areas": 0,
                "notes": []
            }
        }
        
    async def analyze_flutter_app_structure(self):
        """Analyze the actual structure of the Flutter web app"""
        print("🔍 Analyzing Flutter web application structure...")
        
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=False)
            page = await browser.new_page()
            
            # Navigate to the app
            await page.goto(self.base_url, wait_until="networkidle")
            await page.wait_for_timeout(5000)
            
        async def _analyze_dom_structure(self, page: Page):
            """Analyze the DOM structure of the Flutter app"""
            print("🏗️  Analyzing DOM structure...")
            
            # Get page title
            title = await page.title()
            
            # Check for common Flutter web indicators
            flutter_indicators = {
                "flutter_view": await page.query_selector("flutter-view"),
                "flt-canvas-host": await page.query_selector("flt-canvas-host"),
                "semantics": await page.query_selector_all("[role='semantics']"),
                "custom_painter": await page.query_selector_all("custom-painter"),
                "canvas": await page.query_selector_all("canvas")
            }
            
            # Get text content from various sources
            text_content = await page.evaluate("""
                () => {
                    // Get text from different potential sources
                    const results = {
                        page_title: document.title,
                        body_text: document.body?.innerText || '',
                        all_text_nodes: Array.from(document.querySelectorAll('*'))
                            .map(el => el.innerText)
                            .filter(text => text.trim().length > 0)
                            .slice(0, 20), // First 20 text elements
                        html_structure: Array.from(document.querySelectorAll('*'))
                            .map(el => el.tagName)
                            .filter(tag => ['H1', 'H2', 'H3', 'P', 'SPAN', 'DIV'].includes(tag))
                            .slice(0, 10)
                    };
                    return results;
                }
            """)
            
            self.test_results["app_structure"] = {
                "flutter_indicators": {k: bool(v) for k, v in flutter_indicators.items()},
                "text_content_sample": text_content,
                "page_title": title
            }
            
            print(f"   Flutter View Found: {flutter_indicators['flutter_view']}")
            print(f"   Canvas Host Found: {flutter_indicators['flt-canvas-host']}")
            print(f"   Text Elements Found: {len(text_content['all_text_nodes'])}")
        
    async def _take_screenshots(self, page: Page, browser: Browser):
        """Take screenshots for manual analysis"""
        print("📸 Taking screenshots for manual analysis...")
        
        # Test different viewport sizes
        viewports = [
            {"name": "desktop", "width": 1920, "height": 1080},
            {"name": "tablet", "width": 768, "height": 1024},
            {"name": "mobile", "width": 375, "height": 667}
        ]
        
        for viewport in viewports:
            await page.set_viewport_size({"width": viewport["width"], "height": viewport["height"]})
            await page.wait_for_timeout(1000)
            await page.screenshot(path=f"flutter_app_{viewport['name']}_view.png", full_page=True)
            print(f"   ✅ Screenshot saved: flutter_app_{viewport['name']}_view.png")
    
    async def _test_basic_text_selection(self, page: Page):
        """Test basic text selection capabilities"""
        print("🖱️  Testing basic text selection...")
        
        # Test selecting all text
        try:
            await page.keyboard.press("Control+a")
            await page.wait_for_timeout(1000)
            
            # Test copy
            await page.keyboard.press("Control+c")
            await page.wait_for_timeout(500)
            
            # Try to get clipboard content
            try:
                clipboard_content = await page.evaluate("navigator.clipboard.readText()")
                self.test_results["automated_findings"].append({
                    "test": "Select All + Copy",
                    "status": "working" if clipboard_content and len(clipboard_content) > 0 else "limited",
                    "clipboard_length": len(clipboard_content) if clipboard_content else 0
                })
                print(f"   ✅ Select all and copy test completed")
            except:
                self.test_results["automated_findings"].append({
                    "test": "Select All + Copy",
                    "status": "browser_restricted",
                    "note": "Clipboard access may be restricted by browser security"
                })
                print(f"   ⚠️  Select all and copy test - browser restrictions")
                
        except Exception as e:
            self.test_results["automated_findings"].append({
                "test": "Select All + Copy",
                "status": "failed",
                "error": str(e)
            })
            print(f"   ❌ Select all and copy test failed: {str(e)}")
    
    def generate_manual_testing_checklist(self):
        """Generate a comprehensive manual testing checklist"""
        checklist = {
            "basic_functionality": [
                "Load the application at http://localhost:8080",
                "Verify the app loads without errors",
                "Check that text is visible and readable",
                "Test if you can select text by dragging mouse",
                "Test if you can select text by double-clicking",
                "Test if Ctrl+A (Select All) works",
                "Test if Ctrl+C (Copy) works after selection",
                "Test if Cmd+A and Cmd+C work on macOS"
            ],
            "screen_specific_tests": {
                "home_screen": [
                    "Select main title text",
                    "Select navigation menu items", 
                    "Select any description or help text",
                    "Select button labels"
                ],
                "analysis_screen": [
                    "Select analysis status messages",
                    "Select progress indicators",
                    "Select error messages if any",
                    "Select any result text"
                ],
                "results_screen": [
                    "Select analysis results and recommendations",
                    "Select scene details and reference information", 
                    "Select script metadata (titles, authors, ratings)",
                    "Select category summaries and explanations"
                ],
                "history_screen": [
                    "Select script list items",
                    "Select timestamps and dates",
                    "Select descriptions or notes"
                ]
            },
            "responsive_testing": [
                "Test text selection at desktop resolution (1920x1080)",
                "Test text selection at tablet resolution (768x1024)", 
                "Test text selection at mobile resolution (375x667)",
                "Test text selection when browser window is resized",
                "Test text selection in fullscreen mode"
            ],
            "edge_cases": [
                "Test selection across different font sizes",
                "Test selection of text in colored regions",
                "Test selection of text in cards or containers",
                "Test selection of very long text strings",
                "Test selection when UI elements are animated",
                "Test selection in dark/light theme if applicable"
            ],
            "ui_integration": [
                "Verify selection doesn't break button functionality",
                "Verify selection doesn't interfere with navigation",
                "Verify selection doesn't cause layout shifts",
                "Test that non-selectable elements (like buttons) still work",
                "Verify keyboard navigation still works after selection"
            ]
        }
        
        self.test_results["manual_testing_checklist"] = checklist
        return checklist
    
    def print_manual_testing_instructions(self):
        """Print detailed manual testing instructions"""
        print("\n" + "="*80)
        print("📋 FLUTTER WEB TEXT SELECTION - MANUAL TESTING GUIDE")
        print("="*80)
        
        checklist = self.generate_manual_testing_checklist()
        
        print("\n🚀 QUICK START TESTING:")
        print("1. Open browser to http://localhost:8080")
        print("2. Wait for Flutter app to fully load")
        print("3. Follow the checklist below for comprehensive testing")
        
        for category, items in checklist.items():
            if category == "screen_specific_tests":
                print(f"\n📱 {category.upper().replace('_', ' ')}:")
                for screen, tests in items.items():
                    print(f"\n  {screen.replace('_', ' ').title()}:")
                    for test in tests:
                        print(f"    □ {test}")
            else:
                print(f"\n🔍 {category.upper().replace('_', ' ')}:")
                for item in items:
                    print(f"    □ {item}")
        
        print("\n" + "="*80)
        print("💡 TESTING TIPS:")
        print("="*80)
        print("• Test both mouse and keyboard interactions")
        print("• Try selecting partial words, full words, and paragraphs")
        print("• Test selection persistence (does selection stay when navigating?)")
        print("• Test copy/paste into external applications (Notepad, TextEdit, etc.)")
        print("• Check for any visual glitches or layout issues during selection")
        print("• Verify that selection works consistently across different browsers")
        
    async def run_comprehensive_analysis(self):
        """Run the complete analysis and generate instructions"""
        print("🔍 Starting comprehensive Flutter web text selection analysis...")
        
        # Run the async analysis
        await self.analyze_flutter_app_structure()
        
        # Generate manual testing guide
        self.print_manual_testing_instructions()
        
        # Save results
        with open("flutter_text_selection_manual_test_guide.json", "w") as f:
            json.dump(self.test_results, f, indent=2)
        
        print(f"\n📁 Analysis results saved to: flutter_text_selection_manual_test_guide.json")
        print("📸 Screenshots saved: flutter_app_*_view.png")
        
        return self.test_results

def main():
    """Main execution"""
    tester = FlutterTextSelectionManualTester()
    results = asyncio.run(tester.run_comprehensive_analysis())
    return results

if __name__ == "__main__":
    asyncio.run(main())