# Unit 03: Ingredient Grouping Schema

- **Related**: [ADR-0003](../../adr/0003-first-class-ingredient-groups.md)
- **Depends on**: —

## Goal

Implement ADR-0003's schema changes — the foundation everything in the autosort design depends on.

## In scope

- Migration: `recipe_ingredient_groups` (`recipe_id`, `name`, `position`)
- Migration: `recipe_ingredients` gains `recipe_ingredient_group_id` (nullable), `preparation`, `position`
- Migration: `instructions` gains `recipe_ingredient_group_id` (nullable)
- Migration: `instruction_ingredients` join table (`instruction_id`, `recipe_ingredient_id`)
- Model associations + validations for the above
- `RecipeSerializer` updated to include groups and preparation

## Out of scope

- Any matching/autosort logic (Units 04, 05)
- Any UI

## Acceptance criteria

- Migrations run cleanly
- Models expose group associations (`Recipe has_many :recipe_ingredient_groups`, etc.)
- Existing recipe CRUD still works with the new fields nullable/optional
