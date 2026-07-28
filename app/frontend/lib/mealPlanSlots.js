const MEAL_TYPE_FIELDS = [
  { slot: 'breakfast', field: 'show_breakfast' },
  { slot: 'lunch', field: 'show_lunch' },
  { slot: 'dinner', field: 'show_dinner' },
  { slot: 'snack', field: 'show_snack' },
]

export function visibleMealTypes(user) {
  return MEAL_TYPE_FIELDS.filter((meal) => user?.[meal.field] !== false).map((meal) => meal.slot)
}

export function groupPlansBySlot(items) {
  const map = new Map()
  for (const plan of items) {
    const key = `${plan.date}|${plan.meal_type}`
    if (!map.has(key)) map.set(key, [])
    map.get(key).push(plan)
  }
  for (const list of map.values()) list.sort((a, b) => a.position - b.position)
  return map
}

const MEAL_TYPE_ORDER = [ 'breakfast', 'lunch', 'dinner', 'snack' ]
export const MAX_MONTH_CELL_PLANS = 3

// A month cell shows dish names directly rather than just a count, so a
// day's plans need to be ordered meal-type-first (not raw API/array order)
// for that list to read naturally - same idea as groupPlansBySlot but keyed
// by date alone since a month cell isn't broken out by slot. Shared by
// Planner.vue's month view and Home.vue's monthly homepage widget.
export function groupPlansByDate(items, visibleTypes) {
  const map = new Map()
  for (const plan of items) {
    if (!visibleTypes.includes(plan.meal_type)) continue
    if (!map.has(plan.date)) map.set(plan.date, [])
    map.get(plan.date).push(plan)
  }
  for (const list of map.values()) {
    list.sort((a, b) => MEAL_TYPE_ORDER.indexOf(a.meal_type) - MEAL_TYPE_ORDER.indexOf(b.meal_type) || a.position - b.position)
  }
  return map
}

export function slotLabel(slot) {
  return slot.charAt(0).toUpperCase() + slot.slice(1)
}

export function weekdayLabel(day) {
  return day.toLocaleDateString('en-US', { weekday: 'short' })
}

export function dayNumberLabel(day) {
  return day.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}
