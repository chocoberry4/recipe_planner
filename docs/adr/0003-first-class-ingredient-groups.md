# ADR-0003: First-class ingredient groups

- **Status**: Accepted
- **Related**: [Intent 0001](../intent/0001-recipe-planner-phase1.md), [Design: Recipe Import & Autosort](../design/recipe-import-and-autosort.md)

## Context

Recipes commonly section their ingredients ("Marinade", "For the sauce", "Dry ingredients"). Instructions then often refer to a whole section collectively ("mix the marinade ingredients together") rather than naming each ingredient. Separately, the same ingredient can appear twice in one recipe with different quantities for different steps (e.g. "2 tbsp soy sauce" in the marinade, "1 tbsp soy sauce" in the glaze) — Tandoor, the tool motivating this project, gets both cases wrong because it treats ingredients as a flat list and matches by first occurrence / substring.

The current schema (`recipe_ingredients` as a flat join table between `recipes` and `ingredients`) has no concept of sectioning.

## Decision

Add ingredient groups as first-class schema, not a display-only convention:

```
recipe_ingredient_groups
  id, recipe_id, name, position

recipe_ingredients (additive changes)
  recipe_ingredient_group_id  (nullable — ungrouped recipes leave this null)
  preparation                 (string, nullable — "minced", "room temperature",
                                split out of the ingredient name so matching
                                works against the clean canonical name)
  position
```

This is deliberately decided now, before building the auto-sort engine, because the matching algorithm's two strongest tiers (structural section alignment, and group-name-in-prose matching — see the design doc) depend on groups existing as real rows, not being inferred at read time.

## Consequences

- Migration required on `recipe_ingredients`; existing recipes are treated as fully ungrouped (`recipe_ingredient_group_id IS NULL`) after migration — no backfill needed since no recipes with real ingredient data exist yet.
- `instructions` also gains an optional `recipe_ingredient_group_id` for recipes whose source data structurally ties a step to a section (see ADR-0005).
- Recipe forms/UI need to support creating/naming/reordering groups, not just flat ingredient lists.
