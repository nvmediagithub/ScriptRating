from __future__ import annotations

"""
Simple rule-based scene analysis engine.

This implementation is intentionally minimal and self-contained to allow
fast prototyping of per-scene checks without touching the main RAG/LLM
pipeline.
"""

from dataclasses import dataclass
from typing import List, Dict

from app.presentation.api.schemas import (
    AgeRating,
    Category,
    SceneViolation,
)


@dataclass
class SimpleRule:
    rule_id: str
    law_ref: str
    rating_level: AgeRating
    category: Category
    keywords: List[str]
    comment: str


class SimpleNormativeDoc:
    """
    In-memory normative document representation.

    In a real system this would be backed by a database or RAG corpus.
    """

    def __init__(self, doc_id: str, version: str, rules: List[SimpleRule]) -> None:
        self.doc_id = doc_id
        self.version = version
        self.rules = rules


class SimpleRulesEngine:
    """
    Very small, keyword-based rules engine for scene analysis.

    Limitations:
    - No morphology / lemmatization.
    - Case-insensitive substring search only.
    - Rating is computed as max rating_level across triggered rules.
    """

    def __init__(self) -> None:
        self._normative_doc = self._build_default_normative_doc()
        self._rating_order: Dict[AgeRating, int] = {
            AgeRating.ZERO_PLUS: 0,
            AgeRating.SIX_PLUS: 1,
            AgeRating.TWELVE_PLUS: 2,
            AgeRating.SIXTEEN_PLUS: 3,
            AgeRating.EIGHTEEN_PLUS: 4,
        }

    @staticmethod
    def _build_default_normative_doc() -> SimpleNormativeDoc:
        """
        Build a tiny hard-coded ruleset.

        This is a placeholder for real FZ-436 rules, but enough to
        exercise the end-to-end flow and UI.
        """
        rules: List[SimpleRule] = [
            SimpleRule(
                rule_id="R1_LANGUAGE_MILD",
                law_ref="FZ-436 Art. 5, mild language",
                rating_level=AgeRating.SIX_PLUS,
                category=Category.LANGUAGE,
                keywords=["чёрт", "блин"],
                comment="Мягкая ненормативная лексика, допустимая с 6+.",
            ),
            SimpleRule(
                rule_id="R2_LANGUAGE_STRONG",
                law_ref="FZ-436 Art. 5, strong profanity",
                rating_level=AgeRating.SIXTEEN_PLUS,
                category=Category.LANGUAGE,
                keywords=["хрен", "сука", "fuck"],
                comment="Сильная ненормативная лексика, повышает рейтинг до 16+.",
            ),
            SimpleRule(
                rule_id="R3_VIOLENCE_MODERATE",
                law_ref="FZ-436 Art. 6, non-graphic violence",
                rating_level=AgeRating.TWELVE_PLUS,
                category=Category.VIOLENCE,
                keywords=["ударил", "драка", "fight"],
                comment="Неграфическое насилие, допустимо с 12+.",
            ),
            SimpleRule(
                rule_id="R4_VIOLENCE_SEVERE",
                law_ref="FZ-436 Art. 6, graphic violence",
                rating_level=AgeRating.SIXTEEN_PLUS,
                category=Category.VIOLENCE,
                keywords=["кровь", "расстрел", "убил"],
                comment="Более жестокое насилие, рейтинг не ниже 16+.",
            ),
            SimpleRule(
                rule_id="R5_SUBSTANCES",
                law_ref="FZ-436 Art. 5, alcohol & drugs",
                rating_level=AgeRating.SIXTEEN_PLUS,
                category=Category.ALCOHOL_DRUGS,
                keywords=["вино", "водка", "наркотики", "героин"],
                comment="Упоминание алкоголя/наркотиков, рейтинг от 16+.",
            ),
        ]
        return SimpleNormativeDoc(doc_id="FZ436_SIMPLE", version="1.0", rules=rules)

    @property
    def normative_doc(self) -> SimpleNormativeDoc:
        return self._normative_doc

    def analyze_scene(self, scene_text: str) -> List[SceneViolation]:
        """
        Run all simple rules against scene_text and return violations.
        """
        text_lower = scene_text.lower()
        violations: List[SceneViolation] = []

        for rule in self._normative_doc.rules:
            # very naive: first keyword that appears triggers the rule
            for kw in rule.keywords:
                kw_lower = kw.lower()
                idx = text_lower.find(kw_lower)
                if idx != -1:
                    snippet = scene_text[max(0, idx - 20): idx + len(kw_lower) + 20]
                    violations.append(
                        SceneViolation(
                            rule_id=rule.rule_id,
                            law_ref=rule.law_ref,
                            rating_level=rule.rating_level,
                            category=rule.category,
                            snippet=snippet.strip(),
                            comment=rule.comment,
                        )
                    )
                    break  # do not add multiple times per rule

        return violations

    def compute_final_rating(self, violations: List[SceneViolation]) -> AgeRating:
        """
        Compute final rating as max rating_level across violations.
        """
        if not violations:
            return AgeRating.ZERO_PLUS

        max_rating = AgeRating.ZERO_PLUS
        max_score = self._rating_order[max_rating]

        for v in violations:
            score = self._rating_order.get(v.rating_level, max_score)
            if score > max_score:
                max_score = score
                max_rating = v.rating_level

        return max_rating

