# Breastfeeding Counter — MVP Backlog

## 1. Purpose

This document is the implementation backlog for the MVP described in `prd.md`. It translates the
product requirements and the client/server technical definitions into Jira-style epics and tickets.
Agents must read this file together with:

- `prd.md`
- `client/technical-definition.md`
- `server/technical_definition.md`
- `docs/openapi.yaml`
- `.codex/skills/init1-project/references/data-and-api.md`
- `.codex/skills/init1-project/references/implementation-roadmap.md`

The backlog is ordered by dependency and milestone. It does not replace the PRD, OpenAPI contract,
ADRs, or technical definitions. If they conflict, resolve the discrepancy before implementation and
record the decision in an ADR when it changes architecture, security, or a public contract.

## 2. Jira conventions

### Ticket fields

- **ID:** stable key in the `BFC-*` namespace.
- **Type:** Epic, Story, Task, Spike, or Bug.
- **Status:** Backlog, Ready, In Progress, Blocked, In Review, or Done.
- **Priority:** Highest, High, Medium, or Low.
- **Estimate:** Fibonacci story points. Re-estimate during refinement if necessary.
- **Milestone:** H0 Foundation, H1 Identity and profiles, H2 Complete feeding, H3 Products, or
  H4 Beta readiness.
- **Dependencies:** tickets that must be Done, or contracts that must be agreed, first.
- **References:** PRD requirements and relevant technical sources.

All tickets start in **Backlog**. Before moving one to **Ready**, verify its dependencies, refine any
open product decision, and confirm that the repository has not already implemented part of its scope.

### Global Definition of Ready

A ticket is Ready when its user outcome and acceptance criteria are unambiguous, its API and data
impact are identified, dependencies are available, test data can be synthetic, and no unresolved
decision would change its solution materially.

### Global Definition of Done

A ticket is Done only when:

- Its acceptance criteria and relevant empty, loading, error, retry, and success states work.
- Server input is validated with Pydantic, authorization is enforced by resource ownership, and
  transactions belong to the service layer.
- Database changes include a reviewed Alembic migration, PostgreSQL constraints/indexes, and a
  tested upgrade path. Schema changes are never applied with `create_all()`.
- HTTP changes update and validate `docs/openapi.yaml`; generated client types are current.
- Client changes use strict TypeScript, accessible shadcn/ui primitives and design tokens, and do not
  use `any`, duplicated server state, or direct ad-hoc `fetch` calls.
- Unit/component tests cover business behavior; PostgreSQL integration tests cover persistence and
  concurrency where relevant; Cypress covers altered critical journeys.
- Ruff, mypy, pytest with coverage, ESLint, TypeScript, Vitest with coverage, build, OpenAPI validation,
  security checks, and applicable Cypress tests pass in GitHub Actions.
- Mobile use, keyboard use, screen readers, 200% zoom, and 44 x 44 CSS pixel touch targets have been
  considered. Copy is calm, concise, and does not imply medical guidance.
- No secrets or sensitive user data appear in logs, analytics, fixtures, screenshots, or artifacts.
- Implementation memory is updated in English in `client/client-history.md` and/or
  `server/server_history.md`; project milestones are indexed in `history.md`.

## 3. Backlog overview

| Epic | Name | Milestone | Outcome |
|---|---|---|---|
| BFC-E00 | Engineering foundation | H0 | Reproducible, typed, tested client/server platform |
| BFC-E01 | Google authentication and sessions | H1 | Secure Google-only account access and session lifecycle |
| BFC-E02 | Profile and babies | H1 | A mother can manage her profile and only her babies |
| BFC-E03 | Breastfeeding sessions | H2 | Fast, recoverable, accurate breast feeding registration |
| BFC-E04 | Product catalog and usage | H3 | Personal products and product usage can be recorded safely |
| BFC-E05 | History | H2-H3 | Stable chronological review and correction of activity |
| BFC-E06 | Dashboard | H2-H3 | Useful daily summary in the user's timezone |
| BFC-E07 | Privacy and account controls | H4 | Export and deletion rights are usable and verifiable |
| BFC-E08 | Security, accessibility, and observability | H4 | Beta quality and operational safeguards are measurable |
| BFC-E09 | Delivery and beta release | H4 | Reproducible staging/production delivery and launch evidence |

---

## BFC-E00 — Engineering foundation

**Type:** Epic  
**Status:** Backlog  
**Priority:** Highest  
**Milestone:** H0 Foundation  
**Objective:** Complete and validate the existing H0 baseline so every vertical feature can be built
with the required architecture, strict types, automated tests, and CI gates.  
**Exit criteria:** A clean clone can be configured, migrated, linted, typed, tested, built, and run
locally; CI enforces the same commands.

### BFC-001 — Audit and lock the MVP dependency baseline

**Type:** Task | **Priority:** Highest | **Estimate:** 2 | **Dependencies:** None  
**References:** Client definition §§2-3; server definition §§2-3; H0  
**Description:** Compare installed dependencies and lockfiles with the approved MVP stack. Add only
missing required packages, including Pydantic v2, Flask-JWT-Extended, shadcn/ui prerequisites,
React Hook Form, Zod, Cypress, and supporting test tooling. Pin runtime versions through
`.nvmrc`, `package.json`, `.python-version`, and reproducible lock files.

**Acceptance criteria:**

- `npm ci` and the documented Python locked installation work from a clean environment.
- Runtime and tooling versions are consistent locally and in CI.
- Dependency changes contain no unused alternative framework or authentication library.

### BFC-002 — Initialize the client design system with shadcn/ui

**Type:** Story | **Priority:** High | **Estimate:** 3 | **Dependencies:** BFC-001  
**References:** Client definition §§4-5, 12; PRD UX and accessibility requirements  
**Description:** Configure Tailwind CSS, `components.json`, the `@/*` alias, `cn()` utility,
CSS-variable design tokens, Lucide icons, and the initial accessible primitives needed by the MVP.
Keep generated primitives in `src/components/ui` and composed product components elsewhere.

**Acceptance criteria:**

- Light and dark token sets provide WCAG 2.2 AA-compatible contrast for core states.
- Button, input, label, dialog, toast, card, select, and confirmation patterns render in Story/demo
  coverage without handwritten duplicate primitives.
- The production build resolves aliases and purges/styles Tailwind correctly.

### BFC-003 — Enforce strict TypeScript project boundaries

**Type:** Task | **Priority:** High | **Estimate:** 3 | **Dependencies:** BFC-001  
**References:** Client definition §6  
**Description:** Separate app, Node/tooling, test, and Cypress TypeScript configurations. Enable the
strict flags defined by the client technical definition and scope environment types to the correct
project.

**Acceptance criteria:**

- `npm run typecheck` validates all TypeScript projects with no `any` escape hatch.
- Production code does not receive Vitest, Node, or Cypress globals accidentally.
- CI fails on unused code, unchecked indexed access, invalid overrides, or unsafe catch handling.

### BFC-004 — Establish typed API validation and Problem Details

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-001  
**References:** Server definition §§4-9; data/API §§3, 6  
**Description:** Add Pydantic v2 request/response schemas, shared pagination types, an exception
taxonomy, and the global `application/problem+json` handler. Keep routes thin and map expected
validation, domain, authentication, conflict, and not-found failures consistently.

**Acceptance criteria:**

- Request models reject unknown fields and return field-level 422 errors with `request_id`.
- Expected 400/401/403/404/409/422/429 errors follow the documented Problem Details shape.
- Unexpected failures return a generic 500 response and are logged once without payloads or secrets.
- Representative schema and error mappings have unit and API integration tests.

### BFC-005 — Make OpenAPI the executable client/server contract

**Type:** Task | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-003, BFC-004  
**References:** Client definition §§7-8, 11; server definition §§8-9, 16; data/API §7  
**Description:** Complete OpenAPI schemas for implemented endpoints, validate the document, generate
strict client DTO types, and add the centralized HTTP client plus TanStack Query provider. The client
must normalize JSON, Problem Details, credentials, cancellation, and access token injection.

**Acceptance criteria:**

- Contract validation and a generated-types drift check run with stable commands.
- Feature code imports generated DTOs and calls the centralized client rather than raw `fetch`.
- Access tokens remain in memory and cookie-authenticated requests use the documented credentials.
- A mocked success and Problem Details failure are covered in client tests.

### BFC-006 — Build deterministic client and server test foundations

**Type:** Task | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-001, BFC-004  
**References:** Client definition §§9-10; server definition §15  
**Description:** Provide reusable pytest factories, isolated PostgreSQL integration fixtures, RTL
custom render helpers, MSW handlers, and Cypress configuration. Add a testing-only reset/seed path
that cannot be enabled in production and supports fake Google identity verification.

**Acceptance criteria:**

- Unit tests do not require PostgreSQL; integration tests use PostgreSQL and isolate state.
- RTL tests use semantic queries and user events; no component test calls a real API.
- Cypress can seed deterministic synthetic users/babies and reset them between specs.
- The reset/seed mechanism fails closed outside the test environment.

### BFC-007 — Enforce the complete GitHub Actions quality pipeline

**Type:** Task | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-003, BFC-005, BFC-006  
**References:** Client definition §11; server definition §16; delivery/operations §3  
**Description:** Extend CI with `client-quality`, `server-quality`, `contract`, `security`, and `e2e`
jobs, path-aware triggers that preserve root checks, concurrency cancellation, coverage thresholds,
PostgreSQL services, cached deterministic installs, and SHA-pinned third-party actions.

**Acceptance criteria:**

- Pull requests cannot pass with formatting, lint, type, test, coverage, build, contract, or security
  failures.
- Client coverage is at least 80% for lines/statements/functions and 75% for branches; server coverage
  is at least 85%.
- Cypress artifacts are uploaded only on failure and contain synthetic data.
- Dependabot covers npm, Python, and GitHub Actions dependencies.

### BFC-008 — Validate one-command local development

**Type:** Task | **Priority:** Medium | **Estimate:** 2 | **Dependencies:** BFC-001, BFC-006  
**References:** H0; `run-all` skill; delivery/operations §2  
**Description:** Verify and document stable root commands for setup, PostgreSQL, migrations, client,
server, tests, linting, and shutdown on Windows. Keep `.env.example` files complete and secret-free.

**Acceptance criteria:**

- A clean-clone rehearsal reaches healthy API, migrated PostgreSQL, and Vite without manual repair.
- Live and readiness checks distinguish process health from database availability.
- Shutdown is safe, repeatable, and does not remove developer data unless explicitly requested.

---

## BFC-E01 — Google authentication and sessions

**Type:** Epic  
**Status:** Backlog  
**Priority:** Highest  
**Milestone:** H1 Identity and profiles  
**Objective:** Let a person create or recover an internal account through Google Identity only, with
secure short-lived access and rotating refresh sessions.  
**Exit criteria:** Login, refresh, reload recovery, logout, expiry, and refresh-token reuse behavior
are covered without storing access tokens persistently or exposing Google credentials.

### BFC-101 — Finalize the Google Identity contract and environment configuration

**Type:** Spike | **Priority:** Highest | **Estimate:** 3 | **Dependencies:** BFC-004  
**References:** AUTH-001 to AUTH-003; ADR-002; ADR-003  
**Description:** Confirm the Google Identity Services client flow, allowed origins, client IDs per
environment, server-side issuer/audience/nonce validation, minimal scopes, and the exact
`POST /api/v1/auth/google` request/response contract. Record any contract change in OpenAPI/ADR.

**Acceptance criteria:**

- Only `openid`, `email`, and `profile` scopes are requested.
- No Google client secret or refresh token is shipped to or stored by the SPA.
- Local, staging, and production configuration requirements and ownership are documented.

### BFC-102 — Persist users, external identities, and refresh sessions

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-101  
**References:** AUTH-002 to AUTH-008; data/API §2; server definition §§5-7, 11  
**Description:** Add typed SQLAlchemy models and Alembic migrations for users, Google external
identities, refresh-token families/rotations, expiry, and revocation. Store only token hashes and
link identity by `(issuer, subject)`, never by email alone.

**Acceptance criteria:**

- UUIDs, UTC timestamps, foreign keys, uniqueness constraints, and lookup indexes exist in PostgreSQL.
- A verified email is contact information and cannot silently merge two identities.
- Migration upgrade is tested against PostgreSQL and downgrade limitations are documented.

### BFC-103 — Implement Google credential exchange and account provisioning

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-101, BFC-102  
**References:** AUTH-001 to AUTH-003  
**Description:** Create a replaceable Google verifier boundary, authentication service, repository
operations, and thin `/auth/google` route. Validate the proof server-side, require verified email,
and atomically create or retrieve the internal account and identity.

**Acceptance criteria:**

- Valid first login creates one user and identity; subsequent login retrieves the same account.
- Invalid issuer, audience, signature, expiry, nonce/state, or unverified email is rejected safely.
- Concurrent first login cannot create duplicate identities.
- Tests replace the verifier; they never call real Google services.

### BFC-104 — Issue and authorize short-lived access JWTs

**Type:** Story | **Priority:** Highest | **Estimate:** 3 | **Dependencies:** BFC-103  
**References:** AUTH-004, AUTH-005; server definition §11  
**Description:** Integrate Flask-JWT-Extended for access JWT creation and protected-route identity.
Use minimal claims, short configurable expiry, Authorization headers only, and common authorization
helpers that load ownership through repositories.

**Acceptance criteria:**

- Protected endpoints reject absent, invalid, and expired access tokens with Problem Details.
- Access JWTs are accepted only through `Authorization: Bearer` and contain no sensitive profile data.
- Authentication and authorization failures are distinct internally without leaking resource existence.

### BFC-105 — Rotate refresh tokens with CSRF and reuse detection

**Type:** Story | **Priority:** Highest | **Estimate:** 8 | **Dependencies:** BFC-102, BFC-104  
**References:** AUTH-004 to AUTH-008; server definition §11; data/API §3  
**Description:** Implement `/auth/refresh` with opaque high-entropy refresh tokens in Secure,
HttpOnly cookies, double-submit CSRF protection, atomic one-time rotation, family tracking, and reuse
detection that revokes the affected family.

**Acceptance criteria:**

- Successful refresh invalidates the previous hash and produces a new cookie/access pair atomically.
- Missing/invalid CSRF, expired/revoked token, or cookie misuse returns the documented error.
- Reuse of a rotated token revokes its family and prevents further refresh.
- Concurrency and cookie attributes are verified by PostgreSQL integration tests.

### BFC-106 — Implement logout and session revocation semantics

**Type:** Story | **Priority:** High | **Estimate:** 3 | **Dependencies:** BFC-105  
**References:** AUTH-006 to AUTH-008  
**Description:** Implement `/auth/logout` to revoke the current refresh session, clear the cookie,
and support safe repeat calls. Define the service operation needed to revoke all sessions during
account deletion or a security event.

**Acceptance criteria:**

- Logout requires CSRF, clears the cookie with matching attributes, and is idempotent.
- A revoked session cannot refresh even if the old cookie is replayed.
- Revoking all user sessions is transactional and integration-tested.

### BFC-107 — Build the client authentication lifecycle

**Type:** Story | **Priority:** Highest | **Estimate:** 8 | **Dependencies:** BFC-005, BFC-103 to BFC-106  
**References:** AUTH-001, AUTH-004 to AUTH-008; client definition §§7-8  
**Description:** Add Google sign-in UI, in-memory auth state, startup refresh, protected-route guard,
centralized single-flight refresh, logout, expiry handling, and calm recoverable error states. Never
store access tokens in local/session storage or IndexedDB.

**Acceptance criteria:**

- A successful Google sign-in reaches onboarding or the authenticated home as appropriate.
- Reload restores a valid session through the refresh cookie without flashing protected content.
- Concurrent 401 responses trigger at most one refresh attempt and retry eligible requests once.
- Login, reload recovery, expiry, and logout have RTL/MSW coverage and a fake-Google Cypress journey.

---

## BFC-E02 — Profile and babies

**Type:** Epic  
**Status:** Backlog  
**Priority:** Highest  
**Milestone:** H1 Identity and profiles  
**Objective:** Give an authenticated mother a timezone-aware profile and isolated baby records.  
**Exit criteria:** A user can complete onboarding and create, view, edit, select, and safely archive
only her own babies.

### BFC-201 — Implement profile read and update

**Type:** Story | **Priority:** High | **Estimate:** 3 | **Dependencies:** BFC-104  
**References:** AUTH-003; SUM-002; `GET/PATCH /me`  
**Description:** Implement typed repository/service/routes for `GET /me` and `PATCH /me`, including
display name and validated IANA timezone. Treat PATCH omitted fields differently from explicit nulls.

**Acceptance criteria:**

- The response exposes only the authenticated user's public profile fields.
- Invalid timezone, unknown fields, and invalid nulls produce field-level 422 errors.
- Day-boundary consumers receive a canonical IANA timezone value.

### BFC-202 — Create the baby persistence model and migration

**Type:** Story | **Priority:** Highest | **Estimate:** 3 | **Dependencies:** BFC-102  
**References:** BABY-001 to BABY-007; data/API §2  
**Description:** Add the typed baby model with owner, name, optional non-future birth date,
archive timestamp, UTC audit timestamps, constraints, and owner/archive index.

**Acceptance criteria:**

- PostgreSQL prevents invalid ownership and schema-level violations where appropriate.
- Archive state preserves the row and future historical references.
- Migration and model behavior have PostgreSQL integration coverage.

### BFC-203 — Implement owner-scoped baby API

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-201, BFC-202  
**References:** BABY-001 to BABY-007; `/babies` endpoints  
**Description:** Implement list/create/detail/update/archive through routes, services, and repositories.
Use 404 for resources outside the authenticated user's ownership and default list results to active
babies.

**Acceptance criteria:**

- Name is trimmed/validated and birth date cannot be in the future.
- Users cannot read, mutate, or infer babies owned by another account.
- Archive is idempotent and a baby with an active feeding cannot be archived.
- OpenAPI documents request, response, filter, and error behavior.

### BFC-204 — Build first-run onboarding

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-107, BFC-201, BFC-203  
**References:** Critical journey A; BABY-001, BABY-002  
**Description:** After first login, guide the user through confirming profile/timezone and creating the
first baby with the fewest required fields. Preserve valid input after recoverable failures.

**Acceptance criteria:**

- A user with no active baby is routed to onboarding and cannot land in an unusable dashboard.
- The flow is usable at 320 CSS pixels, by keyboard, and with a screen reader.
- Success selects the new baby and reaches the home screen; retry does not duplicate records.

### BFC-205 — Build baby management and active-baby selection

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-203, BFC-204  
**References:** BABY-003 to BABY-007  
**Description:** Add active-baby selector, list, edit, and archive confirmation UI using Query keys by
user/baby and targeted invalidation. Archived babies remain available in historical contexts but
cannot receive new records.

**Acceptance criteria:**

- Switching baby updates all baby-scoped screens without stale cross-baby data.
- Destructive/archive actions require clear confirmation and explain active-feeding conflicts.
- RTL tests cover empty, validation, conflict, success, and cache update behavior.
- Cypress proves two users cannot access each other's baby and covers create/edit/archive.

---

## BFC-E03 — Breastfeeding sessions

**Type:** Epic  
**Status:** Backlog  
**Priority:** Highest  
**Milestone:** H2 Complete feeding  
**Objective:** Make direct breastfeeding registration fast, recoverable after reload, editable, and
accurate under retries and concurrency.  
**Exit criteria:** Start, recover, finish, manually create, edit, delete, and list flows work with one
active feeding per user/baby and server-derived duration.

### BFC-301 — Create feeding persistence and invariants

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-203  
**References:** FEED-001 to FEED-012; data/API §§2, 5  
**Description:** Add typed feeding model and migration for owner, baby, UTC start/end, side, notes,
and timestamps. Enforce `ended_at >= started_at`, owner/baby indexes, and a unique partial active
session index. Do not persist duration.

**Acceptance criteria:**

- PostgreSQL rejects a second active feeding for the same user/baby under concurrent writes.
- Duration is derived from timestamps and serialized consistently.
- Ownership, future-time tolerance, note length, and configurable maximum duration are testable rules.

### BFC-302 — Implement feeding start and active-session recovery API

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-301  
**References:** FEED-001 to FEED-004; `POST/GET /feedings`  
**Description:** Implement the service/repository/route path to start a feeding with selected side and
to retrieve the active feeding through the documented filtered list or explicit contract. Convert the
unique-index collision into a 409 containing enough safe information to recover.

**Acceptance criteria:**

- A start uses server time unless a valid explicit start is part of the contract.
- A second start cannot create a duplicate and returns a documented recoverable conflict.
- Active session retrieval is owner/baby scoped and survives browser reload.

### BFC-303 — Finish a feeding idempotently and safely

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-302  
**References:** FEED-005 to FEED-007; `POST /feedings/{id}/finish`  
**Description:** Implement transactional finish with row locking or equivalent concurrency control.
The server owns duration calculation and distinguishes a repeated identical final time from an
incompatible second finish.

**Acceptance criteria:**

- The first valid finish closes the feeding and returns derived duration.
- Repeating the same finish returns the same resource; a different finish returns 409.
- Finish cannot mutate another user's feeding or create negative/excessive duration.
- Concurrent finish integration tests prove stable idempotent behavior.

### BFC-304 — Implement manual feeding creation

**Type:** Story | **Priority:** High | **Estimate:** 3 | **Dependencies:** BFC-301  
**References:** FEED-008, FEED-009  
**Description:** Support completed past feedings with explicit start/end, side, and optional notes
through the common create endpoint and service rules.

**Acceptance criteria:**

- Future, reversed, excessive, or unauthorized timestamps are rejected, never silently corrected.
- Manual creation cannot violate the active-session constraint.
- Date/time handling is displayed in user timezone and transported with an explicit offset.

### BFC-305 — Implement feeding detail, edit, delete, and paginated list API

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-303, BFC-304  
**References:** FEED-009 to FEED-012; HIST-001 to HIST-003  
**Description:** Complete owner-scoped detail, PATCH, hard delete, and cursor-paginated list services.
Order by `(started_at DESC, id DESC)`, cap limit at 100, and preserve PATCH omitted/null semantics.

**Acceptance criteria:**

- Baby/date filters and stable cursor pagination neither duplicate nor skip unchanged records.
- Edits reapply all temporal rules and update `updated_at`.
- Delete is explicit, removes the feeding, and leaves product usages via `ON DELETE SET NULL`.
- Contract tests cover serialization, authorization, filters, cursors, and errors.

### BFC-306 — Build the quick feeding timer and reload recovery UX

**Type:** Story | **Priority:** Highest | **Estimate:** 8 | **Dependencies:** BFC-205, BFC-302, BFC-303  
**References:** Critical journey B; FEED-001 to FEED-007  
**Description:** Build side selection and prominent start/finish controls, active timer display, and
reload recovery. The displayed elapsed time must derive from server timestamps plus current clock;
no interval tick is persisted as source of truth.

**Acceptance criteria:**

- The critical action is reachable in no more than two primary interactions from home.
- Start is disabled while submitting; retries/conflicts recover the server's active feeding.
- Reload or temporary network loss restores the active state and correct elapsed time.
- Controls meet touch, keyboard, focus, screen-reader, reduced-motion, and zoom requirements.

### BFC-307 — Build manual correction and deletion UX with complete tests

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-305, BFC-306  
**References:** FEED-008 to FEED-012; Critical journey C  
**Description:** Add manual-entry, edit, and confirmed-delete forms using React Hook Form and Zod for
interaction rules while treating server validation as authoritative. Invalidate only affected feeding,
history, and dashboard queries.

**Acceptance criteria:**

- Forms retain input after server errors and focus/announce the first invalid field.
- Successful edits/deletes update detail, history, and summary without full-page reload.
- RTL covers validation and Problem Details; Cypress covers start, reload, finish, edit, and delete.

---

## BFC-E04 — Product catalog and usage

**Type:** Epic  
**Status:** Backlog  
**Priority:** High  
**Milestone:** H3 Products  
**Objective:** Let each user maintain a personal product catalog and quickly register product usage,
optionally connected to a feeding.  
**Exit criteria:** Product records remain account-isolated, archived catalog items preserve history,
and mixed activity is represented without forcing quantity data.

### BFC-401 — Create product and product-usage persistence

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-203, BFC-301  
**References:** PROD-001 to PROD-011; data/API §2  
**Description:** Add typed models/migrations for products and usages with approved category values,
optional positive decimal quantity/unit, optional feeding association, archive timestamps, ownership,
UTC timestamps, indexes, checks, and `ON DELETE SET NULL` from usage to feeding.

**Acceptance criteria:**

- Database constraints preserve valid categories, quantities, ownership relations, and history.
- The service can distinguish quantity omitted from invalid zero/negative quantity.
- Migrations and relationship deletion behavior are integration-tested on PostgreSQL.

### BFC-402 — Implement product catalog API and archive rules

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-401  
**References:** PROD-001 to PROD-005; `/products` endpoints  
**Description:** Implement owner-scoped list, create, detail, update, and idempotent archive through the
defined layers. Default list to active products, support `include_archived`, and prohibit archived
products in new usages while retaining old usages.

**Acceptance criteria:**

- Name, category, brand, and notes validation produce documented responses.
- Cross-account product access returns 404 and cannot be inferred.
- Archive removes the product from quick selection but preserves all historical usage.

### BFC-403 — Implement product-usage API and association rules

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-305, BFC-401, BFC-402  
**References:** PROD-006 to PROD-011; `/product-usages` endpoints  
**Description:** Implement create/list/update/delete services with stable `(used_at DESC, id DESC)`
cursor pagination. Validate that user, product, optional baby context, and optional feeding association
belong together and that the usage time is valid.

**Acceptance criteria:**

- A usage can be saved without quantity and may optionally reference an owned feeding.
- New usages cannot select archived or foreign products/feedings.
- Editing/deleting a usage invalidates summaries/history and obeys owner isolation.
- Pagination, association, and authorization have contract/integration coverage.

### BFC-404 — Build personal product catalog UX

**Type:** Story | **Priority:** Medium | **Estimate:** 5 | **Dependencies:** BFC-205, BFC-402  
**References:** PROD-001 to PROD-005  
**Description:** Add responsive list, create, edit, and archive flows with approved category labels,
clear archived state, confirmation, and query invalidation.

**Acceptance criteria:**

- Empty, loading, retry, validation, success, and archived-filter states are accessible.
- Archived products cannot be selected for new usage but remain identifiable in history.
- RTL tests cover catalog behavior and server conflict/error mapping.

### BFC-405 — Build fast product-usage and mixed-registration UX

**Type:** Story | **Priority:** High | **Estimate:** 8 | **Dependencies:** BFC-306, BFC-403, BFC-404  
**References:** Critical journey D; PROD-006 to PROD-011  
**Description:** Add a low-interaction usage flow from home/history with recent product shortcuts,
optional quantity/unit/notes, editable timestamp, and optional association with the relevant feeding.
Do not force inventory semantics into the MVP.

**Acceptance criteria:**

- A recent product can be recorded without quantity in a few primary interactions.
- Quantity, when supplied, is positive and paired with a valid unit according to the contract.
- Duplicate submit protection and recoverable errors do not create duplicate usages.
- RTL and Cypress cover standalone and feeding-associated usage plus edit/delete.

---

## BFC-E05 — History

**Type:** Epic  
**Status:** Backlog  
**Priority:** High  
**Milestone:** H2 Complete feeding and H3 Products  
**Objective:** Provide a stable chronological account of breast, product, and mixed activity that can
be filtered and corrected.  
**Exit criteria:** Long histories paginate without omissions/duplicates and archived/deleted related
records remain represented according to product rules.

### BFC-501 — Define the unified history projection contract

**Type:** Spike | **Priority:** High | **Estimate:** 3 | **Dependencies:** BFC-305, BFC-403  
**References:** HIST-001 to HIST-005; PRD §10.6  
**Description:** Decide and document how the client receives one chronological breast/product/mixed
timeline. Prefer a server-owned stable projection over merging independent cursors in the client.
Specify event identity, type, timestamps, associations, archived labels, filters, cursor, and detail links
in OpenAPI; add an ADR only if this changes the approved architecture materially.

**Acceptance criteria:**

- One contract supports baby/date filters and stable ordering with a deterministic tie-breaker.
- Mixed activity is represented without duplicating or losing its feeding and usage identities.
- Pagination behavior under newly inserted records and archived products is explicitly tested/designable.

### BFC-502 — Implement the unified history query

**Type:** Story | **Priority:** High | **Estimate:** 8 | **Dependencies:** BFC-501  
**References:** HIST-001 to HIST-005  
**Description:** Implement the owner-scoped repository query, service projection, schemas, and endpoint
defined by BFC-501. Keep SQL in repositories and pagination/domain orchestration in services.

**Acceptance criteria:**

- Results distinguish breast, product, and mixed activity and are ordered newest first.
- Baby/date filters, default/capped limits, cursor errors, and empty pages follow the contract.
- PostgreSQL tests prove stable pagination and strict isolation across users and babies.

### BFC-503 — Build the accessible history timeline and filters

**Type:** Story | **Priority:** High | **Estimate:** 8 | **Dependencies:** BFC-405, BFC-502  
**References:** HIST-001 to HIST-005; Critical journey E  
**Description:** Build mobile-first history with baby/date filters, semantic event labels, incremental
pagination, empty/retry states, and navigation to the correct feeding or usage edit/delete flow.

**Acceptance criteria:**

- Event type is conveyed by text, not color alone; archived product context remains understandable.
- Filter changes reset the cursor and cannot show stale data for the prior baby.
- Loading more retains focus/scroll context and does not duplicate rendered events.
- RTL covers all event variants; Cypress covers filtering, pagination, edit, and delete propagation.

---

## BFC-E06 — Dashboard

**Type:** Epic  
**Status:** Backlog  
**Priority:** High  
**Milestone:** H2 Complete feeding and H3 Products  
**Objective:** Give the user a calm, glanceable home view with the next action and accurate daily
context, without medical recommendations.  
**Exit criteria:** Summary values match persisted data and the user's local day, including DST.

### BFC-601 — Implement timezone-aware dashboard summary API

**Type:** Story | **Priority:** High | **Estimate:** 8 | **Dependencies:** BFC-305, BFC-403  
**References:** SUM-001 to SUM-005; `GET /dashboard/summary`  
**Description:** Implement a service that converts the requested local date in the user's IANA
timezone to UTC bounds and returns last feeding, active feeding, daily count/duration, side distribution,
and recent products for one owned baby.

**Acceptance criteria:**

- DST transitions, UTC offsets, no-data days, active sessions, and corrected/deleted records calculate
  consistently.
- Side totals include the documented handling for `both` and `unspecified`.
- Queries are indexed/bounded and do not load full history into Python.
- Unit tests cover time-boundary rules; PostgreSQL tests cover aggregates and ownership.

### BFC-602 — Build the mobile-first home dashboard

**Type:** Story | **Priority:** High | **Estimate:** 8 | **Dependencies:** BFC-306, BFC-405, BFC-601  
**References:** SUM-001 to SUM-005; PRD UX principles  
**Description:** Compose the selected baby, active/last feeding, primary start/finish action, daily
totals, side distribution, and recent product shortcuts. Use server state through TanStack Query and
derive the live timer locally from server timestamps.

**Acceptance criteria:**

- Primary registration action is visually dominant and usable one-handed on a phone.
- Skeleton, empty, partial-error, retry, offline-like network error, and success states avoid misleading
  zero values.
- The screen contains factual records only and no diagnostic, prescriptive, or medical copy.
- RTL tests validate summaries and active state; Cypress validates dashboard updates after both event types.

---

## BFC-E07 — Privacy and account controls

**Type:** Epic  
**Status:** Backlog  
**Priority:** High  
**Milestone:** H4 Beta readiness  
**Objective:** Give users understandable control over their profile, data export, sessions, and account
deletion.  
**Exit criteria:** Export and deletion are complete, owner-scoped, auditable without sensitive content,
and tested end to end.

### BFC-701 — Implement complete account data export

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-502, BFC-601  
**References:** DATA-001, DATA-002; `GET /me/export`  
**Description:** Define and implement a versioned, machine-readable export containing profile,
babies, feedings, products, and usages with UTC timestamps and relationship identifiers. Stream or
bound memory appropriately and audit only export metadata.

**Acceptance criteria:**

- Export contains all and only the authenticated user's current data and preserved archived history.
- The format/version and timestamp semantics are documented in OpenAPI/user help.
- Logs contain request/user technical IDs and outcome, not exported content or filenames with PII.

### BFC-702 — Implement transactional account deletion

**Type:** Story | **Priority:** Highest | **Estimate:** 8 | **Dependencies:** BFC-106, BFC-701  
**References:** DATA-003, DATA-004; `DELETE /me`  
**Description:** Implement re-authenticated/confirmed account deletion according to the approved
retention policy. Revoke sessions and delete or irreversibly schedule all owned application data in a
verifiable transaction/process; document failure recovery.

**Acceptance criteria:**

- A partial failure cannot leave an active login with ambiguously deleted data.
- All refresh sessions are revoked and cookies cleared on success.
- Repeated requests are safe, cross-user deletion is impossible, and completion can be audited without PII.
- Integration tests verify cascades/retention and failure rollback.

### BFC-703 — Build profile, export, and delete-account UX

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-201, BFC-701, BFC-702  
**References:** DATA-001 to DATA-004; Critical journey F  
**Description:** Add settings for display name/timezone, data export, session logout, and a deliberate
destructive account-deletion flow with explicit consequences and accessible confirmation.

**Acceptance criteria:**

- Export communicates preparation/download failures and supports retry without duplicate side effects.
- Account deletion cannot occur through one accidental tap and requires fresh confirmation.
- Success clears client caches/auth state and cannot navigate back into private data.
- RTL and Cypress cover profile edit, export, cancellation, failed delete, and successful deletion.

---

## BFC-E08 — Security, accessibility, and observability

**Type:** Epic  
**Status:** Backlog  
**Priority:** Highest  
**Milestone:** H4 Beta readiness  
**Objective:** Apply cross-cutting safeguards and produce evidence that the MVP is usable, private,
observable, and resilient enough for beta.  
**Exit criteria:** Security/accessibility audits have no unresolved release-blocking findings and
operational telemetry avoids sensitive content.

### BFC-801 — Apply API and browser security hardening

**Type:** Story | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-107, BFC-703  
**References:** PRD §§13.3-13.6, 16; delivery/operations §§6-7  
**Description:** Add explicit CORS allowlists, secure cookie configuration, rate limiting for Google
login/refresh/export/delete, request-size limits, CSP, HSTS in production, content-type, referrer, and
permissions headers. Validate production configuration at startup without revealing values.

**Acceptance criteria:**

- Wildcard credentialed CORS is impossible and insecure production cookie/config combinations fail fast.
- Rate-limited responses use 429 Problem Details without becoming an account enumeration vector.
- Security headers and auth endpoint limits have automated tests.
- Dependency/static scans have no unaccepted High/Critical finding.

### BFC-802 — Implement privacy-safe observability and request correlation

**Type:** Story | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-004, BFC-801  
**References:** PRD §13.8; delivery/operations §8  
**Description:** Add JSON logs with environment/version/route/status/latency/request ID, safe request-ID
propagation, error monitoring with redaction, health/alert metrics, and technical audit events for login,
export, deletion, and refresh reuse. Select the provider through configuration.

**Acceptance criteria:**

- Automated redaction tests prove email, baby/product names, notes, tokens, cookies, and bodies are absent.
- A client-visible `request_id` can be correlated to one server failure safely.
- Readiness, sustained error rate, failed deployment, DB saturation, and storage alerts have owners/runbook links.

### BFC-803 — Complete the WCAG 2.2 AA and low-attention UX audit

**Type:** Task | **Priority:** Highest | **Estimate:** 8 | **Dependencies:** BFC-503, BFC-602, BFC-703  
**References:** PRD §§7, 13.2, beta criteria 14; client definition §§5, 12  
**Description:** Audit every critical journey at mobile widths, 200% zoom, keyboard-only, common screen
reader semantics, light/dark themes, reduced motion, and impaired/interrupted interaction conditions.
Fix focus, labels, announcements, contrast, target size, error recovery, and calm-copy defects.

**Acceptance criteria:**

- Automated accessibility checks plus a documented manual matrix cover all critical journeys.
- No critical/serious axe finding or keyboard trap remains; focus order and modal restoration are correct.
- Core actions meet 44 x 44 targets and work at 320 CSS pixels and 200% zoom without loss of content.
- No interface text claims medical conclusions or shames the user.

### BFC-804 — Validate performance, compatibility, and failure recovery

**Type:** Task | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-503, BFC-602, BFC-802  
**References:** PRD §§13.1, 13.7; beta criteria 15  
**Description:** Define measurable budgets and test supported current mobile/desktop browsers, slow
networks, API timeout/retry behavior, long histories, and server query performance. Optimize based on
evidence rather than speculative caching.

**Acceptance criteria:**

- Vite chunks, critical interaction latency, API p95 targets, and representative query plans are recorded.
- No unbounded list/query or retry loop exists; cancellation prevents stale response overwrites.
- Critical flows pass in the agreed browser matrix and recover from a transient network/API failure.

### BFC-805 — Decide optional product analytics with privacy gate

**Type:** Spike | **Priority:** Medium | **Estimate:** 2 | **Dependencies:** BFC-803  
**References:** PRD §§6, 13.8, 15  
**Description:** Decide whether MVP product analytics are needed to measure success. If adopted, define
consent/legal basis, event allowlist, retention, provider, and aggregation without names, notes, health
content, stable cross-site identifiers, or raw activity details. Non-essential analytics must not block use.

**Acceptance criteria:**

- The decision and event dictionary or explicit no-analytics choice are recorded.
- Consent and opt-out behavior are testable before any provider script is enabled.
- No analytics implementation starts until privacy/legal review for the launch market is complete.

---

## BFC-E09 — Delivery and beta release

**Type:** Epic  
**Status:** Backlog  
**Priority:** Highest  
**Milestone:** H4 Beta readiness  
**Objective:** Deploy the same tested commit reproducibly to isolated staging and production, protect
data with backups/runbooks, and produce beta acceptance evidence.  
**Exit criteria:** A manually approved production release can be rolled back operationally, backup
restoration has been rehearsed, and all PRD beta criteria pass.

### BFC-901 — Provision isolated staging on Vercel and Render

**Type:** Task | **Priority:** High | **Estimate:** 5 | **Dependencies:** BFC-007, BFC-801  
**References:** PRD §17.2; delivery/operations §§1, 4-6  
**Description:** Configure Vercel client staging, Render Flask service, and Render PostgreSQL in one
region using distinct secrets/data. Configure SPA fallback, Gunicorn, non-root Docker image, readiness,
explicit origins/cookies, migrations, and synthetic seed/smoke data.

**Acceptance criteria:**

- Staging deploys an exact commit after CI, runs migrations once, waits for readiness, then deploys client.
- Staging shares no database, cookie namespace, Google client configuration, or secret with production.
- Smoke tests cover login, baby, feeding, product usage, history, export, and logout with synthetic data.

### BFC-902 — Implement controlled production delivery

**Type:** Task | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-901  
**References:** PRD §17.3; delivery/operations §5  
**Description:** Add manual `workflow_dispatch` promotion of a staging-validated commit through a
protected GitHub Environment. Use deployment concurrency, backward-compatible migrations, API-first
health validation, client promotion, smoke tests, and semantic release metadata.

**Acceptance criteria:**

- Production cannot deploy an arbitrary unvalidated SHA or run two simultaneous promotions.
- Failed readiness/smoke checks stop promotion and expose a documented application rollback path.
- Secrets remain in GitHub/Vercel/Render environments and are never printed or embedded in artifacts.

### BFC-903 — Establish backup, restore, incident, and rollback runbooks

**Type:** Task | **Priority:** Highest | **Estimate:** 5 | **Dependencies:** BFC-901, BFC-802  
**References:** PRD §§13.7, 17.3; delivery/operations §§5, 8  
**Description:** Define RPO/RTO, automated backup retention, restore rehearsal, expand/contract migration
practice, credential-compromise response, incident communication, and application rollback. Verify
current hosting plan capabilities before launch.

**Acceptance criteria:**

- A staging restore rehearsal records time, integrity checks, owner, date, and follow-up actions.
- Runbooks identify triggers, permissions, commands, validation, escalation, and safe rollback limits.
- No procedure proposes automatic reversal of a destructive production migration.

### BFC-904 — Complete beta acceptance and release readiness review

**Type:** Story | **Priority:** Highest | **Estimate:** 8 | **Dependencies:** BFC-701 to BFC-805, BFC-902, BFC-903  
**References:** PRD §§12, 18; all MVP requirements  
**Description:** Execute the complete beta checklist with representative mothers and synthetic/consented
test accounts. Confirm critical journeys, isolation, security, accessibility, privacy/terms/support,
operational ownership, and unresolved risk acceptance. Record evidence and release decision.

**Acceptance criteria:**

- All 16 PRD beta acceptance criteria have linked evidence and an owner/date.
- Critical E2E flows pass against the release candidate and no Highest/High defect is open.
- Privacy policy, terms, support channel, launch countries, and legal review are approved before public use.
- Product/engineering explicitly approve go/no-go; postponed items are ticketed outside MVP scope.

## 4. Requirement traceability

| PRD requirement | Primary tickets |
|---|---|
| AUTH-001 to AUTH-003 | BFC-101, BFC-103, BFC-107 |
| AUTH-004 to AUTH-008 | BFC-102, BFC-104 to BFC-107 |
| BABY-001 to BABY-007 | BFC-202 to BFC-205 |
| FEED-001 to FEED-004 | BFC-301, BFC-302, BFC-306 |
| FEED-005 to FEED-007 | BFC-303, BFC-306 |
| FEED-008 to FEED-012 | BFC-304, BFC-305, BFC-307 |
| PROD-001 to PROD-005 | BFC-401, BFC-402, BFC-404 |
| PROD-006 to PROD-011 | BFC-401, BFC-403, BFC-405 |
| HIST-001 to HIST-005 | BFC-305, BFC-501 to BFC-503 |
| SUM-001 to SUM-005 | BFC-601, BFC-602 |
| DATA-001 to DATA-004 | BFC-701 to BFC-703 |
| Non-functional requirements | BFC-001 to BFC-008, BFC-801 to BFC-805 |
| Beta acceptance criteria | BFC-901 to BFC-904 |

## 5. Dependency path and implementation rule

The recommended critical path is:

`BFC-E00 -> BFC-E01 -> BFC-E02 -> BFC-E03 -> BFC-E04 -> BFC-E05/BFC-E06 -> BFC-E07 -> BFC-E08 -> BFC-E09`

Within that path, implement vertical slices rather than all database tables at once. A useful first
slice is Google login -> profile -> first baby -> protected UI -> first Cypress test. The next slice is
start -> reload -> finish feeding -> dashboard update. Products, unified history, privacy controls, and
release hardening follow once those foundations are stable.

Do not start H5 features (PWA/offline mode, caregiver sharing, reminders, side segments, or advanced
analytics) until BFC-904 is Done and the MVP has been validated with real target users.
