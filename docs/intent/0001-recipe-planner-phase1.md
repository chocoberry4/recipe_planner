# Intent 0001: Recipe Planner — Phase 1 (Personal Recipe & Meal Planning)

- **Status**: Accepted
- **Owner**: Vonnie Voong
- **Related**: [ADR-0001](../adr/0001-cookie-session-auth.md), [ADR-0002](../adr/0002-postgresql-over-mongodb.md), [ADR-0003](../adr/0003-first-class-ingredient-groups.md), [ADR-0004](../adr/0004-suggest-and-correct-autosort-ux.md), [ADR-0005](../adr/0005-jsonld-first-recipe-import.md), [Design: Recipe Import & Autosort](../design/recipe-import-and-autosort.md), [Design: Meal Planning Calendar](../design/meal-planning-calendar.md)

## Why

Existing recipe/meal-planning tools (e.g. Tandoor, self-hosted on the author's NAS) get the basics right but fall down on recipe import quality — specifically, matching ingredients to instruction steps is unreliable once a recipe has sectioned ingredients ("Marinade", "For the sauce") or repeats an ingredient with different quantities per step. Recipe Planner exists to be a personal meal-planning tool that solves that problem properly, while covering the standard personal recipe/meal-planning workflow end to end.

## Scope — Phase 1 (this intent)

Single-user personal use. In scope:

- Recipe CRUD with rich metadata (ingredients, step-by-step instructions, sectioned ingredient groups)
- Recipe import from a URL (structured-data extraction) and manual entry, both feeding a shared step/ingredient auto-sort engine
- Recipe search/filtering (tags, categories, dietary flags) — not yet designed, tracked as a future unit
- Meal planning calendar — not yet designed, tracked as a future unit
- Shopping list generation from planned meals — schema exists (`shopping_lists`, `shopping_list_items`), generation logic not yet built
- Dietary preferences, ingredient likes/dislikes, allergen tracking — not yet designed
- Portion scaling, nutritional info — not yet designed

Out of scope for Phase 1 (see CLAUDE.md for the full phased vision):

- Multi-user/household coordination (Phase 2)
- Public community sharing, ratings, follows (Phase 3)

## System context (current, as of this intent)

- Rails 8.0 API-only backend + Vue.js frontend (Vite), monolithic repo
- PostgreSQL with Solid Cache/Queue/Cable
- Schema: `users`, `recipes`, `ingredients`, `recipe_ingredients`, `instructions`, `pantry_items`, `shopping_lists`, `shopping_list_items`
- `RecipesController` has full CRUD; `users`/`ingredients`/`auth` routes exist but have no controllers yet
- Vue: only an empty `Home.vue`; `Recipes.vue` is routed but not created

## Success criteria

1. A user can paste a recipe URL (or type one manually) and get ingredients split into groups and instructions split into steps, with each step showing the ingredients it needs — correctly, including sectioned and duplicate-ingredient cases Tandoor gets wrong.
2. Auto-sort suggestions are always reviewable/correctable before being saved — never silently wrong.
3. A user can log in, create/edit/view their own recipes, and the Vue frontend actually renders this (no dead routes).

## Open questions (deferred, not blocking Phase 1 recipe/import work)

- ~~Meal planning calendar data model~~ — resolved, see [Design: Meal Planning Calendar](../design/meal-planning-calendar.md)
- ~~Tags/categories data model~~ — resolved ad-hoc 2026-07-22, see CLAUDE.md's Development Priorities status log (`Tag`/`RecipeTag`)
- Dietary restriction / allergen / ingredient preference data model
- Nutrition + portion scaling approach
