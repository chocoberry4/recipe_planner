# Bolt 005: Autosort Matching Engine

- **Unit covered**: [Unit 05 — Autosort Matching Engine](../../units/05-autosort-matching-engine/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)
- **Depends on**: Bolt 004 (`IngredientLineParser`, for the shared unit list), Unit 03 schema (`recipe_ingredient_groups`, `instruction_ingredients`)

## Approach

`RecipeAutosorter` (`app/services/recipe_autosorter.rb`) is a plain Ruby service object — `RecipeAutosorter.call(recipe)` — that runs the three tiers from the design doc in order over a single recipe's `instructions` and `recipe_ingredients`, writing results directly as `InstructionIngredient` rows. Each tier only considers ingredients the previous tier left unassigned (tracked via an in-memory `Set` of assigned `recipe_ingredient` ids, not re-queried per tier).

- **Tier 0 (structural)**: `instruction.recipe_ingredient_group_id` set → assign every remaining member of that group to that instruction. No text analysis.
- **Tier 1 (group prose)**: for instructions without a structural link, normalize the step text and every group's name into token sets; if a group's name tokens are all present in the step's tokens, assign the whole (still-unassigned) group to that step.
- **Tier 2 (individual fuzzy)**: normalize each remaining ingredient's canonical `name` (never `preparation` — that's a separate column, already excluded) into tokens and require the full set to appear in the step's token set. This is set containment, not substring — it's what fixes the design doc's failure mode #1 ("diced tomatoes" vs "tomatoes, diced"), since token order and comma placement no longer matter. For an ingredient with multiple unassigned occurrences (failure mode #2 — duplicate ingredient, different quantities), a regex scan for a restated quantity+unit in the step text (reusing `IngredientLineParser::KNOWN_UNITS`) picks the matching occurrence; with no restated measurement it falls back to `position`/id order.
- **Tier 3 (unresolved)**: whatever no tier claimed is left with no `InstructionIngredient` row — never force-assigned.

**Matching threshold, an explicit scope decision**: Tier 1/2 matching requires *all* normalized tokens of the group/ingredient name to appear in the step text (full set containment), not a partial-overlap score. This exactly reverses failure mode #1 (order/phrasing invariance) without inventing an undocumented partial-match scoring formula. The tradeoff: a step that mentions only part of a multi-word ingredient name (e.g. step says "flour" for an ingredient named "all-purpose flour") won't match and falls through to Tier 3 unresolved. That's consistent with the design doc's "silence beats a wrong guess" — not a bug, a conservative default that can be revisited if Unit 07's review UI shows it firing too often in practice.

## Definition of done

- `RecipeAutosorter.call(recipe)` populates `instruction_ingredients` per the tiered algorithm.
- Fixture coverage for both documented failure modes: sectioned/grouped ingredients (Tier 0 structural + Tier 1 prose-only) and duplicate-ingredient-different-quantity (Tier 2 tiebreak by restated measurement, with a list-order fallback case).
- An ingredient mentioned nowhere is left unassigned, not guessed (Tier 3).
- `spec/services/recipe_autosorter_spec.rb`, 6 examples; full suite 58 examples, 0 failures.

## Out of scope

- Review/correction UI (Unit 07)
- Fetching import data (Unit 06)
- Synonym/alias handling, partial-overlap scoring — not in the design doc's stated scope for this unit
