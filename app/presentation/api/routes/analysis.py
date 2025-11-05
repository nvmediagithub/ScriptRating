"""
Script analysis API routes.

This module provides endpoints for script analysis and rating calculation.
"""
import uuid
from datetime import datetime
from typing import Dict, Optional
import random
from fastapi import APIRouter, BackgroundTasks, HTTPException
from fastapi.responses import JSONResponse

from app.presentation.api.schemas import (
    ScriptAnalysisRequest,
    ScriptAnalysisResponse,
    AnalysisStatusResponse,
    RatingResult,
    SceneAssessment,
    Category,
    Severity,
    AgeRating,
    ErrorResponse,
    ErrorDetail
)

router = APIRouter()


# Mock storage for analyses
_mock_analyses = {}


def _generate_mock_rating_result() -> RatingResult:
    """Generate a mock rating result with realistic data."""
    # Randomly select final rating
    ratings = [AgeRating.ZERO_PLUS, AgeRating.SIX_PLUS, AgeRating.TWELVE_PLUS, AgeRating.SIXTEEN_PLUS, AgeRating.EIGHTEEN_PLUS]
    final_rating = random.choice(ratings)

    # Generate category summaries based on rating
    categories = {}
    severity_levels = [Severity.NONE, Severity.MILD, Severity.MODERATE, Severity.SEVERE]

    for category in Category:
        if final_rating == AgeRating.EIGHTEEN_PLUS and random.random() > 0.3:
            categories[category] = random.choice([Severity.SEVERE, Severity.MODERATE])
        elif final_rating in [AgeRating.SIXTEEN_PLUS, AgeRating.TWELVE_PLUS] and random.random() > 0.5:
            categories[category] = random.choice([Severity.MODERATE, Severity.MILD])
        else:
            categories[category] = random.choice([Severity.NONE, Severity.MILD])

    return RatingResult(
        final_rating=final_rating,
        confidence_score=round(random.uniform(0.7, 0.95), 2),
        problem_scenes_count=random.randint(0, 8),
        categories_summary=categories
    )


def _generate_mock_scene_assessments(count: int = 5) -> list[SceneAssessment]:
    """Generate mock scene assessments."""
    assessments = []
    for i in range(1, count + 1):
        categories = {}
        flagged_content = []

        for category in Category:
            severity = random.choice(list(Severity))
            categories[category] = severity
            if severity != Severity.NONE:
                flagged_content.append(f"Sample {category.value} content")

        assessments.append(SceneAssessment(
            scene_number=i,
            heading=f"INT/EXT. LOCATION {i} - DAY",
            page_range=f"{i*2-1}-{i*2}",
            categories=categories,
            flagged_content=flagged_content,
            justification=f"Scene {i} assessment completed with {len(flagged_content)} flagged items."
        ))

    return assessments


@router.post(
    "/analyze",
    response_model=ScriptAnalysisResponse,
    summary="Start script analysis",
    description="Initiate analysis of an uploaded script document."
)
async def start_analysis(
    request: ScriptAnalysisRequest,
    background_tasks: BackgroundTasks
) -> ScriptAnalysisResponse:
    """
    Start script analysis.

    This endpoint initiates the analysis process for an uploaded document.
    In a real implementation, this would be an asynchronous background task.

    Args:
        request: Analysis request with document ID and options

    Returns:
        Analysis response with ID and initial status
    """
    # Validate document exists (mock check)
    if request.document_id not in ["mock-doc-1", "mock-doc-2"]:  # Mock validation
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Document with ID {request.document_id} not found"
            ).dict()
        )

    # Generate mock analysis
    analysis_id = str(uuid.uuid4())
    rating_result = _generate_mock_rating_result()
    scene_assessments = _generate_mock_scene_assessments(random.randint(3, 8))

    recommendations = []
    if rating_result.problem_scenes_count > 0:
        recommendations = [
            "Consider reducing violent content to achieve target rating",
            "Review language usage in scenes 3 and 5",
            "Evaluate sexual content context and necessity"
        ]

    # Store mock analysis
    _mock_analyses[analysis_id] = {
        "analysis_id": analysis_id,
        "document_id": request.document_id,
        "status": "completed",  # Mock immediate completion
        "rating_result": rating_result,
        "scene_assessments": scene_assessments,
        "created_at": datetime.utcnow(),
        "options": request.options.dict(),
        "recommendations": recommendations
    }

    return ScriptAnalysisResponse(
        analysis_id=analysis_id,
        document_id=request.document_id,
        status="completed",
        rating_result=rating_result,
        scene_assessments=scene_assessments,
        created_at=_mock_analyses[analysis_id]["created_at"],
        recommendations=recommendations
    )


@router.get(
    "/status/{analysis_id}",
    response_model=AnalysisStatusResponse,
    summary="Get analysis status",
    description="Check the status and progress of a script analysis."
)
async def get_analysis_status(analysis_id: str) -> AnalysisStatusResponse:
    """
    Get the status of an analysis.

    Args:
        analysis_id: Unique analysis identifier

    Returns:
        Analysis status information
    """
    if analysis_id not in _mock_analyses:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found"
            ).dict()
        )

    analysis = _mock_analyses[analysis_id]
    return AnalysisStatusResponse(
        analysis_id=analysis_id,
        status=analysis["status"],
        progress=100.0 if analysis["status"] == "completed" else random.uniform(0, 99),
        estimated_time_remaining=random.randint(0, 300) if analysis["status"] != "completed" else None
    )


@router.get(
    "/{analysis_id}",
    response_model=ScriptAnalysisResponse,
    summary="Get analysis results",
    description="Retrieve the complete results of a script analysis."
)
async def get_analysis_results(analysis_id: str) -> ScriptAnalysisResponse:
    """
    Get analysis results.

    Args:
        analysis_id: Unique analysis identifier

    Returns:
        Complete analysis results
    """
    if analysis_id not in _mock_analyses:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found"
            ).dict()
        )

    analysis = _mock_analyses[analysis_id]
    return ScriptAnalysisResponse(
        analysis_id=analysis["analysis_id"],
        document_id=analysis["document_id"],
        status=analysis["status"],
        rating_result=analysis["rating_result"],
        scene_assessments=analysis["scene_assessments"],
        created_at=analysis["created_at"],
        recommendations=analysis["recommendations"]
    )


@router.post(
    "/{analysis_id}/cancel",
    summary="Cancel analysis",
    description="Cancel a running analysis task."
)
async def cancel_analysis(analysis_id: str):
    """
    Cancel an ongoing analysis.

    Args:
        analysis_id: Unique analysis identifier

    Returns:
        Cancellation confirmation
    """
    if analysis_id not in _mock_analyses:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found"
            ).dict()
        )

    analysis = _mock_analyses[analysis_id]
    if analysis["status"] == "completed":
        raise HTTPException(
            status_code=400,
            detail=ErrorDetail(
                code="ANALYSIS_ALREADY_COMPLETED",
                message="Cannot cancel a completed analysis"
            ).dict()
        )

    # Mark as cancelled
    analysis["status"] = "cancelled"

    return JSONResponse(
        content={"message": "Analysis cancelled successfully", "analysis_id": analysis_id},
        status_code=200
    )