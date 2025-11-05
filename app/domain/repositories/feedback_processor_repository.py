"""
Feedback Processor Repository interface.

This module defines the interface for user feedback processing operations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional

from ..entities.user_feedback import UserFeedback, FeedbackItem
from ..entities.rating_result import RatingResult


class FeedbackProcessorRepository(ABC):
    """
    Abstract repository for user feedback processing operations.

    This interface defines the contract for handling user corrections,
    updating analyses, and incorporating feedback into the system.
    """

    @abstractmethod
    async def process_feedback(
        self,
        feedback: UserFeedback
    ) -> RatingResult:
        """
        Process user feedback and recalculate rating result.

        Args:
            feedback: UserFeedback to process

        Returns:
            RatingResult: Updated rating result after applying feedback

        Raises:
            FeedbackProcessingError: If processing fails
        """
        pass

    @abstractmethod
    async def apply_false_positive_correction(
        self,
        feedback_item: FeedbackItem
    ) -> None:
        """
        Apply false positive correction by ignoring flagged content.

        Args:
            feedback_item: FeedbackItem with false positive correction
        """
        pass

    @abstractmethod
    async def apply_false_negative_addition(
        self,
        feedback_item: FeedbackItem
    ) -> None:
        """
        Apply false negative addition by adding missed content flags.

        Args:
            feedback_item: FeedbackItem with false negative addition
        """
        pass

    @abstractmethod
    def get_feedback_stats(
        self,
        analysis_id: str
    ) -> dict[str, int]:
        """
        Get statistics about feedback for an analysis.

        Args:
            analysis_id: ID of the analysis

        Returns:
            dict[str, int]: Statistics (total_feedback, corrections_applied, etc.)
        """
        pass

    @abstractmethod
    def export_feedback_for_training(
        self,
        analysis_id: Optional[str] = None
    ) -> List[dict]:
        """
        Export feedback data for model training or RAG updates.

        Args:
            analysis_id: Optional specific analysis ID, or all if None

        Returns:
            List[dict]: Feedback data suitable for training
        """
        pass

    @abstractmethod
    def get_pending_feedback_count(self) -> int:
        """
        Get count of unprocessed feedback items.

        Returns:
            int: Number of pending feedback items
        """
        pass

    @abstractmethod
    async def batch_process_feedback(
        self,
        feedback_list: List[UserFeedback]
    ) -> List[RatingResult]:
        """
        Process multiple feedback items in batch.

        Args:
            feedback_list: List of UserFeedback to process

        Returns:
            List[RatingResult]: Updated rating results

        Raises:
            BatchProcessingError: If batch processing fails
        """
        pass