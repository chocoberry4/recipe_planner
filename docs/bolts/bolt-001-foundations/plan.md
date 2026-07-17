# Bolt 001: Foundations — Auth + Ingredient Grouping Schema

- **Units covered**: [Unit 01 — Authentication](../../units/01-authentication/unit-brief.md), [Unit 03 — Ingredient Grouping Schema](../../units/03-ingredient-grouping-schema/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)

## Why these two, together, first

Neither unit depends on anything else, and both unblock everything downstream:

- Unit 02 (Vue views) needs Unit 01 (auth) to know the current user.
- Units 04–07 (parser, matching engine, import, review UI) all need Unit 03 (schema) to exist before they have anything to operate on.

Bundling them into one bolt because they're independent of each other and can be worked in either order (or in parallel) without blocking, and together they clear every first-layer dependency in the unit graph.

## Definition of done

- `AuthController` live: login/signup/logout work through the Vue app, session cookie set/cleared correctly, CORS configured for the Vite dev server.
- Migrations for `recipe_ingredient_groups`, the additive `recipe_ingredients`/`instructions` columns, and `instruction_ingredients` are applied; models and `RecipeSerializer` updated; existing recipe CRUD specs still pass.
- Request specs added for the auth flow; existing `spec/requests/recipe_spec.rb` extended to cover `show`/`create`/`update`/`destroy` (already a known gap) plus the new nullable fields.

## Out of scope for this bolt

- Recipe Vue views (Unit 02) — next bolt, once auth exists.
- Parser, matching engine, import, review UI (Units 04–07) — next bolts, once schema exists.
