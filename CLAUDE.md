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
.\bin\dev-local.ps1       # one-shot: docker-compose up -d, db:prepare, then npx vite in the foreground
```
Or manually:
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

## Deployment

Two independent deployment paths run from the same `Dockerfile`/image:

- **GCP + Kamal** (primary): `config/deploy.yml` + `.kamal/secrets`, deployed via `bin/kamal deploy` — also wired into `.github/workflows/ci.yml`'s `deploy` job on every push. Runs on a free-tier e2-micro VM (1 shared vCPU, 1GB RAM + a 2GB swap file) with no domain/TLS cert yet, hence `proxy.ssl: false`.
- **Unraid** (self-hosted alternative): `unraid/docker-compose.yml` + a sibling, gitignored `unraid/.env` for secrets. Pulls from a self-hosted Docker Registry v2 on the LAN (`192.168.50.181:5000`) — build+push is manual from a dev machine, since GitHub Actions runners can't reach LAN IPs, so this path isn't part of CI.

**No real TLS terminates in front of either deployment yet.** `config/environments/production.rb`'s `assume_ssl`/`force_ssl` and `config/application.rb`'s `session_store` `secure:` option were both previously tied to `Rails.env.production?` alone — which silently broke login/signup, since browsers refuse to store/send back a cookie marked `Secure` over a non-HTTPS connection. Both are now hardcoded off; only flip them back once a real domain + TLS cert sits in front of the app.

**Building the image on Windows**: the Dockerfile's final stage `chown`s *and* `chmod`s `db log storage tmp` — the chmod matters because Docker Desktop's Windows file-sharing layer can carry over fresh/empty directories with the write bit stripped (mode 555), which a Linux-native build (e.g. GitHub Actions) never hits. An `Errno::EACCES` on `/rails/tmp/sockets` at container boot, only on a locally-built image, traces back to this.

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
- **User**: accounts + cookie-session authentication; also carries planner display preferences (`show_breakfast/lunch/dinner/snack` booleans, `home_view` enum) — see `docs/design/meal-planning-calendar.md`
- **Recipe**: title, description, instructions
- **Ingredient**: ingredient master list
- **RecipeIngredient**: join model linking recipes to ingredients, with `preparation` and optional group membership
- **RecipeIngredientGroup**: named sub-groups of ingredients (e.g. "Marinade") — see `docs/adr/0003-first-class-ingredient-groups.md`
- **Instruction**: step-by-step recipe instructions, optionally scoped to a `RecipeIngredientGroup`
- **InstructionIngredient**: join model linking an instruction step to the specific ingredients it uses (the core of the autosort-matching design in `docs/design/recipe-import-and-autosort.md`)
- **Tag** / **RecipeTag**: recipe categorization tags, many-to-many via `RecipeTag`; user-entered free text normalized (strip/downcase) on write
- **TagPin**: per-user "pinned" tags (set on the Settings page) that surface first in the recipe index's tag-filter row
- **MealPlan**: a recipe *or freeform label* scheduled onto a `date` + fixed `meal_type` (breakfast/lunch/dinner/snack), drag-and-drop movable between slots; see `docs/design/meal-planning-calendar.md`

### Planned
- **ShoppingList**: Generated shopping lists
- **ShoppingListItem**: Individual items on shopping lists
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
- **Bolt 006 (recipe import) — done**: `JsonLdRecipeExtractor` + `RecipeImporter` (`app/services/`), `POST /api/v1/recipes/import` (URL or manual-paste text), both paths running `IngredientLineParser` + `RecipeAutosorter`. Includes an SSRF guard on the URL path and a `RecipeIngredient#quantity` validation fix (now allows `nil`). See `docs/bolts/bolt-006-recipe-import/plan.md`, including a later follow-up: some sites' JSON-LD (e.g. RecipeTinEats) embeds raw, undecoded HTML entities (`&nbsp;`, `&#39;`) as literal text — `JsonLdRecipeExtractor` now decodes them via `Nokogiri::HTML.fragment(...).text` and squishes the result.
- **Bolt 007 (autosort review UI) — done**: `RecipeImport.vue` (URL/paste-text form) and `RecipeReview.vue` (suggest-and-correct editor per ADR-0004 — assign/remove ingredients per step, Unresolved tray, Save), plus the backend `PATCH /api/v1/recipes/:recipe_id/instruction_ingredients` they call. Verified end-to-end in-browser via Playwright. See `docs/bolts/bolt-007-autosort-review-ui/plan.md` for the "drag" scope decision (implemented as remove-then-add, not HTML5 drag gestures), a Windows dev-server gotcha it surfaced, and later follow-ups (typable multi-add combobox; a manual paste-ingredients/instructions path briefly added to `RecipeForm.vue` then consolidated into `RecipeImport.vue` — "Import" and "New recipe" are now one "Add recipe" entry point, `/recipes/new` is gone).
- **Bolt 008 (implied collective grouping) — done**: found by testing the URL-import path against a real external site (RecipeTinEats) rather than synthetic data. Fixed a parser bug (`IngredientLineParser` was leaving parenthetical asides like "(30 g)"/"((Note 4))" baked into `name`, silently blocking Tier 2 matching), and added a new, deliberately conservative `RecipeAutosorter` tier ("Tier 2.5") that groups ingredients referenced only collectively in prose ("the Marinade ingredients") when there's exactly one such label and exactly one contiguous unassigned ingredient run — otherwise it bails out rather than guess. See `docs/bolts/bolt-008-implied-collective-grouping/plan.md` for the full before/after and the multi-section case it deliberately doesn't cover.

**All of Units 01-08 (the recipe-import/autosort roadmap from `docs/design/recipe-import-and-autosort.md`, plus the real-world-testing follow-up in Unit 08) are now done.**

- **2026-07-19 follow-up — Tier 2 loosened, real match-rate improvement verified live**: real-world testing found Tier 2's all-tokens-required rule left most ingredients unresolved whenever a step dropped a descriptive modifier ("dark soy sauce" → step just says "soy sauce"). `RecipeAutosorter`'s Tier 2 now requires only the ingredient's head noun (last token) to be present, tolerating one missing modifier token; when two different ingredients share a head noun, a complete match always wins outright, and a genuine tie among partial matches is left unresolved rather than guessed (see `match_score`/`candidate_ingredient_ids`). Also fixed `IngredientLineParser` to split a bare, non-parenthetical alternate-name synonym ("plain flour / all-purpose flour", "chicken stock/broth") into a canonical name + an "aka" preparation note (`extract_alt_name`), instead of leaving a permanent multi-word compound name Tier 2 could never fully restate. Verified by re-importing both real test recipes fresh: Tres Leches Cake went from 1/16 → 8/16 matched; Thai Chicken Peanut Noodles went from 6/15 → 12/15. Full spec suite green throughout (128 examples). Remaining unresolved items on both recipes now trace to distinct, separately-scoped issues not yet tackled: "or"-based ingredient substitutions ("instant ramen **or** noodle cakes"), a quantity word leaking into the name ("**handfuls** baby spinach"), a leading descriptive phrase with no comma to split on ("**Roughly chopped fresh** coriander"), and Tres Leches' still-unfixed multi-section grouping problem (see the 2026-07-19 investigation above).

- **2026-07-22 follow-up — tags, search/filter, Settings page, dark/light theme (ad-hoc, no bolt directory)**: added recipe tagging end to end — `Tag`/`RecipeTag` models, a chip editor on `RecipeReview.vue`, tag pills on both the index and detail pages, and search + AND-tag-filtering on the recipe index (`Recipes.vue`). Added a `Settings.vue` page for two orthogonal things: pinning tags (`TagPin` model, `GET/PATCH /api/v1/pinned_tags`) so a long tag list doesn't crowd out the ones the user cares about on the index's filter row, and a light/dark/system theme toggle (`stores/theme.js`, `[data-theme]` CSS-variable overrides in `main.css`, a pre-paint inline script in the layout to avoid a flash of the wrong theme — no per-component `dark:` classes needed). Also: hover-reveal Edit button on index cards (no reserved layout space), a Delete button on the edit page mirroring the detail page's, `recipe.source_url` shown on the detail page, a fix for the top-right nav showing blank instead of falling back to email when `username` is nil, and a wider main container (`max-w-4xl` → `max-w-6xl`). Verified via the full RSpec suite (139 examples) and live Playwright walkthroughs of every UI change. Separately, CI's `deploy` job (`.github/workflows/ci.yml`) was hardcoded to `if: false` to disable auto-deploy-on-push-to-main "for now" — brakeman/bundle_audit/lint/test still run; flip the `if:` back per the comment above the job when ready to re-enable.

- **2026-07-22 follow-up #2 — step mode, custom delete modal, per-step images, recipe duration (ad-hoc, no bolt directory)**: added `StepMode.vue` (route `/recipes/:id/steps`), a full-screen cook-along view showing one instruction at a time with giant Previous/Next buttons (disabled at the first/last step), arrow-key support, and a Wake Lock (`navigator.wakeLock`) to keep the screen on while cooking — re-acquired on visibility change, degrades silently where unsupported (e.g. Firefox). Extracted the ingredient-lookup logic `RecipeDetail.vue` already had into `lib/recipeIngredients.js` so both views share it. Replaced `window.confirm` for recipe deletion (detail + edit pages) with a reusable `ConfirmDialog.vue` modal (`Teleport`'d overlay; closes on Cancel/Escape/backdrop click). Added per-step images (`instructions.image_url`): a "Step image URL" field + thumbnail on the edit page, shown on the detail page and prominently in Step Mode; `JsonLdRecipeExtractor` also pulls a `HowToStep`'s own `image` on import (same polymorphic shape as the recipe-level image) — verified against a real site (Japanese Taste's Famichiki recipe, 8/8 steps with photos). Added recipe duration (`recipes.duration_minutes`): shown at the top of the recipe page ("45 min" / "1 hr 30 min") plus a one-shot estimated finish time computed from the viewer's own system clock ("Finish by 11:09 PM", not a live-ticking clock); editable as a plain minutes field on the edit form; `JsonLdRecipeExtractor` parses ISO 8601 durations from a source's `totalTime` (falling back to summing `prepTime`+`cookTime`) so import pre-fills it too — verified against real recipes with both shapes. Added a "30 min or less" quick-filter + badge on the recipe index, computed live from `duration_minutes` rather than a real Tag/RecipeTag row (no sync needed as duration changes) — this surfaced and fixed a real gap where `RecipeSummarySerializer` never exposed `duration_minutes` at all. Verified throughout via the full RSpec suite (153 examples) and live Playwright walkthroughs, including real external recipe imports.

- **2026-07-22 follow-up #3 — meal planning calendar (ad-hoc, no bolt directory)**: resolved the "meal planning calendar data model" open question from Intent 0001 in a new design doc (`docs/design/meal-planning-calendar.md`) before building — fixed Breakfast/Lunch/Dinner/Snack slots per day (not a freeform list), a slot can hold more than one recipe, month view is a read-only overview only (no direct editing there). Added the `MealPlan` model/migration (`user_id`, `recipe_id`, `date`, `meal_type` enum, `position`), `Api::V1::MealPlansController` (`index` scoped by `start_date`/`end_date`, `create`, `destroy` — no reorder/PATCH endpoint yet, drag-and-drop is deferred), and `MealPlanSerializer`. New `/planner` route (`Planner.vue`): week view is the default (day columns × 4 meal-type rows, previous/next paging; laid out as rows of 3/3/1 day-cards per a later same-day tweak, not one 7-wide row), with a "Show month"/"Show week" toggle in the middle of the header switching to a read-only month grid whose day cells show a scheduled-meal count badge and jump back into that day's week on click. Recipe assignment uses a new `RecipePicker.vue` (search-and-select dropdown, deliberately separate from the existing `IngredientCombobox.vue` despite similar shape, since reusing an "ingredient"-named component for recipe-picking read as a conceptual mismatch) and a new `lib/calendar.js` for week/month date math (Monday-start weeks). Verified via the full RSpec suite (153 examples, still green) and a live Playwright walkthrough: assign a recipe to a slot, remove it, switch to month view and confirm the count badge, click a day to jump back to its week.

- **2026-07-23 follow-up #1 — freeform meal-plan entries**: revised the "recipes only" v1 decision (see `docs/design/meal-planning-calendar.md`) after real usage wanted to jot down "leftovers"/"eating out" without a recipe existing for it — `meal_plans.recipe_id` is now nullable and a `label` string was added (model validation requires one or the other, not a DB constraint). `RecipePicker.vue` now offers an "+ Add "<query>"" option whenever the typed text doesn't exactly match an existing recipe, emitting a separate `add-text` event the picker's caller handles alongside `select`. A freeform chip in `Planner.vue` renders in italics with an extra "Add" link (`/recipes/import?title=<label>`) that jumps into the existing add-recipe flow with the title pre-filled (defaults that page to "Paste text" mode). Initially shipped *without* auto-relinking the slot to the newly created recipe afterward — see follow-up #3 below, where that turned out to be wrong. Added `spec/models/meal_plan_spec.rb` and `spec/requests/meal_plans_spec.rb` (recipe-or-label validation, cross-user scoping/ownership on create and destroy, position-append behavior) — full suite 169 examples, still green. Verified live via Playwright: typed a non-existent meal, added it as freeform text, confirmed the italic chip and its Add/× buttons, followed Add through to the pre-filled creation form.

- **2026-07-23 follow-up #2 — ingredient checkboxes, editable source URL**: `RecipeDetail.vue` and `StepMode.vue` render each ingredient as a checkbox instead of a bullet (ticking one strikes through the text) — purely local prep-checklist state, not persisted, resets on reload; no backend change, since there's no "checked" concept in the data model and none was asked for. `RecipeReview.vue` gained a "Source URL" field, seeded from `recipe.source_url` and included in the save payload — previously `source_url` was populated on import but had no way to be set or corrected afterward, since `RecipesController#update_params` didn't permit it and `RecipeUpdater`'s attribute slice didn't include it (both fixed). Added coverage in `spec/requests/recipe_spec.rb` and `spec/services/recipe_updater_spec.rb` — full suite 171 examples. Verified live: ticked ingredients on both pages, edited and saved a recipe's source URL, confirmed it persisted.

- **2026-07-23 follow-up #3 — meal-plan "Add" now relinks the slot**: follow-up #1's freeform-chip "Add" shortcut deliberately didn't relink the slot to the recipe it created, on the theory the user would just re-pick it — in practice that read as a bug: the slot kept showing the stale typed label forever, which was actively misleading whenever the saved title differed (a manual correction, or a URL import pulling its own title). Added `PATCH /api/v1/meal_plans/:id` (`{ recipe_id }` only, deliberately narrow — not a general edit endpoint) that relinks and clears `label`; `RecipeImport.vue` calls it right after a successful create/import (both the URL and paste-text paths) whenever it arrived via the planner's "Add" link (`mealPlanId` query param), before its normal post-creation redirect. Added request specs for the new endpoint (ownership/cross-user 404s, label-clearing) — full suite 175 examples, still green. Verified live: created a freeform "Grandma's meatloaf" entry, followed Add, retitled it to "Meatloaf Deluxe" on creation, confirmed the planner slot updated to the new title with no leftover "Add" link.

- **2026-07-23 follow-up #4 — planner grid-overflow fix, drag-and-drop, meal-category visibility, homepage widget**: a long freeform label made a day card's chip row overflow — root cause was the classic CSS Grid `min-width: auto` trap (an unconstrained grid item can grow past its 1fr track to fit unbreakable content), not the label's own truncation; fixed by adding `min-w-0` to the day-card grid item itself (the label already had `truncate`, that alone wasn't the problem). Added native HTML5 drag-and-drop (no library) so a chip can be dragged to a different day or meal-type slot — `PATCH /api/v1/meal_plans/:id` extended to also accept `{ date, meal_type }` (alongside the existing narrow `recipe_id` relink case), dropping always appends to the end of the destination slot, no within-slot reordering. Added per-user planner preferences on `users` (`show_breakfast/lunch/dinner/snack` booleans, `home_view` enum: `random_recipes`/`weekly_planner`/`today`) via a new `GET/PATCH /api/v1/user_preferences` singleton resource (same response shape as `AuthController#me`, mirroring the `pinned_tags` pattern) and two new Settings.vue sections. Hiding a meal-type filters it out of both planner views and the homepage widget everywhere, without touching existing `meal_plans` rows in that slot. Extracted shared meal-slot display logic (`visibleMealTypes`, `groupPlansBySlot`, label formatters) into `lib/mealPlanSlots.js` once genuinely needed in two places (`Planner.vue` and `Home.vue`'s new widget) rather than duplicated. `Home.vue`'s `weekly_planner`/`today` modes render a **read-only** summary (no add/remove/drag) plus an "Open planner" link — deliberately not a second fully-interactive planner on the homepage. Added move/relink-together request specs to `spec/requests/meal_plans_spec.rb` and full `user_preferences_spec.rb` — full suite 182 examples, still green, RuboCop clean. Verified live: dragged a chip across days/slots and confirmed the move persisted, toggled Snack off in Settings and confirmed it disappeared from every planner surface, switched the homepage through all three `home_view` modes. **Noted, not started**: a request to redesign the recipe picker as an image-grid modal with meal-category tag prefiltering (deselectable) and inline text/recipe-creation — flagged back to the user as a separate future pass rather than folded into this already-large batch.

- **2026-07-26 follow-up — planner recipe-picker rework: tag-based Suggest, image-grid modal, pagination (ad-hoc, no bolt directory)**: picked up the recipe-picker redesign flagged back in follow-up #4. First added a tag-based "Suggest" feature to the then-still-dropdown `RecipePicker.vue`: a tag `<select>` plus a "Suggest" button that randomly picks a matching recipe, shown inline with "Try another" (re-rolls, no back-to-back repeats) and "Use this" (commits). Surfaced and fixed an unrelated dark-mode bug in the process: native `<select>` option popups were unreadable in dark mode (light-scheme white popup chrome against `--color-ink`'s near-white dark-mode value) — fixed in `main.css` via `color-scheme` overrides alongside the existing `--color-*` dark-mode blocks, plus an explicit `select`/`option` background-color/color fallback since headless Chromium ignored `color-scheme` for the popup specifically.

  Then reworked `RecipePicker.vue` from that dropdown into a `Teleport`'d modal (same pattern as `ConfirmDialog.vue`): an image grid of recipe cards (placeholder tile when a recipe has no `image_url`), multi-select AND-filtered tag chips (same convention as `Recipes.vue`) that auto-pre-select a chip matching the slot's `meal_type` by name when opened (e.g. a "breakfast" tag on a Breakfast slot) — deselectable, just a starting filter, not a lock — and the Suggest feature folded in to share the grid's filtered pool instead of its own separate `<select>`. Freeform "+ Add <text>" and direct card-click-to-select carried over unchanged from the dropdown version. Moving off a single wrapper-`<div>` root broke Vue's automatic `class="mt-1"` attr inheritance from `Planner.vue` (fragment roots can't auto-inherit) — fixed with `defineOptions({ inheritAttrs: false })` plus an explicit `v-bind="$attrs"` on the trigger button.

  Finally added pagination at 12 per page (4 cols × 3 rows) to the picker's image grid, resetting to page 1 on any search/tag change or modal reopen, plus the same 12-per-page treatment (matching Previous/Next controls) on the recipe index (`Recipes.vue`) — neither surface had been paginated before; both loaded and filtered the user's full recipe collection client-side. Verified live via Playwright throughout: dark/light `<select>` rendering, meal-type auto-prefilter and deselecting it, Suggest + re-roll + commit, freeform add, direct card select, Escape/backdrop close, and pagination boundary/reset behavior on both surfaces using 15 seeded test recipes. No JS test suite exists in this repo — frontend-only changes, RSpec suite untouched.

### Next up (per `docs/units/`)
No unit briefs exist yet for what comes next — pick from "Future Enhancements" below (shopping lists, portion scaling, nutritional info are the nearest Phase 1 remainder) or revisit UI polish, since Unit 07 was the first new UI surface since Bolt 003's design pass and hasn't had one. A good next real-world-testing candidate: import a recipe with *multiple* ungrouped sections to see how often Tier 2.5's single-label/single-run restriction actually bails out in practice. On the planner: drag-and-drop rescheduling and a reorder/PATCH endpoint were deliberately deferred (see `docs/design/meal-planning-calendar.md`) — natural next slice if the add/remove-only flow proves too slow in practice.

### Future Enhancements (Phase 2/3, not yet scheduled into units)
1. Shopping list generation, portion scaling, nutritional info (Phase 1 remainder); meal-planning drag-and-drop reorder
2. Multi-user household features (Phase 2)
3. Community and social features (Phase 3)
4. Browser bookmarklet import ("Save to Recipe Planner" from any recipe site, Yummly-style) — see "Future extension" in `docs/design/recipe-import-and-autosort.md` for the thin-vs-fat approach