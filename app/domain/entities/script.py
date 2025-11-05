"""
Script domain entity.

This module defines the Script entity representing a script document in the domain.
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime


@dataclass
class Script:
    """
    Domain entity representing a script.

    Attributes:
        id: Unique identifier for the script
        title: Script title
        content: Script content/text
        author: Script author (optional)
        created_at: Creation timestamp
        updated_at: Last update timestamp
        rating: Current rating score (optional)
    """
    id: str
    title: str
    content: str
    author: Optional[str] = None
    created_at: datetime = None
    updated_at: datetime = None
    rating: Optional[float] = None

    def __post_init__(self):
        """Set default timestamps if not provided."""
        if self.created_at is None:
            self.created_at = datetime.utcnow()
        if self.updated_at is None:
            self.updated_at = datetime.utcnow()

    def update_rating(self, new_rating: float) -> None:
        """
        Update the script's rating.

        Args:
            new_rating: New rating score to assign.
        """
        self.rating = new_rating
        self.updated_at = datetime.utcnow()