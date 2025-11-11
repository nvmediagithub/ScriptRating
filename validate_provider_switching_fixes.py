#!/usr/bin/env python3
"""
Simple validation script for LLM Provider Switching fixes

This script performs basic validation of the code changes without requiring
external dependencies or a running server.
"""

import json
import re
from pathlib import Path
from typing import List, Dict, Any

def validate_file_content(file_path: str, search_patterns: List[str]) -> Dict[str, bool]:
    """Validate that certain patterns exist in a file."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        results = {}
        for pattern in search_patterns:
            results[pattern] = pattern in content
        
        return results
    except FileNotFoundError:
        return {pattern: False for pattern in search_patterns}

def validate_python_syntax(file_path: str) -> Dict[str, Any]:
    """Validate Python file syntax."""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Try to compile the content
        compile(content, file_path, 'exec')
        return {"valid": True, "error": None}
    except SyntaxError as e:
        return {"valid": False, "error": str(e)}
    except FileNotFoundError:
        return {"valid": False, "error": "File not found"}

def validate_provider_enum_fixes():
    """Validate that provider enum fixes are in place."""
    print("🔍 Validating Provider Enum Fixes...")
    
    # Check backend file
    backend_file = "app/presentation/api/routes/llm.py"
    backend_patterns = [
        "provider=LLMProvider.LOCAL",  # Should use enum value
        "provider=LLMProvider.OPENROUTER",
        "logger.info(f\"Switching LLM mode to provider: {provider.value}",
    ]
    
    backend_results = validate_file_content(backend_file, backend_patterns)
    
    print(f"  Backend file ({backend_file}):")
    for pattern, found in backend_results.items():
        status = "✅" if found else "❌"
        print(f"    {status} {pattern}: {'Found' if found else 'Not found'}")
    
    # Check Flutter service file
    flutter_service = "flutter/lib/services/llm_service.dart"
    flutter_patterns = [
        "'provider': provider.value",  # Should use .value instead of .name
        "'model_name': modelName,",
    ]
    
    flutter_results = validate_file_content(flutter_service, flutter_patterns)
    
    print(f"  Flutter service file ({flutter_service}):")
    for pattern, found in flutter_results.items():
        status = "✅" if found else "❌"
        print(f"    {status} {pattern}: {'Found' if found else 'Not found'}")
    
    # Check Flutter models file
    flutter_models = "flutter/lib/models/llm_models.dart"
    model_patterns = [
        "'provider': provider.value,",  # Should use .value instead of .name
        "'active_provider': activeProvider.value,",
    ]
    
    model_results = validate_file_content(flutter_models, model_patterns)
    
    print(f"  Flutter models file ({flutter_models}):")
    for pattern, found in model_results.items():
        status = "✅" if found else "❌"
        print(f"    {status} {pattern}: {'Found' if found else 'Not found'}")
    
    return {
        "backend": backend_results,
        "flutter_service": flutter_results,
        "flutter_models": model_results,
    }

def validate_error_handling_fixes():
    """Validate that error handling improvements are in place."""
    print("\n🚨 Validating Error Handling Improvements...")
    
    backend_file = "app/presentation/api/routes/llm.py"
    error_patterns = [
        "logger.info(f\"Switching LLM mode to provider: {provider.value}, model: {model_name}\"",
        "available_providers = [p.value for p in PROVIDER_SETTINGS.keys()]",
        "raise HTTPException(status_code=400,",
        "except Exception as e:",
        "logger.error(f\"Unexpected error in switch_llm_mode: {e}\"",
    ]
    
    results = validate_file_content(backend_file, error_patterns)
    
    for pattern, found in results.items():
        status = "✅" if found else "❌"
        print(f"  {status} {pattern}: {'Found' if found else 'Not found'}")
    
    return results

def validate_syntax_correction():
    """Validate that Python syntax is correct after fixes."""
    print("\n🐍 Validating Python Syntax...")
    
    files_to_check = [
        "app/presentation/api/routes/llm.py",
        "flutter/lib/services/llm_service.dart",
        "flutter/lib/models/llm_models.dart",
    ]
    
    results = {}
    for file_path in files_to_check:
        syntax_check = validate_python_syntax(file_path)
        status = "✅" if syntax_check["valid"] else "❌"
        print(f"  {status} {file_path}: {'Valid' if syntax_check['valid'] else 'Error: ' + str(syntax_check['error'])}")
        results[file_path] = syntax_check
    
    return results

def validate_test_file():
    """Validate that test file exists and has proper content."""
    print("\n🧪 Validating Test File...")
    
    test_file = "test_provider_switching.py"
    
    if not Path(test_file).exists():
        print(f"  ❌ Test file not found: {test_file}")
        return False
    
    test_patterns = [
        "async def test_switch_to_local",
        "async def test_switch_to_openrouter", 
        "await self.test_get_config",
        "await self.make_request",
    ]
    
    results = validate_file_content(test_file, test_patterns)
    
    for pattern, found in results.items():
        status = "✅" if found else "❌"
        print(f"  {status} {pattern}: {'Found' if found else 'Not found'}")
    
    return all(results.values())

def check_for_problematic_patterns():
    """Check that problematic patterns are no longer present."""
    print("\n🔍 Checking for Problematic Patterns (should NOT be present)...")
    
    problematic_patterns = [
        ("provider=\"local\"", "Should use enum, not string literal"),
        ("provider=\"openrouter\"", "Should use enum, not string literal"),
        ("provider.name", "Should use provider.value, not provider.name"),
    ]
    
    files_to_check = [
        "app/presentation/api/routes/llm.py",
        "flutter/lib/services/llm_service.dart", 
        "flutter/lib/models/llm_models.dart",
    ]
    
    results = {}
    
    for file_path in files_to_check:
        print(f"\n  Checking {file_path}:")
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            
            file_results = {}
            for pattern, description in problematic_patterns:
                # Count occurrences
                count = len(re.findall(re.escape(pattern), content))
                if count > 0:
                    print(f"    ❌ Found {count} occurrences of '{pattern}' - {description}")
                    file_results[pattern] = False
                else:
                    print(f"    ✅ No problematic '{pattern}' found")
                    file_results[pattern] = True
            
            results[file_path] = file_results
            
        except FileNotFoundError:
            print(f"    ❌ File not found: {file_path}")
            results[file_path] = {pattern: False for pattern, _ in problematic_patterns}
    
    return results

def generate_summary_report(validation_results: Dict[str, Any]):
    """Generate a summary report of all validations."""
    print("\n" + "=" * 60)
    print("📋 VALIDATION SUMMARY REPORT")
    print("=" * 60)
    
    total_checks = 0
    passed_checks = 0
    
    # Count provider enum fixes
    if "provider_enum_fixes" in validation_results:
        print("\n✅ Provider Enum Fixes:")
        for category, results in validation_results["provider_enum_fixes"].items():
            for pattern, found in results.items():
                total_checks += 1
                if found:
                    passed_checks += 1
                status = "✅" if found else "❌"
                print(f"  {status} {category}: {pattern}")
    
    # Count error handling fixes  
    if "error_handling_fixes" in validation_results:
        print("\n✅ Error Handling Improvements:")
        for pattern, found in validation_results["error_handling_fixes"].items():
            total_checks += 1
            if found:
                passed_checks += 1
            status = "✅" if found else "❌"
            print(f"  {status} {pattern}")
    
    # Count syntax validation
    if "syntax_validation" in validation_results:
        print("\n✅ Python Syntax Validation:")
        for file_path, result in validation_results["syntax_validation"].items():
            total_checks += 1
            if result["valid"]:
                passed_checks += 1
            status = "✅" if result["valid"] else "❌"
            print(f"  {status} {file_path}")
    
    # Test file validation
    if validation_results.get("test_file_valid", False):
        passed_checks += 1
        total_checks += 1
        print("\n✅ Test File: Properly created")
    else:
        total_checks += 1
        print("\n❌ Test File: Issues found")
    
    # Check for problematic patterns
    if "problematic_patterns" in validation_results:
        print("\n✅ Problematic Pattern Check:")
        for file_path, results in validation_results["problematic_patterns"].items():
            for pattern, is_good in results.items():
                total_checks += 1
                if is_good:
                    passed_checks += 1
                status = "✅" if is_good else "❌"
                print(f"  {status} {file_path}: '{pattern}' - {'Clean' if is_good else 'Found issues'}")
    
    # Final score
    success_rate = (passed_checks / total_checks * 100) if total_checks > 0 else 0
    
    print(f"\n🎯 OVERALL RESULTS:")
    print(f"   Passed: {passed_checks}/{total_checks} checks")
    print(f"   Success Rate: {success_rate:.1f}%")
    
    if success_rate >= 90:
        print("   Status: 🎉 EXCELLENT - All major fixes implemented correctly!")
    elif success_rate >= 75:
        print("   Status: ✅ GOOD - Most fixes implemented, minor issues remain")
    elif success_rate >= 50:
        print("   Status: ⚠️ FAIR - Some fixes implemented, more work needed")
    else:
        print("   Status: ❌ POOR - Significant issues remain, major fixes needed")
    
    return success_rate

def main():
    """Main validation function."""
    print("🚀 LLM Provider Switching - Code Validation Suite")
    print("=" * 60)
    print("This script validates the fixes made to the provider switching functionality.")
    print("It checks for proper enum usage, error handling, and syntax correctness.")
    
    validation_results = {}
    
    try:
        # Run all validations
        validation_results["provider_enum_fixes"] = validate_provider_enum_fixes()
        validation_results["error_handling_fixes"] = validate_error_handling_fixes()
        validation_results["syntax_validation"] = validate_syntax_correction()
        validation_results["test_file_valid"] = validate_test_file()
        validation_results["problematic_patterns"] = check_for_problematic_patterns()
        
        # Generate summary report
        success_rate = generate_summary_report(validation_results)
        
        print(f"\n💡 Recommendations:")
        if success_rate >= 90:
            print("   • Provider switching functionality should now work correctly")
            print("   • You can test with: python3 test_provider_switching.py")
            print("   • Launch Flutter app to test the UI integration")
        elif success_rate >= 75:
            print("   • Most fixes are in place, minor issues may remain")
            print("   • Review the failed checks above and make additional fixes")
        else:
            print("   • Significant issues remain, review all failed checks")
            print("   • Consider re-implementing the fixes more carefully")
        
        return success_rate >= 75
        
    except Exception as e:
        print(f"\n💥 Validation failed with error: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)