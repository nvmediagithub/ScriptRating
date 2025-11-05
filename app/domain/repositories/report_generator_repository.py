"""
Report Generator Repository interface.

This module defines the interface for report generation and export operations.
"""
from abc import ABC, abstractmethod
from typing import List

from ..entities.analysis_report import AnalysisReport
from ..entities.generated_report import GeneratedReport


class ReportGeneratorRepository(ABC):
    """
    Abstract repository for report generation and export operations.

    This interface defines the contract for converting analysis reports
    into various output formats (PDF, DOCX, JSON, etc.).
    """

    @abstractmethod
    async def generate_report(
        self,
        analysis_report: AnalysisReport,
        format_type: str
    ) -> GeneratedReport:
        """
        Generate a report in the specified format.

        Args:
            analysis_report: AnalysisReport to generate from
            format_type: Target format (pdf, docx, json, html)

        Returns:
            GeneratedReport: Generated report with file information

        Raises:
            ReportGenerationError: If generation fails
        """
        pass

    @abstractmethod
    def get_supported_formats(self) -> List[str]:
        """
        Get list of supported output formats.

        Returns:
            List[str]: List of supported formats
        """
        pass

    @abstractmethod
    def validate_format(self, format_type: str) -> bool:
        """
        Validate that a format is supported.

        Args:
            format_type: Format to validate

        Returns:
            bool: True if supported, False otherwise
        """
        pass

    @abstractmethod
    def get_template_for_format(self, format_type: str) -> dict:
        """
        Get the template configuration for a specific format.

        Args:
            format_type: Format to get template for

        Returns:
            dict: Template configuration
        """
        pass

    @abstractmethod
    def update_template(self, format_type: str, template: dict) -> None:
        """
        Update the template for a specific format.

        Args:
            format_type: Format to update template for
            template: New template configuration
        """
        pass

    @abstractmethod
    def preview_report(self, analysis_report: AnalysisReport, format_type: str) -> bytes:
        """
        Generate a preview of the report without saving to file.

        Args:
            analysis_report: AnalysisReport to preview
            format_type: Format for preview

        Returns:
            bytes: Preview data

        Raises:
            PreviewError: If preview generation fails
        """
        pass