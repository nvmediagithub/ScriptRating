"""Schemas package for API request/response models."""

# Import only the necessary schemas for the main application
# Avoid circular imports by being explicit about what we export

# Import main schemas from schemas.py file (which is in the parent directory)
import os
import sys

# Get the parent directory path (schemas.py is in the parent of this directory)
parent_dir = os.path.dirname(os.path.dirname(__file__))

# Import schemas.py directly by reading and executing its content
schemas_file_path = os.path.join(parent_dir, "schemas.py")
if os.path.exists(schemas_file_path):
    with open(schemas_file_path, 'r') as f:
        schemas_code = f.read()
    
    # Execute the schemas.py code in the current namespace
    # This makes all classes available in the current module
    exec(schemas_code, globals())
    print(f"✓ Successfully loaded schemas.py from parent directory")
else:
    print(f"Warning: schemas.py not found at {schemas_file_path}")

# Import chat schemas from the chat_schemas.py file in this directory
try:
    from .chat_schemas import *
    print("✓ Successfully imported chat_schemas")
except ImportError as e:
    print(f"Warning: Could not import chat_schemas: {e}")

# Remove temporary variables that shouldn't be in __all__
_temp_vars = {'schemas_code', 'schemas_file_path', 'parent_dir', 'f', 'os', 'sys', 'e'}
__all__ = [name for name in globals() if not name.startswith('_') and name not in _temp_vars]

print(f"Total schemas loaded: {len(__all__)} items")
print(f"Key schemas available: {[name for name in __all__ if name in ['DocumentType', 'AgeRating', 'Category', 'Severity']]}")