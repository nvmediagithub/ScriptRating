"""
GeneratedReport domain entity.

This module defines the GeneratedReport entity representing exported report files.
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime


class ReportFormat:
    """Enumeration of supported report formats."""
    JSON = "json"
    PDF = "pdf"
    DOCX = "docx"
    HTML = "html"


@dataclass
class GeneratedReport:
    """
    Domain entity representing an exported/generated report file.

    Attributes:
        id: Unique identifier
        analysis_report_id: Reference to the analysis report
        format: Export format (json, pdf, docx, html)
        filename: Generated filename
        file_path: Path to the generated file
        file_size: Size of the generated file in bytes
        content_hash: Hash of the file content for integrity checks
        metadata: Additional metadata about the generation
        generated_at: Timestamp of report generation
    """
    id: str
    analysis_report_id: str
    format: str
    filename: str
    file_path: str
    file_size: int
    content_hash: str
    metadata: dict[str, str]
    generated_at: datetime = None

    def __post_init__(self):
        """Set default generation timestamp."""
        if self.generated_at is None:
            self.generated_at = datetime.utcnow()

    def validate_format(self) -> bool:
        """Validate that the format is supported."""
        return self.format in [ReportFormat.JSON, ReportFormat.PDF,
                              ReportFormat.DOCX, ReportFormat.HTML]

    def get_file_extension(self) -> str:
        """Get the file extension for this format."""
        extensions = {
            ReportFormat.JSON: ".json",
            ReportFormat.PDF: ".pdf",
            ReportFormat.DOCX: ".docx",
            ReportFormat.HTML: ".html"
        }
        return extensions.get(self.format, "")