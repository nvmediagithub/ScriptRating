"""
History Manager Repository interface.

This module defines the interface for analysis history management operations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional
from datetime import datetime

from ..entities.analysis_history import AnalysisHistory, AnalysisIssue


class HistoryManagerRepository(ABC):
    """
    Abstract repository for analysis history management operations.

    This interface defines the contract for storing, retrieving, and managing
    analysis records, issues, and historical data.
    """

    @abstractmethod
    async def save_analysis(self, analysis: AnalysisHistory) -> str:
        """
        Save a complete analysis record to history.

        Args:
            analysis: AnalysisHistory to save

        Returns:
            str: Analysis ID

        Raises:
            HistorySaveError: If saving fails
        """
        pass

    @abstractmethod
    async def get_analysis(self, analysis_id: str) -> Optional[AnalysisHistory]:
        """
        Retrieve an analysis record by ID.

        Args:
            analysis_id: ID of the analysis to retrieve

        Returns:
            Optional[AnalysisHistory]: Analysis record or None if not found
        """
        pass

    @abstractmethod
    async def list_analyses(
        self,
        limit: int = 50,
        offset: int = 0,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> List[AnalysisHistory]:
        """
        List analysis records with optional filtering.

        Args:
            limit: Maximum number of records to return
            offset: Number of records to skip
            start_date: Filter by creation date (from)
            end_date: Filter by creation date (to)

        Returns:
            List[AnalysisHistory]: List of analysis records
        """
        pass

    @abstractmethod
    async def update_analysis_feedback(
        self,
        analysis_id: str,
        feedback_data: dict
    ) -> None:
        """
        Update analysis record with user feedback.

        Args:
            analysis_id: ID of the analysis to update
            feedback_data: Feedback data to apply

        Raises:
            AnalysisNotFoundError: If analysis doesn't exist
        """
        pass

    @abstractmethod
    async def delete_analysis(self, analysis_id: str) -> None:
        """
        Delete an analysis record and associated data.

        Args:
            analysis_id: ID of the analysis to delete

        Raises:
            AnalysisNotFoundError: If analysis doesn't exist
        """
        pass

    @abstractmethod
    def get_analysis_stats(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> dict[str, int]:
        """
        Get statistics about analyses in the given date range.

        Args:
            start_date: Start date for statistics
            end_date: End date for statistics

        Returns:
            dict[str, int]: Statistics (total_analyses, avg_rating, etc.)
        """
        pass

    @abstractmethod
    def cleanup_old_analyses(self, days_old: int) -> int:
        """
        Remove analyses older than specified days.

        Args:
            days_old: Remove analyses older than this many days

        Returns:
            int: Number of analyses removed
        """
        pass

    @abstractmethod
    async def export_analyses(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        format_type: str = "json"
    ) -> bytes:
        """
        Export analysis data in specified format.

        Args:
            start_date: Start date for export
            end_date: End date for export
            format_type: Export format (json, csv, etc.)

        Returns:
            bytes: Exported data

        Raises:
            ExportError: If export fails
        """
        pass