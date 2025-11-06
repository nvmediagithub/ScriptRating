"""
Script analysis API routes backed by the asynchronous analysis manager.
"""
from __future__ import annotations

from datetime import datetime
from typing import Dict, List

from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse

from app.infrastructure.services.runtime_context import analysis_manager
from app.presentation.api.schemas import (
    AgeRating,
    AnalysisStatusResponse,
    ErrorDetail,
    HighlightFragment,
    NormativeReference,
    RatingResult,
    SceneAssessment,
    ScriptAnalysisRequest,
    ScriptAnalysisResponse,
    Category,
    Severity,
)

router = APIRouter()


def _build_rating_result(payload: Dict | None) -> RatingResult:
    if not payload:
        categories_summary = {category: Severity.NONE for category in Category}
        return RatingResult(
            final_rating=AgeRating.ZERO_PLUS,
            target_rating=None,
            confidence_score=0.0,
            problem_scenes_count=0,
            categories_summary=categories_summary,
        )

    categories_summary = {}
    for key, value in payload.get("categories_summary", {}).items():
        category = key if isinstance(key, Category) else Category(key)
        severity = value if isinstance(value, Severity) else Severity(value)
        categories_summary[category] = severity

    final_rating = payload.get("final_rating", AgeRating.ZERO_PLUS)
    if not isinstance(final_rating, AgeRating):
        final_rating = AgeRating(final_rating)

    target_rating = payload.get("target_rating")
    if target_rating is not None and not isinstance(target_rating, AgeRating):
        target_rating = AgeRating(target_rating)

    return RatingResult(
        final_rating=final_rating,
        target_rating=target_rating,
        confidence_score=float(payload.get("confidence_score", 0.0)),
        problem_scenes_count=int(payload.get("problem_scenes_count", 0)),
        categories_summary=categories_summary,
    )


def _build_references(raw_refs: List[Dict]) -> List[NormativeReference]:
    references = []
    for ref in raw_refs:
        references.append(
            NormativeReference(
                document_id=ref["document_id"],
                title=ref["title"],
                page=int(ref["page"]),
                paragraph=int(ref["paragraph"]),
                excerpt=ref["excerpt"],
                score=float(ref["score"]),
            )
        )
    return references


def _build_scene_assessment(raw: Dict) -> SceneAssessment:
    categories = {}
    for key, value in raw.get("categories", {}).items():
        category = key if isinstance(key, Category) else Category(key)
        severity = value if isinstance(value, Severity) else Severity(value)
        categories[category] = severity

    age_rating = raw.get("age_rating", AgeRating.ZERO_PLUS)
    if not isinstance(age_rating, AgeRating):
        age_rating = AgeRating(age_rating)

    references = _build_references(raw.get("references", []))
    justification = raw.get("llm_comment")

    return SceneAssessment(
        scene_number=int(raw.get("scene_number", 0)),
        heading=raw.get("heading", f"Block {raw.get('scene_number', 0)}"),
        page_range=raw.get("page_range", "1"),
        categories=categories,
        flagged_content=list(raw.get("flagged_content", [])),
        justification=justification,
        age_rating=age_rating,
        llm_comment=justification or "",
        references=references,
        text=raw.get("text", ""),
        text_preview=raw.get("text_preview"),
        highlights=[
            HighlightFragment(
                start=int(fragment.get("start", 0)),
                end=int(fragment.get("end", 0)),
                text=fragment.get("text", ""),
                category=fragment.get("category") if isinstance(fragment.get("category"), Category) else Category(fragment.get("category", Category.VIOLENCE.value)),
                severity=fragment.get("severity") if isinstance(fragment.get("severity"), Severity) else Severity(fragment.get("severity", Severity.MILD.value)),
            )
            for fragment in raw.get("highlights", [])
            if isinstance(fragment, dict)
        ],
    )


@router.post(
    "/analyze",
    response_model=ScriptAnalysisResponse,
    summary="Start script analysis",
    description="Initiate analysis of an uploaded script document.",
)
async def start_analysis(request: ScriptAnalysisRequest) -> ScriptAnalysisResponse:
    """Start a new analysis task."""
    try:
        state = await analysis_manager.start_analysis(
            document_id=request.document_id,
            options=request.options.dict(),
            criteria_document_id=request.criteria_document_id,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=str(exc),
            ).dict(),
        ) from exc

    assessments = [_build_scene_assessment(item) for item in state.get("scene_assessments", [])]
    rating_result = _build_rating_result(state.get("rating_result"))

    return ScriptAnalysisResponse(
        analysis_id=state["analysis_id"],
        document_id=state["document_id"],
        status=state["status"],
        rating_result=rating_result,
        scene_assessments=assessments,
        created_at=state.get("created_at", datetime.utcnow()),
        recommendations=state.get("recommendations") or [],
    )


@router.get(
    "/status/{analysis_id}",
    response_model=AnalysisStatusResponse,
    summary="Get analysis status",
    description="Check the status and progress of a script analysis.",
)
async def get_analysis_status(analysis_id: str) -> AnalysisStatusResponse:
    """Return current status and processed blocks for an analysis."""
    try:
        state = await analysis_manager.get_status(analysis_id)
    except KeyError as exc:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found",
            ).dict(),
        ) from exc

    assessments = [_build_scene_assessment(item) for item in state.get("scene_assessments", [])]
    rating_result = state.get("rating_result")

    return AnalysisStatusResponse(
        analysis_id=analysis_id,
        status=state.get("status", "unknown"),
        progress=state.get("progress", 0.0),
        estimated_time_remaining=None,
        processed_blocks=assessments if assessments else None,
        rating_result=_build_rating_result(rating_result) if rating_result else None,
        recommendations=state.get("recommendations"),
        errors=state.get("errors"),
    )


@router.get(
    "/{analysis_id}",
    response_model=ScriptAnalysisResponse,
    summary="Get analysis results",
    description="Retrieve the complete results of a script analysis.",
)
async def get_analysis_results(analysis_id: str) -> ScriptAnalysisResponse:
    """Return the final (or latest) analysis result."""
    try:
        state = await analysis_manager.get_status(analysis_id)
    except KeyError as exc:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found",
            ).dict(),
        ) from exc

    assessments = [_build_scene_assessment(item) for item in state.get("scene_assessments", [])]
    rating_result = _build_rating_result(state.get("rating_result"))

    return ScriptAnalysisResponse(
        analysis_id=analysis_id,
        document_id=state.get("document_id"),
        status=state.get("status", "processing"),
        rating_result=rating_result,
        scene_assessments=assessments,
        created_at=state.get("created_at", datetime.utcnow()),
        recommendations=state.get("recommendations"),
    )


@router.post(
    "/{analysis_id}/cancel",
    summary="Cancel analysis",
    description="Cancel a running analysis task.",
)
async def cancel_analysis(analysis_id: str):
    """Request cancellation of an analysis task."""
    try:
        await analysis_manager.cancel_analysis(analysis_id)
    except KeyError as exc:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {analysis_id} not found",
            ).dict(),
        ) from exc
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=ErrorDetail(
                code="ANALYSIS_ALREADY_COMPLETED",
                message=str(exc),
            ).dict(),
        ) from exc

    return JSONResponse(
        content={"message": "Analysis cancellation requested", "analysis_id": analysis_id},
        status_code=200,
    )
