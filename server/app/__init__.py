from __future__ import annotations

import logging
import os
import re
import secrets
from typing import Any

from flask import Flask, g, request

from app.api.v1 import api_v1
from app.config import CONFIGS
from app.errors import register_error_handlers
from app.extensions import cors, db, migrate

REQUEST_ID_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,128}$")


def create_app(config_name: str | None = None, overrides: dict[str, Any] | None = None) -> Flask:
    app = Flask(__name__)
    selected_config = config_name or os.getenv("FLASK_ENV") or "development"
    config_class = CONFIGS.get(selected_config, CONFIGS["development"])
    app.config.from_object(config_class)

    if overrides:
        app.config.update(overrides)

    config_class.validate(app.config)
    _configure_extensions(app)
    _configure_request_context(app)
    register_error_handlers(app)
    app.register_blueprint(api_v1)

    return app


def _configure_extensions(app: Flask) -> None:
    db.init_app(app)
    migrate.init_app(app, db)
    cors.init_app(
        app,
        resources={r"/api/*": {"origins": app.config["FRONTEND_ORIGINS"]}},
        supports_credentials=True,
    )


def _configure_request_context(app: Flask) -> None:
    @app.before_request
    def assign_request_id() -> None:
        incoming = request.headers.get("X-Request-ID", "")
        g.request_id = incoming if REQUEST_ID_PATTERN.fullmatch(incoming) else secrets.token_hex(12)

    @app.after_request
    def add_response_headers(response: Any) -> Any:
        response.headers["X-Request-ID"] = g.request_id
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response

    if not app.testing:
        logging.basicConfig(
            level=app.config["LOG_LEVEL"],
            format="%(asctime)s %(levelname)s %(name)s %(message)s",
        )
