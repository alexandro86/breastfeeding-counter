ifeq ($(OS),Windows_NT)
PYTHON_VENV := server/.venv/Scripts/python.exe
else
PYTHON_VENV := server/.venv/bin/python
endif

.PHONY: setup setup-client setup-server dev dev-client dev-server db-up db-down migrate lint test build

setup: setup-client setup-server

setup-client:
	cd client && npm ci

setup-server:
	python -m venv server/.venv
	$(PYTHON_VENV) -m pip install --requirement server/requirements-dev.lock
	$(PYTHON_VENV) -m pip install --no-build-isolation --no-deps --editable server

dev:
	$(MAKE) -j2 dev-client dev-server

dev-client:
	cd client && npm run dev

dev-server:
	cd server && ../$(PYTHON_VENV) -m flask --app wsgi run --debug

db-up:
	docker compose up -d db

db-down:
	docker compose down

migrate:
	cd server && ../$(PYTHON_VENV) -m flask --app wsgi db upgrade

lint:
	cd client && npm run format:check && npm run lint && npm run typecheck
	cd server && ../$(PYTHON_VENV) -m ruff format --check . && ../$(PYTHON_VENV) -m ruff check . && ../$(PYTHON_VENV) -m mypy app

test:
	cd client && npm run test:coverage
	cd server && ../$(PYTHON_VENV) -m pytest --cov=app --cov-report=term-missing

build:
	cd client && npm run build
