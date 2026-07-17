<template>
  <div class="flex items-center justify-between">
    <h1 class="font-display text-3xl font-semibold text-ink">Recipes</h1>
    <router-link
      to="/recipes/new"
      class="rounded-full bg-accent px-4 py-2 text-sm font-medium text-white hover:bg-accent-dark transition-colors"
    >
      New recipe
    </router-link>
  </div>

  <p v-if="loading" class="mt-8 text-ink/50">Loading...</p>
  <p v-else-if="error" class="mt-8 text-accent-dark">Failed to load recipes: {{ error }}</p>
  <p v-else-if="recipes.length === 0" class="mt-8 text-ink/50">No recipes yet.</p>
  <ul v-else class="mt-8 grid gap-4 sm:grid-cols-2">
    <li v-for="recipe in recipes" :key="recipe.id">
      <router-link
        :to="`/recipes/${recipe.id}`"
        class="block h-full rounded-xl border border-line bg-white p-5 hover:border-accent hover:shadow-sm transition"
      >
        <h2 class="font-display text-lg font-semibold text-ink">{{ recipe.title }}</h2>
        <p v-if="recipe.description" class="mt-1.5 text-sm text-ink/60 line-clamp-2">
          {{ recipe.description }}
        </p>
      </router-link>
    </li>
  </ul>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const recipes = ref([])
const loading = ref(true)
const error = ref(null)

onMounted(async () => {
  try {
    const response = await fetch('/api/v1/recipes')
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    recipes.value = await response.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})
</script>
