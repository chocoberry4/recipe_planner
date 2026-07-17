# Bolt 001 — Tasks

**Status: done.** Both tracks built in parallel (two background `executor` agents), then verified and integrated by hand — see the note at the bottom for what verification actually found.

## Auth (Unit 01)

- [x] `AuthController#signup` — create user, start session
- [x] `AuthController#login` — authenticate, start session
- [x] `AuthController#logout` — clear session
- [x] CORS config (`rack-cors`) allowing the Vite origin with credentials
- [x] Session cookie config reviewed (`SameSite`, secure flag for prod)
- [x] Vue: `Login.vue`, `Signup.vue` forms
- [x] Vue: router guard redirecting unauthenticated users away from recipe routes
- [x] Request specs: signup, login, logout, unauthenticated access rejected

## Ingredient grouping schema (Unit 03)

- [x] Migration: `recipe_ingredient_groups` (`recipe_id`, `name`, `position`)
- [x] Migration: `recipe_ingredients` add `recipe_ingredient_group_id` (nullable FK), `preparation` (string), `position`
- [x] Migration: `instructions` add `recipe_ingredient_group_id` (nullable FK)
- [x] Migration: `instruction_ingredients` join table (`instruction_id`, `recipe_ingredient_id`)
- [x] Model: `RecipeIngredientGroup` (`belongs_to :recipe`, `has_many :recipe_ingredients`)
- [x] Model: `Recipe` gains `has_many :recipe_ingredient_groups`
- [x] Model: `RecipeIngredient` gains `belongs_to :recipe_ingredient_group, optional: true`
- [x] Model: `Instruction` gains `belongs_to :recipe_ingredient_group, optional: true` and `has_many :recipe_ingredients, through: :instruction_ingredients`
- [x] `RecipeSerializer` updated to include groups + `preparation`
- [x] Existing request/model specs still green after migration
- [x] Finish existing known gap: `show`/`create`/`update`/`destroy` specs in `spec/requests/recipe_spec.rb`

## What verification found (not in the original plan)

Both tracks' own work was solid on inspection. Three real bugs only showed up once the full suite ran together in a properly isolated environment:

1. **`docker-compose exec web bundle exec rspec` was silently running against the development database/config, not test** — the container's `RAILS_ENV=development` and `DATABASE_URL=...recipe_planner_development` env vars win over `config/database.yml`'s test settings unless explicitly overridden per-invocation (`docker-compose exec -e RAILS_ENV=test -e DATABASE_URL=...recipe_planner_test web ...`). This was masking real failures and polluting the dev DB with factory data.
2. **`Api::BaseController.allow_forgery_protection` was hardcoded `true` regardless of environment** — `include ActionController::RequestForgeryProtection` on an `ActionController::API`-based hierarchy bypasses the Rails Railtie hook that normally syncs this from `config.action_controller.allow_forgery_protection`. Fixed with an explicit sync line after `protect_from_forgery`. This is a pre-existing bug, not introduced by either track.
3. **Track A's `require_login` on recipe mutations wasn't reflected in Track B's mutation specs** (written in parallel, before either could see the other's final state) — fixed by adding a `log_in_as` helper to `spec/requests/recipe_spec.rb`.

Full suite: 37 examples, 0 failures, 3 pending (2 are the known `recipe_params` bug, tracked separately; 1 is a pre-existing unrelated placeholder spec).

**Update:** the `recipe_params` bug is now fixed — `recipe_params` permits `:title`/`:description`, and `RecipesController#create` sets the owner from `current_user` rather than a client-supplied `user_id`. Full suite: 37 examples, 0 failures, 1 pending (the unrelated placeholder spec only).
