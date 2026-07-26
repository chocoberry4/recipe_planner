<template>
  <h1 class="font-display text-3xl font-semibold text-ink">Settings</h1>

  <section class="mt-8 border-t border-line pt-6">
    <h2 class="font-display text-lg font-semibold text-sage">Appearance</h2>
    <p class="mt-1 text-sm text-ink/60">Choose how Dishio looks on this device.</p>

    <div class="mt-4 inline-flex rounded-full border border-line bg-white p-1">
      <button
        v-for="option in themeOptions"
        :key="option.value"
        type="button"
        class="rounded-full px-4 py-1.5 text-sm font-medium transition-colors cursor-pointer"
        :class="theme.theme === option.value ? 'bg-accent text-white' : 'text-ink/70 hover:text-accent'"
        :aria-pressed="theme.theme === option.value"
        @click="theme.setTheme(option.value)"
      >
        {{ option.label }}
      </button>
    </div>
  </section>

  <section class="mt-8 border-t border-line pt-6">
    <h2 class="font-display text-lg font-semibold text-sage">Homepage</h2>
    <p class="mt-1 text-sm text-ink/60">Choose what you see first after logging in.</p>

    <div class="mt-4 inline-flex rounded-full border border-line bg-white p-1">
      <button
        v-for="option in homeViewOptions"
        :key="option.value"
        type="button"
        class="rounded-full px-4 py-1.5 text-sm font-medium transition-colors cursor-pointer"
        :class="auth.user.home_view === option.value ? 'bg-accent text-white' : 'text-ink/70 hover:text-accent'"
        :aria-pressed="auth.user.home_view === option.value"
        @click="setHomeView(option.value)"
      >
        {{ option.label }}
      </button>
    </div>
    <p v-if="preferencesError" class="mt-3 text-sm text-accent-dark">{{ preferencesError }}</p>
  </section>

  <section class="mt-8 border-t border-line pt-6">
    <h2 class="font-display text-lg font-semibold text-sage">Meal categories</h2>
    <p class="mt-1 text-sm text-ink/60">Hide categories you never use to declutter the planner.</p>

    <div class="mt-4 flex flex-wrap gap-2">
      <button
        v-for="option in mealTypeOptions"
        :key="option.field"
        type="button"
        class="rounded-full px-3 py-1 text-sm font-medium transition-colors cursor-pointer"
        :class="auth.user[option.field] ? 'bg-accent text-white' : 'bg-sage/15 text-ink/70 hover:bg-sage/25'"
        :aria-pressed="auth.user[option.field]"
        @click="toggleMealType(option.field)"
      >
        {{ option.label }}
      </button>
    </div>
    <p v-if="preferencesError" class="mt-3 text-sm text-accent-dark">{{ preferencesError }}</p>
  </section>

  <section class="mt-8 border-t border-line pt-6">
    <h2 class="font-display text-lg font-semibold text-sage">Import</h2>
    <p class="mt-1 text-sm text-ink/60">
      Enable importing recipes directly from a Tandoor Recipes export.
    </p>

    <div class="mt-4 inline-flex rounded-full border border-line bg-white p-1">
      <button
        type="button"
        class="rounded-full px-4 py-1.5 text-sm font-medium transition-colors cursor-pointer"
        :class="auth.user.tandoor_import_enabled ? 'bg-accent text-white' : 'text-ink/70 hover:text-accent'"
        :aria-pressed="auth.user.tandoor_import_enabled"
        @click="toggleTandoorImport"
      >
        {{ auth.user.tandoor_import_enabled ? 'Enabled' : 'Disabled' }}
      </button>
    </div>
    <p v-if="preferencesError" class="mt-3 text-sm text-accent-dark">{{ preferencesError }}</p>
  </section>

  <section class="mt-8 border-t border-line pt-6">
    <h2 class="font-display text-lg font-semibold text-sage">Pinned tags</h2>
    <p class="mt-1 text-sm text-ink/60">
      Pinned tags always show in the filter row on the Recipes page, ahead of everything else.
    </p>

    <p v-if="loading" class="mt-4 text-ink/50">Loading...</p>
    <p v-else-if="allTags.length === 0" class="mt-4 text-ink/50">
      No tags yet - add some from a recipe's edit page first.
    </p>
    <div v-else class="mt-4 flex flex-wrap gap-2">
      <button
        v-for="tag in allTags"
        :key="tag.id"
        type="button"
        class="rounded-full px-3 py-1 text-sm font-medium transition-colors cursor-pointer"
        :class="pinnedIds.has(tag.id) ? 'bg-accent text-white' : 'bg-sage/15 text-ink/70 hover:bg-sage/25'"
        :aria-pressed="pinnedIds.has(tag.id)"
        @click="togglePin(tag)"
      >
        {{ tag.name }}
      </button>
    </div>
    <p v-if="saveError" class="mt-3 text-sm text-accent-dark">{{ saveError }}</p>
  </section>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useThemeStore } from '../stores/theme'
import { useAuthStore } from '../stores/auth'
import { csrfToken } from '../lib/csrf'

const theme = useThemeStore()
const auth = useAuthStore()
const themeOptions = [
  { value: 'system', label: 'System' },
  { value: 'light', label: 'Light' },
  { value: 'dark', label: 'Dark' },
]
const homeViewOptions = [
  { value: 'random_recipes', label: 'Recipe ideas' },
  { value: 'weekly_planner', label: 'This week\'s planner' },
  { value: 'today', label: "Today's meals" },
]
const mealTypeOptions = [
  { field: 'show_breakfast', label: 'Breakfast' },
  { field: 'show_lunch', label: 'Lunch' },
  { field: 'show_dinner', label: 'Dinner' },
  { field: 'show_snack', label: 'Snack' },
]

const loading = ref(true)
const allTags = ref([])
const pinnedIds = ref(new Set())
const saveError = ref(null)
const preferencesError = ref(null)

async function savePreferences(partial) {
  const previous = { ...auth.user }
  auth.updateUser(partial)
  preferencesError.value = null

  const response = await fetch('/api/v1/user_preferences', {
    method: 'PATCH',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: JSON.stringify(partial),
  })

  if (!response.ok) {
    auth.updateUser(previous)
    preferencesError.value = 'Failed to save. Try again.'
  }
}

function setHomeView(value) {
  savePreferences({ home_view: value })
}

function toggleMealType(field) {
  savePreferences({ [field]: !auth.user[field] })
}

function toggleTandoorImport() {
  savePreferences({ tandoor_import_enabled: !auth.user.tandoor_import_enabled })
}

onMounted(async () => {
  try {
    const [ recipesResponse, pinnedResponse ] = await Promise.all([
      fetch('/api/v1/recipes', { credentials: 'include' }),
      fetch('/api/v1/pinned_tags', { credentials: 'include' }),
    ])

    if (recipesResponse.ok) {
      const recipes = await recipesResponse.json()
      const byId = new Map()
      recipes.forEach((recipe) => recipe.tags.forEach((tag) => byId.set(tag.id, tag)))
      allTags.value = [ ...byId.values() ].sort((a, b) => a.name.localeCompare(b.name))
    }

    if (pinnedResponse.ok) {
      const pinned = await pinnedResponse.json()
      pinnedIds.value = new Set(pinned.map((tag) => tag.id))
    }
  } finally {
    loading.value = false
  }
})

async function togglePin(tag) {
  const next = new Set(pinnedIds.value)
  if (next.has(tag.id)) next.delete(tag.id)
  else next.add(tag.id)

  const previous = pinnedIds.value
  pinnedIds.value = next
  saveError.value = null

  const response = await fetch('/api/v1/pinned_tags', {
    method: 'PATCH',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken(),
    },
    body: JSON.stringify({ tag_ids: [ ...next ] }),
  })

  if (!response.ok) {
    pinnedIds.value = previous
    saveError.value = 'Failed to save. Try again.'
  }
}
</script>
