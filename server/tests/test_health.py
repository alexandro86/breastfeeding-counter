from typing import Any

from flask.testing import FlaskClient
from sqlalchemy.exc import OperationalError

from app.extensions import db


def test_liveness_does_not_require_database(client: FlaskClient) -> None:
    response = client.get("/api/v1/health/live")

    assert response.status_code == 200
    assert response.get_json() == {
        "service": "breastfeeding-counter-api",
        "status": "ok",
        "version": "development",
    }
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Request-ID"]


def test_readiness_checks_database(client: FlaskClient) -> None:
    response = client.get("/api/v1/health/ready")

    assert response.status_code == 200
    assert response.get_json() == {"database": "ready", "status": "ok"}


def test_readiness_reports_database_failure(client: FlaskClient, monkeypatch: Any) -> None:
    def fail_query(*_args: Any, **_kwargs: Any) -> None:
        raise OperationalError("SELECT 1", {}, Exception("database unavailable"))

    monkeypatch.setattr(db.session, "execute", fail_query)

    response = client.get("/api/v1/health/ready")

    assert response.status_code == 503
    assert response.content_type == "application/problem+json"
    assert response.get_json()["type"].endswith("/database-unavailable")


def test_liveness_exposes_configured_version(app: Any) -> None:
    app.config["APP_VERSION"] = "a" * 40

    with app.test_client() as client:
        response = client.get("/api/v1/health/live")

    assert response.status_code == 200
    assert response.get_json()["version"] == "a" * 40
