import { defineStore } from 'pinia'
import { csrfToken } from '../lib/csrf'

async function submitAuth(url, body) {
  const response = await fetch(url, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const data = await response.json().catch(() => ({}))

  if (response.ok) return { ok: true, user: data }
  return { ok: false, errors: data.errors || [data.error || 'Something went wrong'] }
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    checked: false,
  }),
  getters: {
    isLoggedIn: (state) => !!state.user,
  },
  actions: {
    async fetchCurrentUser() {
      try {
        const response = await fetch('/api/v1/me', { credentials: 'include' })
        this.user = response.ok ? await response.json() : null
      } catch {
        this.user = null
      } finally {
        this.checked = true
      }
    },

    async signup({ email, username, password, passwordConfirmation }) {
      const result = await submitAuth('/api/v1/signup', {
        user: { email, username, password, password_confirmation: passwordConfirmation },
      })
      if (result.ok) {
        this.user = result.user
        this.checked = true
      }
      return result
    },

    async login({ email, password, rememberMe }) {
      const result = await submitAuth('/api/v1/login', { user: { email, password, remember_me: rememberMe } })
      if (result.ok) {
        this.user = result.user
        this.checked = true
      }
      return result
    },

    updateUser(partial) {
      this.user = { ...this.user, ...partial }
    },

    async logout() {
      await fetch('/api/v1/logout', {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'X-CSRF-Token': csrfToken() },
      })
      this.user = null
      this.checked = true
    },
  },
})
