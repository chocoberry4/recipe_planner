# Unit 02: Recipe Vue Views

- **Related**: [Intent 0001](../../intent/0001-recipe-planner-phase1.md)
- **Depends on**: split — see below

Split into two independently-schedulable slices, since they have different dependencies.

**Done (prerequisite, discovered while wiring up Slice A):** there was no `root` route and no view mounting the Vue app at all — `App.vue`/`main.js`/the router existed but nothing bootstrapped them. Fixed: `root "pages#index"` + a `get "*path"` catch-all (excluding `/api/`) so Vue Router's history mode works on refresh/direct nav; `PagesController < ActionController::Base` (bypassing the API-only `ApplicationController`) with an explicit `layout "application"` (automatic layout lookup did not fire for this controller — root cause not fully identified, explicit declaration is the fix); `app/views/layouts/application.html.erb` with `vite_client_tag`/`vite_javascript_tag`. Also fixed along the way: `main.js` moved to `app/frontend/entrypoints/main.js` (vite_rails convention — it wasn't a recognized entrypoint before), the router moved from a stray `app/frontend/src/router/` to `app/frontend/router/` so its `../views/*.vue` imports actually resolve, and `vue-router` was added to `package.json` (imported but never declared). See project memory for the Docker↔Vite dev-server networking setup this required.

## Slice A — Recipe Index Page

- **Depends on**: — (none)

`RecipesController#index` currently does `Recipe.all` with no auth check, so a read-only recipe list is buildable immediately, without waiting on Unit 01.

**In scope**: `Recipes.vue` rendering `GET /api/v1/recipes` as a list (title, description snippet); `Home.vue` can link to it. Detail/create/edit are not part of this slice.

**Acceptance criteria**: navigating to `/recipes` in the browser shows every recipe currently in the database.

**Tracked as**: [Bolt 002](../../bolts/bolt-002-recipe-index/plan.md) — can run before, after, or in parallel with Bolt 001.

## Slice B — Create / Edit / Detail

- **Depends on**: Unit 01 (Authentication) — creating a recipe should be tied to `current_user`

**In scope**: recipe detail view, create form, edit form, delete action, wired to `show`/`create`/`update`/`destroy`.

**Known issue to fix as part of this slice**: `RecipesController#recipe_params` currently permits `:name, :description, :ingredients, :instructions`, but the `recipes` table has `:title`/`:source_url` (no `:name` column) and `:user_id` isn't permitted/set at all. Create/update will not work correctly against the real schema until this is fixed.

**Out of scope**: ingredient grouping UI (Unit 07, once schema/engine exist), meal planning UI (not yet designed).

**Acceptance criteria**: user can view, create, edit, and delete a recipe end-to-end in the browser, correctly attributed to the logged-in user.
