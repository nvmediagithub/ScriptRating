"""
RatingResult domain entity.

This module defines the RatingResult entity representing final age rating calculation.
"""
from dataclasses import dataclass
from typing import List, Dict, Optional
from datetime import datetime

from .scene_assessment import SceneAssessment

# AgeRating is now imported from app.presentation.api.schemas
# to avoid namespace conflicts

@dataclass
class ProblemScene:
    """
    Represents a scene that contributes to the final rating.

    Attributes:
        scene_number: Scene number in the script
        scene_heading: Scene heading text
        categories: Categories that caused the rating increase
        severity: Highest severity in this scene
        reasoning: Explanation of why this scene affects rating
    """
    scene_number: int
    scene_heading: str
    categories: List[str]
    severity: str
    reasoning: str


@dataclass
class RatingResult:
    """
    Domain entity representing the final age rating calculation.

    Attributes:
        id: Unique identifier
        script_structure_id: Reference to the script structure
        final_rating: Calculated age rating (0+, 6+, 12+, 16+, 18+)
        target_rating: Optional user-specified target rating
        problem_scenes: List of scenes that determine the rating
        category_breakdown: Summary by content categories
        reasoning: Overall explanation for the rating
        confidence_score: Overall confidence in the rating (0.0 to 1.0)
        rated_at: Timestamp of rating calculation
    """
    id: str
    script_structure_id: str
    final_rating: str
    target_rating: Optional[str]
    problem_scenes: List[ProblemScene]
    category_breakdown: Dict[str, Dict[str, int]]  # category -> severity -> count
    reasoning: str
    confidence_score: float
    rated_at: datetime = None

    def __post_init__(self):
        """Set default rating timestamp."""
        if self.rated_at is None:
            self.rated_at = datetime.utcnow()

    def is_target_met(self) -> bool:
        """
        Check if the calculated rating meets or is below the target rating.

        Returns:
            bool: True if rating meets target, False otherwise
        """
        if not self.target_rating:
            return True

        rating_order = ["0+", "6+", "12+", "16+", "18+"]
        try:
            final_idx = rating_order.index(self.final_rating)
            target_idx = rating_order.index(self.target_rating)
            return final_idx <= target_idx
        except ValueError:
            return False

    def get_severity_distribution(self) -> Dict[str, int]:
        """
        Get distribution of severity levels across all problem scenes.

        Returns:
            Dict[str, int]: Severity level counts
        """
        distribution = {}
        for scene in self.problem_scenes:
            distribution[scene.severity] = distribution.get(scene.severity, 0) + 1
        return distribution