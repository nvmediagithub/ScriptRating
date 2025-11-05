"""
SceneAssessment domain entity.

This module defines the SceneAssessment entity representing LLM classification results.
"""
from dataclasses import dataclass
from typing import Dict, List, Optional
from datetime import datetime

from .script_structure import Scene
from .flagged_scene import Severity, Category


@dataclass
class CategoryAssessment:
    """
    Assessment for a specific content category within a scene.

    Attributes:
        category: Content category
        severity: Determined severity level
        confidence: Confidence score (0.0 to 1.0)
        reasoning: Explanation for the assessment
        rag_references: List of RAG document references used
    """
    category: str
    severity: str
    confidence: float
    reasoning: str
    rag_references: List[str]


@dataclass
class SceneAssessment:
    """
    Domain entity representing LLM assessment of a scene.

    Attributes:
        id: Unique identifier
        scene: Original Scene entity
        script_structure_id: Reference to the script structure
        flagged_scene_id: Reference to the flagged scene (if any)
        categories: Dict of category assessments
        overall_severity: Highest severity across all categories
        classification_model: Name/version of the LLM used
        prompt_version: Version of the classification prompt
        rag_context_used: Whether RAG context was used
        classified_at: Timestamp of classification
    """
    id: str
    scene: Scene
    script_structure_id: str
    flagged_scene_id: Optional[str]
    categories: Dict[str, CategoryAssessment]
    overall_severity: str
    classification_model: str
    prompt_version: str
    rag_context_used: bool
    classified_at: datetime = None

    def __post_init__(self):
        """Set default classification timestamp."""
        if self.classified_at is None:
            self.classified_at = datetime.utcnow()

    def get_categories_by_severity(self, severity: str) -> List[str]:
        """Get categories with specific severity level."""
        return [
            category for category, assessment in self.categories.items()
            if assessment.severity == severity
        ]

    def has_severe_content(self) -> bool:
        """Check if scene has any severe content."""
        return self.overall_severity == Severity.SEVERE

    def get_confidence_score(self) -> float:
        """Get average confidence across all categories."""
        if not self.categories:
            return 0.0
        return sum(assessment.confidence for assessment in self.categories.values()) / len(self.categories)