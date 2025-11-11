#!/usr/bin/env python3
"""
Enhanced debug script to validate import assumptions.
"""
import sys
import traceback
import logging

# Set up logging to see what's happening during imports
logging.basicConfig(level=logging.DEBUG)

print("=== ENHANCED IMPORT DEBUG ===")
print(f"Python version: {sys.version}")

# Test 1: What happens in the __init__.py try/except block
print("\n1. Simulating __init__.py import logic:")

try:
    print("  Attempting: from .schemas import *")
    from app.presentation.api.schemas import *
    print("  ✓ schemas import * succeeded")
except Exception as e:
    print(f"  ✗ schemas import * failed: {e}")
    print("  This explains why main schemas are missing!")

try:
    print("  Attempting: from .chat_schemas import *")
    from app.presentation.api.schemas.chat_schemas import *
    print("  ✓ chat_schemas import * succeeded")
except Exception as e:
    print(f"  ✗ chat_schemas import * failed: {e}")

# Test 2: Direct access to schemas.py content
print("\n2. Direct access to schemas.py:")
try:
    import importlib.util
    spec = importlib.util.spec_from_file_location("schemas_direct", "/Users/user/Documents/Repositories/ScriptRating/app/presentation/api/schemas.py")
    schemas_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(schemas_module)
    print(f"  ✓ schemas.py loaded directly")
    print(f"  Available in schemas.py: {[attr for attr in dir(schemas_module) if not attr.startswith('_')]}")
    
    # Test specific problematic imports
    print(f"  DocumentType in schemas.py: {hasattr(schemas_module, 'DocumentType')}")
    print(f"  AgeRating in schemas.py: {hasattr(schemas_module, 'AgeRating')}")
    print(f"  Category in schemas.py: {hasattr(schemas_module, 'Category')}")
    
except Exception as e:
    print(f"  ✗ Direct schemas.py load failed: {e}")
    traceback.print_exc()

# Test 3: Check __all__ consistency
print("\n3. __all__ list analysis:")
try:
    import app.presentation.api.schemas as schemas_pkg
    all_list = schemas_pkg.__all__
    print(f"  __all__ contains: {len(all_list)} items")
    print(f"  First 10 items: {all_list[:10]}")
    
    # Check what's actually available vs what's in __all__
    actual_available = [attr for attr in dir(schemas_pkg) if not attr.startswith('_')]
    print(f"  Actually available: {len(actual_available)} items")
    missing_from_all = set(actual_available) - set(all_list)
    print(f"  Available but not in __all__: {missing_from_all}")
    
except Exception as e:
    print(f"  ✗ __all__ analysis failed: {e}")

print("\n=== END ENHANCED DEBUG ===")