<template>
  <div class="max-w-xl mx-auto">
    <h1 class="font-display text-2xl font-semibold text-ink">
      {{ isEdit ? 'Edit recipe' : 'New recipe' }}
    </h1>

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

      <template v-if="!isEdit">
        <button
          v-if="!showIngredients"
          type="button"
          class="rounded-full border border-line px-4 py-2 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors cursor-pointer"
          @click="showIngredients = true"
        >
          + Paste ingredients
        </button>

        <label v-else class="block">
          <span class="text-sm font-medium text-ink/80">Ingredients (one per line)</span>
          <textarea
            v-model="ingredientsText"
            rows="6"
            placeholder="1 onion&#10;1 x chicken breast&#10;1 tbsp salt"
            class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 font-mono text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
          ></textarea>
        </label>

        <label class="block">
          <span class="text-sm font-medium text-ink/80">Instructions (one step per line)</span>
          <textarea
            v-model="instructionsText"
            rows="6"
            placeholder="Whisk the eggs.&#10;Add the flour and stir."
            class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
          ></textarea>
        </label>
      </template>

      <button
        type="submit"
        :disabled="submitting"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
      >
        {{ isEdit ? 'Save' : 'Create' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()

const isEdit = computed(() => !!route.params.id)

const title = ref('')
const description = ref('')
const showIngredients = ref(false)
const ingredientsText = ref('')
const instructionsText = ref('')
const error = ref(null)
const submitting = ref(false)

onMounted(async () => {
  if (!isEdit.value) return

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

  if (isEdit.value) {
    const result = await recipes.update(route.params.id, { title: title.value, description: description.value })
    submitting.value = false

    if (result.ok) {
      router.push(`/recipes/${result.recipe.id}`)
    } else {
      error.value = result.errors.join(', ')
    }
    return
  }

  const result = await recipes.importFromText({
    title: title.value,
    description: description.value,
    ingredients_text: ingredientsText.value,
    instructions_text: instructionsText.value,
  })

  submitting.value = false

  if (result.ok) {
    const destination = result.recipe.instructions.length
      ? `/recipes/${result.recipe.id}/review`
      : `/recipes/${result.recipe.id}`
    router.push(destination)
  } else {
    error.value = result.error || 'Failed to create recipe.'
  }
}
</script>
