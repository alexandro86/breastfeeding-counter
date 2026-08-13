# Client Technical Definition

## 1. Purpose and authority

This document is the technical contract for the `client/` application of
`breastfeeding-counter`. Every agent and contributor MUST read it before planning or implementing
client functionality.

The client is a mobile-first React single-page application built with Vite. It records and
presents personal breastfeeding information but does not own business rules, authorization, or
persisted calculations. Flask and PostgreSQL remain the source of truth.

The key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are normative.

When instructions conflict, use this order:

1. Security, privacy, and data integrity requirements.
2. Accepted ADRs and the versioned OpenAPI contract.
3. This document.
4. Repository-wide architecture and delivery documentation.
5. Local conventions inferred from existing code.

An agent MUST NOT silently bypass this contract. A necessary exception must be explained in the
pull request and recorded as an ADR when it changes architecture, tooling, authentication, the API
contract, hosting, or application boundaries.

## 2. Current baseline and target stack

The lockfile, not this document, is the source of truth for exact dependency versions. Dependencies
MUST be installed with `npm ci` in CI and MUST be updated together with `package-lock.json`.

| Concern                 | Standard                                     | Status at definition time                                     |
| ----------------------- | -------------------------------------------- | ------------------------------------------------------------- |
| UI runtime              | React 19                                     | Installed                                                     |
| Build and development   | Vite 8                                       | Installed                                                     |
| Language                | TypeScript 6 in strict mode                  | Installed; strictness must be strengthened as described below |
| Server state            | TanStack Query                               | Installed                                                     |
| Unit/integration runner | Vitest with jsdom                            | Installed                                                     |
| UI tests                | React Testing Library, user-event, jest-dom  | Installed                                                     |
| HTTP mocks              | MSW                                          | Installed                                                     |
| Formatting              | Prettier                                     | Installed                                                     |
| Static analysis         | ESLint with TypeScript and React rules       | Installed                                                     |
| Component system        | shadcn/ui with Tailwind CSS and Lucide icons | Required target; not yet initialized                          |
| End-to-end tests        | Cypress                                      | Required target; not yet initialized                          |
| Continuous integration  | GitHub Actions                               | Installed; must be extended for Cypress                       |
| Hosting                 | Vercel                                       | Configured target                                             |

Agents MUST inspect `package.json`, `package-lock.json`, TypeScript configurations, and relevant
source files before assuming that a target capability has already been installed. New dependencies
require a concrete use case and MUST pass the dependency audit.

## 3. Architectural principles

### 3.1 Application responsibilities

The client owns:

- presentation, interaction, responsive behavior, and accessibility;
- navigation and transient UI state;
- input assistance and immediate, non-authoritative validation;
- remote state orchestration, cache invalidation, and user-facing error states;
- locale-aware rendering of dates and times in the user's configured timezone.

The client MUST NOT own:

- authorization or ownership decisions;
- authoritative duration, summary, or feeding calculations;
- canonical validation of persisted data;
- persistence of sensitive data outside the approved session mechanism;
- medical recommendations, diagnoses, or judgments about feeding behavior.

The feeding timer is a projection of persisted timestamps. It MUST recover from `started_at` after
reload and MUST NOT treat an in-memory interval counter as authoritative.

### 3.2 Feature-first structure

New code SHOULD follow this shape:

```text
src/
|-- app/                    # Providers, application shell, global configuration
|-- components/
|   `-- ui/                 # shadcn/ui primitives owned by this repository
|-- features/
|   |-- auth/
|   |-- babies/
|   |-- feedings/
|   |-- products/
|   `-- dashboard/
|-- hooks/                  # Truly reusable client hooks
|-- lib/                    # HTTP client, errors, dates, utilities, shared configuration
|-- routes/                 # Route composition and route-level boundaries
|-- styles/                 # Global tokens and application-wide styles
|-- test/                   # Shared Vitest/RTL setup, render helpers, MSW server
`-- main.tsx
cypress/
|-- e2e/
|-- fixtures/               # Synthetic, non-sensitive fixtures only
`-- support/
```

A feature MAY contain `api`, `components`, `hooks`, `schemas`, `types`, and `tests` when those files
are private to that feature. Do not create broad global folders merely to group files by extension.

Dependency direction MUST flow inward:

```text
routes -> features -> shared UI/lib
app    -> features -> shared UI/lib
```

Shared primitives MUST NOT import feature modules. Features SHOULD NOT import private files from
other features; expose a deliberate public module when cross-feature reuse is justified.

### 3.3 Component boundaries

- Route components coordinate data and compose features.
- Feature components implement a user capability.
- `components/ui` contains shadcn/ui primitives and small visual extensions only.
- Presentational components MUST NOT call HTTP APIs directly.
- Reusable components SHOULD receive serializable props and expose semantic events.
- Business rules MUST remain in Flask services. UI-only derivations may live in pure functions.
- Prefer composition over boolean-heavy components. If a component needs many modes, split it.
- Avoid premature `memo`, `useMemo`, and `useCallback`; optimize only with measured evidence.

## 4. shadcn/ui and visual system

shadcn/ui components are source code owned by this repository, not an opaque component package.
Agents MAY adapt generated components, but MUST preserve accessibility behavior and document
meaningful divergence from the upstream primitive.

### 4.1 Initialization contract

Before adding the first shadcn/ui component, initialize the existing Vite application rather than
scaffolding a new application. The resulting setup MUST include:

- `components.json` committed to Git;
- Tailwind CSS configured through the Vite-supported integration;
- global CSS variables for semantic design tokens;
- `@/*` mapped to `./src/*` in TypeScript and Vite;
- `src/lib/utils.ts` with the canonical class-merging helper;
- generated primitives under `src/components/ui`;
- Lucide as the default icon library;
- TypeScript output (`tsx: true`) and React Server Components disabled (`rsc: false`).

Run the shadcn CLI only for named components that the current increment needs. Do not add the whole
registry. Generated code MUST be formatted, linted, reviewed, and tested like handwritten code.

### 4.2 Styling rules

- Use semantic tokens such as `background`, `foreground`, `primary`, `muted`, `destructive`, and
  `border`; do not scatter raw brand colors through feature components.
- Centralize theme tokens in the global stylesheet. A theme change SHOULD not require editing
  feature components.
- Use the class-merging helper for conditional utility classes.
- Avoid inline styles except for values that are genuinely calculated at runtime.
- Do not use Tailwind arbitrary values when an existing token or standard utility expresses the
  same intent.
- Keep motion subtle and respect `prefers-reduced-motion`.
- Dark mode MAY be prepared in the token system but MUST NOT delay an MVP feature unless requested.

### 4.3 Accessibility and mobile use

The interface MUST target WCAG 2.2 AA and one-handed mobile use:

- interactive targets are at least 44 by 44 CSS pixels;
- all controls have an accessible name and visible focus;
- native semantic HTML is preferred over ARIA reconstruction;
- form inputs have persistent labels, instructions, and programmatically associated errors;
- dialogs manage focus and provide an intentional initial focus target;
- color is never the only indicator of status;
- loading, empty, error, success, disabled, and offline states are explicit;
- touch, keyboard, screen-reader, narrow viewport, and 200% zoom behavior are considered;
- visible product copy is Spanish initially and text is kept ready for future localization.

Do not assume a shadcn/ui primitive makes the composed feature accessible. Test the complete
interaction and content.

## 5. TypeScript standard

No production `.js` or `.jsx` files may be added. Avoid `any`; use `unknown` at untrusted
boundaries and narrow it explicitly. Type assertions are a last resort and must be locally
justified. `@ts-ignore` is forbidden; `@ts-expect-error` requires a reason and a test when relevant.

### 5.1 Configuration layout

TypeScript configuration SHOULD be separated by execution environment:

- `tsconfig.app.json`: browser production code;
- `tsconfig.node.json`: Vite and Node-based tooling;
- `tsconfig.test.json`: Vitest and React Testing Library code;
- `cypress/tsconfig.json`: Cypress browser and Node configuration.

Production code MUST NOT receive Vitest or Cypress globals. Test files SHOULD be excluded from the
production project and included by the corresponding test project.

The browser configuration MUST retain bundler-compatible settings and enable at least:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "useUnknownInCatchVariables": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "verbatimModuleSyntax": true,
    "moduleResolution": "bundler",
    "moduleDetection": "force",
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

`skipLibCheck` MAY remain enabled to isolate the application from declaration defects in external
packages; it does not excuse weak typing in application code. Compiler relaxations MUST NOT be
introduced globally to accommodate one dependency or one file.

### 5.2 Type design

- Infer internal types where intent remains clear; annotate public function boundaries.
- Model finite states with discriminated unions instead of multiple unrelated booleans.
- Keep API transport types distinct from view models when conversion is required.
- Validate network and storage input at runtime; static types do not validate JSON.
- Prefer generated OpenAPI types once generation is adopted. Never manually drift from the API.
- Use `import type` for type-only imports under `verbatimModuleSyntax`.
- Represent dates crossing the API as ISO 8601 strings. Parse only at the presentation boundary.
- Optional and nullable are different and MUST match the OpenAPI schema.
- Exhaustively handle domain-like unions using `never` checks where practical.

## 6. State, forms, and API access

### 6.1 State ownership

- TanStack Query is the source of truth for server state.
- Component state is for ephemeral interaction state.
- URL state SHOULD hold shareable navigation, pagination, and filter state.
- Context is reserved for session, theme, locale, or genuinely application-wide concerns.
- Do not copy query results into local state without a documented synchronization need.
- Mutations MUST invalidate or update the smallest correct query scope.

### 6.2 HTTP boundary

All requests MUST pass through the centralized client in `src/lib`. Feature components MUST NOT
call `fetch` directly. The HTTP layer owns:

- the `VITE_API_BASE_URL` public configuration;
- credentials/session behavior once authentication is implemented;
- JSON and Problem Details parsing;
- request cancellation through `AbortSignal`;
- normalized, typed errors safe for user-facing mapping;
- request identifiers when supported by the API.

Only public values may use the `VITE_*` prefix. Tokens, secrets, personal notes, email addresses,
and complete payloads MUST NOT be written to console output, analytics, test artifacts, or client
storage. Authentication storage strategy must follow the accepted authentication ADR.

### 6.3 Forms

Use React Hook Form and Zod when forms are introduced, unless an ADR changes this choice.
Client-side validation improves feedback but never replaces server validation. Server field and
form errors MUST be mapped to accessible messages without exposing internal details.

Prevent duplicate submission, preserve safe user input after recoverable failures, and ask for
confirmation before destructive actions. Optimistic updates MAY be used only when rollback and
conflict behavior are explicit.

## 7. Formatting and static analysis

Prettier is the sole formatting authority for supported files. Agents MUST NOT manually align code
against Prettier output or add competing formatters.

The committed Prettier configuration is canonical. Changes to it MUST be repository-wide,
intentional, and isolated from functional changes when possible. Generated output, coverage,
build output, and dependencies belong in `.prettierignore`; source files do not.

ESLint owns correctness and maintainability rules rather than formatting. It MUST cover TypeScript,
React hooks, refresh boundaries, tests, and Cypress-specific rules once Cypress is installed.
Warnings fail CI (`--max-warnings=0`), so intentional exceptions must be narrow, explained inline,
and never disable a rule for the whole project without review.

Before completing a client change, run:

```powershell
cd client
npm run format:check
npm run lint
npm run typecheck
npm run test:coverage
npm run build
```

Use `npm run format` to apply formatting, then review the resulting diff.

## 8. Unit and integration testing with React Testing Library

Vitest remains the test runner and jsdom environment. React Testing Library is the standard for
component and feature integration tests. MSW is the standard network boundary; do not mock the
central HTTP client or TanStack Query internals when an HTTP-level handler can express the case.

### 8.1 Test placement and setup

- Co-locate focused `*.test.ts` and `*.test.tsx` files with the behavior they verify.
- Keep global setup, MSW lifecycle, factories, and a custom `render` in `src/test`.
- The custom render SHOULD create a fresh QueryClient and required providers per test.
- Query retries MUST be disabled in tests unless retry behavior is the subject under test.
- Reset MSW handlers and all mutable state after every test.
- Unhandled MSW requests MUST fail tests.
- Use synthetic fixtures and fixed clocks/IDs where determinism requires them.

### 8.2 Testing behavior

Tests MUST describe observable user behavior rather than component internals:

- prefer `screen.getByRole` with accessible name, then label text and visible text;
- use `findBy*` for asynchronous appearance and `queryBy*` for absence;
- use `userEvent` for realistic interaction; reserve `fireEvent` for low-level cases;
- assert meaningful status, content, focus, and enabled/disabled behavior;
- cover loading, success, empty, validation, API error, and retry behavior as applicable;
- verify timer behavior with controlled time and persisted timestamps;
- avoid snapshots of large component trees;
- do not assert Tailwind classes unless the class itself is the behavior under test;
- use `data-testid` only when no semantic query can represent the interaction.

A bug fix MUST include a regression test that fails before the fix. A feature MUST test its main
success path and meaningful failure paths. shadcn/ui generated primitives do not need duplicated
upstream tests, but every product-specific composition and modification does.

### 8.3 Coverage

Coverage is a safety signal, not a substitute for assertions. The current global minimums are:

- lines: 80%;
- statements: 80%;
- functions: 80%;
- branches: 75%.

Thresholds MUST NOT be lowered to merge a change. New critical modules—authentication, feeding
timer, destructive actions, timezone conversion, and API error mapping—SHOULD receive branch-level
coverage beyond the global minimum. Exclusions must be limited to generated or non-executable code.

## 9. End-to-end testing with Cypress

Cypress is the canonical E2E tool for the client. This decision supersedes earlier generic
references to Playwright for this repository.

### 9.1 Required setup

When Cypress is initialized, commit:

- `cypress.config.ts` with `baseUrl` provided by environment and a local default;
- `cypress/e2e`, `cypress/support`, and only necessary synthetic fixtures;
- a dedicated Cypress TypeScript configuration;
- scripts `e2e`, `e2e:open`, and `e2e:ci` in `package.json`;
- ignore rules for screenshots and videos produced locally;
- CI artifact upload for screenshots and videos only on failure.

The application and API MUST be started outside Cypress. CI MUST wait on readiness endpoints rather
than sleep for a fixed duration.

### 9.2 E2E scope

Use Cypress for a small set of high-value cross-system journeys:

1. authenticate through a controlled Google Identity boundary and restore a session;
2. create/select a baby profile;
3. start, reload, recover, and finish a feeding;
4. create a manual feeding and verify history;
5. create a product and register its use;
6. sign out and verify protected navigation;
7. verify one representative narrow mobile viewport for critical flows.

Do not reproduce every React Testing Library case in Cypress. Add an E2E case when behavior crosses
routing, browser, API, session, or persistence boundaries.

### 9.3 Determinism and selectors

- Every spec MUST be independent and able to run alone or in any order.
- Create state through controlled API/task helpers; do not share state between specs.
- Prefer programmatic login over repeating the login UI except in the login journey itself.
- Never depend on production, third-party systems, real email, or real personal data.
- Never use arbitrary `cy.wait(milliseconds)`. Wait on routes, readiness, or observable UI state.
- Prefer accessible role/label queries when semantics are part of the requirement.
- Use stable `data-cy` attributes when wording or structure is intentionally free to change.
- Do not select by Tailwind classes, generated IDs, or brittle DOM ancestry.
- Keep secrets in CI secret storage and prevent them from appearing in Cypress output or artifacts.

The server must eventually expose a testing-only, environment-gated mechanism to reset and seed
synthetic E2E state. It MUST be impossible to enable that mechanism in staging or production.

## 10. GitHub Actions quality gates

All pull requests and pushes to `main` MUST run client quality checks. Workflows use least-privilege
permissions, cancel superseded runs for the same branch/PR, set explicit timeouts, and pin every
third-party action to a full commit SHA with a readable version comment.

### 10.1 Client quality job

The `client-quality` job MUST:

1. check out the exact commit;
2. install Node from `.nvmrc` and cache npm data using `client/package-lock.json`;
3. run `npm ci` from `client/`;
4. run `format:check`;
5. run ESLint with zero warnings;
6. run the strict TypeScript check;
7. run Vitest with coverage thresholds;
8. build the production bundle;
9. upload the coverage report with bounded retention and no sensitive data.

These are required checks and MUST NOT use `continue-on-error`.

### 10.2 Cypress E2E job

After Cypress and deterministic test data support exist, a `client-e2e` job MUST:

1. use an isolated PostgreSQL service container;
2. install locked server and client dependencies;
3. apply database migrations;
4. start Flask in testing/E2E mode and wait for readiness;
5. build and serve the Vite application using the production build where practical;
6. run Cypress headlessly in a pinned browser/runtime environment;
7. upload screenshots and videos only when the run fails;
8. always terminate managed processes.

Critical smoke E2E tests MUST block pull requests once the test harness is stable. A broader suite
MAY run on `main` or on a schedule if execution cost becomes significant. Flaky tests MUST be fixed
or quarantined with an owner and tracking issue; blind retries are not a solution.

### 10.3 Dependency and workflow security

- `npm audit --audit-level=high` remains a required gate.
- Dependabot MUST monitor npm and GitHub Actions.
- Lockfile changes require review and must not be hidden among unrelated generated changes.
- Workflow code from forks MUST NOT receive deployment secrets.
- Vite build-time variables are public by design and MUST never contain secrets.
- Build and test artifacts MUST have short, explicit retention and contain synthetic data only.
- Deployment jobs MUST depend on successful CI and deploy the exact validated commit.

## 11. Required npm script interface

Agents and CI may rely on these stable commands:

| Script          | Responsibility                                       |
| --------------- | ---------------------------------------------------- |
| `dev`           | Start the Vite development server                    |
| `build`         | Type-check production code and create the Vite build |
| `preview`       | Serve the production build locally                   |
| `format`        | Apply Prettier                                       |
| `format:check`  | Verify formatting without changes                    |
| `lint`          | Run ESLint with zero warnings                        |
| `typecheck`     | Run all required TypeScript project checks           |
| `test`          | Run Vitest once                                      |
| `test:coverage` | Run Vitest with enforced coverage                    |
| `e2e`           | Run Cypress E2E headlessly                           |
| `e2e:open`      | Open Cypress for local development                   |
| `e2e:ci`        | Run the deterministic CI E2E suite                   |

The Cypress scripts are a required target and MUST be added with Cypress initialization. Renaming a
stable script requires updating GitHub Actions, root tooling, README instructions, and this file in
the same change.

## 12. Performance and production behavior

- Route-level code splitting SHOULD be used as features grow.
- Avoid adding large dependencies for small utilities.
- Images require dimensions, appropriate formats, lazy loading when below the fold, and useful alt
  text or an empty alt attribute when decorative.
- Prevent layout shift in timer and dashboard surfaces.
- Loading behavior SHOULD favor stable skeleton/layout states over spinners that move content.
- Production builds MUST contain no development-only test hooks except inert `data-cy` attributes.
- Browser console errors and unhandled promise rejections are defects.
- Support the two latest stable versions of Chrome, Safari, Firefox, and Edge.

## 13. Agent workflow for every client change

### Before implementation

1. Read this file and the relevant accepted ADRs.
2. Inspect `client-history.md`, the affected feature, tests, package scripts, and current CI.
3. Read `docs/openapi.yaml` before consuming or changing an endpoint.
4. Identify loading, empty, error, success, permission, and mobile states.
5. Decide the smallest vertical increment and its RTL/E2E coverage.
6. Confirm whether target dependencies such as shadcn/ui or Cypress are actually initialized.

### During implementation

1. Keep API access, feature logic, and UI primitives in their defined layers.
2. Add or update tests with the behavior, not after it.
3. Use accessible semantics and verify keyboard/focus behavior.
4. Keep test data synthetic and logs free of private content.
5. Update OpenAPI/generated types when the HTTP contract changes.
6. Avoid unrelated refactors and dependency additions.

### Before completion

1. Run formatting, lint, strict type checking, coverage tests, and production build.
2. Run relevant Cypress specs when the harness exists and the change affects a critical flow.
3. Review the production diff for secrets, accidental logs, weak types, and generated noise.
4. Update `client-history.md` in English with a unique numeric ID, implementation details, and
   pending issues.
5. Add or update the corresponding root `history.md` reference when the work constitutes a project
   milestone.
6. Report exactly which checks passed and which could not be run.

## 14. Definition of done

A client increment is complete only when:

- acceptance behavior and all meaningful UI states are implemented;
- the UI is usable on narrow mobile screens and by keyboard;
- accessible names, focus, validation, and status announcements are correct;
- server state and business rules remain in their proper layers;
- the OpenAPI contract and client types agree;
- no secrets or sensitive personal data enter code, logs, fixtures, or artifacts;
- regression, integration, and required E2E tests exist and pass;
- Prettier, ESLint, TypeScript, coverage, build, and applicable Cypress gates pass;
- implementation history is updated and pending issues are explicit;
- no unexplained TODO, skipped test, warning, or architectural exception remains.

## 15. Primary references

- shadcn/ui installation: https://ui.shadcn.com/docs/installation
- shadcn/ui manual setup: https://ui.shadcn.com/docs/installation/manual
- TypeScript strict mode: https://www.typescriptlang.org/tsconfig/strict
- Testing Library principles and queries: https://testing-library.com/docs/queries/about
- Cypress E2E best practices: https://docs.cypress.io/app/core-concepts/best-practices
- Cypress on GitHub Actions: https://docs.cypress.io/app/continuous-integration/github-actions
- GitHub Actions secure use: https://docs.github.com/en/actions/reference/security/secure-use
