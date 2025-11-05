"""
UserFeedback domain entity.

This module defines the UserFeedback entity representing user corrections and feedback.
"""
from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime

from .scene_assessment import SceneAssessment


class FeedbackType:
    """Enumeration of feedback types."""
    FALSE_POSITIVE = "false_positive"
    FALSE_NEGATIVE = "false_negative"
    SEVERITY_CORRECTION = "severity_correction"
    CATEGORY_ADDITION = "category_addition"
    SCENE_EDIT = "scene_edit"
    RATING_OVERRIDE = "rating_override"


@dataclass
class FeedbackItem:
    """
    Individual feedback item from user corrections.

    Attributes:
        id: Unique identifier
        analysis_id: Reference to the analysis
        scene_number: Scene number being corrected
        feedback_type: Type of feedback
        original_assessment: Original SceneAssessment
        user_correction: User's corrected data
        comment: User's comment/explanation
        created_at: Timestamp of feedback creation
    """
    id: str
    analysis_id: str
    scene_number: int
    feedback_type: str
    original_assessment: Optional[SceneAssessment]
    user_correction: dict
    comment: str
    created_at: datetime = None

    def __post_init__(self):
        """Set default creation timestamp."""
        if self.created_at is None:
            self.created_at = datetime.utcnow()

    def is_false_positive(self) -> bool:
        """Check if this is a false positive correction."""
        return self.feedback_type == FeedbackType.FALSE_POSITIVE

    def is_false_negative(self) -> bool:
        """Check if this is a false negative addition."""
        return self.feedback_type == FeedbackType.FALSE_NEGATIVE


@dataclass
class UserFeedback:
    """
    Domain entity representing a collection of user feedback for an analysis.

    Attributes:
        id: Unique identifier
        analysis_id: Reference to the analysis
        feedback_items: List of individual feedback items
        overall_rating_override: Optional user-specified final rating
        processed: Whether feedback has been processed
        created_at: Timestamp of feedback creation
        processed_at: Timestamp when feedback was processed
    """
    id: str
    analysis_id: str
    feedback_items: List[FeedbackItem]
    overall_rating_override: Optional[str]
    processed: bool = False
    created_at: datetime = None
    processed_at: Optional[datetime] = None

    def __post_init__(self):
        """Set default creation timestamp."""
        if self.created_at is None:
            self.created_at = datetime.utcnow()

    def has_rating_override(self) -> bool:
        """Check if user provided rating override."""
        return self.overall_rating_override is not None

    def get_false_positives(self) -> List[FeedbackItem]:
        """Get all false positive corrections."""
        return [item for item in self.feedback_items if item.is_false_positive()]

    def get_false_negatives(self) -> List[FeedbackItem]:
        """Get all false negative additions."""
        return [item for item in self.feedback_items if item.is_false_negative()]

    def mark_processed(self) -> None:
        """Mark feedback as processed."""
        self.processed = True
        self.processed_at = datetime.utcnow()