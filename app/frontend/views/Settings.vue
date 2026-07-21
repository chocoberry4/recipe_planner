<template>
  <h1 class="font-display text-3xl font-semibold text-ink">Settings</h1>

  <section class="mt-8 border-t border-line pt-6">
    <h2 class="font-display text-lg font-semibold text-sage">Appearance</h2>
    <p class="mt-1 text-sm text-ink/60">Choose how Recipe Planner looks on this device.</p>

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
import { csrfToken } from '../lib/csrf'

const theme = useThemeStore()
const themeOptions = [
  { value: 'system', label: 'System' },
  { value: 'light', label: 'Light' },
  { value: 'dark', label: 'Dark' },
]

const loading = ref(true)
const allTags = ref([])
const pinnedIds = ref(new Set())
const saveError = ref(null)

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
