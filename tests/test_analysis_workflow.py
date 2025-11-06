import time

from fastapi.testclient import TestClient

from app.presentation.api.main import create_app


client = TestClient(create_app())


def _upload_document(filename: str, content: str, document_type: str) -> str:
    response = client.post(
        "/api/v1/documents/upload",
        data={"filename": filename, "document_type": document_type},
        files={
            "file": (
                filename,
                content.encode("utf-8"),
                "text/plain",
            )
        },
    )
    assert response.status_code == 200, response.text
    payload = response.json()
    return payload["document_id"]


def test_end_to_end_analysis_creates_referenced_blocks():
    criteria_id = _upload_document(
        "criteria.txt",
        (
            "Статья 5. Запрещено отображать кровавое насилие и жестокие драки.\n\n"
            "Статья 6. Недопустимы сцены с подробными описаниями жестокости."
        ),
        "criteria",
    )

    script_id = _upload_document(
        "script.txt",
        (
            "Сцена 1. Герой вступает в кровавую драку, удары сопровождаются брызгами крови. "
            "После боя описывается труп противника."
        ),
        "script",
    )

    response = client.post(
        "/api/v1/analysis/analyze",
        json={
            "document_id": script_id,
            "criteria_document_id": criteria_id,
            "options": {
                "include_recommendations": True,
                "detailed_scenes": True,
            },
        },
    )
    assert response.status_code == 200, response.text
    analysis_payload = response.json()
    analysis_id = analysis_payload["analysis_id"]

    status_payload = None
    for _ in range(40):
        status_response = client.get(f"/api/v1/analysis/status/{analysis_id}")
        assert status_response.status_code == 200, status_response.text
        status_payload = status_response.json()
        if status_payload["status"] in {"completed", "failed", "cancelled"}:
            break
        time.sleep(0.1)

    assert status_payload is not None
    assert status_payload["status"] == "completed"
    assert status_payload["processed_blocks"], "expected processed blocks in status payload"

    first_block = status_payload["processed_blocks"][0]
    assert first_block["references"], "block should include normative references"
    assert first_block["age_rating"] in {"12+", "16+", "18+"}

    final_result = client.get(f"/api/v1/analysis/{analysis_id}")
    assert final_result.status_code == 200, final_result.text
    final_payload = final_result.json()
    assert final_payload["rating_result"]["final_rating"] in {"12+", "16+", "18+"}
