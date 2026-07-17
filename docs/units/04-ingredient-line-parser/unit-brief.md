# Unit 04: Ingredient-Line Parser

- **Related**: [Design: Recipe Import & Autosort](../../design/recipe-import-and-autosort.md)
- **Depends on**: Unit 03 (needs `preparation` column to exist)

## Goal

Implement the shared parser described in the design doc: turn a raw ingredient line into structured fields.

## In scope

- Parse strings like `"1 1/2 cups all-purpose flour, sifted"` into `quantity`, `unit`, `name`, `preparation`
- Handle numeric and unicode fractions, a known-unit list, missing quantity/unit, prep-note-free lines
- Test suite covering the cases above

## Out of scope

- Matching/autosort itself (Unit 05)
- Fetching import data (Unit 06)

## Acceptance criteria

- Parser is a standalone service/class with test coverage for the documented edge cases
