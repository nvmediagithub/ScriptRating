#!/usr/bin/env python3
"""
Detailed investigation of why the relative import from .schemas fails.
"""
import sys
import traceback
import os

print("=== RELATIVE IMPORT INVESTIGATION ===")

# Test 1: What happens when we try the exact import from __init__.py
print("\n1. Testing exact import from __init__.py context:")

try:
    # Simulate being inside the schemas package directory
    original_path = sys.path[0]
    schemas_dir = "/Users/user/Documents/Repositories/ScriptRating/app/presentation/api/schemas"
    print(f"Current working directory: {os.getcwd()}")
    print(f"Expected schemas directory: {schemas_dir}")
    print(f"Schemas directory exists: {os.path.exists(schemas_dir)}")
    
    # Check if schemas.py is in the same directory as __init__.py
    schemas_py = os.path.join(schemas_dir, "schemas.py")
    print(f"schemas.py path: {schemas_py}")
    print(f"schemas.py exists: {os.path.exists(schemas_py)}")
    
    # Try to import from the current package context
    import importlib
    import importlib.util
    
    # Load the __init__.py module
    init_spec = importlib.util.spec_from_file_location("schemas_init", os.path.join(schemas_dir, "__init__.py"))
    init_module = importlib.util.module_from_spec(init_spec)
    
    # Set up the module's __path__ to simulate package context
    init_module.__path__ = [schemas_dir]
    init_module.__name__ = "app.presentation.api.schemas"
    
    # Try to execute the __init__.py in a controlled environment
    print(f"\n2. Executing __init__.py in controlled environment:")
    try:
        init_spec.loader.exec_module(init_module)
        print("✓ __init__.py executed successfully")
    except Exception as e:
        print(f"✗ __init__.py execution failed: {e}")
        traceback.print_exc()
        
    # Now test the specific problematic import
    print(f"\n3. Testing the specific problematic import:")
    try:
        # This is what fails in the try/except block
        exec("from .schemas import *", init_module.__dict__)
        print("✓ 'from .schemas import *' succeeded")
    except Exception as e:
        print(f"✗ 'from .schemas import *' failed: {e}")
        print(f"   Error type: {type(e).__name__}")
        print(f"   Full traceback:")
        traceback.print_exc()
        
    # Alternative: test absolute import
    print(f"\n4. Testing absolute import alternative:")
    try:
        exec("from app.presentation.api.schemas.schemas import *", init_module.__dict__)
        print("✓ Absolute import 'from app.presentation.api.schemas.schemas import *' succeeded")
    except Exception as e:
        print(f"✗ Absolute import failed: {e}")
        traceback.print_exc()

except Exception as e:
    print(f"Overall test failed: {e}")
    traceback.print_exc()

# Test 2: Check Python's module resolution behavior
print(f"\n5. Understanding module resolution:")

try:
    # Import the package normally
    import app.presentation.api.schemas as schemas_pkg
    print(f"Package name: {schemas_pkg.__name__}")
    print(f"Package path: {schemas_pkg.__path__}")
    print(f"Package spec: {schemas_pkg.__spec__}")
    print(f"Package spec name: {schemas_pkg.__spec__.name}")
    print(f"Package spec origin: {schemas_pkg.__spec__.origin}")
    
    # Check what Python thinks is in the parent package
    import app.presentation.api
    api_pkg = app.presentation.api
    print(f"API package: {api_pkg}")
    print(f"API package files: {os.listdir(api_pkg.__path__[0])}")
    
except Exception as e:
    print(f"Module resolution test failed: {e}")
    traceback.print_exc()

print("\n=== END RELATIVE IMPORT INVESTIGATION ===")