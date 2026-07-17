# Bolt 005 — Tasks

**Status: done.** Full RSpec suite: 58 examples, 0 failures, 1 unrelated pending. Rubocop clean.

- [x] `RecipeAutosorter` service object (`app/services/recipe_autosorter.rb`)
- [x] Tier 0: structural alignment via `instructions.recipe_ingredient_group_id`
- [x] Tier 1: group name matched in step prose (token containment)
- [x] Tier 2: individual fuzzy match on normalized, preparation-stripped names
- [x] Tier 2: duplicate-occurrence disambiguation by restated quantity/unit, with list-order fallback
- [x] Tier 3: unresolved ingredients left unassigned, not guessed
- [x] Fixture specs for both design-doc failure modes (`spec/services/recipe_autosorter_spec.rb`, 6 examples)
