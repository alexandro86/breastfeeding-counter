from __future__ import annotations

from typing import Any

from flask import Flask, g, jsonify
from werkzeug.exceptions import HTTPException


def problem(
    *,
    status: int,
    title: str,
    detail: str,
    problem_type: str = "about:blank",
) -> tuple[Any, int, dict[str, str]]:
    payload = {
        "type": problem_type,
        "title": title,
        "status": status,
        "detail": detail,
        "request_id": getattr(g, "request_id", None),
    }
    return jsonify(payload), status, {"Content-Type": "application/problem+json"}


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(HTTPException)
    def handle_http_error(error: HTTPException) -> tuple[Any, int, dict[str, str]]:
        return problem(
            status=error.code or 500,
            title=error.name,
            detail=error.description or "La solicitud no pudo procesarse.",
        )

    @app.errorhandler(Exception)
    def handle_unexpected_error(error: Exception) -> tuple[Any, int, dict[str, str]]:
        app.logger.exception("Unhandled application error", exc_info=error)
        return problem(
            status=500,
            title="Error interno",
            detail="Ocurrió un error inesperado.",
            problem_type="https://breastfeeding-counter.example/problems/internal-error",
        )
