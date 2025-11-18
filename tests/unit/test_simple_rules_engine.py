import pytest

from app.infrastructure.services.simple_rules_engine import SimpleRulesEngine
from app.presentation.api.schemas import AgeRating, Category


@pytest.fixture
def engine() -> SimpleRulesEngine:
    return SimpleRulesEngine()


def test_analyze_scene_no_violations(engine: SimpleRulesEngine) -> None:
    text = "Это совершенно нейтральная сцена без нарушений."
    violations = engine.analyze_scene(text)

    assert violations == []
    assert engine.compute_final_rating(violations) == AgeRating.ZERO_PLUS


def test_analyze_scene_detects_moderate_violence(engine: SimpleRulesEngine) -> None:
    text = "Между героями начинается драка, но без подробностей."
    violations = engine.analyze_scene(text)

    # Должно хотя бы одно нарушение категории VIOLENCE
    assert any(v.category == Category.VIOLENCE for v in violations)

    final_rating = engine.compute_final_rating(violations)
    # Для неграфического насилия базовое правило даёт не ниже 12+
    assert final_rating in {AgeRating.TWELVE_PLUS, AgeRating.SIXTEEN_PLUS, AgeRating.EIGHTEEN_PLUS}


def test_analyze_scene_detects_strong_language_and_updates_rating(engine: SimpleRulesEngine) -> None:
    # Используем английское слово, чтобы не зависеть от кодировки исходника
    text = "The character shouts: fuck this fight!"
    violations = engine.analyze_scene(text)

    assert violations, "Ожидались нарушения для сильной лексики"
    assert any(v.category == Category.LANGUAGE for v in violations)

    final_rating = engine.compute_final_rating(violations)
    # Правило для сильной лексики поднимает рейтинг минимум до 16+
    assert final_rating in {AgeRating.SIXTEEN_PLUS, AgeRating.EIGHTEEN_PLUS}

