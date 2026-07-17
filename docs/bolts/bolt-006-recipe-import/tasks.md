# Bolt 006 — Tasks

**Status: done.** Full RSpec suite: 76 examples, 0 failures, 1 unrelated pending. Rubocop and Brakeman clean.

- [x] `JsonLdRecipeExtractor` service (`app/services/json_ld_recipe_extractor.rb`)
- [x] `@graph` unwrapping, `HowToStep`/`HowToSection`/plain-string instruction handling
- [x] Malformed JSON-LD in one `<script>` tag doesn't take down extraction of a later valid one
- [x] `RecipeImporter.from_url` — fetch, extract, persist, run `RecipeAutosorter`
- [x] `RecipeImporter.from_text` — manual-paste path, same persistence/autosort pipeline
- [x] SSRF guard: reject private/loopback/link-local hosts before fetching
- [x] `POST /api/v1/recipes/import` (`RecipeImportsController`), login required
- [x] Fix: `RecipeIngredient#quantity` now allows `nil` (needed for "to taste"-style lines)
- [x] Specs: `json_ld_recipe_extractor_spec.rb` (8), `recipe_importer_spec.rb` (6), `recipe_imports_spec.rb` (4), plus a `recipe_ingredient_spec.rb` addition
- [x] Brakeman scan run given the new server-side URL fetch — 0 warnings
