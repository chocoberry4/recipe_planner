# Unit 08: Implied Collective Grouping

- **Related**: [Design: Recipe Import & Autosort Engine](../../design/recipe-import-and-autosort.md) (revises its "Known limitations" section), [ADR-0003](../../adr/0003-first-class-ingredient-groups.md)
- **Depends on**: Unit 05 (Autosort Matching Engine), Unit 06 (Recipe Import), Unit 07 (Autosort Review UI)

## Goal

Live-testing real-world recipe imports (RecipeTinEats' Butter Chicken) surfaced two problems in the shipped Units 04-07 pipeline:

1. A parser bug: parenthetical asides ("(30 g)", "(aka tomato puree)", "((Note 4))") were left inside `RecipeIngredient#name` instead of being stripped, which silently blocked Tier 2 exact-token-containment matching for any ingredient whose source line had one — even when the ingredient was named verbatim in a step.
2. A real design gap the original design doc had explicitly called out and deferred: sites that group ingredients only in instruction prose ("Marinade: Combine the Marinade ingredients...") with zero grouping signal anywhere in their structured data leave every ingredient in that group permanently unresolved, since neither Tier 0/1 (need a pre-existing group) nor Tier 2 (needs the ingredient individually named) can fire.

## In scope

- Fix `IngredientLineParser` to strip parenthetical asides into `preparation` instead of leaving them in `name`.
- A new, deliberately conservative autosort tier ("Tier 2.5") that detects a single collective-reference label in prose (e.g. "the Marinade") and, only when there's exactly one such label and exactly one contiguous run of still-unassigned ingredients, creates a real `RecipeIngredientGroup` for it and assigns the whole run to the step that most directly names it.

## Out of scope

- Multi-section recipes with this same data gap (e.g. both "Filling" and "Topping" ungrouped in source data) — pairing multiple labels to multiple runs isn't reliably derivable from position alone, so this case still falls through to fully-manual grouping. See the bolt plan for why.
- General synonym/alias matching, or fixing every possible parser edge case (e.g. slash-separated alternate units like "1.5 lb / 750 g") — out of scope here, unchanged from the original design doc's stated limitations.

## Acceptance criteria

- Importing RecipeTinEats' Butter Chicken assigns all 9 marinade ingredients to the step that actually uses them ("Marinade: Combine..."), not left unresolved and not assigned to an unrelated step that merely mentions the group in passing.
- Ingredients named directly in a step (e.g. "ghee", "tomato passata") that were previously blocked by parser artifacts now match correctly.
