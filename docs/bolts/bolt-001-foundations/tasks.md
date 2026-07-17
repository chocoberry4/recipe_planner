# Bolt 001 — Tasks

## Auth (Unit 01)

- [ ] `AuthController#signup` — create user, start session
- [ ] `AuthController#login` — authenticate, start session
- [ ] `AuthController#logout` — clear session
- [ ] CORS config (`rack-cors` or equivalent) allowing the Vite origin with credentials
- [ ] Session cookie config reviewed (`SameSite`, secure flag for prod)
- [ ] Vue: `Login.vue`, `Signup.vue` forms
- [ ] Vue: router guard redirecting unauthenticated users away from recipe routes
- [ ] Request specs: signup, login, logout, unauthenticated access rejected

## Ingredient grouping schema (Unit 03)

- [ ] Migration: `recipe_ingredient_groups` (`recipe_id`, `name`, `position`)
- [ ] Migration: `recipe_ingredients` add `recipe_ingredient_group_id` (nullable FK), `preparation` (string), `position`
- [ ] Migration: `instructions` add `recipe_ingredient_group_id` (nullable FK)
- [ ] Migration: `instruction_ingredients` join table (`instruction_id`, `recipe_ingredient_id`)
- [ ] Model: `RecipeIngredientGroup` (`belongs_to :recipe`, `has_many :recipe_ingredients`)
- [ ] Model: `Recipe` gains `has_many :recipe_ingredient_groups`
- [ ] Model: `RecipeIngredient` gains `belongs_to :recipe_ingredient_group, optional: true`
- [ ] Model: `Instruction` gains `belongs_to :recipe_ingredient_group, optional: true` and `has_many :recipe_ingredients, through: :instruction_ingredients`
- [ ] `RecipeSerializer` updated to include groups + `preparation`
- [ ] Existing request/model specs still green after migration
- [ ] Finish existing known gap: `show`/`create`/`update`/`destroy` specs in `spec/requests/recipe_spec.rb`
