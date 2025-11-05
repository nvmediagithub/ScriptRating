"""
Feedback processing API routes.

This module provides endpoints for handling user feedback on analysis results.
"""
import uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse

from app.presentation.api.schemas import (
    FeedbackSubmissionRequest,
    FeedbackSubmissionResponse,
    FeedbackItem,
    FeedbackType,
    RatingResult,
    Category,
    Severity,
    AgeRating,
    ErrorResponse,
    ErrorDetail
)

router = APIRouter()


# Mock storage for feedback
_mock_feedback = {}


def _recalculate_rating_with_feedback(original_rating: RatingResult, feedback_items: list[FeedbackItem]) -> RatingResult:
    """Mock recalculation of rating based on feedback."""
    # Simple mock logic: adjust rating based on feedback
    new_categories = original_rating.categories_summary.copy()
    problem_scenes_count = original_rating.problem_scenes_count

    for item in feedback_items:
        if item.feedback_type == FeedbackType.FALSE_POSITIVE:
            # Reduce severity for false positives
            if new_categories[item.category] in [Severity.SEVERE, Severity.MODERATE]:
                new_categories[item.category] = Severity.MILD
                problem_scenes_count = max(0, problem_scenes_count - 1)
        elif item.feedback_type == FeedbackType.FALSE_NEGATIVE:
            # Increase severity for false negatives
            if item.corrected_severity:
                new_categories[item.category] = item.corrected_severity
                if item.corrected_severity != Severity.NONE:
                    problem_scenes_count += 1

    # Recalculate final rating based on new categories
    if any(sev == Severity.SEVERE for sev in new_categories.values()):
        final_rating = AgeRating.EIGHTEEN_PLUS
    elif any(sev == Severity.MODERATE for sev in new_categories.values()):
        final_rating = AgeRating.SIXTEEN_PLUS
    elif any(sev == Severity.MILD for sev in new_categories.values()):
        final_rating = AgeRating.TWELVE_PLUS
    else:
        final_rating = AgeRating.SIX_PLUS

    return RatingResult(
        final_rating=final_rating,
        confidence_score=min(1.0, original_rating.confidence_score + 0.05),  # Slight confidence boost
        problem_scenes_count=problem_scenes_count,
        categories_summary=new_categories
    )


@router.post(
    "/submit",
    response_model=FeedbackSubmissionResponse,
    summary="Submit feedback",
    description="Submit user feedback to correct analysis results."
)
async def submit_feedback(request: FeedbackSubmissionRequest) -> FeedbackSubmissionResponse:
    """
    Submit feedback for an analysis.

    Args:
        request: Feedback submission request with analysis ID and feedback items

    Returns:
        Feedback submission response with updated rating
    """
    # Validate analysis exists (mock check)
    if request.analysis_id not in ["mock-analysis-1", "mock-analysis-2", "mock-analysis-3"]:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {request.analysis_id} not found"
            ).dict()
        )

    # Generate mock original rating for recalculation
    original_rating = RatingResult(
        final_rating=AgeRating.TWELVE_PLUS,
        confidence_score=0.85,
        problem_scenes_count=3,
        categories_summary={
            Category.VIOLENCE: Severity.MODERATE,
            Category.SEXUAL_CONTENT: Severity.NONE,
            Category.LANGUAGE: Severity.MILD,
            Category.ALCOHOL_DRUGS: Severity.NONE,
            Category.DISTURBING_SCENES: Severity.MILD
        }
    )

    # Recalculate rating with feedback
    updated_rating = _recalculate_rating_with_feedback(original_rating, request.feedback_items)

    # Store feedback
    feedback_id = str(uuid.uuid4())
    _mock_feedback[feedback_id] = {
        "feedback_id": feedback_id,
        "analysis_id": request.analysis_id,
        "feedback_items": [item.dict() for item in request.feedback_items],
        "original_rating": original_rating,
        "updated_rating": updated_rating,
        "processed_at": datetime.utcnow()
    }

    return FeedbackSubmissionResponse(
        feedback_id=feedback_id,
        analysis_id=request.analysis_id,
        updated_rating=updated_rating,
        processed_at=_mock_feedback[feedback_id]["processed_at"]
    )


@router.get(
    "/{feedback_id}",
    summary="Get feedback details",
    description="Retrieve details of submitted feedback."
)
async def get_feedback(feedback_id: str):
    """
    Get feedback details.

    Args:
        feedback_id: Unique feedback identifier

    Returns:
        Feedback details including original and updated ratings
    """
    if feedback_id not in _mock_feedback:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="FEEDBACK_NOT_FOUND",
                message=f"Feedback with ID {feedback_id} not found"
            ).dict()
        )

    feedback = _mock_feedback[feedback_id]
    return {
        "feedback_id": feedback["feedback_id"],
        "analysis_id": feedback["analysis_id"],
        "feedback_items": feedback["feedback_items"],
        "original_rating": feedback["original_rating"].dict(),
        "updated_rating": feedback["updated_rating"].dict(),
        "processed_at": feedback["processed_at"]
    }


@router.get(
    "/analysis/{analysis_id}",
    summary="Get feedback for analysis",
    description="Retrieve all feedback submitted for a specific analysis."
)
async def get_analysis_feedback(analysis_id: str):
    """
    Get all feedback for an analysis.

    Args:
        analysis_id: Unique analysis identifier

    Returns:
        List of feedback for the analysis
    """
    analysis_feedback = []
    for feedback in _mock_feedback.values():
        if feedback["analysis_id"] == analysis_id:
            analysis_feedback.append({
                "feedback_id": feedback["feedback_id"],
                "feedback_items": feedback["feedback_items"],
                "original_rating": feedback["original_rating"].dict(),
                "updated_rating": feedback["updated_rating"].dict(),
                "processed_at": feedback["processed_at"]
            })

    return {
        "analysis_id": analysis_id,
        "feedback_count": len(analysis_feedback),
        "feedback": analysis_feedback
    }


@router.delete(
    "/{feedback_id}",
    summary="Delete feedback",
    description="Delete submitted feedback and revert rating changes."
)
async def delete_feedback(feedback_id: str):
    """
    Delete feedback and revert changes.

    Args:
        feedback_id: Unique feedback identifier

    Returns:
        Deletion confirmation
    """
    if feedback_id not in _mock_feedback:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="FEEDBACK_NOT_FOUND",
                message=f"Feedback with ID {feedback_id} not found"
            ).dict()
        )

    # Remove from mock storage
    del _mock_feedback[feedback_id]

    return JSONResponse(
        content={"message": "Feedback deleted successfully", "feedback_id": feedback_id},
        status_code=200
    )


@router.get(
    "/",
    summary="List all feedback",
    description="Get a list of all submitted feedback."
)
async def list_feedback():
    """
    List all feedback.

    Returns:
        List of all feedback entries
    """
    feedback_list = []
    for feedback in _mock_feedback.values():
        feedback_list.append({
            "feedback_id": feedback["feedback_id"],
            "analysis_id": feedback["analysis_id"],
            "feedback_items_count": len(feedback["feedback_items"]),
            "processed_at": feedback["processed_at"]
        })

    return {"feedback": feedback_list, "count": len(feedback_list)}