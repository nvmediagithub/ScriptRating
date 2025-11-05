"""
FlaggedScene domain entity.

This module defines the FlaggedScene entity representing scenes flagged by rule-based filters.
"""
from dataclasses import dataclass
from typing import List, Dict, Set
from datetime import datetime

from .script_structure import Scene


class Severity:
    """Enumeration of severity levels for content flags."""
    NONE = "none"
    MILD = "mild"
    MODERATE = "moderate"
    SEVERE = "severe"


class Category:
    """Enumeration of content categories."""
    VIOLENCE = "violence"
    SEXUAL_CONTENT = "sexual_content"
    LANGUAGE = "language"
    SUBSTANCE_USE = "substance_use"
    DISTURBING_CONTENT = "disturbing_content"


@dataclass
class ContentFlag:
    """
    Represents a specific content flag within a category.

    Attributes:
        category: Content category (violence, language, etc.)
        severity: Severity level (none, mild, moderate, severe)
        description: Description of the flagged content
        matches: List of matched terms/patterns
        confidence: Confidence score (0.0 to 1.0)
    """
    category: str
    severity: str
    description: str
    matches: List[str]
    confidence: float


@dataclass
class FlaggedScene:
    """
    Domain entity representing a scene that has been scanned by rule-based filters.

    Attributes:
        id: Unique identifier
        scene: Original Scene entity
        script_structure_id: Reference to the script structure
        flags: List of content flags found in the scene
        flagged_categories: Set of categories that were flagged
        scanned_at: Timestamp of rule-based scanning
    """
    id: str
    scene: Scene
    script_structure_id: str
    flags: List[ContentFlag]
    flagged_categories: Set[str]
    scanned_at: datetime = None

    def __post_init__(self):
        """Set default scanning timestamp."""
        if self.scanned_at is None:
            self.scanned_at = datetime.utcnow()

    def has_severe_flags(self) -> bool:
        """Check if scene has any severe flags."""
        return any(flag.severity == Severity.SEVERE for flag in self.flags)

    def get_categories_by_severity(self, severity: str) -> List[str]:
        """Get categories with specific severity level."""
        return [flag.category for flag in self.flags if flag.severity == severity]