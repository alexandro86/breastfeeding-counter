from __future__ import annotations

import os
from collections.abc import Mapping
from typing import Any, ClassVar


def _database_url(default: str) -> str:
    value = os.getenv("DATABASE_URL", default)
    if value.startswith("postgres://"):
        return value.replace("postgres://", "postgresql+psycopg://", 1)
    if value.startswith("postgresql://"):
        return value.replace("postgresql://", "postgresql+psycopg://", 1)
    return value


def _origins() -> list[str]:
    raw_origins = os.getenv("FRONTEND_ORIGINS", "http://localhost:5173")
    return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]


class BaseConfig:
    SQLALCHEMY_DATABASE_URI = _database_url(
        "postgresql+psycopg://breastfeeding:breastfeeding@localhost:5432/breastfeeding"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS: ClassVar[dict[str, bool]] = {"pool_pre_ping": True}
    SECRET_KEY = os.getenv("SECRET_KEY", "development-only-secret")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "development-only-jwt-secret")
    FRONTEND_ORIGINS = _origins()
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    JSON_SORT_KEYS = False

    @classmethod
    def validate(cls, config: Mapping[str, Any]) -> None:
        if not config["FRONTEND_ORIGINS"]:
            raise RuntimeError("FRONTEND_ORIGINS debe contener al menos un origen.")


class DevelopmentConfig(BaseConfig):
    DEBUG = True


class TestingConfig(BaseConfig):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = _database_url("sqlite+pysqlite:///:memory:")


class ProductionConfig(BaseConfig):
    DEBUG = False

    @classmethod
    def validate(cls, config: Mapping[str, Any]) -> None:
        super().validate(config)
        invalid_values = {
            "development-only-secret",
            "development-only-jwt-secret",
            "change-me",
        }
        if config["SECRET_KEY"] in invalid_values or config["JWT_SECRET_KEY"] in invalid_values:
            raise RuntimeError("Los secretos de producción deben configurarse explícitamente.")
        if "*" in config["FRONTEND_ORIGINS"]:
            raise RuntimeError("FRONTEND_ORIGINS no puede usar comodines en producción.")


CONFIGS = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "testing": TestingConfig,
}
