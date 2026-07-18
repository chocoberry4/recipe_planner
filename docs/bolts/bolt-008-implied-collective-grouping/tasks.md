# Bolt 008 — Tasks

**Status: done.** Full backend suite: 94 examples, 0 failures, 1 unrelated pending. Rubocop clean. Verified end-to-end in-browser via Playwright against a real external recipe URL, comparing pre-fix and post-fix imports of the same page.

- [x] Found via live testing against `https://www.recipetineats.com/butter-chicken/`, not synthetic data — see plan.md
- [x] `IngredientLineParser#extract_parentheticals` — strips (possibly nested) parenthetical asides out of `name`, folds into `preparation`
- [x] `RecipeAutosorter` Tier 2.5 (`assign_tier2_5_implied_collective_group`) — implied group from a collective-reference phrase, conservatively scoped to the single-label/single-run case
- [x] `detect_collective_labels` — mid-sentence `the <Capitalized>` pattern, excludes real ingredient names
- [x] `contiguous_unassigned_runs` — position-ordered, min length 2
- [x] `primary_instruction_for` — prefers a step with a leading `"Label:"` prefix over an earlier passing mention
- [x] Specs: 4 new in `ingredient_line_parser_spec.rb`, 4 new in `recipe_autosorter_spec.rb`
- [x] Re-imported the same live URL post-fix, confirmed via API read that a real "Marinade" `RecipeIngredientGroup` now exists with all 9 correct ingredients
- [x] Updated `docs/design/recipe-import-and-autosort.md`'s matching algorithm and "Known limitations" sections to describe Tier 2.5 and narrow the limitation to the multi-section case
