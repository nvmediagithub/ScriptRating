#!/usr/bin/env python3
"""
Debug script to understand import structure issues.
"""
import sys
import traceback

print("=== IMPORT STRUCTURE DEBUG ===")
print(f"Python version: {sys.version}")
print(f"Current working directory: {sys.path[0]}")

# Try to import the schemas package
print("\n1. Testing import of app.presentation.api.schemas package:")
try:
    import app.presentation.api.schemas as schemas_package
    print(f"✓ Successfully imported schemas package: {schemas_package}")
    print(f"  Package location: {schemas_package.__file__}")
    print(f"  Available attributes: {dir(schemas_package)}")
except Exception as e:
    print(f"✗ Failed to import schemas package: {e}")
    traceback.print_exc()

print("\n2. Testing import of app.presentation.api.schemas.py module:")
try:
    from app.presentation.api.schemas import DocumentType, AgeRating, Category
    print(f"✓ Successfully imported from schemas.py: DocumentType={DocumentType}, AgeRating={AgeRating}, Category={Category}")
except Exception as e:
    print(f"✗ Failed to import from schemas.py: {e}")
    traceback.print_exc()

print("\n3. Testing direct file access:")
import os
schemas_py_path = "/Users/user/Documents/Repositories/ScriptRating/app/presentation/api/schemas.py"
schemas_dir_path = "/Users/user/Documents/Repositories/ScriptRating/app/presentation/api/schemas/__init__.py"

print(f"schemas.py exists: {os.path.exists(schemas_py_path)}")
print(f"schemas/__init__.py exists: {os.path.exists(schemas_dir_path)}")

if os.path.exists(schemas_py_path):
    with open(schemas_py_path, 'r') as f:
        first_few_lines = f.readlines()[:5]
    print(f"schemas.py first lines: {''.join(first_few_lines)}")

if os.path.exists(schemas_dir_path):
    with open(schemas_dir_path, 'r') as f:
        first_few_lines = f.readlines()[:10]
    print(f"schemas/__init__.py first lines: {''.join(first_few_lines)}")

print("\n4. Testing the problematic import:")
try:
    from app.presentation.api.schemas import DocumentType
    print(f"✓ DocumentType import successful: {DocumentType}")
except Exception as e:
    print(f"✗ DocumentType import failed: {e}")
    traceback.print_exc()

print("\n=== END DEBUG ===")