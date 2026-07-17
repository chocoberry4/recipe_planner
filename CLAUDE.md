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
- **Bolt 003 (recipe CRUD) — done**: `RecipeDetail.vue`, `RecipeForm.vue` (shared create/edit), delete, `stores/recipes.js`, router routes for `/recipes/new`, `/recipes/:id`, `/recipes/:id/edit`. See `docs/bolts/bolt-003-recipe-crud/plan.md` for a known follow-up (no ownership check on update/destroy — any logged-in user can currently edit/delete any recipe).
- **`recipe_params` bug — fixed**: now permits `:title`/`:description`; owner is set from `current_user` (not a client-supplied `user_id`) in `RecipesController#create`.

### Next up (per `docs/units/`)
1. Follow-up: add an ownership check (`require_owner`) to `RecipesController#update`/`#destroy` — see Bolt 003 known gap
2. Units 04-05 — ingredient-line parser + autosort matching engine (the core differentiator vs. Tandoor, see `docs/design/recipe-import-and-autosort.md`)
3. Unit 06 — recipe import (JSON-LD first, per `docs/adr/0005-jsonld-first-recipe-import.md`)
4. Unit 07 — autosort review UI

### Future Enhancements (Phase 2/3, not yet scheduled into units)
1. Meal planning calendar, shopping list generation, portion scaling, nutritional info (Phase 1 remainder)
2. Multi-user household features (Phase 2)
3. Community and social features (Phase 3)