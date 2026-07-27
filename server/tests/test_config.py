import pytest

from app import create_app


def test_production_rejects_default_secrets() -> None:
    with pytest.raises(RuntimeError, match="secretos de producción"):
        create_app(
            "production",
            {
                "SECRET_KEY": "development-only-secret",
                "JWT_SECRET_KEY": "development-only-jwt-secret",
            },
        )


def test_production_accepts_explicit_secrets() -> None:
    app = create_app(
        "production",
        {
            "SECRET_KEY": "a-production-secret",
            "JWT_SECRET_KEY": "a-distinct-production-jwt-secret",
        },
    )

    assert app.config["DEBUG"] is False
