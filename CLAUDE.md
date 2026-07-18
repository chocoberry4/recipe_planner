# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a monolithic Ruby on Rails 8.0 application called "recipe_planner" designed for comprehensive meal planning, recipe management, and community recipe sharing. The application combines a Rails API backend with a Vue.js frontend in a single codebase.

## Project Vision

Recipe Planner is a comprehensive meal planning and recipe management system that helps individuals and families organize their meals, discover new recipes, and share culinary experiences with a global community.

### Primary Goals

1. **Personal Meal Planning**: Enable users to plan weekly/monthly meals with an intuitive calendar interface
2. **Recipe Management**: Store, organize, and search personal recipe collections with rich metadata
3. **Family Coordination**: Support household meal planning with dietary preferences and restrictions
4. **Community Sharing**: Create a global platform for users to share, discover, and rate recipes
5. **Smart Shopping**: Automatically generate shopping lists from planned meals

### Target Users

- **Phase 1**: Single user personal meal planning and recipe management
- **Phase 2**: Multi-user household/family coordination
- **Phase 3**: Community-based platform for worldwide recipe sharing and discovery

## Architecture

Rails 8.0 API-only backend (`config.api_only = true`) serving a Vue 3 SPA (`app/frontend/`) built with Vite. `PagesController` (an `ActionController::Base` subclass, not `API`) renders the single SPA shell; `config/routes.rb` catches all non-`/api/` paths and routes them there. Auth is cookie/session-based (not tokens) — see `docs/adr/0001-cookie-session-auth.md`.

All non-obvious architecture decisions, the recipe-import/autosort design, and the unit/bolt task breakdown are tracked under `docs/` (AI-DLC process): `docs/intent/`, `docs/adr/`, `docs/design/`, `docs/units/`, `docs/bolts/`. Check `docs/bolts/*/tasks.md` for what's actually been built vs. still planned before assuming a feature exists.

## Common Development Commands

**Local stack:** the `web` Docker image has no Node.js — Vite must run on the host, not in the container.
```
npx vite                 # run on the Windows host (bin/vite dev won't work — no host-side bundle install)
docker-compose up        # Rails + Postgres; VITE_RUBY_HOST=host.docker.internal bridges the two
```
**Note:** On Windows, use `bin\vite.cmd dev` if `bin/vite dev` doesn't work.

**Running specs — must override `RAILS_ENV` and `DATABASE_URL`, or they silently run against dev:**
```
docker-compose exec -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:postgres@postgres:5432/recipe_planner_test web bundle exec rspec
```
`docker-compose.yml` hardcodes `RAILS_ENV=development` and a dev `DATABASE_URL` as container env vars — `rails_helper.rb`'s `ENV["RAILS_ENV"] ||= "test"` never overrides an already-set value, and `DATABASE_URL` overrides `database.yml` regardless of `RAILS_ENV`. Skipping either flag masks real spec failures as CSRF 403s and pollutes the dev database.

**Linting:** `docker-compose exec web bundle exec rubocop`

See [k8s/README.md](k8s/README.md) for Kubernetes deployment instructions including SSL/TLS setup, scaling, and troubleshooting.

## Core Features

### Phase 1: Personal Recipe & Meal Planning (Current Focus)

#### Recipe Management
- **CRUD Operations**: Create, read, update, and delete recipes
- **Rich Recipe Data**:
  - Title, description, instructions (step-by-step)
  - Ingredients with quantities and units
  - Prep time, cook time, total time
  - Servings/yield information
  - Photos/images
  - Tags and categories (breakfast, lunch, dinner, dessert, etc.)
- **Recipe Search & Filtering**:
  - Search by recipe name, ingredients, or tags
  - Filter by dietary preferences (vegetarian, vegan, gluten-free, dairy-free, etc.)
  - Filter by liked/disliked ingredients
  - Filter by meal type, cuisine, preparation time
- **Portion Scaling**: Automatically adjust ingredient quantities based on desired servings
- **Nutritional Information**: Calculate and display nutritional data per serving

#### Meal Planning
- **Calendar Interface**:
  - Weekly and monthly views
  - Drag-and-drop recipe scheduling
  - Multiple meals per day (breakfast, lunch, dinner, snacks)
- **Meal Dashboard**: Overview of upcoming meals and planning statistics
- **Meal Prep Notes**: Add preparation notes and timing for each scheduled meal

#### Shopping Lists
- **Auto-Generation**: Create shopping lists from planned meals
- **Ingredient Aggregation**: Combine ingredients across multiple recipes
- **List Management**:
  - Check off purchased items
  - Add custom items
  - Organize by store sections/categories
  - Share lists with household members

#### User Preferences
- **Dietary Restrictions**: Set dietary requirements (vegetarian, vegan, allergies, etc.)
- **Ingredient Preferences**:
  - Mark favorite ingredients
  - Mark disliked/avoided ingredients
  - Filter recipes automatically based on preferences
- **Allergen Tracking**: Track and warn about allergens in recipes

### Phase 2: Household/Family Features (Future)

- **Multi-User Support**: Multiple users within a household
- **Shared Meal Planning**: Collaborative meal calendar
- **Individual Preferences**: Track dietary preferences per household member
- **Meal Voting**: Family members vote on meal options
- **Cooking Assignments**: Assign who cooks which meals

### Phase 3: Community & Social Features (Future)

#### Public Recipe Sharing
- **Publish Recipes**: Share personal recipes with the community
- **Recipe Discovery**: Browse and search community recipes
- **Recipe Collections**: Curated recipe collections and meal plans

#### Social Interaction
- **User Profiles**: Public profiles showing shared recipes and activity
- **Recipe Ratings & Reviews**: Community feedback on recipes
- **Comments**: Discussion on recipes
- **Favorites/Bookmarks**: Save community recipes to personal collection
- **Follow System**: Follow favorite recipe creators
- **Recipe Forking**: Copy and modify community recipes for personal use

#### Community Features
- **Trending Recipes**: Popular and trending recipes
- **Seasonal Collections**: Curated seasonal recipe collections
- **Global Cuisine Explorer**: Browse recipes by country/region
- **Cooking Challenges**: Community cooking challenges and events

## Data Models

### Implemented
- **User**: accounts + cookie-session authentication
- **Recipe**: title, description, instructions
- **Ingredient**: ingredient master list
- **RecipeIngredient**: join model linking recipes to ingredients, with `preparation` and optional group membership
- **RecipeIngredientGroup**: named sub-groups of ingredients (e.g. "Marinade") — see `docs/adr/0003-first-class-ingredient-groups.md`
- **Instruction**: step-by-step recipe instructions, optionally scoped to a `RecipeIngredientGroup`
- **InstructionIngredient**: join model linking an instruction step to the specific ingredients it uses (the core of the autosort-matching design in `docs/design/recipe-import-and-autosort.md`)

### Planned
- **MealPlan**: Scheduled meals on calendar
- **ShoppingList**: Generated shopping lists
- **ShoppingListItem**: Individual items on shopping lists
- **Tag**: Recipe categorization tags
- **Category**: Recipe categories (meal type, cuisine, etc.)

### User Preference Models
- **UserDietaryRestriction**: User dietary requirements
- **UserIngredientPreference**: Liked/disliked ingredients
- **UserAllergen**: Allergen tracking

### Community Models (Phase 3)
- **PublicRecipe**: Community-shared recipes
- **RecipeRating**: User ratings on recipes
- **RecipeReview**: User reviews/comments
- **UserFollow**: User following relationships
- **RecipeCollection**: Curated recipe collections
- **RecipeFavorite**: User-favorited recipes

## Development Priorities

### Status
- **Bolt 001 (foundations) — done**: cookie-session auth (signup/login/logout, CORS, router guard), and the ingredient-grouping schema (migrations, models, serializer). See `docs/bolts/bolt-001-foundations/tasks.md` for the 3 real bugs verification found and fixed.
- **Bolt 002 (recipe index) — done**: Vue recipe list page (`app/frontend/views/Recipes.vue`) fetching `GET /api/v1/recipes`.
- **Bolt 003 (recipe CRUD) — done**: `RecipeDetail.vue`, `RecipeForm.vue`, delete, `stores/recipes.js`, router routes for `/recipes/:id`, `/recipes/:id/edit`, plus a first Tailwind-based visual design pass. Ownership check (`require_owner` on update/destroy) added same day — see `docs/bolts/bolt-003-recipe-crud/plan.md`. `RecipeForm.vue` was originally shared create/edit (`/recipes/new` too); as of the Bolt 007 follow-up below it's edit-only — creation lives entirely in `RecipeImport.vue`.
- **`recipe_params` bug — fixed**: now permits `:title`/`:description`; owner is set from `current_user` (not a client-supplied `user_id`) in `RecipesController#create`.
- **Bolt 004 (ingredient-line parser) — done**: `IngredientLineParser` service object (`app/services/ingredient_line_parser.rb`) turns a raw ingredient string into `quantity`/`unit`/`name`/`preparation`. See `docs/bolts/bolt-004-ingredient-line-parser/plan.md`.
- **Bolt 005 (autosort matching engine) — done**: `RecipeAutosorter` service object (`app/services/recipe_autosorter.rb`) implements the tiered structural/group-prose/fuzzy/unresolved matching algorithm, populating `instruction_ingredients`. See `docs/bolts/bolt-005-autosort-matching-engine/plan.md` for the matching-threshold scope decision.
- **Bolt 006 (recipe import) — done**: `JsonLdRecipeExtractor` + `RecipeImporter` (`app/services/`), `POST /api/v1/recipes/import` (URL or manual-paste text), both paths running `IngredientLineParser` + `RecipeAutosorter`. Includes an SSRF guard on the URL path and a `RecipeIngredient#quantity` validation fix (now allows `nil`). See `docs/bolts/bolt-006-recipe-import/plan.md`.
- **Bolt 007 (autosort review UI) — done**: `RecipeImport.vue` (URL/paste-text form) and `RecipeReview.vue` (suggest-and-correct editor per ADR-0004 — assign/remove ingredients per step, Unresolved tray, Save), plus the backend `PATCH /api/v1/recipes/:recipe_id/instruction_ingredients` they call. Verified end-to-end in-browser via Playwright. See `docs/bolts/bolt-007-autosort-review-ui/plan.md` for the "drag" scope decision (implemented as remove-then-add, not HTML5 drag gestures), a Windows dev-server gotcha it surfaced, and later follow-ups (typable multi-add combobox; a manual paste-ingredients/instructions path briefly added to `RecipeForm.vue` then consolidated into `RecipeImport.vue` — "Import" and "New recipe" are now one "Add recipe" entry point, `/recipes/new` is gone).
- **Bolt 008 (implied collective grouping) — done**: found by testing the URL-import path against a real external site (RecipeTinEats) rather than synthetic data. Fixed a parser bug (`IngredientLineParser` was leaving parenthetical asides like "(30 g)"/"((Note 4))" baked into `name`, silently blocking Tier 2 matching), and added a new, deliberately conservative `RecipeAutosorter` tier ("Tier 2.5") that groups ingredients referenced only collectively in prose ("the Marinade ingredients") when there's exactly one such label and exactly one contiguous unassigned ingredient run — otherwise it bails out rather than guess. See `docs/bolts/bolt-008-implied-collective-grouping/plan.md` for the full before/after and the multi-section case it deliberately doesn't cover.

**All of Units 01-08 (the recipe-import/autosort roadmap from `docs/design/recipe-import-and-autosort.md`, plus the real-world-testing follow-up in Unit 08) are now done.**

### Next up (per `docs/units/`)
No unit briefs exist yet for what comes next — pick from "Future Enhancements" below (meal planning, shopping lists, portion scaling, nutritional info are the nearest Phase 1 remainder) or revisit UI polish, since Unit 07 was the first new UI surface since Bolt 003's design pass and hasn't had one. A good next real-world-testing candidate: import a recipe with *multiple* ungrouped sections to see how often Tier 2.5's single-label/single-run restriction actually bails out in practice.

### Future Enhancements (Phase 2/3, not yet scheduled into units)
1. Meal planning calendar, shopping list generation, portion scaling, nutritional info (Phase 1 remainder)
2. Multi-user household features (Phase 2)
3. Community and social features (Phase 3)