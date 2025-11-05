"""
Justification Builder Repository interface.

This module defines the interface for report generation and justification operations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional

from ..entities.rating_result import RatingResult
from ..entities.script_structure import ScriptStructure
from ..entities.analysis_report import AnalysisReport


class JustificationBuilderRepository(ABC):
    """
    Abstract repository for report generation and justification operations.

    This interface defines the contract for building analysis reports
    with justifications, recommendations, and structured explanations.
    """

    @abstractmethod
    async def build_report(
        self,
        rating_result: RatingResult,
        script_structure: ScriptStructure,
        include_rag_citations: bool = True
    ) -> AnalysisReport:
        """
        Build a complete analysis report from rating result and script structure.

        Args:
            rating_result: RatingResult entity
            script_structure: ScriptStructure entity
            include_rag_citations: Whether to include RAG-based citations

        Returns:
            AnalysisReport: Complete analysis report with justifications

        Raises:
            ReportGenerationError: If report building fails
        """
        pass

    @abstractmethod
    def get_report_templates(self) -> dict[str, dict]:
        """
        Get available report templates and their configurations.

        Returns:
            dict[str, dict]: Template configurations
        """
        pass

    @abstractmethod
    def update_template(self, template_name: str, template_config: dict) -> None:
        """
        Update a report template configuration.

        Args:
            template_name: Name of the template to update
            template_config: New template configuration
        """
        pass

    @abstractmethod
    def validate_report(self, report: AnalysisReport) -> bool:
        """
        Validate that a report meets quality standards.

        Args:
            report: AnalysisReport to validate

        Returns:
            bool: True if valid, False otherwise
        """
        pass

    @abstractmethod
    def get_supported_formats(self) -> List[str]:
        """
        Get list of supported report output formats.

        Returns:
            List[str]: List of formats (JSON, PDF, DOCX, etc.)
        """
        pass

    @abstractmethod
    def export_report(self, report: AnalysisReport, format_type: str) -> bytes:
        """
        Export report to a specific format.

        Args:
            report: AnalysisReport to export
            format_type: Target format

        Returns:
            bytes: Exported report data

        Raises:
            ExportError: If export fails
        """
        pass