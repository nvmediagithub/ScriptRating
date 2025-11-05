"""
History management API routes.

This module provides endpoints for managing analysis history and audit trails.
"""
import uuid
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse

from app.presentation.api.schemas import (
    HistoryQueryRequest,
    HistoryQueryResponse,
    AnalysisHistoryItem,
    AnalysisDeletionRequest,
    AgeRating,
    ReportFormat,
    ErrorResponse,
    ErrorDetail
)

router = APIRouter()


# Mock storage for analysis history
_mock_history = {}


def _generate_mock_history():
    """Generate mock history data for demonstration."""
    if not _mock_history:
        base_date = datetime.utcnow() - timedelta(days=30)
        for i in range(15):
            analysis_id = str(uuid.uuid4())
            created_at = base_date + timedelta(days=i*2, hours=i)

            _mock_history[analysis_id] = {
                "analysis_id": analysis_id,
                "document_name": f"script_{i+1:03d}.pdf",
                "final_rating": random.choice(list(AgeRating)),
                "created_at": created_at,
                "has_feedback": random.choice([True, False]),
                "report_formats": random.sample([ReportFormat.JSON, ReportFormat.PDF, ReportFormat.DOCX], random.randint(0, 3))
            }


import random
_generate_mock_history()


@router.get(
    "/analyses",
    response_model=HistoryQueryResponse,
    summary="Query analysis history",
    description="Query and filter analysis history with pagination."
)
async def query_history(
    limit: int = Query(10, ge=1, le=100, description="Number of items to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    rating_filter: Optional[AgeRating] = Query(None, description="Filter by age rating"),
    date_from: Optional[datetime] = Query(None, description="Filter from date"),
    date_to: Optional[datetime] = Query(None, description="Filter to date")
) -> HistoryQueryResponse:
    """
    Query analysis history with filters and pagination.

    Args:
        limit: Maximum number of items to return
        offset: Number of items to skip
        rating_filter: Filter by age rating
        date_from: Filter analyses created after this date
        date_to: Filter analyses created before this date

    Returns:
        Paginated history query results
    """
    # Apply filters
    filtered_items = []
    for item in _mock_history.values():
        if rating_filter and item["final_rating"] != rating_filter:
            continue
        if date_from and item["created_at"] < date_from:
            continue
        if date_to and item["created_at"] > date_to:
            continue
        filtered_items.append(item)

    # Sort by creation date (newest first)
    filtered_items.sort(key=lambda x: x["created_at"], reverse=True)

    # Apply pagination
    total_count = len(filtered_items)
    paginated_items = filtered_items[offset:offset + limit]

    # Convert to response format
    items = []
    for item in paginated_items:
        items.append(AnalysisHistoryItem(
            analysis_id=item["analysis_id"],
            document_name=item["document_name"],
            final_rating=item["final_rating"],
            created_at=item["created_at"],
            has_feedback=item["has_feedback"],
            report_formats=item["report_formats"]
        ))

    return HistoryQueryResponse(
        items=items,
        total_count=total_count,
        limit=limit,
        offset=offset
    )


@router.get(
    "/analyses/{analysis_id}",
    summary="Get analysis details",
    description="Get detailed information about a specific analysis."
)
async def get_analysis_details(analysis_id: str):
    """
    Get detailed analysis information.

    Args:
        analysis_id: Unique analysis identifier

    Returns:
        Detailed analysis information
    """
    if analysis_id not in _mock_history:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found"
            ).dict()
        )

    item = _mock_history[analysis_id]
    return {
        "analysis_id": item["analysis_id"],
        "document_name": item["document_name"],
        "final_rating": item["final_rating"].value,
        "created_at": item["created_at"],
        "has_feedback": item["has_feedback"],
        "report_formats": [fmt.value for fmt in item["report_formats"]],
        "metadata": {
            "processing_time_seconds": random.randint(30, 300),
            "model_version": "llm-classifier-v1.2.0",
            "scene_count": random.randint(20, 80),
            "word_count": random.randint(15000, 45000)
        }
    }


@router.delete(
    "/analyses/{analysis_id}",
    summary="Delete analysis",
    description="Delete an analysis and all associated data from history."
)
async def delete_analysis(analysis_id: str, confirm_deletion: bool = Query(..., description="Confirmation flag")):
    """
    Delete an analysis from history.

    Args:
        analysis_id: Unique analysis identifier
        confirm_deletion: Confirmation that deletion is intended

    Returns:
        Deletion confirmation
    """
    if not confirm_deletion:
        raise HTTPException(
            status_code=400,
            detail=ErrorDetail(
                code="CONFIRMATION_REQUIRED",
                message="Deletion must be confirmed with confirm_deletion=true"
            ).dict()
        )

    if analysis_id not in _mock_history:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found"
            ).dict()
        )

    # Remove from mock storage
    del _mock_history[analysis_id]

    return JSONResponse(
        content={"message": "Analysis deleted successfully", "analysis_id": analysis_id},
        status_code=200
    )


@router.get(
    "/stats",
    summary="Get history statistics",
    description="Get statistical overview of analysis history."
)
async def get_history_stats():
    """
    Get statistical information about analysis history.

    Returns:
        History statistics
    """
    if not _mock_history:
        return {
            "total_analyses": 0,
            "rating_distribution": {},
            "average_processing_time": 0,
            "most_common_rating": None
        }

    items = list(_mock_history.values())

    # Rating distribution
    rating_counts = {}
    for item in items:
        rating = item["final_rating"].value
        rating_counts[rating] = rating_counts.get(rating, 0) + 1

    most_common_rating = max(rating_counts.items(), key=lambda x: x[1])[0] if rating_counts else None

    return {
        "total_analyses": len(items),
        "rating_distribution": rating_counts,
        "average_processing_time": 120,  # Mock average
        "most_common_rating": most_common_rating,
        "date_range": {
            "earliest": min(item["created_at"] for item in items),
            "latest": max(item["created_at"] for item in items)
        }
    }


@router.post(
    "/cleanup",
    summary="Cleanup old analyses",
    description="Remove analyses older than specified days."
)
async def cleanup_old_analyses(days: int = Query(..., gt=0, description="Remove analyses older than this many days")):
    """
    Clean up old analyses from history.

    Args:
        days: Remove analyses older than this many days

    Returns:
        Cleanup summary
    """
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    deleted_count = 0

    analyses_to_delete = []
    for analysis_id, item in _mock_history.items():
        if item["created_at"] < cutoff_date:
            analyses_to_delete.append(analysis_id)

    for analysis_id in analyses_to_delete:
        del _mock_history[analysis_id]
        deleted_count += 1

    return JSONResponse(
        content={
            "message": f"Cleanup completed successfully",
            "deleted_count": deleted_count,
            "cutoff_date": cutoff_date.isoformat()
        },
        status_code=200
    )