from collections.abc import Iterator

import pytest
from flask import Flask

from app import create_app
from app.extensions import db


@pytest.fixture
def app() -> Iterator[Flask]:
    application = create_app("testing")

    with application.app_context():
        db.create_all()
        yield application
        db.session.remove()
        db.drop_all()
        db.engine.dispose()


@pytest.fixture
def client(app: Flask):
    return app.test_client()
