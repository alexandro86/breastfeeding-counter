# Server Technical Definition

## Contents

1. [Purpose and authority](#1-purpose-and-authority)
2. [Current baseline and target stack](#2-current-baseline-and-target-stack)
3. [Architectural model](#3-architectural-model)
4. [Application Factory](#4-application-factory)
5. [Blueprints and HTTP routes](#5-blueprints-and-http-routes)
6. [Layer boundaries](#6-layer-boundaries)
7. [Pydantic validation and serialization](#7-pydantic-validation-and-serialization)
8. [Database and models](#8-database-and-models)
9. [Transactions and concurrency](#9-transactions-and-concurrency)
10. [Migrations](#10-migrations)
11. [Configuration and python-dotenv](#11-configuration-and-python-dotenv)
12. [Authentication and authorization](#12-authentication-and-authorization)
13. [Global error handling](#13-global-error-handling)
14. [Type hints and static analysis](#14-type-hints-and-static-analysis)
15. [Security and privacy](#15-security-and-privacy)
16. [Observability](#16-observability)
17. [Testing strategy](#17-testing-strategy)
18. [GitHub Actions quality gates](#18-github-actions-quality-gates)
19. [Agent workflow](#19-agent-workflow)
20. [Definition of done](#20-definition-of-done)
21. [Primary references](#21-primary-references)

## 1. Purpose and authority

This document is the technical contract for the `server/` application of
`breastfeeding-counter`. Every agent and contributor MUST read it before planning or implementing
server functionality.

The server is a modular Flask monolith. It owns authentication, authorization, business rules,
transactions, calculations, validation of persisted data, and the versioned HTTP contract.
PostgreSQL is the only production source of truth.

The key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are normative.

When instructions conflict, use this order:

1. Security, privacy, and data integrity requirements.
2. Accepted ADRs and `docs/openapi.yaml`.
3. This document.
4. Repository-wide architecture and delivery references.
5. Existing local conventions.

An agent MUST NOT silently bypass this contract. Architectural exceptions require an explanation
in the pull request. Changes to authentication, the API contract, the central schema, hosting, or
application boundaries require an ADR.

## 2. Current baseline and target stack

Exact versions are defined by `requirements.lock` and `requirements-dev.lock`, not by this file.
Locked dependencies MUST be installed in CI.

| Concern             | Standard                                        | Status at definition time                     |
| ------------------- | ----------------------------------------------- | --------------------------------------------- |
| Runtime             | Python 3.13                                     | Installed                                     |
| Web framework       | Flask 3.1                                       | Installed                                     |
| Architecture        | Application Factory and Blueprints              | Implemented                                   |
| ORM                 | Flask-SQLAlchemy with SQLAlchemy 2 typed models | Installed                                     |
| Database            | PostgreSQL with Psycopg 3                       | Installed                                     |
| Migrations          | Flask-Migrate and Alembic                       | Installed                                     |
| Validation          | Pydantic 2                                      | Required target; not yet a project dependency |
| Authentication      | Flask-JWT-Extended                              | Required target; not yet a project dependency |
| Environment loading | python-dotenv                                   | Installed                                     |
| HTTP errors         | RFC 9457-style Problem Details                  | Foundation implemented                        |
| Testing             | pytest and pytest-cov                           | Installed                                     |
| Quality             | Ruff and mypy                                   | Installed                                     |
| Production server   | Gunicorn                                        | Installed                                     |

Agents MUST inspect the lockfiles, `pyproject.toml`, migrations, OpenAPI document, and affected code
before assuming that a target capability is initialized. Dependency additions require a concrete
use case, locked versions, audit success, and corresponding tests.

## 3. Architectural model

Use a modular monolith with explicit layers:

```text
HTTP request
    |
    v
Blueprint route / controller
    | validates transport input and extracts identity
    v
Application service
    | enforces business rules and owns transaction boundary
    v
Repository
    | expresses reusable persistence queries
    v
SQLAlchemy model / PostgreSQL

Service result
    |
    v
Pydantic response schema
    |
    v
HTTP JSON response
```

Expected package shape:

```text
server/
|-- app/
|   |-- api/
|   |   `-- v1/
|   |       |-- auth.py
|   |       |-- babies.py
|   |       |-- feedings.py
|   |       |-- products.py
|   |       `-- health.py
|   |-- auth/               # Google identity, JWT callbacks, session primitives
|   |-- models/             # SQLAlchemy persistence models only
|   |-- repositories/       # Queries and persistence operations
|   |-- schemas/            # Pydantic request, response, and query models
|   |-- services/           # Use cases, rules, authorization, transactions
|   |-- config.py
|   |-- errors.py
|   |-- extensions.py
|   `-- __init__.py         # create_app
|-- migrations/
|-- tests/
|   |-- integration/
|   |-- unit/
|   `-- conftest.py
|-- .env.example
|-- pyproject.toml
`-- wsgi.py
```

Dependencies MUST point inward:

```text
routes -> services -> repositories -> models
routes -> schemas
services -> domain errors and typed service values
```

Models, repositories, and services MUST NOT import blueprints or Flask request globals. Services
SHOULD receive ordinary typed values and explicit actor identity so they remain testable without an
HTTP request.

## 4. Application Factory

The only supported application construction path is:

```python
def create_app(
    config_name: str | None = None,
    overrides: dict[str, object] | None = None,
) -> Flask:
    ...
```

The factory MUST, in a deterministic order:

1. create the `Flask` instance;
2. load the selected configuration;
3. apply explicit test overrides;
4. validate required configuration without revealing secret values;
5. initialize unbound extensions with `init_app`;
6. register JWT callbacks and global error handlers;
7. configure request IDs, security headers, CORS, and logging;
8. register the versioned API blueprint;
9. register CLI commands when needed;
10. return the application.

Extension objects MUST be created once in `app/extensions.py` without binding them to a Flask app:

```python
db = SQLAlchemy(model_class=Base)
migrate = Migrate()
jwt = JWTManager()
```

Do not create an application or open a database connection at import time. Use `current_app` only
inside an application context. `wsgi.py` may expose the result of the factory for Gunicorn but MUST
contain no application logic.

The `overrides` argument exists for tests and controlled tooling. Production configuration MUST
come from environment-backed configuration classes, not ad hoc dictionaries.

## 5. Blueprints and HTTP routes

All public API routes MUST live under `/api/v1`. Register a parent `api_v1` blueprint and group
resource routes into child blueprints when modules grow. Blueprint names and endpoint names MUST be
stable and unique.

Route functions are transport adapters. A route MUST only:

1. read path, query, header, and JSON input;
2. validate it with a Pydantic schema;
3. obtain the authenticated identity from the approved authentication helper;
4. call one application service;
5. serialize the result through a response schema;
6. return the documented status, body, and headers.

Routes MUST NOT:

- contain business decisions or ownership queries;
- call `db.session.commit()`;
- build complex SQLAlchemy statements;
- expose ORM objects directly;
- validate Google identity or create/revoke sessions directly;
- catch broad exceptions merely to return a generic response;
- return HTML from `/api/v1`.

Use explicit HTTP methods and status codes. `POST` creation returns `201`; successful deletion may
return `204`; validation returns `422`; state conflict returns `409`. Update OpenAPI in the same
change as any route, payload, response, header, or status change.

## 6. Layer boundaries

### 6.1 Services

Services implement one use case and own its transaction boundary. They MUST:

- receive validated typed input and explicit actor/user identity;
- enforce ownership and business invariants;
- coordinate repositories and related entities;
- calculate authoritative values such as feeding duration;
- raise typed domain exceptions;
- commit exactly once on success when they own a write transaction;
- roll back on failure before translating or re-raising an exception.

Prefer small service functions or focused classes. A service MUST NOT depend on Flask `request`,
`g`, or JSON response construction.

### 6.2 Repositories

Repositories encapsulate reusable persistence queries. They MAY add, fetch, list, lock, update, and
delete models, but SHOULD NOT commit. They MUST use SQLAlchemy 2 statements:

```python
statement = db.select(Baby).where(Baby.id == baby_id, Baby.user_id == user_id)
baby = db.session.execute(statement).scalar_one_or_none()
```

Do not use legacy `Model.query`. Ownership SHOULD be part of the query predicate so inaccessible
resources are indistinguishable from nonexistent resources where required. Repository methods MUST
not silently broaden user scope.

### 6.3 Models

Models describe persistence and database relationships. They MAY contain small persistence-local
invariants and safe computed properties, but MUST NOT contain HTTP handling, token creation, or
multi-aggregate workflows.

### 6.4 Schemas

Schemas describe transport data. Pydantic models MUST NOT be used as SQLAlchemy models, and ORM
models MUST NOT be returned as API schemas. Explicit mapping prevents accidental exposure of
identity-provider data, token hashes, internal keys, or data belonging to another user.

## 7. Pydantic validation and serialization

Pydantic 2 is the single validation and serialization library for the server. Do not introduce
Marshmallow alongside it unless an ADR replaces this decision.

Organize schemas by resource and purpose:

```text
app/schemas/
|-- common.py
|-- auth.py
|-- babies.py
|-- feedings.py
`-- products.py
```

Use distinct request and response types such as `BabyCreate`, `BabyUpdate`, and `BabyResponse`.
Shared base models SHOULD use a deliberate configuration:

```python
from pydantic import BaseModel, ConfigDict


class RequestSchema(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class ResponseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
```

Rules:

- validate untrusted JSON with `model_validate` or `model_validate_json`;
- reject unknown request fields with `extra="forbid"`;
- add length, range, timezone, enum, and cross-field constraints explicitly;
- distinguish omitted fields from explicit `null`, especially in PATCH requests;
- use `model_fields_set` for partial update semantics;
- never use `model_construct` for request data;
- serialize with `model_dump(mode="json")` or an equivalent centralized helper;
- normalize timestamps to ISO 8601 UTC with `Z` in HTTP responses;
- map `ValidationError` to Problem Details without including raw sensitive input;
- keep business validation in services even when a Pydantic validator offers early feedback.

Pydantic conversion is permissive by default. Apply strict fields or strict validation where
coercion could hide an invalid request. Query and path values may require controlled string
conversion because HTTP transports them as text.

## 8. Database and models

Use Flask-SQLAlchemy as the integration layer and SQLAlchemy 2 typed declarative models. New models
MUST use `Mapped[...]` and `mapped_column(...)` with explicit nullability and relationships.

Every persisted design MUST consider:

- UUID public identifiers;
- `created_at` and `updated_at` where editing exists;
- timezone-aware PostgreSQL timestamps stored in UTC;
- foreign keys and deliberate `ON DELETE` behavior;
- uniqueness, `CHECK` constraints, indexes, and maximum lengths;
- ownership indexes beginning with `user_id` where appropriate;
- archive timestamps for catalog entities and real deletion only where product rules require it.

Do not persist derivable values that can drift. In particular, feeding duration is derived from
`ended_at - started_at` on the server.

Use `db.session.execute(db.select(...))`, `scalar_one_or_none`, and explicit eager-loading choices.
Prevent N+1 behavior in list endpoints. Do not call `db.create_all()` in application startup,
tests intended to validate migrations, or production code. Schema changes use migrations only.

Never serialize ORM instances with `__dict__`. Never expose lazy relationships accidentally.

## 9. Transactions and concurrency

The service layer owns write transactions. A normal command performs validation and ownership
checks, mutates all necessary models, flushes when generated values or constraint feedback are
needed, and commits once.

Rules:

- repositories do not commit independently;
- rollback after expected database exceptions before raising a domain error;
- translate known integrity violations to stable `409` or `422` domain errors;
- do not expose SQL, constraint internals, or driver messages to clients;
- use database constraints as the final defense against races;
- use row locks or optimistic concurrency only when a documented race requires them;
- make retryable commands idempotent where required by the contract.

Finishing a feeding is idempotent: the same `ended_at` returns the resource, while an incompatible
second value is a conflict. The unique partial index for an active feeding is authoritative under
concurrency.

## 10. Migrations

Flask-Migrate/Alembic is the only schema evolution mechanism. Every model change that affects
persistence MUST include a migration in the same increment.

Workflow:

```powershell
cd server
python -m flask --app wsgi db migrate -m "describe change"
python -m flask --app wsgi db upgrade
python -m flask --app wsgi db downgrade
python -m flask --app wsgi db upgrade
```

Autogenerated migrations are drafts. Agents MUST review identifiers, types, defaults, indexes,
constraint names, foreign keys, and downgrade behavior. Rename operations often require manual
editing. Commit migration files and never rewrite a migration already applied in shared
environments; create a corrective migration.

Production changes follow expand/contract:

1. add a backward-compatible schema;
2. deploy code compatible with old and new states;
3. backfill separately and observably;
4. enforce or remove old structures in a later release.

Migrations run as a pre-deploy task, never while importing or serving the application. Destructive
migrations require a backup, rollback plan, and explicit review.

## 11. Configuration and python-dotenv

Configuration flows from environment variables into typed or validated Flask configuration
classes. Supported environments are `development`, `testing`, and `production`; unknown names MUST
fail explicitly rather than silently selecting development.

`python-dotenv` is for local convenience. The local `.env` file:

- MUST be ignored by Git;
- MUST be based on `.env.example`;
- MUST NOT override already-defined environment variables;
- MUST NOT be required in CI, staging, or production;
- MUST NOT be logged or returned by diagnostics.

Flask's CLI may load `.env` through python-dotenv automatically. If the application calls
`load_dotenv`, do so once before reading environment-backed module values and use
`override=False`. Do not scatter `load_dotenv` across modules.

At minimum validate:

- `DATABASE_URL`;
- `SECRET_KEY`;
- `JWT_SECRET_KEY`;
- `FRONTEND_ORIGINS`;
- access token lifetime;
- opaque refresh session lifetime;
- cookie security, domain, path, and SameSite policy;
- environment and log level.

Production MUST reject placeholder secrets, wildcard origins, debug mode, insecure cookies, and
missing required settings. Secrets must be independent, high entropy, and different per
environment.

## 12. Authentication and authorization

Authentication follows `ADR-002`. Flask-JWT-Extended is responsible for short-lived **access
JWTs** and protection of bearer-authenticated routes. The accepted refresh mechanism remains an
**opaque rotating token**, not a refresh JWT, because only its hash is persisted and token-family
reuse must be detectable.

### 12.1 Extension setup

Create one unbound `JWTManager` in `app/extensions.py` and initialize it in the factory. Configure
access tokens to be accepted only from the `Authorization: Bearer` header. Do not accept JWTs from
query strings or JSON bodies. Register callbacks centrally for:

- missing token;
- invalid token;
- expired token;
- revoked token;
- user lookup failure when automatic user loading is used.

Every callback MUST return the same Problem Details structure as the global error system.

Access JWT requirements:

- short configurable lifetime, initially 15 minutes;
- stable string user UUID in `sub`;
- unique `jti`;
- explicit issuer and audience when deployment topology is finalized;
- minimal claims with no email, display name, notes, or sensitive profile data;
- secret or signing key distinct from Flask `SECRET_KEY`;
- no access token persistence in the browser beyond memory.

### 12.2 Opaque refresh sessions

Generate refresh tokens with a cryptographically secure random generator. Return the raw value
only in an `HttpOnly`, `Secure`, `SameSite=None` production cookie with the narrowest practical
path. Store only a keyed hash/digest plus session metadata:

- session and user IDs;
- token family ID;
- expiration;
- creation, last use, revocation, and replacement timestamps;
- safe technical metadata only when justified.

Rotate the token atomically on every refresh. Reuse of a replaced token MUST revoke the affected
family. Logout revokes the current session and clears the cookie. Account deactivation, identity
unlinking, or suspected compromise MUST support revoking all user sessions.

Refresh and logout require explicit CSRF protection because the browser sends the cookie
automatically. CORS MUST allow credentials only for exact configured client origins. Never log raw
JWTs, Google credentials, refresh tokens, CSRF values, or authorization headers.

### 12.3 Google identity and authorization

- Follow ADR-003 and validate Google OpenID Connect evidence only on the server.
- Request only `openid`, `email`, and `profile` scopes.
- Link internal accounts by verified `(issuer, subject)`, never by email alone.
- Do not store Google credentials or implement local passwords in the MVP.
- Apply rate limits to Google sign-in, refresh, and logout.
- Use generic authentication failures that avoid unnecessary account disclosure.
- Require ownership in every repository query for user data.
- Prefer `404` over revealing the existence of another user's resource.
- Never rely on UUID unpredictability as authorization.
- Keep authentication (who) distinct from authorization (may this actor access this resource).

`@jwt_required()` is necessary but never sufficient for routes operating on owned resources.

## 13. Global error handling

All API errors use `application/problem+json` and a stable RFC 9457-inspired shape:

```json
{
  "type": "https://breastfeeding-counter.example/problems/validation-error",
  "title": "Invalid data",
  "status": 422,
  "detail": "Review the indicated fields.",
  "instance": "/api/v1/feedings",
  "errors": {
    "started_at": ["Must not be in the future."]
  },
  "request_id": "01..."
}
```

Define a typed domain exception hierarchy carrying safe public fields:

```text
AppError
|-- ValidationProblem      422
|-- AuthenticationProblem 401
|-- AuthorizationProblem  403
|-- NotFoundProblem       404
|-- ConflictProblem       409
`-- RateLimitProblem      429
```

Register handlers on the Flask application, not only on a blueprint, so router-level 404 and 405
errors are JSON. Handlers MUST cover:

- domain `AppError`;
- Pydantic `ValidationError`;
- Werkzeug `HTTPException` while preserving its status and allowed-method headers;
- known SQLAlchemy exceptions after rollback;
- Flask-JWT-Extended callbacks;
- unexpected `Exception` as a final boundary.

The unexpected-error handler MUST log the exception server-side with `request_id` and return a
generic 500 without class names, stack traces, SQL, configuration, or input payloads. In testing,
unexpected exceptions MAY propagate when explicitly configured so defects remain visible.

Error responses MUST:

- set the HTTP status explicitly;
- set `Content-Type: application/problem+json`;
- include the current request ID;
- use stable machine-readable `type` values;
- localize user-facing text later without changing error identity;
- include field errors only for safe validation details;
- never include Google credentials, tokens, notes, emails, or raw submitted objects.

## 14. Type hints and static analysis

Every function and method, including nested Flask hooks, route handlers, fixtures, callbacks, and
migration helpers, MUST declare parameter and return types. Use `from __future__ import annotations`
for consistent modern annotations.

Rules:

- avoid `Any`; use `object`, `Mapping[str, object]`, protocols, generics, or concrete types;
- contain unavoidable framework `Any` at small adapter boundaries;
- use typed SQLAlchemy `Mapped` attributes;
- use Pydantic models or dataclasses for structured service input/output;
- use `Protocol` for replaceable collaborators when useful;
- use `Never`/`assert_never` for exhaustive enums when appropriate;
- do not suppress mypy globally to fix one integration;
- every `type: ignore` requires a narrow error code and explanation;
- avoid returning heterogeneous untyped Flask tuples from service code.

Mypy MUST retain at least:

- `disallow_untyped_defs = true`;
- `check_untyped_defs = true`;
- `no_implicit_optional = true`;
- `warn_return_any = true`;
- `warn_unused_ignores = true`;
- `warn_redundant_casts = true`.

Strengthen strictness incrementally. Third-party missing-stub overrides MUST list exact modules and
must not hide application packages.

## 15. Security and privacy

This application processes personal and potentially sensitive data. Agents MUST apply:

- least-privilege data access and explicit ownership filters;
- parameterized SQLAlchemy statements;
- request size and field length limits;
- exact CORS origins, methods, and headers;
- TLS and secure cookies in production;
- security headers configured centrally;
- rate limiting for abuse-prone endpoints;
- constant-time comparison for secret token digests;
- secure random generation from `secrets`;
- dependency and static analysis in CI;
- redaction of private data from logs and monitoring.

Do not log complete payloads. Do not expose medical advice, diagnoses, or judgments. Do not add
administrative access to private records as a shortcut for debugging.

## 16. Observability

Every request receives or generates a validated request ID and returns it as `X-Request-ID`.
Structured production logs SHOULD include timestamp, severity, environment, app version, request
ID, method, route template, status, and duration.

Logs MUST NOT include tokens, cookies, Google credentials, authorization headers, email addresses, baby
names, feeding notes, product notes, or full payloads. Prefer stable event names and internal
non-sensitive identifiers only when necessary.

Health endpoints:

- `/api/v1/health/live` confirms process liveness and performs no dependency call;
- `/api/v1/health/ready` performs a bounded database readiness check;
- neither endpoint reveals configuration, versions of vulnerable components, credentials, or
  detailed database errors.

Expected domain errors are not logged as server faults. Unexpected failures are logged once at the
global boundary with exception information and request ID.

## 17. Testing strategy

Use pytest with application and database fixtures built through `create_app`. Tests MUST use
synthetic data and independent state.

### 17.1 Unit tests

Unit-test services, pure rules, schema validators, token helpers, and error mapping without network
access. Mock repository protocols rather than Flask internals. Cover success, boundary, conflict,
ownership denial, and rollback behavior.

### 17.2 Integration tests

Integration tests exercise the Flask test client, registered blueprints, Pydantic validation,
authentication callbacks, SQLAlchemy, migrations, and PostgreSQL constraints. SQLite MAY support
fast isolated tests but MUST NOT be the only database for behavior relying on PostgreSQL UUID,
timezone, locking, partial indexes, or constraints.

At minimum test:

- the app factory in each configuration mode;
- live and ready health behavior;
- valid and invalid request schemas;
- every documented status and Problem Details content type;
- access token missing, invalid, expired, and valid cases;
- refresh rotation, reuse detection, CSRF, logout, and revocation;
- cross-user isolation for every owned resource;
- migration from an empty PostgreSQL database to head;
- transaction rollback after domain and integrity errors;
- idempotent feeding completion and active-session race protection.

A bug fix MUST include a regression test that fails before the fix. Tests MUST NOT depend on order,
real time, real external services, or shared user data. Freeze or inject clocks and generators where
determinism matters.

Coverage is branch-aware and MUST remain at or above the configured 85% project threshold. Do not
lower coverage to merge a change. Authentication, authorization, session rotation, destructive
operations, and transaction logic SHOULD receive substantially higher direct coverage.

## 18. GitHub Actions quality gates

The `server-quality` job is required for pull requests and pushes to `main`. It MUST:

1. check out the exact commit;
2. install Python from the repository version policy;
3. cache using the locked dependency file;
4. install locked dependencies and the local package without resolving new versions;
5. start an isolated PostgreSQL service container and wait for readiness;
6. run `ruff format --check`;
7. run `ruff check`;
8. run mypy on application code and typed tests where configured;
9. apply all migrations to an empty database;
10. run pytest with branch coverage and the enforced threshold;
11. validate `docs/openapi.yaml`;
12. upload only synthetic coverage artifacts with bounded retention.

Required checks MUST NOT use `continue-on-error`. Workflows MUST use least-privilege permissions,
explicit timeouts, concurrency cancellation, and full commit SHA pins for third-party actions.

The dependency audit MUST include the locked Python runtime dependencies. Dependabot monitors pip
and GitHub Actions. Deployment jobs depend on successful CI and deploy the exact validated commit.
Forked pull requests MUST NOT receive deployment secrets.

Local verification interface:

```powershell
cd server
python -m ruff format --check .
python -m ruff check .
python -m mypy app
python -m flask --app wsgi db upgrade
python -m pytest --cov=app --cov-branch --cov-report=term-missing
openapi-spec-validator ../docs/openapi.yaml
```

## 19. Agent workflow

### Before implementation

1. Read this file, `server_history.md`, relevant ADRs, and `docs/openapi.yaml`.
2. Inspect the affected routes, services, repositories, models, schemas, migrations, and tests.
3. Confirm the actual dependencies and versions in the lockfiles.
4. Identify actor, ownership boundary, invariants, transaction boundary, errors, and audit needs.
5. Plan the smallest vertical increment, including migration, contract, and tests.
6. Confirm whether target dependencies such as Pydantic and Flask-JWT-Extended are installed.

### During implementation

1. Keep routes thin and services independent of Flask request globals.
2. Validate all input at the boundary and again enforce business invariants in services.
3. Include ownership in data access.
4. Commit once per service transaction and translate only known failures.
5. Add tests with the behavior, not after it.
6. Update OpenAPI and migrations in the same increment.
7. Keep logs, fixtures, and exceptions free of private data.

### Before completion

1. Run Ruff formatting and linting, mypy, migration checks, pytest coverage, and OpenAPI validation.
2. Review the diff for secrets, missing ownership, broad exception handling, `Any`, legacy queries,
   accidental commits in repositories, and sensitive logs.
3. Exercise both success and failure responses through the Flask test client.
4. Update `server_history.md` in English with a unique numeric ID, details, and pending issues.
5. Update root `history.md` when the work constitutes a project milestone.
6. Report exactly which checks passed and which could not run.

## 20. Definition of done

A server increment is complete only when:

- route, service, repository, model, and schema responsibilities remain separated;
- every function and method is typed and mypy passes;
- input and output use Pydantic schemas without exposing ORM internals;
- ownership and authorization are enforced server-side;
- transaction, concurrency, and rollback behavior are explicit;
- schema changes include a reviewed migration;
- OpenAPI matches the implemented HTTP behavior;
- all errors use safe, structured Problem Details JSON;
- authentication changes preserve ADR-002, rotation, CSRF, and revocation behavior;
- no secrets or personal data appear in logs, fixtures, artifacts, or error responses;
- unit, integration, regression, migration, and applicable E2E tests pass;
- Ruff, mypy, coverage, OpenAPI validation, and dependency audits pass;
- implementation history is updated and pending issues are explicit;
- no unexplained TODO, skipped test, warning, or architectural exception remains.

## 21. Primary references

- Flask Application Factories: https://flask.palletsprojects.com/en/stable/patterns/appfactories/
- Flask Blueprints: https://flask.palletsprojects.com/en/stable/blueprints/
- Flask error handling: https://flask.palletsprojects.com/en/stable/errorhandling/
- Flask-SQLAlchemy quick start: https://flask-sqlalchemy.palletsprojects.com/en/stable/quickstart/
- Flask-Migrate: https://flask-migrate.readthedocs.io/en/latest/
- Pydantic models: https://docs.pydantic.dev/latest/concepts/models/
- Pydantic strict mode: https://docs.pydantic.dev/latest/concepts/strict_mode/
- Flask-JWT-Extended: https://flask-jwt-extended.readthedocs.io/en/stable/
- Flask-JWT-Extended token locations: https://flask-jwt-extended.readthedocs.io/en/stable/token_locations.html
- python-dotenv: https://pypi.org/project/python-dotenv/
