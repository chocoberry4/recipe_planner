# Unit 05: Autosort Matching Engine

- **Related**: [Design: Recipe Import & Autosort](../../design/recipe-import-and-autosort.md), [ADR-0004](../../adr/0004-suggest-and-correct-autosort-ux.md)
- **Depends on**: Units 03, 04

## Goal

Implement the tiered matching algorithm (Tier 0 structural, Tier 1 group-in-prose, Tier 2 fuzzy individual, Tier 3 unresolved) as a service object.

## In scope

- Operates on a recipe's `instructions` + `recipe_ingredients` (+ groups)
- Populates `instruction_ingredients` with its best-guess assignment
- Leaves genuinely ambiguous ingredients unassigned rather than force-guessing

## Out of scope

- The review/correction UI (Unit 07)
- Fetching import data (Unit 06)

## Acceptance criteria

- Given fixture recipes covering sectioned ingredients and duplicate-ingredient-different-quantity cases (the two failure modes from the design doc), the engine assigns per the documented tier behavior
- Unresolved cases are left unassigned, not guessed
