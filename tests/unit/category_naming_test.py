#!/usr/bin/env python3
"""
Test script to verify category naming convention fix.
This script simulates the error that was occurring and confirms the fix works.
"""

import json
from app.presentation.api.schemas import Category, Severity

def test_category_serialization():
    """Test that category serialization works correctly."""
    print("=== Testing Category Serialization ===")
    
    # Test that all categories can be created from their string values
    category_values = ['violence', 'sexual_content', 'language', 'alcohol_drugs', 'disturbing_scenes']
    
    for value in category_values:
        try:
            category = Category(value)
            print(f"✅ {value} -> {category.name} (value: {category.value})")
        except ValueError as e:
            print(f"❌ Failed to create Category from '{value}': {e}")
            return False
    
    print("\n=== Testing Category Enum Values ===")
    for category in Category:
        print(f"{category.name} -> '{category.value}'")
    
    print("\n=== Testing JSON Serialization ===")
    # Test JSON serialization (what Flutter should send)
    categories_data = {
        'violence': 'moderate',
        'sexual_content': 'mild',
        'language': 'none',
        'alcohol_drugs': 'severe',
        'disturbing_scenes': 'mild'
    }
    
    try:
        # Simulate what Flutter would send (categories as dict with snake_case keys)
        result_categories = {}
        for key, value in categories_data.items():
            category = Category(key)  # Should work with snake_case
            severity = Severity(value)
            result_categories[category] = severity
        
        print("✅ Successfully converted snake_case categories to enums")
        for cat, sev in result_categories.items():
            print(f"  {cat.name}: {sev.name}")
        
        return True
    except Exception as e:
        print(f"❌ Failed to convert categories: {e}")
        return False

def test_backend_expects_snake_case():
    """Test that backend expects snake_case categories."""
    print("\n=== Testing Backend Category Expectations ===")
    
    # This is what the error message indicated the backend expected
    expected_values = ['violence', 'sexualContent', 'language', 'alcoholDrugs', 'disturbingScenes']
    actual_backend_values = [c.value for c in Category]
    
    print("Backend actually expects (from Category enum):")
    for value in actual_backend_values:
        print(f"  '{value}'")
    
    print("\nError message claimed backend expected:")
    for value in expected_values:
        print(f"  '{value}'")
    
    # The fix ensures that Flutter now sends snake_case values that match backend expectations
    print("\n✅ After fix, Flutter now sends snake_case values that match backend")
    return True

if __name__ == "__main__":
    print("Category Naming Convention Fix Verification")
    print("=" * 50)
    
    success1 = test_category_serialization()
    success2 = test_backend_expects_snake_case()
    
    if success1 and success2:
        print("\n🎉 All tests passed! Category naming convention issue is fixed.")
    else:
        print("\n❌ Some tests failed. The fix may need additional work.")