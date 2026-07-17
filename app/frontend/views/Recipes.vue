<template>
  <h1>Recipes</h1>

  <p v-if="loading">Loading...</p>
  <p v-else-if="error">Failed to load recipes: {{ error }}</p>
  <p v-else-if="recipes.length === 0">No recipes yet.</p>
  <ul v-else>
    <li v-for="recipe in recipes" :key="recipe.id">
      <strong>{{ recipe.title }}</strong>
      <p v-if="recipe.description">{{ recipe.description }}</p>
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
