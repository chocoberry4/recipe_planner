# Bolt 003 — Tasks

**Status: done.** Verified in-browser via Playwright (signup, create, view, edit, delete, logged-out redirect) plus full RSpec suite (37 examples, 0 failures, 1 unrelated pending).

- [x] Extract `csrfToken()` from `stores/auth.js` into shared `lib/csrf.js`
- [x] `stores/recipes.js`: `fetchOne`, `create`, `update`, `destroy` actions
- [x] `RecipeDetail.vue`: render title, description, ingredient groups, ingredients, instructions; Edit/Delete controls
- [x] `RecipeForm.vue`: shared create/edit form, pre-fills on edit
- [x] `Recipes.vue`: link list items to detail; add "New recipe" link
- [x] Router: `/recipes/new`, `/recipes/:id`, `/recipes/:id/edit`; generalize auth guard to `meta.requiresAuth`
- [x] Manual end-to-end browser verification (not just spec-level)

## Follow-up filed, not fixed here

- `RecipesController` has no ownership check on `update`/`destroy` (any logged-in user can edit/delete any recipe) — see `plan.md`.
