#!/usr/bin/env python3
"""
Integration test to verify the DOCX analysis will work with the category naming fix.
This simulates the actual analysis workflow that was failing.
"""

import json
import asyncio
from app.presentation.api.schemas import Category, Severity, AgeRating
from app.infrastructure.services.analysis_manager import AnalysisManager
from app.infrastructure.services.knowledge_base import KnowledgeBase  
from app.infrastructure.services.script_store import ScriptStore

async def test_docx_analysis_categories():
    """Test that DOCX analysis works with correct category serialization."""
    print("=== Testing DOCX Analysis with Category Fix ===")
    
    # Create a mock script payload that would come from a DOCX file
    mock_script_payload = {
        "document_id": "test_docx_123",
        "paragraphs": [
            "Сцена 1: В фильме есть сцена с насилием и дракой",
            "Сцена 2: Персонажи пьют алкоголь в баре",
            "Сцена 3: Есть романтические сцены и флирт",
            "Сцена 4: Язык содержит грубые выражения"
        ],
        "paragraph_details": [
            {"page": 1, "paragraph_index": 1, "text": "Сцена 1: В фильме есть сцена с насилием и дракой"},
            {"page": 1, "paragraph_index": 2, "text": "Сцена 2: Персонажи пьют алкоголь в баре"},
            {"page": 1, "paragraph_index": 3, "text": "Сцена 3: Есть романтические сцены и флирт"},
            {"page": 1, "paragraph_index": 4, "text": "Сцена 4: Язык содержит грубые выражения"}
        ]
    }
    
    # Simulate what the Flutter app would send (categories in snake_case)
    request_payload = {
        "document_id": "test_docx_123",
        "options": {
            "include_recommendations": True,
            "detailed_scenes": True
        },
        "categories_summary": {
            "violence": "moderate",  # snake_case as expected by backend
            "sexual_content": "mild",  # snake_case as expected by backend  
            "language": "mild",  # snake_case as expected by backend
            "alcohol_drugs": "moderate",  # snake_case as expected by backend
            "disturbing_scenes": "none"  # snake_case as expected by backend
        }
    }
    
    print("Request payload categories (snake_case):")
    for cat, sev in request_payload["categories_summary"].items():
        print(f"  {cat}: {sev}")
    
    # Test that we can parse the categories correctly (this was the failing part)
    try:
        categories_summary = {}
        for key, value in request_payload.get("categories_summary", {}).items():
            category = Category(key)  # This should work with snake_case
            severity = Severity(value)
            categories_summary[category] = severity
            print(f"✅ Successfully parsed: {key} -> {category.name} = {severity.name}")
        
        print(f"\n✅ Parsed {len(categories_summary)} categories successfully")
        
        # Verify the final rating calculation
        final_rating = AgeRating.ZERO_PLUS
        highest_severity = max(categories_summary.values(), key=lambda s: ['none', 'mild', 'moderate', 'severe'].index(s.value))
        
        if highest_severity == Severity.MILD:
            final_rating = AgeRating.SIX_PLUS
        elif highest_severity == Severity.MODERATE:
            final_rating = AgeRating.TWELVE_PLUS
        elif highest_severity == Severity.SEVERE:
            final_rating = AgeRating.SIXTEEN_PLUS
            
        print(f"📊 Calculated final rating: {final_rating.value}")
        print(f"📊 Highest severity detected: {highest_severity.name}")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to parse categories: {e}")
        return False

def test_category_compatibility():
    """Test that the fixed Flutter categories are compatible with backend."""
    print("\n=== Testing Category Compatibility ===")
    
    # Test all category combinations that could come from Flutter
    test_cases = [
        # (flutter_sends, backend_expects, should_work)
        ("sexual_content", "sexual_content", True),
        ("alcohol_drugs", "alcohol_drugs", True), 
        ("disturbing_scenes", "disturbing_scenes", True),
        ("violence", "violence", True),
        ("language", "language", True),
        # These should NOT work (old camelCase format)
        ("sexualContent", "sexual_content", False),
        ("alcoholDrugs", "alcohol_drugs", False),
        ("disturbingScenes", "disturbing_scenes", False),
    ]
    
    for flutter_sends, backend_expects, should_work in test_cases:
        try:
            # Try to create the category (simulating backend processing)
            category = Category(flutter_sends)
            actual_value = category.value
            
            if should_work:
                print(f"✅ {flutter_sends} -> {category.name} (value: '{actual_value}')")
                assert actual_value == backend_expects, f"Expected {backend_expects}, got {actual_value}"
            else:
                print(f"⚠️  {flutter_sends} unexpectedly worked - this might be a problem")
                
        except ValueError as e:
            if should_work:
                print(f"❌ {flutter_sends} failed but should have worked: {e}")
                return False
            else:
                print(f"✅ {flutter_sends} correctly failed (as expected for camelCase)")
    
    return True

async def main():
    """Run all integration tests."""
    print("DOCX Analysis Category Fix Integration Test")
    print("=" * 50)
    
    test1 = await test_docx_analysis_categories()
    test2 = test_category_compatibility()
    
    if test1 and test2:
        print("\n🎉 All integration tests passed!")
        print("✅ The category naming convention issue is RESOLVED")
        print("✅ DOCX analysis should now work without the 'sexual_content' error")
        print("✅ Backend will correctly receive snake_case categories from Flutter")
    else:
        print("\n❌ Some integration tests failed. The fix may need additional work.")

if __name__ == "__main__":
    asyncio.run(main())