<template>
  <div class="flex items-center justify-between">
    <h1 class="font-display text-3xl font-semibold text-ink">Recipes</h1>
    <router-link
      to="/recipes/import"
      class="rounded-full bg-accent px-4 py-2 text-sm font-medium text-white hover:bg-accent-dark transition-colors"
    >
      Add recipe
    </router-link>
  </div>

  <p v-if="loading" class="mt-8 text-ink/50">Loading...</p>
  <p v-else-if="error" class="mt-8 text-accent-dark">Failed to load recipes: {{ error }}</p>
  <p v-else-if="recipes.length === 0" class="mt-8 text-ink/50">No recipes yet.</p>

  <template v-else>
    <div class="mt-6 space-y-3">
      <input
        v-model="search"
        type="search"
        placeholder="Search recipes..."
        class="w-full rounded-lg border border-line bg-white px-4 py-3 text-base text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 sm:max-w-lg"
      />

      <div v-if="allTags.length" class="flex flex-wrap items-center gap-2">
        <button
          v-for="name in visibleTags"
          :key="name"
          type="button"
          class="rounded-full px-3 py-1 text-xs font-medium transition-colors cursor-pointer"
          :class="selectedTags.has(name)
            ? 'bg-accent text-white'
            : 'bg-sage/15 text-ink/70 hover:bg-sage/25'"
          :aria-pressed="selectedTags.has(name)"
          @click="toggleTag(name)"
        >
          {{ name }}
        </button>
        <button
          v-if="hiddenTagCount > 0"
          type="button"
          class="text-xs font-medium text-ink/50 hover:text-accent-dark cursor-pointer"
          @click="showAllTags = !showAllTags"
        >
          {{ showAllTags ? 'Show fewer' : `+${hiddenTagCount} more` }}
        </button>
        <button
          v-if="search || selectedTags.size"
          type="button"
          class="text-xs font-medium text-ink/50 hover:text-accent-dark cursor-pointer"
          @click="clearFilters"
        >
          Clear filters
        </button>
      </div>
    </div>

    <p v-if="filteredRecipes.length === 0" class="mt-8 text-ink/50">No recipes match your filters.</p>
    <ul v-else class="mt-6 grid gap-4 sm:grid-cols-2">
      <li v-for="recipe in filteredRecipes" :key="recipe.id" class="group relative">
        <router-link
          :to="`/recipes/${recipe.id}`"
          class="flex h-full gap-4 rounded-xl border border-line bg-white p-5 hover:border-accent hover:shadow-sm transition"
        >
          <img
            v-if="recipe.image_url"
            :src="recipe.image_url"
            alt=""
            class="h-16 w-16 shrink-0 rounded-lg object-cover"
          />
          <div class="min-w-0">
            <h2 class="font-display text-lg font-semibold text-ink">{{ recipe.title }}</h2>
            <p v-if="recipe.description" class="mt-1.5 text-sm text-ink/60 line-clamp-2">
              {{ recipe.description }}
            </p>
            <ul v-if="recipe.tags.length" class="mt-2 flex flex-wrap gap-1.5">
              <li
                v-for="tag in recipe.tags"
                :key="tag.id"
                class="rounded-full bg-sage/15 px-2.5 py-0.5 text-xs font-medium text-ink/70"
              >
                {{ tag.name }}
              </li>
            </ul>
          </div>
        </router-link>

        <router-link
          v-if="isOwner(recipe)"
          :to="`/recipes/${recipe.id}/edit`"
          class="absolute right-3 top-3 rounded-full border border-line bg-white px-3 py-1 text-xs font-medium text-ink opacity-0 transition-opacity hover:border-accent hover:text-accent group-hover:opacity-100"
        >
          Edit
        </router-link>
      </li>
    </ul>
  </template>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const recipes = ref([])
const loading = ref(true)
const error = ref(null)

const search = ref('')
const selectedTags = ref(new Set())
const pinnedTagNames = ref([])
const showAllTags = ref(false)

function isOwner(recipe) {
  return auth.isLoggedIn && recipe.user_id === auth.user.id
}

const allTags = computed(() => {
  const names = new Set()
  recipes.value.forEach((recipe) => recipe.tags.forEach((tag) => names.add(tag.name)))
  return [ ...names ].sort()
})

// Pinned tags (set in Settings.vue) always show up front, so a long tag
// list doesn't crowd out the ones the user actually cares about. Everything
// else stays collapsed behind "+N more" until expanded - or, if nothing's
// pinned yet, this is just the full list, same as before pinning existed.
const pinnedVisibleTags = computed(() => pinnedTagNames.value.filter((name) => allTags.value.includes(name)))

const visibleTags = computed(() => {
  if (showAllTags.value || pinnedVisibleTags.value.length === 0) return allTags.value
  return pinnedVisibleTags.value
})

const hiddenTagCount = computed(() =>
  pinnedVisibleTags.value.length > 0 ? allTags.value.length - pinnedVisibleTags.value.length : 0
)

function toggleTag(name) {
  const next = new Set(selectedTags.value)
  if (next.has(name)) next.delete(name)
  else next.add(name)
  selectedTags.value = next
}

function clearFilters() {
  search.value = ''
  selectedTags.value = new Set()
}

const filteredRecipes = computed(() => {
  const query = search.value.trim().toLowerCase()

  return recipes.value.filter((recipe) => {
    const matchesSearch = !query
      || recipe.title.toLowerCase().includes(query)
      || (recipe.description || '').toLowerCase().includes(query)

    const recipeTagNames = new Set(recipe.tags.map((tag) => tag.name))
    const matchesTags = [ ...selectedTags.value ].every((name) => recipeTagNames.has(name))

    return matchesSearch && matchesTags
  })
})

onMounted(async () => {
  try {
    const response = await fetch('/api/v1/recipes')
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    recipes.value = await response.json()

    const pinnedResponse = await fetch('/api/v1/pinned_tags', { credentials: 'include' })
    if (pinnedResponse.ok) {
      const pinned = await pinnedResponse.json()
      pinnedTagNames.value = pinned.map((tag) => tag.name).sort()
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})
</script>
