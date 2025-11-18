"""
Script analysis API routes backed by the asynchronous analysis manager.
"""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Dict, List

from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse

from app.infrastructure.services.runtime_context import (
    get_analysis_manager,
    get_knowledge_base,
)
from app.infrastructure.services.simple_rules_engine import SimpleRulesEngine
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
    SceneCheckRequest,
    SceneCheckResponse,
    Category,
    Severity,
)

router = APIRouter()

# Configure logging
logger = logging.getLogger(__name__)
_simple_rules_engine = SimpleRulesEngine()


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
        try:
            category = key if isinstance(key, Category) else Category(key)
            severity = value if isinstance(value, Severity) else Severity(value)
            categories_summary[category] = severity
        except ValueError as e:
            logger.error(f"Invalid category or severity value in categories_summary: key={key}, value={value}, error={e}")
            raise HTTPException(
                status_code=400,
                detail=ErrorDetail(
                    code="INVALID_CATEGORY_SEVERITY",
                    message=f"Invalid category or severity value: {key}={value}. Valid categories: {[c.value for c in Category]}, Valid severities: {[s.value for s in Severity]}",
                ).dict(),
            ) from e

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
        manager = await get_analysis_manager()
        state = await manager.start_analysis(
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
        manager = await get_analysis_manager()
        state = await manager.get_status(analysis_id)
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
        manager = await get_analysis_manager()
        state = await manager.get_status(analysis_id)
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
        manager = await get_analysis_manager()
        await manager.cancel_analysis(analysis_id)
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


@router.post(
    "/check_scene",
    response_model=SceneCheckResponse,
    summary="Per-scene analysis using rating engine and RAG",
    description=(
        "Analyze a single scene text using the same keyword categories as the main rating engine, "
        "optionally enriched with normative references from the KnowledgeBase/RAG. "
        "Falls back to the simple keyword rules engine on errors."
    ),
)
async def check_scene(request: SceneCheckRequest) -> SceneCheckResponse:
    """
    Analyze a single scene using the main rating engine heuristics and KnowledgeBase where available.

    The flow is intentionally simplified:
    - reuse the AnalysisManager category detector for consistency with full-script analysis;
    - derive per-violation ratings from detected severities;
    - query the KnowledgeBase for a top normative reference (if initialized);
    - on any failure in the advanced path, fall back to the SimpleRulesEngine.
    """
    if not request.scene_text or not request.scene_text.strip():
        raise HTTPException(
            status_code=400,
            detail=ErrorDetail(
                code="EMPTY_SCENE_TEXT",
                message="scene_text must not be empty",
            ).dict(),
        )

    # Advanced path: use AnalysisManager + KnowledgeBase/RAG when available
    try:
        manager = await get_analysis_manager()

        # Reuse category detector from the main rating engine
        categories, _flagged_content, highlights = manager._detect_categories(  # type: ignore[attr-defined]
            request.scene_text
        )

        # Compute per-violation ratings from detected severities
        def rating_from_severity(category: Category, severity: Severity) -> AgeRating:
            if severity == Severity.NONE:
                return AgeRating.ZERO_PLUS
            if severity == Severity.MILD:
                return AgeRating.SIX_PLUS
            if severity == Severity.MODERATE:
                return AgeRating.TWELVE_PLUS

            if category in (Category.SEXUAL_CONTENT, Category.VIOLENCE):
                return AgeRating.EIGHTEEN_PLUS
            return AgeRating.SIXTEEN_PLUS

        # Query KnowledgeBase for a top normative reference, if initialized
        normative_doc_id = "KNOWLEDGE_BASE"
        normative_doc_version = "1.0"
        law_ref: str | None = None

        try:
            knowledge_base = await get_knowledge_base()
            references = await knowledge_base.query(request.scene_text, top_k=1)
        except Exception as exc:  # pragma: no cover - defensive
            logger.warning("check_scene: KnowledgeBase query failed: %s", exc)
            references = []

        if references:
            ref = references[0]
            normative_doc_id = str(ref.get("document_id") or normative_doc_id)
            metadata = ref.get("metadata") or {}
            normative_doc_version = str(metadata.get("version", normative_doc_version))
            title = ref.get("title") or ""
            page = ref.get("page")
            paragraph = ref.get("paragraph")
            law_ref_parts = [title.strip()] if title else [normative_doc_id]
            if page is not None and paragraph is not None:
                law_ref_parts.append(f"стр. {page}, ¶{paragraph}")
            law_ref = ", ".join(part for part in law_ref_parts if part)

        # Build violations list from detected highlights
        violations: List[SceneViolation] = []
        for index, fragment in enumerate(highlights):
            category_value = fragment.get("category")
            severity_value = fragment.get("severity")
            text_fragment = fragment.get("text", "")

            try:
                category = Category(category_value)
            except Exception:
                logger.debug("check_scene: skipping fragment with invalid category: %s", category_value)
                continue

            try:
                severity = Severity(severity_value)
            except Exception:
                logger.debug("check_scene: defaulting severity for fragment: %s", severity_value)
                severity = Severity.MILD

            rating_level = rating_from_severity(category, severity)

            violations.append(
                SceneViolation(
                    rule_id=f"AUTO_{category.value}_{severity.value}_{index + 1}",
                    law_ref=law_ref,
                    rating_level=rating_level,
                    category=category,
                    snippet=text_fragment,
                    comment=(
                        f"Обнаружен контент категории '{category.value}' "
                        f"с уровнем серьёзности '{severity.value}'."
                    ),
                )
            )

        # Derive final rating as the maximum across violation rating levels
        if violations:
            rating_order = [
                AgeRating.ZERO_PLUS,
                AgeRating.SIX_PLUS,
                AgeRating.TWELVE_PLUS,
                AgeRating.SIXTEEN_PLUS,
                AgeRating.EIGHTEEN_PLUS,
            ]
            final_rating = max(violations, key=lambda v: rating_order.index(v.rating_level)).rating_level
        else:
            final_rating = AgeRating.ZERO_PLUS

        return SceneCheckResponse(
            script_id=request.script_id,
            scene_id=request.scene_id,
            normative_doc_id=normative_doc_id,
            normative_doc_version=normative_doc_version,
            final_rating=final_rating,
            violations=violations,
        )

    except Exception as exc:  # pragma: no cover - defensive
        logger.exception("check_scene: falling back to SimpleRulesEngine due to error: %s", exc)
        violations = _simple_rules_engine.analyze_scene(request.scene_text)
        final_rating = _simple_rules_engine.compute_final_rating(violations)
        normative_doc = _simple_rules_engine.normative_doc

        return SceneCheckResponse(
            script_id=request.script_id,
            scene_id=request.scene_id,
            normative_doc_id=normative_doc.doc_id,
            normative_doc_version=normative_doc.version,
            final_rating=final_rating,
            violations=violations,
        )
