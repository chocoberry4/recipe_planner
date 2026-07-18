<template>
  <div class="max-w-xl mx-auto">
    <h1 class="font-display text-2xl font-semibold text-ink">Edit recipe</h1>

    <form class="mt-8 space-y-5" @submit.prevent="handleSubmit">
      <p v-if="error" class="rounded-lg bg-accent-soft px-3 py-2 text-sm text-accent-dark">
        {{ error }}
      </p>

      <label class="block">
        <span class="text-sm font-medium text-ink/80">Title</span>
        <input
          v-model="title"
          type="text"
          required
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>

      <label class="block">
        <span class="text-sm font-medium text-ink/80">Description</span>
        <textarea
          v-model="description"
          rows="4"
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        ></textarea>
      </label>

      <button
        type="submit"
        :disabled="submitting"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
      >
        Save
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()

const title = ref('')
const description = ref('')
const error = ref(null)
const submitting = ref(false)

onMounted(async () => {
  const result = await recipes.fetchOne(route.params.id)
  if (result.ok) {
    title.value = recipes.current.title
    description.value = recipes.current.description
  } else {
    error.value = 'Recipe not found'
  }
})

async function handleSubmit() {
  submitting.value = true
  error.value = null

  const result = await recipes.update(route.params.id, { title: title.value, description: description.value })

  submitting.value = false

  if (result.ok) {
    router.push(`/recipes/${result.recipe.id}`)
  } else {
    error.value = result.errors.join(', ')
  }
}
</script>
