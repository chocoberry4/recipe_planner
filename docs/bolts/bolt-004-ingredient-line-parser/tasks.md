# Bolt 004 — Tasks

**Status: done.** Full RSpec suite: 52 examples, 0 failures, 1 unrelated pending. Rubocop clean.

- [x] `IngredientLineParser` service object (`app/services/ingredient_line_parser.rb`)
- [x] Numeric fraction parsing (mixed and simple)
- [x] Unicode fraction parsing (spaced and glued to a whole number)
- [x] Decimal/integer quantity parsing
- [x] Known-unit list matching + `"of"` stripping
- [x] Missing quantity / missing unit handled gracefully
- [x] Name/preparation split on first comma, including prep-note-free lines
- [x] Test suite (`spec/services/ingredient_line_parser_spec.rb`, 13 examples)
