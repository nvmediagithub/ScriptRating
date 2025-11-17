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


class DocumentType(str, Enum):
    SCRIPT = "script"
    CRITERIA = "criteria"


# Document Upload DTOs
class DocumentUploadRequest(BaseModel):
    """Request model for document upload."""
    filename: str = Field(..., description="Name of the uploaded file")
    content_type: str = Field(..., description="MIME type of the file")
    file_size: int = Field(..., description="Size of the file in bytes")


class RAGProcessingDetails(BaseModel):
    """Detailed RAG processing information for criteria documents."""
    total_chunks: int = Field(..., description="Total number of text chunks created")
    chunks_processed: int = Field(..., description="Number of chunks successfully processed")
    embedding_generation_status: str = Field(..., description="Status of embedding generation (success/failed/partial)")
    embedding_model_used: Optional[str] = Field(None, description="Embedding model name used")
    vector_db_indexing_status: str = Field(..., description="Status of vector database indexing (success/failed/partial)")
    documents_indexed: int = Field(..., description="Number of documents indexed in vector database")
    indexing_time_ms: Optional[float] = Field(None, description="Time taken for indexing in milliseconds")
    processing_errors: Optional[List[str]] = Field(None, description="Any processing errors encountered")


class DocumentUploadResponse(BaseModel):
    """Response model for successful document upload."""
    document_id: str = Field(..., description="Unique identifier for the uploaded document")
    filename: str = Field(..., description="Name of the uploaded file")
    uploaded_at: datetime = Field(..., description="Timestamp of upload")
    document_type: DocumentType = Field(..., description="Type of uploaded document (script or criteria)")
    chunks_indexed: Optional[int] = Field(None, description="Number of knowledge chunks indexed for criteria documents")
    rag_processing_details: Optional[RAGProcessingDetails] = Field(None, description="Detailed RAG processing information for criteria documents")
    status: str = Field(default="uploaded", description="Upload status")


class DocumentProcessingStatus(BaseModel):
    """Response model for document processing status and details."""
    document_id: str = Field(..., description="Unique identifier for the document")
    filename: str = Field(..., description="Name of the uploaded file")
    document_type: DocumentType = Field(..., description="Type of document (script or criteria)")
    status: str = Field(..., description="Processing status (uploaded/indexing/completed/failed)")
    uploaded_at: datetime = Field(..., description="Timestamp of upload")
    processing_started_at: Optional[datetime] = Field(None, description="Timestamp when processing started")
    processing_completed_at: Optional[datetime] = Field(None, description="Timestamp when processing completed")
    rag_processing_details: Optional[RAGProcessingDetails] = Field(None, description="Detailed RAG processing information for criteria documents")
    error_message: Optional[str] = Field(None, description="Error message if processing failed")


class NormativeReference(BaseModel):
    """Reference to a normative document fragment used for justification."""
    document_id: str = Field(..., description="Identifier of the source document")
    title: str = Field(..., description="Source document title")
    page: int = Field(..., description="Referenced page number")
    paragraph: int = Field(..., description="Referenced paragraph number")
    excerpt: str = Field(..., description="Excerpt of the normative text")
    score: float = Field(..., description="Relevance score (0-1)")


# Script Analysis DTOs
class AnalysisOptions(BaseModel):
    """Options for script analysis."""
    target_rating: Optional[AgeRating] = Field(None, description="Target age rating for analysis")
    include_recommendations: bool = Field(True, description="Include recommendations in response")
    detailed_scenes: bool = Field(False, description="Include detailed scene breakdown")


class ScriptAnalysisRequest(BaseModel):
    """Request model for script analysis."""
    document_id: str = Field(..., description="ID of the uploaded document")
    criteria_document_id: Optional[str] = Field(None, description="ID of the criteria document for references")
    options: AnalysisOptions = Field(default_factory=AnalysisOptions, description="Analysis options")

class HighlightFragment(BaseModel):
    """Highlighted fragment inside the analyzed text."""
    start: int = Field(..., description="Start index within block text")
    end: int = Field(..., description="End index within block text")
    text: str = Field(..., description="Text fragment that triggered the rating")
    category: Category = Field(..., description="Category responsible for the highlight")
    severity: Severity = Field(..., description="Severity level for this fragment")


class SceneAssessment(BaseModel):
    """Assessment details for a single scene."""
    scene_number: int = Field(..., description="Scene number in the script")
    heading: str = Field(..., description="Scene heading")
    page_range: str = Field(..., description="Page range for the scene")
    categories: Dict[Category, Severity] = Field(..., description="Severity ratings by category")
    flagged_content: List[str] = Field(default_factory=list, description="List of flagged content items")
    justification: Optional[str] = Field(None, description="Explanation for the rating")
    age_rating: AgeRating = Field(..., description="Calculated age rating for the block")
    llm_comment: str = Field(..., description="Generated explanation from LLM")
    references: List[NormativeReference] = Field(default_factory=list, description="Normative references used")
    text: str = Field(..., description="Full text of the semantic block")
    text_preview: Optional[str] = Field(None, description="Short preview of the analyzed block text")
    highlights: List[HighlightFragment] = Field(default_factory=list, description="Highlighted fragments contributing to rating")


class RatingResult(BaseModel):
    """Overall rating result."""
    final_rating: AgeRating = Field(..., description="Calculated age rating")
    target_rating: Optional[AgeRating] = Field(None, description="Target rating used for comparison")
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
    processed_blocks: Optional[List[SceneAssessment]] = Field(None, description="Blocks processed so far")
    rating_result: Optional[RatingResult] = Field(None, description="Intermediate or final rating result")
    recommendations: Optional[List[str]] = Field(None, description="Recommendations when available")
    errors: Optional[str] = Field(None, description="Error details if analysis failed")


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


# LLM Configuration DTOs
class LLMProvider(str, Enum):
    """LLM provider types."""
    LOCAL = "local"
    OPENROUTER = "openrouter"


class LLMProviderSettings(BaseModel):
    """Settings for LLM providers."""
    provider: LLMProvider = Field(..., description="LLM provider type")
    api_key: Optional[str] = Field(None, description="API key for external providers")
    base_url: Optional[str] = Field(None, description="Base URL for local LLM server")
    timeout: int = Field(30, description="Request timeout in seconds")
    max_retries: int = Field(3, description="Maximum retry attempts")


class LLMModelConfig(BaseModel):
    """Configuration for LLM models."""
    model_name: str = Field(..., description="Name of the LLM model")
    provider: LLMProvider = Field(..., description="Provider for this model")
    context_window: int = Field(4096, description="Maximum context window size")
    max_tokens: int = Field(2048, description="Maximum output tokens")
    temperature: float = Field(0.7, description="Sampling temperature")
    top_p: float = Field(0.9, description="Top-p sampling parameter")
    frequency_penalty: float = Field(0.0, description="Frequency penalty")
    presence_penalty: float = Field(0.0, description="Presence penalty")


class LLMStatusResponse(BaseModel):
    """Response model for LLM status checks."""
    provider: LLMProvider = Field(..., description="LLM provider")
    available: bool = Field(..., description="Whether the provider is available")
    healthy: bool = Field(..., description="Health status indicator")
    response_time_ms: Optional[float] = Field(None, description="Response time in milliseconds")
    error_message: Optional[str] = Field(None, description="Error message if unhealthy")
    last_checked_at: datetime = Field(..., description="Last health check timestamp")


class LLMConfigResponse(BaseModel):
    """Response model for LLM configuration retrieval."""
    active_provider: LLMProvider = Field(..., description="Currently active provider")
    active_model: str = Field(..., description="Currently active model name")
    providers: Dict[LLMProvider, LLMProviderSettings] = Field(..., description="All configured providers")
    models: Dict[str, LLMModelConfig] = Field(..., description="All configured models")


class LLMConfigUpdateRequest(BaseModel):
    """Request model for updating LLM configuration."""
    provider: Optional[LLMProvider] = Field(None, description="Provider to update")
    model_name: Optional[str] = Field(None, description="Model to switch to")
    settings: Optional[LLMProviderSettings] = Field(None, description="Updated provider settings")
    llm_model_config: Optional[LLMModelConfig] = Field(None, description="Updated model configuration")


class LLMTestRequest(BaseModel):
    """Request model for LLM testing."""
    prompt: str = Field(..., description="Test prompt to send to LLM")
    model_name: Optional[str] = Field(None, description="Specific model to test (default: active)")
    max_tokens: int = Field(100, description="Maximum tokens in response")


class LLMTestResponse(BaseModel):
    """Response model for LLM testing."""
    model_name: str = Field(..., description="Model that was tested")
    provider: LLMProvider = Field(..., description="Provider used for testing")
    prompt: str = Field(..., description="Original test prompt")
    response: str = Field(..., description="LLM response")
    tokens_used: int = Field(..., description="Number of tokens consumed")
    response_time_ms: float = Field(..., description="Response time in milliseconds")
    success: bool = Field(..., description="Whether the test was successful")


class LLMProvidersListResponse(BaseModel):
    """Response model for listing available LLM providers."""
    providers: List[LLMProvider] = Field(..., description="List of available providers")
    active_provider: LLMProvider = Field(..., description="Currently active provider")


class LLMModelsListResponse(BaseModel):
    """Response model for listing available LLM models."""
    models: List[str] = Field(..., description="List of available model names")
    active_model: str = Field(..., description="Currently active model")
    models_by_provider: Dict[LLMProvider, List[str]] = Field(..., description="Models grouped by provider")


# Additional LLM Management DTOs
class LocalModelInfo(BaseModel):
    """Information about a local model."""
    model_name: str = Field(..., description="Name of the model")
    size_gb: float = Field(..., description="Model size in GB")
    loaded: bool = Field(..., description="Whether the model is currently loaded")
    context_window: int = Field(..., description="Maximum context window")
    max_tokens: int = Field(..., description="Maximum output tokens")
    last_used: Optional[datetime] = Field(None, description="Last usage timestamp")


class LoadModelRequest(BaseModel):
    """Request to load a local model."""
    model_name: str = Field(..., description="Name of the model to load")


class UnloadModelRequest(BaseModel):
    """Request to unload a local model."""
    model_name: str = Field(..., description="Name of the model to unload")


class LocalModelsListResponse(BaseModel):
    """Response for listing available local models."""
    models: List[LocalModelInfo] = Field(..., description="List of local models with info")
    loaded_models: List[str] = Field(..., description="Names of currently loaded models")


class OpenRouterModelsListResponse(BaseModel):
    """Response for listing OpenRouter models."""
    models: List[str] = Field(..., description="List of available models")
    total: int = Field(..., description="Total number of models")


class OpenRouterCallRequest(BaseModel):
    """Request for making an OpenRouter API call."""
    model: str = Field(..., description="Model to use for the call")
    prompt: str = Field(..., description="Input prompt")
    max_tokens: int = Field(100, description="Maximum tokens in response")
    temperature: float = Field(0.7, description="Sampling temperature")


class OpenRouterCallResponse(BaseModel):
    """Response from OpenRouter API call."""
    model: str = Field(..., description="Model used")
    response: str = Field(..., description="Generated response")
    tokens_used: int = Field(..., description="Tokens consumed")
    cost: float = Field(..., description="Estimated cost in USD")
    response_time_ms: float = Field(..., description="Response time")


class OpenRouterStatusResponse(BaseModel):
    """Status of OpenRouter API connectivity."""
    connected: bool = Field(..., description="Whether API is reachable")
    credits_remaining: Optional[float] = Field(None, description="Remaining credits")
    rate_limit_remaining: Optional[int] = Field(None, description="Rate limit remaining")
    error_message: Optional[str] = Field(None, description="Error if any")


class PerformanceMetrics(BaseModel):
    """Performance metrics for LLM operations."""
    total_requests: int = Field(..., description="Total number of requests")
    successful_requests: int = Field(..., description="Number of successful requests")
    failed_requests: int = Field(..., description="Number of failed requests")
    average_response_time_ms: float = Field(..., description="Average response time")
    total_tokens_used: int = Field(..., description="Total tokens consumed")
    error_rate: float = Field(..., description="Error rate percentage")
    uptime_percentage: float = Field(..., description="Uptime percentage")


class PerformanceReportResponse(BaseModel):
    """Performance monitoring report."""
    provider: LLMProvider = Field(..., description="Provider metrics")
    metrics: PerformanceMetrics = Field(..., description="Performance metrics")
    time_range: str = Field(..., description="Time range for the report")
    generated_at: datetime = Field(default_factory=datetime.utcnow, description="Report generation time")
