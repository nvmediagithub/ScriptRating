"""
RawScript domain entity.

This module defines the RawScript entity representing extracted script content.
"""
from dataclasses import dataclass
from typing import List, Dict, Any
from datetime import datetime


@dataclass
class RawScript:
    """
    Domain entity representing raw extracted script content.

    Attributes:
        id: Unique identifier
        filename: Original filename
        text: Full extracted text
        pages: List of page contents
        paragraphs: List of paragraph contents
        metadata: Additional metadata (encoding, source type, etc.)
        extracted_at: Extraction timestamp
    """
    id: str
    filename: str
    text: str
    pages: List[str]
    paragraphs: List[str]
    metadata: Dict[str, Any]
    extracted_at: datetime = None

    def __post_init__(self):
        """Set default extraction timestamp."""
        if self.extracted_at is None:
            self.extracted_at = datetime.utcnow()