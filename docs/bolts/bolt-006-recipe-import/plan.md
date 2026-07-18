# Bolt 006: Recipe Import (URL)

- **Unit covered**: [Unit 06 — Recipe Import (URL)](../../units/06-recipe-import/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)
- **Depends on**: Bolt 004 (`IngredientLineParser`), Bolt 005 (`RecipeAutosorter`), Unit 03 schema

## Approach

Two new service objects, both backend-only (no frontend import form yet — see "Out of scope"):

- **`JsonLdRecipeExtractor`** (`app/services/json_ld_recipe_extractor.rb`): pure parsing, `.extract(html)`. Parses every `<script type="application/ld+json">` tag with Nokogiri, unwraps `@graph` if present, and returns the first node whose `@type` includes `"Recipe"`. `recipeInstructions` is normalized into a flat, ordered list of `{ text, group_name }` entries regardless of whether the source used plain strings, `HowToStep` hashes, or `HowToSection` (whose nested steps get tagged with the section name) — flattening this up front means the persistence layer doesn't need to know about JSON-LD's shape at all. Malformed JSON in one `<script>` tag is skipped, not fatal, in case a page has multiple ld+json blocks. Returns `nil` if no Recipe node is found — the caller's fallback signal.

- **`RecipeImporter`** (`app/services/recipe_importer.rb`): orchestrates both paths from ADR-0005.
  - `.from_url(url, user:)`: validates + fetches the URL, runs it through the extractor, and persists on success; returns a `Result` (`ok?`, `recipe`, `reason`) rather than raising, so a `:no_structured_data` reason cleanly signals "fall back to manual paste" without an exception-driven control flow.
  - `.from_text(title:, description:, ingredients_text:, instructions_text:, user:)`: the manual-paste path — same persistence code, fed from newline-split raw text instead of extracted JSON-LD. This is also the fallback ADR-0005 requires, and (per the ADR) must work standalone as the from-scratch recipe-writing path, not just as a degraded JSON-LD fallback — it takes no `source_url` and needs no JSON-LD detour.
  - Persistence (shared by both): create the `Recipe`, run each ingredient line through `IngredientLineParser` into an `Ingredient` (`find_or_create_by!` on name) + `RecipeIngredient`, create `Instruction`s in order (lazily creating a `RecipeIngredientGroup` per distinct `group_name` seen, so `HowToSection`-sourced steps get Tier-0-ready structural links even though — per the design doc's known limitation — the *ingredient* side of that group starts empty and needs manual grouping later), then call `RecipeAutosorter.call(recipe)`.

**SSRF guard**: `.from_url` fetches a URL the *user* supplies, server-side, before any ownership/trust check on the target — a classic SSRF vector (cloud metadata endpoints, internal services, `localhost`). `RecipeImporter.safe_host?` resolves the hostname and rejects private/loopback/link-local ranges (RFC1918, `127.0.0.0/8`, `169.254.0.0/16`, IPv6 equivalents) before connecting. This is a reasonable but not exhaustive mitigation — it doesn't pin the resolved IP across the DNS-lookup/connect gap (a determined DNS-rebinding attack could still slip through), which is a deliberate scope cut given this app's threat model (small personal/community app, not a target for that level of sophistication); flagged here in case that changes. No redirect-following, which also closes off a common bypass for this kind of check.

**Model fix required for this unit**: `RecipeIngredient#quantity`'s numericality validation had no `allow_nil: true`, which rejected exactly the "missing quantity" ingredient lines (`"Salt to taste"`) `IngredientLineParser` is explicitly designed to produce (Unit 04's own acceptance criteria). Fixed alongside this bolt; covered by a new model spec.

## Definition of done

- `POST /api/v1/recipes/import` (`Api::V1::RecipeImportsController`, login required): accepts either `{ url: }` or `{ title:, description:, ingredients_text:, instructions_text: }`, returns the created recipe (201) or `{ error: reason }` (422).
- JSON-LD path: fetch → extract (including `@graph` unwrapping and `HowToSection`) → parse ingredients via `IngredientLineParser` → autosort via `RecipeAutosorter`.
- Manual-paste path: same pipeline minus the fetch/extract step, working standalone.
- SSRF guard on the URL path (private/loopback/link-local ranges rejected before any request is made).
- Full suite: 76 examples, 0 failures, 1 unrelated pending. Rubocop and Brakeman clean.

## Follow-up (2026-07-18): decode raw HTML entities in JSON-LD text

Found via real-world testing against RecipeTinEats (see Bolt 008): its `recipeInstructions` and `description` fields contain literal, undecoded entity strings — `"Cook chicken:&nbsp;Heat..."`, `"you&#39;ll find..."` — not real whitespace/apostrophe characters. `CGI.unescapeHTML` wouldn't have caught this (it only handles `amp`/`quot`/`gt`/`lt` plus numeric refs, not named entities like `nbsp`). Added a `clean_text` step to `JsonLdRecipeExtractor` using `Nokogiri::HTML.fragment(text).text`, which decodes the full named+numeric entity set; the resulting non-breaking spaces are flattened to regular spaces and whitespace runs squished. Applied to title, description, ingredient lines, instruction text, and `HowToSection` names.

## Out of scope

- Per-site scrapers (ADR-0005 decision — JSON-LD only, no maintenance burden of scraper-per-site)
- Ingredient-side HTML section-header detection (documented limitation in the design doc)
- Frontend import form / review UI — Unit 07 owns the review UI; this bolt is the API + pipeline only, following the same backend-first pattern as Bolts 004-005. `POST /api/v1/recipes/import` is fully testable via request specs in the meantime.
