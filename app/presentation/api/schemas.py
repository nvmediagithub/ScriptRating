"""
Pydantic models for API request/response DTOs.

This module defines all the data transfer objects used in the ScriptRating API.
"""
from datetime import datetime
from typing import Dict, List, Optional, Union, Any
from pydantic import BaseModel, Field
from enum import Enum


class Severity(str, Enum):
    NONE = "none"
    MILD = "mild"
    MODERATE = "moderate"
    SEVERE = "severe"


class Category(str, Enum):
    VIOLENCE = "violence"
    SEXUAL_CONTENT = "sexual_content"
    LANGUAGE = "language"
    ALCOHOL_DRUGS = "alcohol_drugs"
    DISTURBING_SCENES = "disturbing_scenes"


class AgeRating(str, Enum):
    ZERO_PLUS = "0+"
    SIX_PLUS = "6+"
    TWELVE_PLUS = "12+"
    SIXTEEN_PLUS = "16+"
    EIGHTEEN_PLUS = "18+"


# Document Upload DTOs
class DocumentUploadRequest(BaseModel):
    """Request model for document upload."""
    filename: str = Field(..., description="Name of the uploaded file")
    content_type: str = Field(..., description="MIME type of the file")
    file_size: int = Field(..., description="Size of the file in bytes")


class DocumentUploadResponse(BaseModel):
    """Response model for successful document upload."""
    document_id: str = Field(..., description="Unique identifier for the uploaded document")
    filename: str = Field(..., description="Name of the uploaded file")
    uploaded_at: datetime = Field(..., description="Timestamp of upload")
    status: str = Field(default="uploaded", description="Upload status")


# Script Analysis DTOs
class AnalysisOptions(BaseModel):
    """Options for script analysis."""
    target_rating: Optional[AgeRating] = Field(None, description="Target age rating for analysis")
    include_recommendations: bool = Field(True, description="Include recommendations in response")
    detailed_scenes: bool = Field(False, description="Include detailed scene breakdown")


class ScriptAnalysisRequest(BaseModel):
    """Request model for script analysis."""
    document_id: str = Field(..., description="ID of the uploaded document")
    options: AnalysisOptions = Field(default_factory=AnalysisOptions, description="Analysis options")


class SceneAssessment(BaseModel):
    """Assessment details for a single scene."""
    scene_number: int = Field(..., description="Scene number in the script")
    heading: str = Field(..., description="Scene heading")
    page_range: str = Field(..., description="Page range for the scene")
    categories: Dict[Category, Severity] = Field(..., description="Severity ratings by category")
    flagged_content: List[str] = Field(default_factory=list, description="List of flagged content items")
    justification: Optional[str] = Field(None, description="Explanation for the rating")


class RatingResult(BaseModel):
    """Overall rating result."""
    final_rating: AgeRating = Field(..., description="Calculated age rating")
    confidence_score: float = Field(..., description="Confidence score (0-1)")
    problem_scenes_count: int = Field(..., description="Number of scenes with issues")
    categories_summary: Dict[Category, Severity] = Field(..., description="Summary of highest severity per category")


class ScriptAnalysisResponse(BaseModel):
    """Response model for script analysis."""
    analysis_id: str = Field(..., description="Unique identifier for the analysis")
    document_id: str = Field(..., description="ID of the analyzed document")
    status: str = Field(..., description="Analysis status")
    rating_result: RatingResult = Field(..., description="Overall rating result")
    scene_assessments: List[SceneAssessment] = Field(..., description="Detailed scene assessments")
    created_at: datetime = Field(..., description="Analysis timestamp")
    recommendations: Optional[List[str]] = Field(None, description="Improvement recommendations")


class AnalysisStatusResponse(BaseModel):
    """Response model for analysis status check."""
    analysis_id: str = Field(..., description="Analysis ID")
    status: str = Field(..., description="Current status (pending/processing/completed/failed)")
    progress: Optional[float] = Field(None, description="Progress percentage (0-100)")
    estimated_time_remaining: Optional[int] = Field(None, description="Estimated seconds remaining")


# Report Generation DTOs
class ReportFormat(str, Enum):
    JSON = "json"
    PDF = "pdf"
    DOCX = "docx"


class ReportGenerationRequest(BaseModel):
    """Request model for report generation."""
    analysis_id: str = Field(..., description="ID of the completed analysis")
    format: ReportFormat = Field(..., description="Desired report format")
    include_citations: bool = Field(True, description="Include legal citations")
    include_timeline: bool = Field(True, description="Include scene timeline")


class ReportGenerationResponse(BaseModel):
    """Response model for report generation."""
    report_id: str = Field(..., description="Unique identifier for the report")
    analysis_id: str = Field(..., description="ID of the source analysis")
    format: ReportFormat = Field(..., description="Report format")
    download_url: str = Field(..., description="URL to download the report")
    generated_at: datetime = Field(..., description="Generation timestamp")


# Feedback Processing DTOs
class FeedbackType(str, Enum):
    FALSE_POSITIVE = "false_positive"
    FALSE_NEGATIVE = "false_negative"
    ADJUST_SEVERITY = "adjust_severity"


class FeedbackItem(BaseModel):
    """Individual feedback item."""
    scene_number: int = Field(..., description="Scene number")
    category: Category = Field(..., description="Content category")
    feedback_type: FeedbackType = Field(..., description="Type of feedback")
    comment: Optional[str] = Field(None, description="User comment")
    corrected_severity: Optional[Severity] = Field(None, description="Corrected severity level")


class FeedbackSubmissionRequest(BaseModel):
    """Request model for feedback submission."""
    analysis_id: str = Field(..., description="ID of the analysis")
    feedback_items: List[FeedbackItem] = Field(..., description="List of feedback items")


class FeedbackSubmissionResponse(BaseModel):
    """Response model for feedback submission."""
    feedback_id: str = Field(..., description="Unique identifier for the feedback")
    analysis_id: str = Field(..., description="ID of the updated analysis")
    updated_rating: RatingResult = Field(..., description="Updated rating after feedback")
    processed_at: datetime = Field(..., description="Feedback processing timestamp")


# History Management DTOs
class AnalysisHistoryItem(BaseModel):
    """Individual analysis history item."""
    analysis_id: str = Field(..., description="Analysis ID")
    document_name: str = Field(..., description="Original document name")
    final_rating: AgeRating = Field(..., description="Final age rating")
    created_at: datetime = Field(..., description="Analysis timestamp")
    has_feedback: bool = Field(..., description="Whether feedback has been provided")
    report_formats: List[ReportFormat] = Field(..., description="Available report formats")


class HistoryQueryRequest(BaseModel):
    """Request model for history queries."""
    limit: int = Field(10, description="Number of items to return")
    offset: int = Field(0, description="Offset for pagination")
    rating_filter: Optional[AgeRating] = Field(None, description="Filter by rating")
    date_from: Optional[datetime] = Field(None, description="Filter from date")
    date_to: Optional[datetime] = Field(None, description="Filter to date")


class HistoryQueryResponse(BaseModel):
    """Response model for history queries."""
    items: List[AnalysisHistoryItem] = Field(..., description="List of history items")
    total_count: int = Field(..., description="Total number of items")
    limit: int = Field(..., description="Requested limit")
    offset: int = Field(..., description="Requested offset")


class AnalysisDeletionRequest(BaseModel):
    """Request model for analysis deletion."""
    analysis_id: str = Field(..., description="ID of the analysis to delete")
    confirm_deletion: bool = Field(..., description="Confirmation flag")


# RAG Operations DTOs
class RAGQueryRequest(BaseModel):
    """Request model for RAG queries."""
    query: str = Field(..., description="Search query")
    category: Optional[Category] = Field(None, description="Filter by category")
    top_k: int = Field(5, description="Number of results to return")


class CitationSource(BaseModel):
    """Source information for citations."""
    source_id: str = Field(..., description="Unique source identifier")
    title: str = Field(..., description="Source title")
    section: Optional[str] = Field(None, description="Section reference")
    page: Optional[int] = Field(None, description="Page number")


class RAGResult(BaseModel):
    """Individual RAG query result."""
    content: str = Field(..., description="Relevant content excerpt")
    relevance_score: float = Field(..., description="Relevance score")
    source: CitationSource = Field(..., description="Citation source")
    category: Optional[Category] = Field(None, description="Content category")


class RAGQueryResponse(BaseModel):
    """Response model for RAG queries."""
    query: str = Field(..., description="Original query")
    results: List[RAGResult] = Field(..., description="Retrieved results")
    total_found: int = Field(..., description="Total relevant documents found")


class CorpusUpdateRequest(BaseModel):
    """Request model for corpus updates."""
    content: str = Field(..., description="New content to add")
    category: Category = Field(..., description="Content category")
    source_title: str = Field(..., description="Source title")
    source_metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")


class CorpusUpdateResponse(BaseModel):
    """Response model for corpus updates."""
    update_id: str = Field(..., description="Unique identifier for the update")
    content_hash: str = Field(..., description="Hash of the added content")
    updated_at: datetime = Field(..., description="Update timestamp")


# Error Response DTOs
class ErrorDetail(BaseModel):
    """Detailed error information."""
    code: str = Field(..., description="Error code")
    message: str = Field(..., description="Error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional error details")


class ErrorResponse(BaseModel):
    """Standard error response."""
    error: ErrorDetail = Field(..., description="Error details")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Error timestamp")