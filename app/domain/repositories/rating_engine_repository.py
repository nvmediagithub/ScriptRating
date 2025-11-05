"""
Rating Engine Repository interface.

This module defines the interface for age rating calculation operations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional

from ..entities.scene_assessment import SceneAssessment
from ..entities.rating_result import RatingResult


class RatingEngineRepository(ABC):
    """
    Abstract repository for age rating calculation operations.

    This interface defines the contract for calculating final age ratings
    based on scene assessments and FZ-436 compliance rules.
    """

    @abstractmethod
    async def calculate_rating(
        self,
        assessments: List[SceneAssessment],
        target_rating: Optional[str] = None
    ) -> RatingResult:
        """
        Calculate final age rating from scene assessments.

        Args:
            assessments: List of SceneAssessment entities
            target_rating: Optional target rating for compliance check

        Returns:
            RatingResult: Final rating calculation with reasoning

        Raises:
            RatingCalculationError: If calculation fails
        """
        pass

    @abstractmethod
    def get_rating_rules(self) -> dict[str, dict]:
        """
        Get the current rating rules and thresholds.

        Returns:
            dict[str, dict]: Rating rules (severity thresholds, category weights, etc.)
        """
        pass

    @abstractmethod
    def update_rating_rules(self, rules: dict[str, dict]) -> None:
        """
        Update the rating calculation rules.

        Args:
            rules: New rating rules to apply
        """
        pass

    @abstractmethod
    def validate_target_rating(self, target_rating: str) -> bool:
        """
        Validate that a target rating is supported.

        Args:
            target_rating: Rating to validate

        Returns:
            bool: True if supported, False otherwise
        """
        pass

    @abstractmethod
    def get_supported_ratings(self) -> List[str]:
        """
        Get list of supported age rating categories.

        Returns:
            List[str]: List of rating categories (0+, 6+, 12+, 16+, 18+)
        """
        pass

    @abstractmethod
    def get_rating_stats(self, result: RatingResult) -> dict[str, float]:
        """
        Get statistics about the rating calculation.

        Args:
            result: RatingResult to analyze

        Returns:
            dict[str, float]: Statistics (confidence, problem_scene_ratio, etc.)
        """
        pass