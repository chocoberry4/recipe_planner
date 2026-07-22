// Weeks start on Monday throughout the planner.

export function startOfWeek(date) {
  const d = new Date(date)
  const mondayOffset = (d.getDay() + 6) % 7
  d.setDate(d.getDate() - mondayOffset)
  d.setHours(0, 0, 0, 0)
  return d
}

export function addDays(date, n) {
  const d = new Date(date)
  d.setDate(d.getDate() + n)
  return d
}

export function addMonths(date, n) {
  const d = new Date(date)
  d.setMonth(d.getMonth() + n)
  return d
}

export function toISODate(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function weekDays(weekStart) {
  return Array.from({ length: 7 }, (_, i) => addDays(weekStart, i))
}

// A full grid of 7-day weeks that covers every day in the given month,
// including leading/trailing days from adjacent months so every row is complete.
export function monthGridWeeks(monthDate) {
  const firstOfMonth = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1)
  const lastOfMonth = new Date(monthDate.getFullYear(), monthDate.getMonth() + 1, 0)
  const gridStart = startOfWeek(firstOfMonth)
  const gridEnd = addDays(startOfWeek(lastOfMonth), 6)

  const weeks = []
  let cursor = gridStart
  while (cursor <= gridEnd) {
    weeks.push(weekDays(cursor))
    cursor = addDays(cursor, 7)
  }
  return weeks
}

export function weekRangeLabel(weekStart) {
  const end = addDays(weekStart, 6)
  const sameMonth = weekStart.getMonth() === end.getMonth() && weekStart.getFullYear() === end.getFullYear()
  const startLabel = weekStart.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  const endLabel = end.toLocaleDateString('en-US', sameMonth ? { day: 'numeric' } : { month: 'short', day: 'numeric' })
  return `${startLabel} – ${endLabel}, ${end.getFullYear()}`
}

export function monthLabel(monthDate) {
  return monthDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
}
