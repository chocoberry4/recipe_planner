# Bolt 004: Ingredient-Line Parser

- **Unit covered**: [Unit 04 — Ingredient-Line Parser](../../units/04-ingredient-line-parser/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)
- **Depends on**: Bolt 001 (Unit 03 schema — `preparation` column)

## Approach

`IngredientLineParser` is a plain Ruby service object (`app/services/ingredient_line_parser.rb`), not an ActiveRecord model — it has no persistence concerns, matching the design doc's framing of it as a shared building block used by both the JSON-LD import path (Unit 06) and manual paste. `.parse(line)` returns a `Struct` with `quantity`/`unit`/`name`/`preparation`.

Parsing runs in three ordered stages, each consuming a prefix of the string and passing the remainder on: quantity (numeric/unicode fraction/decimal) → unit (checked against a known-unit list, `"of"` stripped if present) → name/preparation (split on the first comma). Anything not recognized at a stage is left untouched for the next one, so `"3 large eggs"` correctly leaves `"large"` as part of the name rather than misreading it as a unit.

Deliberately heuristic per the design doc — it does not need to be perfect, since output lands in an editable field and Tier 2 matching (Unit 05) already tolerates imperfect normalization. Scope was kept to what the unit brief lists (numeric/unicode fractions, known-unit list, missing quantity/unit, prep-note-free lines); things like quantity ranges or synonym handling were intentionally left out as out-of-scope/future work per the design doc.

## Definition of done

- `IngredientLineParser.parse(line)` returns `quantity`, `unit`, `name`, `preparation`.
- Handles mixed numeric fractions (`"1 1/2"`), simple numeric fractions (`"1/2"`), unicode fractions both spaced and glued to a whole number (`"½"`, `"1½"`), and plain decimals.
- Recognizes a known-unit list and strips a leading `"of"` after the unit.
- Leaves quantity/unit `nil` gracefully when absent rather than misparsing.
- Splits the remainder into `name`/`preparation` on the first comma.
- Covered by request-free service spec (`spec/services/ingredient_line_parser_spec.rb`), 13 examples.

## Out of scope

- Matching/autosort (Unit 05)
- Fetching import data (Unit 06)
- Synonym/alias handling, quantity ranges — not in the design doc's stated scope
