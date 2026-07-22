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

export function slotLabel(slot) {
  return slot.charAt(0).toUpperCase() + slot.slice(1)
}

export function weekdayLabel(day) {
  return day.toLocaleDateString('en-US', { weekday: 'short' })
}

export function dayNumberLabel(day) {
  return day.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}
