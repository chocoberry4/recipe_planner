# Bolt 008: Implied Collective Grouping

- **Unit covered**: [Unit 08 — Implied Collective Grouping](../../units/08-implied-collective-grouping/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)
- **Depends on**: Bolt 005 (`RecipeAutosorter`), Bolt 006 (`RecipeImporter`/`IngredientLineParser`), Bolt 007 (autosort review UI)

## How this was found

User request: "can i import a recipe and see all the steps" (Bolt 006/007 follow-up) led to testing the URL-import path against a real external site rather than synthetic test data. First real-world attempt (RecipeTinEats' Butter Chicken, `https://www.recipetineats.com/butter-chicken/`) surfaced two bugs the synthetic specs never would have caught, both diagnosed live via Playwright against the actual imported recipe (id 76) before any fix was written, then re-verified against a fresh import (id 77) after the fix.

## Bug 1: parenthetical asides poisoning Tier 2 matching

`IngredientLineParser#split_name_and_preparation` only ever routed text after the *first comma* into `preparation`. Parenthetical asides with no preceding comma — "(30 g)" (a metric-equivalent aside sitting between the unit and the actual name), "(aka tomato puree)", "((Note 4))" (a doubled-paren footnote marker) — stayed baked into `name` verbatim. `RecipeAutosorter`'s Tier 2 requires *every* normalized token of an ingredient's name to appear in a step's text (see Bolt 005's scope decision on full token-set containment, not partial overlap) — so an ingredient named `"(30 g)  ghee or butter"` could never match a step that says "Heat the ghee...", because tokens `"30"`/`"g"` never appear in any instruction text. This silently broke matching for `ghee`, `tomato passata`, and `coriander/cilantro` in the test recipe, none of which are collective-reference cases — they're named directly in their steps and should have matched.

**Fix**: `IngredientLineParser#extract_parentheticals` (new, private) strips all parenthetical groups — including nested ones, via a loop rather than a single regex pass, since `((Note 4))` requires stripping the inner group before the outer one becomes matchable — out of the remainder text before the name/preparation comma-split runs, folding their contents into `preparation` instead of discarding them. `app/services/ingredient_line_parser.rb`; specs added to `spec/services/ingredient_line_parser_spec.rb` (4 new examples).

## Bug 2 (the reported one): ungrouped collective references

RecipeTinEats' schema.org JSON-LD has *zero* grouping signal anywhere: `recipeIngredient` is a flat array of 17 strings with no group markers, and `recipeInstructions` is flat `HowToStep`s with no `HowToSection` — "Marinade" only exists as prose inside step text ("Marinade: Combine the Marinade ingredients with the chicken..."). This is exactly the scenario the original design doc's "Known limitations" section called out and declined to solve ("This is a real gap, not a bug to fix — there is no standard structured-data field for it"). Confirmed via direct inspection (`bin/rails runner` fetching the live page through `JsonLdRecipeExtractor` and dumping its output) that RecipeTinEats produces `group_name: nil` for every instruction and no grouped ingredient data at all — not an extraction bug, just genuinely absent source data.

Per the user's explicit direction ("design a heuristic fix"), this bolt revises that decision and adds a new, deliberately narrow tier rather than leaving it permanently unresolved.

**New Tier 2.5 — implied collective group** (`RecipeAutosorter#assign_tier2_5_implied_collective_group`), runs after Tier 2 so already-individually-matched ingredients are excluded first:

1. `detect_collective_labels` scans instruction text for `\bthe\s+([A-Z][a-z]+)\b` — a lowercase article followed by a Capitalized word mid-sentence, which is how this kind of prose refers to a named section ("the Marinade ingredients", "the Marinade left in the bowl") without matching ordinary sentence-initial capitalization. Labels that match a real ingredient name in the recipe are excluded (guards against a step like "Fry the Chicken" being mistaken for a section reference).
2. `contiguous_unassigned_runs` finds maximal runs (length ≥ 2 — a lone leftover ingredient isn't a "section") of still-unassigned ingredients in the recipe's original list-order (`position` column).
3. **Only fires when there is exactly one detected label and exactly one qualifying run.** With more than one of either, there's no reliable way to pair labels to runs from position alone — see "Out of scope" below — so the tier bails out entirely and leaves everything for manual assignment, per the existing "silence beats a wrong guess" principle already governing Tier 3.
4. When it fires: creates a real `RecipeIngredientGroup` for the label, assigns the whole run to it, then assigns that group to whichever instruction most directly names the section — preferring a step whose text *starts with* `"Label:"` (e.g. "Marinade: Combine...") over one that merely mentions it in passing (e.g. an earlier "optional" step that also says "the Marinade ingredients"), falling back to first-mention order if no step has that leading-label form.

`app/services/recipe_autosorter.rb`; specs added to `spec/services/recipe_autosorter_spec.rb` (4 new examples: fires correctly and picks the right step over a passing mention, ignores a real ingredient name as a false-positive label, bails out with two runs, bails out with a single non-qualifying leftover).

## Verification

Full backend suite: 94 examples, 0 failures, 1 unrelated pending. Rubocop clean on both changed files.

Re-imported the same live URL end-to-end through the browser (Playwright) after the fix, comparing against the pre-fix import:

| | Before | After |
|---|---|---|
| Marinade ingredients (9) | All unresolved | Grouped as "Marinade", assigned to the correct step (the actual "Marinade:" step, not the earlier "optional blitz" step that also mentions it) |
| ghee/butter | Unresolved (parser artifact) | Assigned to "Cook chicken" step |
| tomato passata | Unresolved (parser artifact) | Assigned to "Sauce" step |
| coriander/cilantro | Unresolved (parser artifact) | Assigned to garnish step |
| Unresolved count | 14 | 2 (heavy/thickened cream — genuine partial-token-overlap gap, unchanged/expected; "White rice" — a real site-data artifact never mentioned in any step) |

Confirmed via a direct API read (`GET /api/v1/recipes/:id`) that a real `recipe_ingredient_groups` row named "Marinade" now exists with all 9 correct ingredients and clean names (no more note-marker junk baked in).

## Out of scope

- **Multi-section recipes with the same ungrouped-source-data problem** (e.g. a recipe with both an ungrouped "Filling" and an ungrouped "Topping"). Tier 2.5's label-to-run pairing has no signal to disambiguate which detected label corresponds to which contiguous run when there's more than one of each — instruction-mention order and ingredient-list order aren't guaranteed to correspond. Rather than guess a pairing that could easily assign the wrong group to the wrong step, this case is left fully unresolved, same as before this bolt. Revisit only if this comes up in practice and a real correspondence signal (e.g. matching each label's first-mention step-number order to each run's position order) turns out to hold reliably across enough real recipes to trust.
- Slash-separated alternate units still leak into the name (e.g. "1.5 lb / 750 g chicken thigh fillets" keeps "/ 750 g" glued on) — not touched by this bolt; it didn't block matching in the recipe that surfaced it and wasn't part of what was reported.
- The pre-existing partial-token-overlap limitation (Bolt 005) is unchanged — "heavy / thickened cream" still won't match a step that only says "cream", by design.
