# ADR-0001: Cookie-based sessions for authentication

- **Status**: Accepted
- **Related**: [Intent 0001](../intent/0001-recipe-planner-phase1.md)

## Context

`config/routes.rb` already defines `POST /login`, `POST /signup`, `DELETE /logout` under `api/v1/auth`, and `User` already has `has_secure_password`. No `AuthController` exists yet. The backend is Rails in API-only mode; the frontend is a separately-served Vue app (Vite dev server on a different port in development). We need to decide how the frontend authenticates against the API.

Two realistic options:

1. **Cookie-based sessions** — Rails' built-in session cookie, set on login, sent automatically by the browser on subsequent requests.
2. **JWT / bearer tokens** — a signed token returned on login, stored client-side (memory or localStorage), sent via `Authorization` header.

## Decision

Use cookie-based sessions.

Rationale:

- `has_secure_password` and Rails session handling are already in place; this is the path of least resistance for a single-user, browser-only Phase 1 app.
- No token expiry/refresh logic to build and maintain.
- The main cost — CORS + `credentials: 'include'` configuration between the Vite dev server and Rails in development — is a one-time setup cost, not ongoing complexity.

We are explicitly not building for a future mobile client or third-party API consumers in Phase 1; if that need arises later, token-based auth can be added alongside sessions without ripping sessions out.

## Consequences

- Need `Rack::Cors` (or equivalent) configured to allow the Vite origin in development with credentials enabled.
- Need CSRF protection considered for state-changing requests, since Rails API mode disables it by default — decide per-controller whether to re-enable or rely on `SameSite` cookie attributes.
- `AuthController` (`login`, `signup`, `logout`) still needs to be built — tracked as a unit of work.
