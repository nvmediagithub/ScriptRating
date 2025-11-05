"""
AnalysisHistory domain entity.

This module defines the AnalysisHistory entity representing analysis records and issues.
"""
from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime

from .rating_result import RatingResult
from .user_feedback import UserFeedback


@dataclass
class AnalysisIssue:
    """
    Individual issue found during analysis.

    Attributes:
        id: Unique identifier
        analysis_id: Reference to the analysis
        scene_number: Scene number where issue occurs
        category: Content category (violence, language, etc.)
        severity: Severity level
        description: Description of the issue
        recommendation: Suggested fix or consideration
        source: Source of the issue detection (rule, llm, user)
        resolved: Whether issue has been resolved via feedback
        created_at: Timestamp of issue creation
    """
    id: str
    analysis_id: str
    scene_number: int
    category: str
    severity: str
    description: str
    recommendation: str
    source: str
    resolved: bool = False
    created_at: datetime = None

    def __post_init__(self):
        """Set default creation timestamp."""
        if self.created_at is None:
            self.created_at = datetime.utcnow()

    def mark_resolved(self) -> None:
        """Mark issue as resolved."""
        self.resolved = True


@dataclass
class AnalysisHistory:
    """
    Domain entity representing a complete analysis record.

    Attributes:
        id: Unique identifier
        filename: Original script filename
        file_hash: Hash of the original file for integrity
        final_rating: Calculated final rating
        target_rating: Optional user target rating
        categories_summary: Summary of flagged categories
        report_path: Path to generated report file
        model_profile: LLM/model profile used
        total_scenes: Total number of scenes analyzed
        processing_time: Time taken for analysis in seconds
        issues: List of analysis issues
        feedback: Optional user feedback
        created_at: Timestamp of analysis creation
        updated_at: Timestamp of last update
    """
    id: str
    filename: str
    file_hash: str
    final_rating: str
    target_rating: Optional[str]
    categories_summary: dict[str, int]  # category -> count
    report_path: Optional[str]
    model_profile: str
    total_scenes: int
    processing_time: float
    issues: List[AnalysisIssue]
    feedback: Optional[UserFeedback]
    created_at: datetime = None
    updated_at: datetime = None

    def __post_init__(self):
        """Set default timestamps."""
        if self.created_at is None:
            self.created_at = datetime.utcnow()
        if self.updated_at is None:
            self.updated_at = datetime.utcnow()

    def update_feedback(self, feedback: UserFeedback) -> None:
        """
        Update analysis with user feedback.

        Args:
            feedback: UserFeedback to apply
        """
        self.feedback = feedback
        self.updated_at = datetime.utcnow()

    def get_unresolved_issues(self) -> List[AnalysisIssue]:
        """Get list of unresolved issues."""
        return [issue for issue in self.issues if not issue.resolved]

    def get_issues_by_category(self, category: str) -> List[AnalysisIssue]:
        """Get issues filtered by category."""
        return [issue for issue in self.issues if issue.category == category]

    def mark_issues_resolved(self, scene_numbers: List[int]) -> None:
        """
        Mark issues as resolved for given scene numbers.

        Args:
            scene_numbers: List of scene numbers to resolve
        """
        for issue in self.issues:
            if issue.scene_number in scene_numbers:
                issue.mark_resolved()
        self.updated_at = datetime.utcnow()