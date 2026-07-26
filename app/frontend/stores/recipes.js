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

    async importFromUrl(url) {
      return importRecipe({ url })
    },

    async importFromText({ title, description, ingredients_text, instructions_text }) {
      return importRecipe({ title, description, ingredients_text, instructions_text })
    },

    async uploadImage(recipeId, file) {
      const formData = new FormData()
      formData.append('image', file)

      const response = await fetch(`/api/v1/recipes/${recipeId}/image`, {
        method: 'POST',
        credentials: 'include',
        // No Content-Type header - the browser sets the multipart boundary
        // itself when the body is a FormData instance.
        headers: { 'X-CSRF-Token': csrfToken() },
        body: formData,
      })
      const body = await response.json().catch(() => ({}))

      if (response.ok) {
        this.current = body
        return { ok: true, recipe: body }
      }
      return { ok: false, errors: body.errors || [ body.error || 'Something went wrong' ] }
    },

    async removeImage(recipeId) {
      const response = await fetch(`/api/v1/recipes/${recipeId}/image`, {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'X-CSRF-Token': csrfToken() },
      })
      const body = await response.json().catch(() => ({}))

      if (response.ok) {
        this.current = body
        return { ok: true, recipe: body }
      }
      return { ok: false }
    },

    async fetchImageCandidates(recipeId) {
      const response = await fetch(`/api/v1/recipes/${recipeId}/image_candidates`, { credentials: 'include' })
      if (!response.ok) return { ok: false, imageUrls: [] }

      const body = await response.json().catch(() => ({}))
      return { ok: true, imageUrls: body.image_urls || [] }
    },

    async saveAssignments(recipeId, assignments) {
      const response = await fetch(`/api/v1/recipes/${recipeId}/instruction_ingredients`, {
        method: 'PATCH',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify({ assignments }),
      })
      const body = await response.json().catch(() => ({}))

      if (response.ok) {
        this.current = body
        return { ok: true, recipe: body }
      }
      return { ok: false, error: body.error || 'Something went wrong' }
    },
  },
})

async function importRecipe(payload) {
  const response = await fetch('/api/v1/recipes/import', {
    method: 'POST',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: JSON.stringify(payload),
  })
  const body = await response.json().catch(() => ({}))

  if (response.ok) return { ok: true, recipe: body }
  return { ok: false, error: body.error || 'Something went wrong' }
}
