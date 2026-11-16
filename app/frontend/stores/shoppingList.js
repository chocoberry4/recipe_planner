import { defineStore } from 'pinia'
import { csrfToken } from '../lib/csrf'

function jsonHeaders() {
  return { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken() }
}

export const useShoppingListStore = defineStore('shoppingList', {
  state: () => ({
    items: [],
  }),
  actions: {
    async fetch() {
      try {
        const response = await fetch('/api/v1/shopping_items', { credentials: 'include' })
        if (response.ok) this.items = await response.json()
        return { ok: response.ok }
      } catch {
        return { ok: false }
      }
    },

    // The server merges a repeat of an existing name+unit into that line
    // (summing quantities), so the response may be an item already in
    // `items` - replace it in place rather than blindly appending.
    async add({ name, quantity, unit }) {
      try {
        const response = await fetch('/api/v1/shopping_items', {
          method: 'POST',
          credentials: 'include',
          headers: jsonHeaders(),
          body: JSON.stringify({ shopping_item: { name, quantity, unit } }),
        })
        const body = await response.json().catch(() => ({}))

        if (response.ok) {
          const index = this.items.findIndex((item) => item.id === body.id)
          if (index !== -1) this.items[index] = body
          else this.items.push(body)
          return { ok: true }
        }
        return { ok: false, errors: body.errors || [ body.error || 'Something went wrong' ] }
      } catch {
        return { ok: false, errors: [ 'Network error - please try again.' ] }
      }
    },

    async setChecked(id, checked) {
      const item = this.items.find((i) => i.id === id)
      if (!item) return { ok: false }
      const previous = item.checked
      item.checked = checked // optimistic; rolled back below if the save fails

      try {
        const response = await fetch(`/api/v1/shopping_items/${id}`, {
          method: 'PATCH',
          credentials: 'include',
          headers: jsonHeaders(),
          body: JSON.stringify({ shopping_item: { checked } }),
        })
        if (response.ok) return { ok: true }
      } catch {
        // fall through to rollback
      }
      item.checked = previous
      return { ok: false }
    },

    async remove(id) {
      try {
        const response = await fetch(`/api/v1/shopping_items/${id}`, {
          method: 'DELETE',
          credentials: 'include',
          headers: { 'X-CSRF-Token': csrfToken() },
        })
        if (response.ok) this.items = this.items.filter((item) => item.id !== id)
        return { ok: response.ok }
      } catch {
        return { ok: false }
      }
    },

    async clearChecked() {
      try {
        const response = await fetch('/api/v1/shopping_items/checked', {
          method: 'DELETE',
          credentials: 'include',
          headers: { 'X-CSRF-Token': csrfToken() },
        })
        if (response.ok) this.items = this.items.filter((item) => !item.checked)
        return { ok: response.ok }
      } catch {
        return { ok: false }
      }
    },
  },
})
