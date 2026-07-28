# Breastfeeding Counter

Aplicación web móvil para registrar tomas de lactancia y productos relacionados de forma
simple, privada y confiable.

Este repositorio usa una estrategia de monorepo:

- `client/`: SPA con React, TypeScript y Vite.
- `server/`: API REST con Python, Flask, SQLAlchemy y PostgreSQL.
- `docs/`: contrato OpenAPI y decisiones de arquitectura.
- `.github/`: controles automatizados de calidad y seguridad.

## Requisitos

- Node.js 22.14 o compatible con `>=22.12`.
- Python 3.13.
- Docker y Docker Compose para PostgreSQL local.
- GNU Make es opcional; todos los comandos se pueden ejecutar directamente.

En Windows con NVM:

```powershell
nvm use 22.14.0
```

## Instalación

### Cliente

```powershell
cd client
npm ci
Copy-Item .env.example .env
```

### Servidor

```powershell
cd server
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements-dev.lock
.\.venv\Scripts\python -m pip install --no-build-isolation --no-deps -e .
Copy-Item .env.example .env
```

En Linux o macOS, sustituir `.\.venv\Scripts\python` por `.venv/bin/python`.

## Desarrollo local

Levantar PostgreSQL:

```powershell
docker compose up -d db
```

Aplicar migraciones y ejecutar la API:

```powershell
cd server
.\.venv\Scripts\python -m flask --app wsgi db upgrade
.\.venv\Scripts\python -m flask --app wsgi run --debug
```

En otra terminal, ejecutar el cliente:

```powershell
cd client
npm run dev
```

- Cliente: <http://localhost:5173>
- API: <http://localhost:5000/api/v1>
- Liveness: <http://localhost:5000/api/v1/health/live>
- Readiness: <http://localhost:5000/api/v1/health/ready>

## Verificaciones

```powershell
cd client
npm run format:check
npm run lint
npm run typecheck
npm run test:coverage
npm run build
```

```powershell
cd server
.\.venv\Scripts\python -m ruff format --check .
.\.venv\Scripts\python -m ruff check .
.\.venv\Scripts\python -m mypy app
.\.venv\Scripts\python -m pytest --cov=app --cov-report=term-missing
```

Con Make, usar `make setup`, `make dev`, `make lint`, `make test` o `make build`.

## Variables de entorno

Copiar los archivos `.env.example`; nunca versionar `.env`.

- El cliente solo recibe valores públicos mediante `VITE_*`.
- El servidor requiere una URL PostgreSQL y secretos independientes.
- Producción rechaza los secretos de desarrollo y orígenes CORS con comodín.

## Migraciones

Crear una migración después de modificar modelos:

```powershell
cd server
.\.venv\Scripts\python -m flask --app wsgi db migrate -m "descripcion"
.\.venv\Scripts\python -m flask --app wsgi db upgrade
```

No ejecutar `db.create_all()` fuera de las pruebas.

## Arquitectura y contrato

- [ADR-001: monorepo y hosting](docs/adr/001-monorepo-and-hosting.md)
- [ADR-002: autenticación de la SPA](docs/adr/002-spa-authentication.md)
- [Contrato OpenAPI](docs/openapi.yaml)
- [Operación de staging y producción](docs/operations/deployment.md)
- [Skill base](.codex/skills/init1-project/SKILL.md)

Las métricas del producto son descriptivas y no constituyen consejo médico.
