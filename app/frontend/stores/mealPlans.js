import { defineStore } from 'pinia'
import { csrfToken } from '../lib/csrf'

export const useMealPlansStore = defineStore('mealPlans', {
  state: () => ({
    items: [],
  }),
  actions: {
    async fetchRange(startDate, endDate) {
      const response = await fetch(`/api/v1/meal_plans?start_date=${startDate}&end_date=${endDate}`, { credentials: 'include' })
      if (response.ok) this.items = await response.json()
      return { ok: response.ok }
    },

    async create({ recipeId, label, date, mealType }) {
      const response = await fetch('/api/v1/meal_plans', {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify({ meal_plan: { recipe_id: recipeId, label, date, meal_type: mealType } }),
      })
      const body = await response.json().catch(() => ({}))

      if (response.ok) {
        this.items.push(body)
        return { ok: true }
      }
      return { ok: false, errors: body.errors || [ body.error || 'Something went wrong' ] }
    },

    // Relinks a freeform (label-only) entry to a real recipe - used when the
    // planner's "Add" shortcut on a label chip is followed through to
    // actually creating that recipe, so the slot doesn't keep pointing at a
    // stale name once a real recipe exists for it.
    async relink(id, recipeId) {
      const response = await fetch(`/api/v1/meal_plans/${id}`, {
        method: 'PATCH',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify({ meal_plan: { recipe_id: recipeId } }),
      })
      const body = await response.json().catch(() => ({}))

      if (response.ok) {
        const index = this.items.findIndex((item) => item.id === Number(id))
        if (index !== -1) this.items[index] = body
        return { ok: true }
      }
      return { ok: false }
    },

    // Moves a plan to a different date/meal_type slot - drag-and-drop
    // between days or meal categories. Always appends to the end of the
    // destination slot; reordering within a slot isn't supported.
    async move(id, { date, mealType }) {
      const response = await fetch(`/api/v1/meal_plans/${id}`, {
        method: 'PATCH',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify({ meal_plan: { date, meal_type: mealType } }),
      })
      const body = await response.json().catch(() => ({}))

      if (response.ok) {
        const index = this.items.findIndex((item) => item.id === Number(id))
        if (index !== -1) this.items[index] = body
        return { ok: true }
      }
      return { ok: false }
    },

    async destroy(id) {
      const response = await fetch(`/api/v1/meal_plans/${id}`, {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'X-CSRF-Token': csrfToken() },
      })
      if (response.ok) this.items = this.items.filter((item) => item.id !== id)
      return { ok: response.ok }
    },
  },
})
