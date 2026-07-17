# Bolt 007: Autosort Review UI

- **Unit covered**: [Unit 07 — Autosort Review UI](../../units/07-autosort-review-ui/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)
- **Depends on**: Bolt 003 (Recipe Detail), Bolt 005 (`RecipeAutosorter`), Bolt 006 (import pipeline)

## Approach

**Backend additions** (needed before any UI could show or save the autosort result):
- `RecipeSerializer#instructions` now includes `recipe_ingredient_ids` per instruction (the `instruction_ingredients` join, exposed for editing) — one line added to the existing serializer method, no new endpoint needed for reading.
- New `PATCH /api/v1/recipes/:recipe_id/instruction_ingredients` (`InstructionIngredientsController`, login + ownership required, mirroring the `require_owner` pattern from Bolt 003). Takes `{ assignments: { instruction_id => [recipe_ingredient_id, ...] } }` and does a full replace (`delete_all` + recreate) of that recipe's `instruction_ingredients` in a transaction, rather than diffing individual moves — the review UI edits a local draft and saves once, so this matches how the client actually uses it. Both `instruction_ids` and `recipe_ingredient_ids` are filtered against the target recipe's own rows before use, closing an IDOR path (a client could otherwise link another recipe's instruction to another recipe's ingredient).
- Bug fixed along the way: `params.require(:assignments)` raises `ParameterMissing` when the client sends an *empty* hash (Rails treats `{}` as blank) — which is exactly the "clear all assignments for this recipe" case. Switched to `params[:assignments]` with a manual nil-guard.

**Frontend** (`app/frontend/`):
- `RecipeImport.vue` (new, route `/recipes/import`): a two-mode form (URL vs. paste-text) posting to `POST /api/v1/recipes/import`, redirecting to `/recipes/:id/review` on success. URL-mode failures are mapped to the backend's `reason` codes (`no_structured_data`, `fetch_failed`, `invalid_url`) with a hint to switch to paste mode.
- `RecipeReview.vue` (new, route `/recipes/:id/review`): renders each instruction with its currently-assigned ingredients (chips with a remove button) and a per-step "add ingredient" `<select>` sourced from whatever's currently unresolved, plus a standalone "Unresolved ingredients" tray (ADR-0004's explicit requirement — pending ingredients stay visible, never silently dropped). All edits happen against a local reactive draft (seeded from the autosort result on load); Save does one `saveAssignments` call.
- `stores/recipes.js`: three new actions (`importFromUrl`, `importFromText`, `saveAssignments`), following the store's existing `{ ok, ... }`/`{ ok: false, ... }` return-shape convention.
- Entry points: an "Import" link next to "New recipe" on `Recipes.vue`; a "Review ingredients" link on `RecipeDetail.vue`, shown to the owner whenever the recipe has instructions (manually-created title/description-only recipes won't show it, since `RecipeForm.vue` still only handles those two fields — instructions/ingredients only exist via the import pipeline right now).

**Scope decision — "drag between steps" implemented as remove-then-add, not HTML5 drag gestures.** The unit brief lists "drag an ingredient between steps" alongside "add/remove." Since an ingredient lives in at most one step at a time in this UI's model (matching how the autosorter itself assigns), removing it from step A makes it appear as an option in every other step's "add" dropdown — the same end result as a drag, reached via two clicks instead of a drag gesture. This was chosen over native HTML5 drag-and-drop because it's dramatically more reliable to build, test (including the Playwright verification below), and use, at the cost of a literal drag interaction. Revisit only if manual use reveals the click-based flow is actually annoying in practice.

## Verification

Full backend suite: 82 examples, 0 failures, 1 unrelated pending. Rubocop clean.

Manually verified end-to-end in the browser (Playwright), since this is the project's first new UI surface since Bolt 003:
1. Signed up a fresh account, imported a recipe via paste-text ("2 eggs" / "1 cup flour" / "1 tsp sesame oil" as ingredients; "Whisk the eggs." / "Add the flour and stir." as instructions).
2. Confirmed the review page showed the correct initial autosort: eggs → step 1, flour → step 2, sesame oil → Unresolved tray (never mentioned in either step).
3. Removed eggs from step 1 (confirmed it reappeared in Unresolved and in both steps' add-dropdowns), added sesame oil to step 1 instead via its dropdown (confirmed it left Unresolved).
4. Saved; redirected to the recipe detail page, which shows a new "Review ingredients" link.
5. Reloaded the review page directly (hard navigation) and confirmed the edited state persisted exactly: sesame oil on step 1, flour on step 2, eggs still unresolved (intentionally left that way to confirm partial/incomplete saves work, not just fully-resolved ones).
6. Logged out and confirmed `/recipes/:id/review` redirects to `/login` (the existing `meta.requiresAuth` router guard covers the new routes without changes).

One real bug caught during this verification and fixed: the first import attempt 500'd with `NameError: uninitialized constant Api::V1::RecipeImportsController::RecipeImporter` — not a code defect (specs for the same code passed), but the long-running dev Puma container not picking up newly-created files via its file watcher over the Windows Docker bind mount. `docker-compose restart web` resolved it; noted in memory as a recurring Windows-dev gotcha for future sessions.

## Out of scope

- The matching logic itself (Unit 05) — this unit only renders and edits its output, per the unit brief
- Native drag-and-drop gestures (see scope decision above)
- Ingredient/instruction editing beyond assignment (adding a whole new ingredient or step isn't part of this review flow)
- A manual-entry path for instructions/ingredients on non-imported recipes (`RecipeForm.vue` still only handles title/description) — the review UI is reachable only for recipes with instructions, i.e. imported ones
