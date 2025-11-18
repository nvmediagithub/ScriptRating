from fastapi.testclient import TestClient

from app.presentation.api.main import create_app
from app.presentation.api.schemas import AgeRating


def _create_test_client() -> TestClient:
    app = create_app()
    return TestClient(app)


def test_check_scene_returns_zero_plus_for_clean_text() -> None:
    client = _create_test_client()

    payload = {
        "script_id": "script-1",
        "scene_id": "scene-1",
        "scene_text": "Это добрый разговор двух героев без конфликтов и нарушений.",
    }

    response = client.post("/api/analysis/check_scene", json=payload)
    assert response.status_code == 200

    data = response.json()
    assert data["script_id"] == payload["script_id"]
    assert data["scene_id"] == payload["scene_id"]
    assert data["final_rating"] == AgeRating.ZERO_PLUS.value
    assert data["violations"] == []


def test_check_scene_detects_violations_and_sets_higher_rating() -> None:
    client = _create_test_client()

    payload = {
        "script_id": "script-2",
        "scene_id": "scene-2",
        "scene_text": "Он ударил его, началась драка, затем достали вино и водку.",
    }

    response = client.post("/api/analysis/check_scene", json=payload)
    assert response.status_code == 200

    data = response.json()
    assert data["script_id"] == payload["script_id"]
    assert data["scene_id"] == payload["scene_id"]

    # Должен быть хотя бы один violation и рейтинг выше 0+
    assert len(data["violations"]) >= 1
    assert data["final_rating"] in [
        AgeRating.SIX_PLUS.value,
        AgeRating.TWELVE_PLUS.value,
        AgeRating.SIXTEEN_PLUS.value,
        AgeRating.EIGHTEEN_PLUS.value,
    ]

