import { defineStore } from 'pinia'

const STORAGE_KEY = 'recipe-planner-theme'

// Mirrors the inline script in application.html.erb, which applies the
// stored value synchronously before first paint to avoid a flash of the
// wrong theme - this just keeps document.documentElement in sync whenever
// the user changes their choice from Settings.vue.
function applyTheme(theme) {
  if (theme === 'dark' || theme === 'light') {
    document.documentElement.dataset.theme = theme
  } else {
    delete document.documentElement.dataset.theme
  }
}

export const useThemeStore = defineStore('theme', {
  state: () => ({
    theme: localStorage.getItem(STORAGE_KEY) || 'system',
  }),
  actions: {
    setTheme(theme) {
      this.theme = theme
      localStorage.setItem(STORAGE_KEY, theme)
      applyTheme(theme)
    },
  },
})
