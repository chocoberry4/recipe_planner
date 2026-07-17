# Bolt 003: Recipe Create / Edit / Detail

- **Unit covered**: [Unit 02 — Recipe Vue Views, Slice B](../../units/02-recipe-vue-views/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)
- **Depends on**: Bolt 001 (auth) — mutations are tied to `current_user`

## Approach

Mirrors the `stores/auth.js` pattern already established for auth: a `stores/recipes.js` Pinia store wraps `fetch` with `credentials: 'include'` and an `X-CSRF-Token` header on mutations, returning `{ ok, ... }` / `{ ok: false, errors }` so views handle results consistently. The `csrfToken()` helper was extracted from `stores/auth.js` into `lib/csrf.js` so both stores share it instead of duplicating it.

Create and edit share a single `RecipeForm.vue` (mode inferred from whether the route has an `:id` param) rather than two near-identical components, since both flows use the same two fields (title, description).

## Definition of done

- `RecipeDetail.vue` (`GET /:id`) renders title, description, ingredient groups, ungrouped ingredients, and instructions.
- `RecipeForm.vue` handles both create (`POST`) and edit (`PATCH`), pre-filling on edit.
- Delete action wired to `DELETE /:id` with a confirmation prompt.
- `Recipes.vue` links each list item to its detail page and adds a "New recipe" link.
- Router gains `/recipes/new`, `/recipes/:id`, `/recipes/:id/edit`; the auth guard (previously an exact match on `/recipes`) now generalizes via `meta.requiresAuth` to cover the whole `/recipes` section, consistent with Unit 01's original intent ("router guard redirecting unauthenticated users away from recipe routes").
- Verified end-to-end in the browser (signup → create → view → edit → delete → list updates) and via a logged-out redirect check, not just code inspection.

## Known follow-up — fixed same day (2026-07-17)

`RecipesController#update`/`#destroy` only checked `require_login`, not recipe ownership — any logged-in user could edit or delete any recipe, not just their own. Fixed with a `before_action :require_owner` (403 if `@recipe.user_id != current_user.id`). `RecipeSerializer` now exposes `user_id` so `RecipeDetail.vue` can hide Edit/Delete for recipes the current user doesn't own, instead of showing controls that would 403 on click. Covered by two new request specs (non-owner update/destroy → 403) and verified live with two separate accounts, including a direct `fetch` bypassing the UI.

## Out of scope

- Ingredient grouping UI (create/edit only touch `title`/`description`; Unit 07)
- Styling (tracked separately, deferred until after this slice per prior discussion)
