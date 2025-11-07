"""
Asynchronous orchestrator for script analysis workflow.

The manager consumes normalized script payloads from the ScriptStore and
provides incremental progress updates while assigning age ratings to semantic
blocks with references fetched from the KnowledgeBase.
"""
from __future__ import annotations

import asyncio
import logging
import math
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from app.presentation.api.schemas import AgeRating, Category, Severity

from .knowledge_base import KnowledgeBase
from .script_store import ScriptStore

# Configure logging
logger = logging.getLogger(__name__)

CATEGORY_KEYWORDS: Dict[Category, Dict[Severity, List[str]]] = {
    Category.VIOLENCE: {
        Severity.SEVERE: ["убий", "расстрел", "кров", "пытк", "казн"],
        Severity.MODERATE: ["драка", "бой", "оруж", "удар", "атака"],
        Severity.MILD: ["спор", "угроз", "конфликт", "схват"],
    },
    Category.SEXUAL_CONTENT: {
        Severity.SEVERE: ["порн", "секс", "интим", "эротич", "совокуп"],
        Severity.MODERATE: ["поцелу", "страсть", "половой", "обнажен"],
        Severity.MILD: ["флирт", "намек", "романтич", "симпат"],
    },
    Category.LANGUAGE: {
        Severity.SEVERE: ["нецензур", "мат", "ругательств"],
        Severity.MODERATE: ["оскорб", "бран", "ругал"],
        Severity.MILD: ["груб", "сарказм", "насмеш"],
    },
    Category.ALCOHOL_DRUGS: {
        Severity.SEVERE: ["наркот", "героин", "инъек", "употреб"],
        Severity.MODERATE: ["алког", "пьян", "курен", "пиво"],
        Severity.MILD: ["бар", "вин", "шампан", "сигар"],
    },
    Category.DISTURBING_SCENES: {
        Severity.SEVERE: ["труп", "расчлен", "ужас", "кошмар", "паник"],
        Severity.MODERATE: ["страх", "крик", "паник", "страшн"],
        Severity.MILD: ["напряж", "тревог", "волн"],
    },
}

SEVERITY_ORDER = [Severity.NONE, Severity.MILD, Severity.MODERATE, Severity.SEVERE]
RATING_ORDER = [
    AgeRating.ZERO_PLUS,
    AgeRating.SIX_PLUS,
    AgeRating.TWELVE_PLUS,
    AgeRating.SIXTEEN_PLUS,
    AgeRating.EIGHTEEN_PLUS,
]


class AnalysisManager:
    """Coordinates script analysis and exposes incremental progress information."""

    def __init__(self, knowledge_base: KnowledgeBase, script_store: ScriptStore) -> None:
        self._knowledge_base = knowledge_base
        self._script_store = script_store
        self._analyses: Dict[str, Dict[str, Any]] = {}
        self._lock = asyncio.Lock()

    async def start_analysis(
        self,
        document_id: str,
        options: Dict[str, Any],
        criteria_document_id: Optional[str],
    ) -> Dict[str, Any]:
        """Create a new analysis task and schedule its execution."""
        script_payload = await self._script_store.get_script(document_id)
        if not script_payload:
            raise ValueError(f"Script with document_id={document_id} not found")

        analysis_id = str(uuid.uuid4())
        initial_state = {
            "analysis_id": analysis_id,
            "document_id": document_id,
            "criteria_document_id": criteria_document_id,
            "options": options,
            "status": "processing",
            "progress": 0.0,
            "created_at": datetime.utcnow(),
            "scene_assessments": [],
            "rating_result": None,
            "recommendations": [],
            "errors": None,
        }

        async with self._lock:
            self._analyses[analysis_id] = initial_state

        asyncio.create_task(
            self._run_analysis(
                analysis_id=analysis_id,
                script_payload=script_payload,
                options=options,
                criteria_document_id=criteria_document_id,
            )
        )

        return initial_state

    async def get_status(self, analysis_id: str) -> Dict[str, Any]:
        """Return current state snapshot for the analysis."""
        async with self._lock:
            if analysis_id not in self._analyses:
                raise KeyError(f"Analysis {analysis_id} not found")
            return self._analyses[analysis_id]

    async def cancel_analysis(self, analysis_id: str) -> None:
        """Mark an analysis as cancelled."""
        async with self._lock:
            state = self._analyses.get(analysis_id)
            if not state:
                raise KeyError(f"Analysis {analysis_id} not found")
            if state.get("status") == "completed":
                raise ValueError("Analysis already completed")
            state["status"] = "cancelled"
            state["progress"] = state.get("progress", 0.0)

    async def _run_analysis(
        self,
        analysis_id: str,
        script_payload: Dict[str, Any],
        options: Dict[str, Any],
        criteria_document_id: Optional[str],
    ) -> None:
        """Execute the analysis workflow and update progress incrementally."""
        try:
            paragraph_details: List[Dict[str, Any]] = script_payload.get(
                "paragraph_details", []
            )
            if not paragraph_details:
                paragraph_details = [
                    {"page": 1, "paragraph_index": idx, "text": text}
                    for idx, text in enumerate(script_payload.get("paragraphs", []), start=1)
                ]

            blocks = self._build_blocks(paragraph_details)
            if not blocks:
                raise ValueError("Не удалось выделить смысловые блоки в сценарии")

            target_rating = options.get("target_rating")
            aggregated_categories: Dict[Category, Severity] = {
                category: Severity.NONE for category in Category
            }
            problem_blocks = 0

            for index, block in enumerate(blocks, start=1):
                if await self._is_cancelled(analysis_id):
                    await self._update_state(
                        analysis_id,
                        {
                            "status": "cancelled",
                            "progress": round(index / len(blocks) * 100, 2),
                        },
                    )
                    return

                block_result = await self._assess_block(
                    block_number=index,
                    block_paragraphs=block,
                    criteria_document_id=criteria_document_id,
                )

                block_severity_values = block_result["categories"]
                if any(value != Severity.NONE for value in block_severity_values.values()):
                    problem_blocks += 1

                for category, severity in block_severity_values.items():
                    if SEVERITY_ORDER.index(severity) > SEVERITY_ORDER.index(
                        aggregated_categories[category]
                    ):
                        aggregated_categories[category] = severity

                progress = round(index / len(blocks) * 100, 2)
                await self._update_state(
                    analysis_id,
                    {
                        "scene_assessments": block_result,
                        "progress": progress,
                    },
                )

            rating_summary = self._build_rating_summary(
                aggregated_categories=aggregated_categories,
                scene_assessments=await self._gather_assessments(analysis_id),
                problem_blocks=problem_blocks,
                target_rating=target_rating,
            )
            recommendations = self._build_recommendations(aggregated_categories)

            await self._update_state(
                analysis_id,
                {
                    "rating_result": rating_summary,
                    "recommendations": recommendations,
                    "status": "completed",
                    "progress": 100.0,
                },
            )
        except Exception as exc:  # noqa: BLE001 - surface error to caller
            await self._update_state(
                analysis_id,
                {
                    "status": "failed",
                    "errors": str(exc),
                    "progress": 100.0,
                },
            )

    async def _update_state(self, analysis_id: str, payload: Dict[str, Any]) -> None:
        async with self._lock:
            state = self._analyses.get(analysis_id)
            if not state:
                return

            assessments = state.setdefault("scene_assessments", [])
            if "scene_assessments" in payload and isinstance(payload["scene_assessments"], dict):
                assessments.append(payload.pop("scene_assessments"))
            state.update(payload)

    async def _gather_assessments(self, analysis_id: str) -> List[Dict[str, Any]]:
        async with self._lock:
            state = self._analyses.get(analysis_id, {})
            return list(state.get("scene_assessments", []))

    async def _is_cancelled(self, analysis_id: str) -> bool:
        async with self._lock:
            state = self._analyses.get(analysis_id)
            return bool(state and state.get("status") == "cancelled")

    def _build_blocks(self, paragraph_details: List[Dict[str, Any]], max_words: int = 160):
        """Group consecutive paragraphs into semantic blocks by word count."""
        blocks: List[List[Dict[str, Any]]] = []
        current_block: List[Dict[str, Any]] = []
        current_words = 0

        for detail in paragraph_details:
            text = detail.get("text", "").strip()
            if not text:
                continue
            words = text.split()
            if current_block and current_words + len(words) > max_words:
                blocks.append(current_block)
                current_block = []
                current_words = 0

            enriched_detail = {
                **detail,
                "text": text,
            }
            current_block.append(enriched_detail)
            current_words += len(words)

        if current_block:
            blocks.append(current_block)

        return blocks

    async def _assess_block(
        self,
        block_number: int,
        block_paragraphs: List[Dict[str, Any]],
        criteria_document_id: Optional[str],
    ) -> Dict[str, Any]:
        """Assign rating metadata for a single block."""
        block_text = " ".join(detail["text"] for detail in block_paragraphs)
        categories, flagged_content, highlights = self._detect_categories(block_text)
        block_rating = self._calculate_block_rating(categories)

        references = await self._knowledge_base.query(block_text, top_k=2)
        if criteria_document_id:
            references = [ref for ref in references if ref["document_id"] == criteria_document_id] or references

        page_numbers = [detail.get("page", 1) for detail in block_paragraphs]
        page_from, page_to = min(page_numbers), max(page_numbers)
        page_range = str(page_from) if page_from == page_to else f"{page_from}-{page_to}"

        heading = block_paragraphs[0]["text"][:80]
        comment = self._build_comment(block_rating, categories, references)

        return {
            "scene_number": block_number,
            "heading": heading,
            "page_range": page_range,
            "age_rating": block_rating,
            "categories": categories,
            "flagged_content": flagged_content,
            "highlights": highlights,
            "llm_comment": comment,
            "references": references,
            "text": block_text,
            "text_preview": block_text[:400],
        }

    def _detect_categories(
        self,
        text: str,
    ) -> (Dict[Category, Severity], List[str], List[Dict[str, Any]]):
        lowered = text.lower()
        categories: Dict[Category, Severity] = {category: Severity.NONE for category in Category}
        flagged_content: List[str] = []
        highlights: List[Dict[str, Any]] = []

        for category, severity_map in CATEGORY_KEYWORDS.items():
            detected_severity = Severity.NONE
            detected_keywords: List[str] = []
            best_match_span: Optional[tuple[int, int]] = None
            for severity in reversed(SEVERITY_ORDER[1:]):  # skip NONE
                keywords = severity_map.get(severity, [])
                matches = []
                for keyword in keywords:
                    idx = lowered.find(keyword)
                    if idx != -1:
                        matches.append(keyword)
                        if best_match_span is None or len(keyword) > (best_match_span[1] - best_match_span[0]):
                            best_match_span = (idx, idx + len(keyword))
                if matches:
                    detected_severity = severity
                    detected_keywords.extend(matches)
                    break

            categories[category] = detected_severity
            if detected_keywords:
                flagged_content.append(
                    f"{category.value.replace('_', ' ').title()}: {', '.join(sorted(set(detected_keywords)))}"
                )
                if best_match_span is not None:
                    start, end = best_match_span
                    highlights.append(
                        {
                            "start": start,
                            "end": end,
                            "text": text[start:end],
                            "category": category.value,
                            "severity": detected_severity.value,
                        }
                    )

        return categories, flagged_content, highlights

    def _calculate_block_rating(self, categories: Dict[Category, Severity]) -> AgeRating:
        """Calculate the appropriate age rating for a block based on detected categories."""
        logger.debug(f"Calculating block rating for categories: {categories}")
        highest_severity = max(
            categories.values(),
            key=lambda severity: SEVERITY_ORDER.index(severity),
        )
        logger.debug(f"Highest severity detected: {highest_severity}")

        if highest_severity == Severity.NONE:
            logger.debug("No violations detected, returning ZERO_PLUS")
            return AgeRating.ZERO_PLUS
        if highest_severity == Severity.MILD:
            logger.debug("Mild violations detected, returning SIX_PLUS")
            return AgeRating.SIX_PLUS
        if highest_severity == Severity.MODERATE:
            logger.debug("Moderate violations detected, returning TWELVE_PLUS")
            return AgeRating.TWELVE_PLUS

        if categories.get(Category.SEXUAL_CONTENT) == Severity.SEVERE or categories.get(
            Category.VIOLENCE
        ) == Severity.SEVERE:
            logger.debug("Severe sexual content or violence detected, returning EIGHTEEN_PLUS")
            return AgeRating.EIGHTEEN_PLUS
        
        logger.debug("Severe violations detected, returning SIXTEEN_PLUS")
        return AgeRating.SIXTEEN_PLUS

    def _build_comment(
        self,
        rating: AgeRating,
        categories: Dict[Category, Severity],
        references: List[Dict[str, Any]],
    ) -> str:
        significant_categories = [
            f"{category.value.replace('_', ' ')} — {severity.value}"
            for category, severity in categories.items()
            if severity != Severity.NONE
        ]
        reference_hint = ""
        if references:
            top_reference = references[0]
            reference_hint = (
                f" См. документ {top_reference['title']} (стр. {top_reference['page']}, "
                f"параграф {top_reference['paragraph']})."
            )

        if not significant_categories:
            return "Нарушений, влияющих на возрастной рейтинг, не обнаружено."

        categories_text = "; ".join(significant_categories)
        return (
            f"Блок отнесен к категории {rating.value} из-за обнаруженного содержимого: "
            f"{categories_text}.{reference_hint}"
        )

    def _build_rating_summary(
        self,
        aggregated_categories: Dict[Category, Severity],
        scene_assessments: List[Dict[str, Any]],
        problem_blocks: int,
        target_rating: Optional[str],
    ) -> Dict[str, Any]:
        logger.debug(f"Building rating summary with {len(scene_assessments)} scene assessments")
        logger.debug(f"Aggregated categories: {aggregated_categories}")
        logger.debug(f"Target rating: {target_rating}")
        
        final_rating = AgeRating.ZERO_PLUS
        for assessment in scene_assessments:
            block_rating = assessment["age_rating"]
            logger.debug(f"Block rating: {block_rating} (type: {type(block_rating)})")
            
            # Ensure we're working with AgeRating enum values
            if not isinstance(block_rating, AgeRating):
                logger.error(f"Block rating is not AgeRating enum: {block_rating} (type: {type(block_rating)})")
                try:
                    block_rating = AgeRating(block_rating)
                    logger.debug(f"Converted block rating to: {block_rating}")
                except Exception as e:
                    logger.error(f"Failed to convert block rating: {e}")
                    continue
                    
            if RATING_ORDER.index(block_rating) > RATING_ORDER.index(final_rating):
                final_rating = block_rating
                logger.debug(f"Updated final rating to: {final_rating}")

        severity_counts = sum(
            SEVERITY_ORDER.index(severity) for severity in aggregated_categories.values()
        )
        confidence = max(0.55, min(0.95, 0.65 + severity_counts * 0.05))

        result = {
            "final_rating": final_rating,
            "target_rating": target_rating,
            "problem_scenes_count": problem_blocks,
            "categories_summary": aggregated_categories,
            "confidence_score": round(confidence, 2),
        }
        
        logger.debug(f"Final rating summary: {result}")
        return result

    def _build_recommendations(
        self, aggregated_categories: Dict[Category, Severity]
    ) -> List[str]:
        recommendations: List[str] = []
        for category, severity in aggregated_categories.items():
            if severity == Severity.NONE:
                continue
            if category == Category.VIOLENCE:
                recommendations.append(
                    "Снизьте интенсивность сцен насилия или сократите их продолжительность."
                )
            elif category == Category.SEXUAL_CONTENT:
                recommendations.append(
                    "Пересмотрите описание интимных сцен, чтобы снизить откровенность."
                )
            elif category == Category.LANGUAGE:
                recommendations.append("Замените грубые выражения на более нейтральные формулировки.")
            elif category == Category.ALCOHOL_DRUGS:
                recommendations.append(
                    "Уберите демонстрацию употребления алкоголя/наркотиков или смягчите акценты."
                )
            elif category == Category.DISTURBING_SCENES:
                recommendations.append(
                    "Смягчите визуальные детали тревожных сцен или сократите их описания."
                )

        if not recommendations:
            recommendations.append("Сценарий соответствует требованиям выбранного возрастного рейтинга.")
        return recommendations
