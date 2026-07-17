# ADR-0002: PostgreSQL over MongoDB

- **Status**: Accepted
- **Related**: [Intent 0001](../intent/0001-recipe-planner-phase1.md)

## Context

The question came up whether MongoDB would be a better fit for recipe data, given recipes/instructions/ingredients have a somewhat nested, semi-structured shape (especially once ingredient groups and imported JSON-LD data are involved).

## Decision

Stay on PostgreSQL. Do not introduce MongoDB.

Rationale:

- The core data model is inherently relational: `users → recipes → recipe_ingredient_groups → recipe_ingredients → instructions`, plus `meal_plans` and `shopping_lists` down the line. This is foreign keys and joins — exactly Postgres's strength — not a set of independent documents.
- The app already runs on Rails 8's Solid stack (Solid Cache, Solid Queue, Solid Cable), which is Postgres-backed. Adding MongoDB would mean running and operating a second database for no relational-modeling gain.
- Where genuine schema flexibility is needed (e.g. storing a raw imported JSON-LD payload for reference, or an evolving user-preferences blob), Postgres's `jsonb` column type covers it inside the existing relational model — no second database required.

## Consequences

- Any semi-structured data (raw import payloads, etc.) is stored as `jsonb` columns on the relevant table, not as separate documents.
- Schema changes go through normal Rails migrations; no schema-less modeling.
