export function ingredientsById(recipe) {
  const grouped = recipe.recipe_ingredient_groups.flatMap((g) => g.recipe_ingredients)
  return new Map([ ...recipe.ingredients, ...grouped ].map((ri) => [ ri.id, ri ]))
}

export function stepIngredients(byId, step) {
  return step.recipe_ingredient_ids.map((id) => byId.get(id)).filter(Boolean)
}

// How much to multiply every stored quantity by to go from the recipe's
// recommended servings to the servings the viewer wants. 1 (no scaling)
// whenever either side is missing/invalid, so recipes without a servings
// value render exactly as stored.
export function scaleFactor(recipeServings, desiredServings) {
  const base = Number(recipeServings)
  const wanted = Number(desiredServings)
  if (!(base > 0) || !(wanted > 0)) return 1
  return wanted / base
}

const FRACTIONS = [
  [ 1 / 8, '\u215B' ], [ 1 / 4, '\u00BC' ], [ 1 / 3, '\u2153' ], [ 3 / 8, '\u215C' ],
  [ 1 / 2, '\u00BD' ], [ 5 / 8, '\u215D' ], [ 2 / 3, '\u2154' ], [ 3 / 4, '\u00BE' ], [ 7 / 8, '\u215E' ]
]

// Tidy display of a (possibly scaled) quantity: common cooking fractions
// ("1\u00BD", "\u2153") when the value is close to one, otherwise at most two
// decimals with trailing zeros stripped ("2", "0.35"). Returns '' for a
// missing quantity so callers can filter it out of a label.
export function formatQuantity(value) {
  if (value === null || value === undefined || value === '') return ''
  const number = Number(value)
  if (!Number.isFinite(number)) return String(value)
  if (number === 0) return '0'

  const whole = Math.floor(number)
  const fraction = number - whole
  if (fraction < 0.02) return String(whole)
  if (fraction > 0.98) return String(whole + 1)

  const match = FRACTIONS.find(([ f ]) => Math.abs(f - fraction) < 0.02)
  if (match) return whole ? `${whole}${match[1]}` : match[1]

  return String(Math.round(number * 100) / 100)
}

export function ingredientLabel(ri, factor = 1) {
  const quantity = ri.quantity === null || ri.quantity === undefined || ri.quantity === ''
    ? ''
    : formatQuantity(Number(ri.quantity) * factor)
  return [ quantity, ri.unit, ri.name ].filter(Boolean).join(' ')
}

// Ocado search for an ingredient by name (preparation notes like "diced" are
// deliberately left out - they're not part of what you'd shop for).
export function ocadoSearchUrl(ri) {
  return `https://www.ocado.com/search?q=${encodeURIComponent(ri.name)}`
}
