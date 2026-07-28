from __future__ import annotations

from typing import Any

from flask import Blueprint, current_app, jsonify
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.errors import problem
from app.extensions import db

health = Blueprint("health", __name__, url_prefix="/health")


@health.get("/live")
def liveness() -> tuple[Any, int]:
    return (
        jsonify(
            status="ok",
            service="breastfeeding-counter-api",
            version=current_app.config["APP_VERSION"],
        ),
        200,
    )


@health.get("/ready")
def readiness() -> tuple[Any, int] | tuple[Any, int, dict[str, str]]:
    try:
        db.session.execute(text("SELECT 1"))
    except SQLAlchemyError:
        db.session.rollback()
        return problem(
            status=503,
            title="Servicio no disponible",
            detail="La base de datos no está disponible.",
            problem_type="https://breastfeeding-counter.example/problems/database-unavailable",
        )

    return jsonify(status="ok", database="ready"), 200
