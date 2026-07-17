import { defineStore } from 'pinia'
import { csrfToken } from '../lib/csrf'

async function submitRecipe(url, method, data) {
  const response = await fetch(url, {
    method,
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: JSON.stringify({ recipe: data }),
  })
  const body = await response.json().catch(() => ({}))

  if (response.ok) return { ok: true, recipe: body }
  return { ok: false, errors: body.errors || [body.error || 'Something went wrong'] }
}

export const useRecipesStore = defineStore('recipes', {
  state: () => ({
    current: null,
  }),
  actions: {
    async fetchOne(id) {
      const response = await fetch(`/api/v1/recipes/${id}`, { credentials: 'include' })
      this.current = response.ok ? await response.json() : null
      return { ok: response.ok }
    },

    async create(data) {
      const result = await submitRecipe('/api/v1/recipes', 'POST', data)
      if (result.ok) this.current = result.recipe
      return result
    },

    async update(id, data) {
      const result = await submitRecipe(`/api/v1/recipes/${id}`, 'PATCH', data)
      if (result.ok) this.current = result.recipe
      return result
    },

    async destroy(id) {
      const response = await fetch(`/api/v1/recipes/${id}`, {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'X-CSRF-Token': csrfToken() },
      })
      if (response.ok) this.current = null
      return { ok: response.ok }
    },
  },
})
