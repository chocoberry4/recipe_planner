# ADR-0005: JSON-LD-first recipe import

- **Status**: Accepted
- **Related**: [Intent 0001](../intent/0001-recipe-planner-phase1.md), [Design: Recipe Import & Autosort](../design/recipe-import-and-autosort.md)

## Context

Tandoor's import (and the feature we're improving on) starts from a pasted URL. Most recipe blogs and recipe-plugin-powered WordPress sites embed `schema.org/Recipe` structured data as `<script type="application/ld+json">` for Google's recipe rich snippets. This is a generic, site-agnostic mechanism — not a per-site scraper — and gives clean `recipeIngredient` (flat string array) and `recipeInstructions` (flat strings, or `HowToStep`/`HowToSection` objects) directly.

## Decision

Import pipeline tries structured data first:

1. Fetch the URL, look for `@type: "Recipe"` JSON-LD (including inside a `@graph` wrapper).
2. If found, extract `recipeIngredient` and `recipeInstructions` directly. If `recipeInstructions` uses `HowToSection`, that's structural section data usable directly by the autosort engine's top tier (see design doc) — no prose guessing needed for those steps.
3. If no JSON-LD is found (or parsing fails), fall back to manual paste: the user pastes raw ingredient/instruction text, which goes through the same shared ingredient-line parser and autosort engine as the JSON-LD path.

A single ingredient-line parser (splits `"1½ cups flour, sifted"` into quantity / unit / canonical name / preparation) backs both paths, so there is one parsing implementation to maintain, not two.

## Consequences

- Known limitation: ingredient-side grouping (section headers like "Marinade" within the ingredient list) is rarely present in JSON-LD even when instructions are sectioned — sites put that in rendered HTML, not structured data. Imported recipes may still need manual ingredient grouping after import; JSON-LD mainly saves retyping, not full auto-structuring.
- No per-site scrapers to build or maintain — reduces long-term maintenance burden compared to Tandoor-style site-specific scrapers, at the cost of not supporting sites with no structured data and no readable fallback text.
- Manual paste path must remain fully functional on its own (not just a degraded JSON-LD fallback), since it's also the primary path for recipes the user writes from scratch.
