export function ingredientsById(recipe) {
  const grouped = recipe.recipe_ingredient_groups.flatMap((g) => g.recipe_ingredients)
  return new Map([ ...recipe.ingredients, ...grouped ].map((ri) => [ ri.id, ri ]))
}

export function stepIngredients(byId, step) {
  return step.recipe_ingredient_ids.map((id) => byId.get(id)).filter(Boolean)
}

export function ingredientLabel(ri) {
  return [ ri.quantity, ri.unit, ri.name ].filter(Boolean).join(' ')
}
