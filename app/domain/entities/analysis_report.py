"""
AnalysisReport domain entity.

This module defines the AnalysisReport entity representing the final analysis report.
"""
from dataclasses import dataclass
from typing import List, Dict, Optional
from datetime import datetime

from .rating_result import RatingResult
from .script_structure import ScriptStructure


@dataclass
class JustificationItem:
    """
    Individual justification item in the report.

    Attributes:
        category: Content category
        severity: Severity level
        description: Human-readable description
        scene_references: List of scene numbers
        legal_references: List of legal document references
        recommendations: Suggested fixes or considerations
    """
    category: str
    severity: str
    description: str
    scene_references: List[int]
    legal_references: List[str]
    recommendations: List[str]


@dataclass
class ReportSection:
    """
    Section of the analysis report.

    Attributes:
        title: Section title
        content: Section content (text or structured data)
        justifications: List of justification items in this section
    """
    title: str
    content: str
    justifications: List[JustificationItem]


@dataclass
class AnalysisReport:
    """
    Domain entity representing the complete analysis report.

    Attributes:
        id: Unique identifier
        rating_result_id: Reference to the rating result
        script_structure_id: Reference to the script structure
        title: Report title
        summary: Executive summary
        sections: List of report sections
        recommendations: Overall recommendations
        metadata: Report metadata (format, version, etc.)
        generated_at: Timestamp of report generation
    """
    id: str
    rating_result_id: str
    script_structure_id: str
    title: str
    summary: str
    sections: List[ReportSection]
    recommendations: List[str]
    metadata: Dict[str, str]
    generated_at: datetime = None

    def __post_init__(self):
        """Set default generation timestamp."""
        if self.generated_at is None:
            self.generated_at = datetime.utcnow()

    def get_section_by_title(self, title: str) -> Optional[ReportSection]:
        """Get a section by its title."""
        return next((section for section in self.sections if section.title == title), None)

    def get_all_justifications(self) -> List[JustificationItem]:
        """Get all justifications across all sections."""
        return [justification for section in self.sections for justification in section.justifications]

    def get_categories_covered(self) -> List[str]:
        """Get list of all categories mentioned in the report."""
        categories = set()
        for justification in self.get_all_justifications():
            categories.add(justification.category)
        return sorted(list(categories))