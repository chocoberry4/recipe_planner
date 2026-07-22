# Design: Meal Planning Calendar

- **Status**: Accepted
- **Related**: [Intent 0001](../intent/0001-recipe-planner-phase1.md)

## Problem

Intent 0001 scoped meal planning into Phase 1 but deferred the data model and UX as an open question. This doc resolves both, at the smallest scope needed to schedule saved recipes onto a calendar.

## Decisions

**Meal slots are fixed, not freeform.** Each day is broken into Breakfast/Lunch/Dinner/Snack, matching the "multiple meals per day" goal already stated in CLAUDE.md's vision. A slot can hold more than one recipe (e.g. two dinner options) — no uniqueness constraint on date+meal_type, ordered by `position`.

**Week view is primary; month view is a read-only overview.** The main page is one week at a time, paged with previous/next. Month view exists only to see the shape of a month at a glance (a per-day count of scheduled meals) and jump back into a given week — it does not support assigning recipes directly, so the schema/API don't need to think about month-grid editing at all.

**A slot can be a saved recipe or freeform text.** Revised after initial ship: `recipe_id` is nullable and a `label` string was added (`recipe_id` XOR `label`, enforced by a model validation, not a DB constraint — this is a personal app with one writer, a check constraint would be belt-and-suspenders). A meal plan entry needs a recipe *or* a label, never neither. The planner's picker shows an "+ Add "<query>"" option whenever the typed text doesn't exactly name an existing recipe, so one-offs ("leftovers", "eating out") don't require a recipe to exist first. A freeform chip gets an extra "Add" link (`/recipes/import?title=<label>&mealPlanId=<id>`) that jumps into the existing add-recipe flow with the title pre-filled.

**The "Add" shortcut auto-relinks the slot once the recipe is created.** Revised again almost immediately: the first cut deliberately skipped this (see the old text below), on the theory that the user would just re-assign it from the picker. In practice that read as a bug, not a deferred nice-to-have — the slot silently kept showing the stale typed-out label, which was actively misleading whenever the saved title ended up different (typed correction, or a URL import that pulls its own title entirely). `RecipeImport.vue` now calls `PATCH /api/v1/meal_plans/:id` with the new recipe's id right after a successful create/import, before its normal post-creation redirect (still autosort review or the plain detail page, unchanged) — so the relink happens silently and the planner is simply correct next time it's viewed. Original (superseded) reasoning: "does not auto-relink... that would mean threading planner state through the autosort review step too" — it doesn't need to; the relink happens immediately on creation success, independent of whatever review step comes after.

**Drag-and-drop is in, but reorder-within-a-slot deliberately isn't.** Also revised almost immediately — real usage wanted to move a chip to a different day or meal-type by dragging it, not just remove-and-re-add. Native HTML5 drag-and-drop (`draggable`, `dragover`/`drop`), no library. Dropping always appends to the end of the destination slot; there's no drag-triggered reordering *within* the same slot's existing list (`position` still only reflects creation/move order, not manual same-slot reordering) — narrower than full drag-and-drop, but it's the part that was actually asked for.

**Two more user-level planner preferences, alongside the theme/pinned-tags pattern already in Settings.vue.** (1) Per-meal-type visibility (`users.show_breakfast/show_lunch/show_dinner/show_snack`, booleans defaulting `true`) — hides a slot everywhere it's rendered (both planner views and the homepage widget below) without touching any existing `meal_plans` rows in that slot; unhiding brings them back. Four fixed booleans rather than an array/join-table, since unlike tags this is a small closed set that isn't going to grow. (2) A homepage widget chooser (`users.home_view` enum: `random_recipes` (default, existing 9-recipe grid) / `weekly_planner` / `today`) — the latter two render a **read-only** summary (no add/remove/drag) of the current week or just today, plus an "Open planner" link for actual editing, deliberately not a second copy of the fully interactive planner on the homepage.

## Schema

```
meal_plans
  id
  user_id       references, not null
  recipe_id     references, nullable          -- either this or label must be present
  label         string, nullable               -- freeform text when there's no recipe
  date          date, not null
  meal_type     integer enum (breakfast: 0, lunch: 1, dinner: 2, snack: 3), not null
  position      integer, not null, default: 0   -- order within a date+meal_type slot

  index [user_id, date]
  index [user_id, date, meal_type]
```

Deleting a recipe cascades to delete its `meal_plans` rows (`dependent: :destroy` both directions) — a scheduled meal for a recipe that no longer exists isn't meaningful to keep.

## API

- `GET /api/v1/meal_plans?start_date=&end_date=` — current_user's scheduled meals in range (inclusive), used for both week and month views (month passes the full 6-week grid range so leading/trailing days from adjacent months still show their counts)
- `POST /api/v1/meal_plans` — `{ recipe_id, label, date, meal_type }` (exactly one of `recipe_id`/`label`), recipe ownership checked via `current_user.recipes.find` when `recipe_id` is present, position appended to the end of its slot
- `PATCH /api/v1/meal_plans/:id` — `{ recipe_id }` and/or `{ date, meal_type }`. Two independent, deliberately narrow things bundled into one action (not a general edit endpoint): relinking a freeform entry to a recipe (clears `label`), and moving a plan to a different slot (drag-and-drop; recomputes `position` via the same "append to end" logic `create` uses, excluding the plan's own current row from that `MAX(position)` scan so a self-slot drop doesn't skew it).
- `DELETE /api/v1/meal_plans/:id` — unschedule, scoped to `current_user.meal_plans`
- `GET/PATCH /api/v1/user_preferences` — meal-type visibility booleans and `home_view`, same response shape as `AuthController#me` so the frontend can drop it straight into the auth store.

## Frontend

- `/planner` route, week view by default
- Week view: 3 columns of day cards (rows of 3/3/1), each with visibility-filtered meal-type rows; each row lists assigned meals as draggable, removable chips (freeform ones shown in italics with an extra "Add" link into recipe creation) plus a small "+ Add" recipe/text picker. A slot is a drop target (`dragover`/`drop`) with a highlight while something's dragged over it.
- Header: Previous/Next buttons that page by week (or by month when month view is active) flanking a center "Show month" / "Show week" toggle
- Month view: standard calendar grid, each day cell shows a scheduled-meal count badge (also visibility-filtered); clicking a day switches back to week view for that day's week
- `stores/mealPlans.js` fetches the visible range wholesale on every navigation (no incremental caching — same fetch-and-replace pattern as `stores/recipes.js`)
- `lib/mealPlanSlots.js` — meal-slot display logic (`visibleMealTypes`, `groupPlansBySlot`, label formatters) shared between `Planner.vue` and `Home.vue`'s widget, extracted once genuinely reused in both rather than duplicated
- Settings.vue: "Homepage" and "Meal categories" sections alongside the existing Appearance/Pinned-tags ones, following the same optimistic-update-with-rollback pattern pinned tags already used

## Out of scope for v1

- Reordering within a slot via drag (drop always appends to the end)
- A general-purpose meal-plan edit endpoint (the `PATCH` action stays narrowly scoped to the two cases above)
- Shopping list generation from planned meals (separate future unit; schema already sketched in CLAUDE.md)
- Per-meal prep notes/timing
- Multi-user/household meal voting (Phase 2)
- A redesigned recipe picker (image-grid modal, meal-category tag prefiltering) — requested, noted for a future pass, not started
- Chip images + click-through to the recipe — requested, noted for a future pass, not started. Applies to every planner surface a chip renders on: `Planner.vue`'s week view, the month view (if it ever shows more than a count badge), and `Home.vue`'s `weekly_planner`/`today` widget. A recipe-backed chip should show its `recipe.image_url` (already in `MealPlanSerializer`'s `recipe` payload, no backend change needed) and the label should be a link to `/recipes/:id`; a freeform (label-only) chip has neither, since there's no recipe to show or link to. Needs a real layout pass, not just dropping an `<img>` in — the current chip is a dense one-line row (label + Add/× packed tight, see the 2026-07-23 grid-overflow fix), so an image likely means restacking to a two-line/card-style chip instead.
