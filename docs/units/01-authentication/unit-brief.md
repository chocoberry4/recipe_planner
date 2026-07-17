# Unit 01: Authentication

- **Related**: [ADR-0001](../../adr/0001-cookie-session-auth.md)
- **Depends on**: —

## Goal

Real, working cookie-session auth — closes Intent 0001 success criterion #3 ("a user can log in").

## In scope

- `AuthController#login`, `#signup`, `#logout` (routes already exist, no controller yet)
- Session cookie set on login, cleared on logout
- CORS + `credentials: 'include'` configuration between Vite dev server and Rails
- Vue login/signup forms
- Router guard redirecting unauthenticated users away from recipe views

## Out of scope

- Password reset / email verification
- Multi-user/household auth (Phase 2)

## Acceptance criteria

- User can sign up, log in, and log out through the Vue UI
- Recipe endpoints reject unauthenticated requests
