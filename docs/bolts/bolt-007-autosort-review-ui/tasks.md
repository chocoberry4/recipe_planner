# Bolt 007 — Tasks

**Status: done.** Full backend suite: 82 examples, 0 failures, 1 unrelated pending. Rubocop clean. Verified end-to-end in-browser via Playwright (import → review → edit → save → reload → persisted correctly → logged-out redirect).

- [x] `RecipeSerializer#instructions` exposes `recipe_ingredient_ids`
- [x] `PATCH /api/v1/recipes/:recipe_id/instruction_ingredients` (`InstructionIngredientsController`), login + ownership required, full-replace semantics
- [x] IDOR guard: instruction/recipe_ingredient ids filtered against the target recipe
- [x] Fix: empty `assignments` hash (clear-all case) no longer 400s (`params.require` → manual guard)
- [x] `RecipeImport.vue` — URL and paste-text modes, error-reason mapping for the URL path
- [x] `RecipeReview.vue` — per-step assigned-ingredient chips with remove, per-step add-dropdown, Unresolved tray, Save/Cancel
- [x] `stores/recipes.js`: `importFromUrl`, `importFromText`, `saveAssignments`
- [x] Router: `/recipes/import`, `/recipes/:id/review`, both `meta.requiresAuth`
- [x] Entry links: "Import" on `Recipes.vue`, "Review ingredients" on `RecipeDetail.vue` (owner + has instructions)
- [x] Specs: `instruction_ingredients_spec.rb` (4), plus a `recipe_spec.rb` addition for the new serializer field
- [x] Manual browser verification (Playwright) — see plan.md for the full walkthrough and the one real bug it caught (dev-server file-watcher restart needed, not a code defect)
