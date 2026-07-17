# Bolt 002: Recipe Index Page

- **Unit covered**: [Unit 02 — Recipe Vue Views, Slice A](../../units/02-recipe-vue-views/unit-brief.md)
- **Tasks**: [tasks.md](tasks.md)

## Why this bolt exists separately from Bolt 001

`RecipesController#index` has no auth check today (`Recipe.all`, unscoped) — so displaying the recipe list has no real dependency on Bolt 001's auth work. It's a small, fast, independently-shippable win: pulling it out means it doesn't have to wait behind auth/schema work, and gives a visible working page sooner.

## Definition of done

- `Recipes.vue` fetches `GET /api/v1/recipes` and renders every recipe's title + description.
- `Home.vue` links to `/recipes`.
- Basic empty state (no recipes yet) handled, not just a blank page.

## Out of scope for this bolt

- Recipe detail view, create/edit forms, delete (Unit 02 Slice B — depends on auth, tracked separately)
- Any styling beyond "readable and not broken"
- Ingredient/instruction display detail (recipe list only needs title/description at this stage)
