# Unit 06: Recipe Import (URL)

- **Related**: [ADR-0005](../../adr/0005-jsonld-first-recipe-import.md), [Design: Recipe Import & Autosort](../../design/recipe-import-and-autosort.md)
- **Depends on**: Units 03, 04, 05

## Goal

Implement the JSON-LD-first import pipeline from ADR-0005.

## In scope

- Endpoint accepting a recipe URL
- Fetch + extract `schema.org/Recipe` JSON-LD (including `@graph` unwrapping)
- Map extracted data into recipe/ingredient/instruction records via the Unit 04 parser
- Invoke the Unit 05 autosort engine on the result
- Fallback path: manual paste of raw text when no JSON-LD is found, through the same parser/engine

## Out of scope

- Per-site scrapers
- Ingredient-side HTML section-header detection (documented limitation in the design doc, not planned)

## Acceptance criteria

- Pasting a URL from a JSON-LD-supporting site produces a recipe with parsed ingredients/instructions and an initial, reviewable autosort assignment
