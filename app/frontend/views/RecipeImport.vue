<template>
  <div class="max-w-xl mx-auto">
    <h1 class="font-display text-2xl font-semibold text-ink">Add a recipe</h1>

    <div class="mt-6 flex gap-1 rounded-full bg-line/40 p-1 text-sm font-medium">
      <button
        type="button"
        class="flex-1 rounded-full py-1.5 transition-colors cursor-pointer"
        :class="mode === 'url' ? 'bg-white text-ink shadow-sm' : 'text-ink/60 hover:text-ink'"
        @click="mode = 'url'"
      >
        From a URL
      </button>
      <button
        type="button"
        class="flex-1 rounded-full py-1.5 transition-colors cursor-pointer"
        :class="mode === 'paste' ? 'bg-white text-ink shadow-sm' : 'text-ink/60 hover:text-ink'"
        @click="mode = 'paste'"
      >
        Paste text
      </button>
    </div>

    <p v-if="error" class="mt-6 rounded-lg bg-accent-soft px-3 py-2 text-sm text-accent-dark">
      {{ error }}
    </p>

    <form v-if="mode === 'url'" class="mt-6 space-y-5" @submit.prevent="handleUrlSubmit">
      <label class="block">
        <span class="text-sm font-medium text-ink/80">Recipe URL</span>
        <input
          v-model="url"
          type="url"
          required
          placeholder="https://example.com/a-recipe"
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>
      <p class="text-sm text-ink/50">
        Works on sites that publish structured recipe data. If it doesn't find any, switch to "Paste text" instead.
      </p>

      <button
        type="submit"
        :disabled="submitting"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
      >
        {{ submitting ? 'Importing...' : 'Import' }}
      </button>
    </form>

    <form v-else class="mt-6 space-y-5" @submit.prevent="handleTextSubmit">
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

      <label class="block">
        <span class="text-sm font-medium text-ink/80">Ingredients (one per line, optional)</span>
        <textarea
          v-model="ingredientsText"
          rows="6"
          placeholder="1 1/2 cups all-purpose flour, sifted&#10;2 eggs&#10;salt to taste"
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 font-mono text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        ></textarea>
      </label>

      <label class="block">
        <span class="text-sm font-medium text-ink/80">Instructions (one step per line, optional)</span>
        <textarea
          v-model="instructionsText"
          rows="6"
          placeholder="Whisk the eggs.&#10;Add the flour and stir."
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        ></textarea>
      </label>

      <button
        type="submit"
        :disabled="submitting"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
      >
        {{ submitting ? 'Creating...' : 'Create' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'
import { useMealPlansStore } from '../stores/mealPlans'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()
const mealPlans = useMealPlansStore()

// Arriving from the planner's "Add" link on a freeform (non-recipe) meal
// plan entry pre-fills the title so the name doesn't need retyping - "paste"
// is the only mode with a title field, so that's the mode this lands in.
const prefillTitle = typeof route.query.title === 'string' ? route.query.title : ''
// Same origin: once the recipe exists, the slot that prompted its creation
// is relinked to it - otherwise the planner keeps showing the original
// typed-out label forever, even after a real recipe now exists for it. The
// title actually saved (especially via URL import, which ignores
// prefillTitle entirely) can end up different from the label the slot still
// has, which is exactly the mismatch this closes.
const relinkMealPlanId = typeof route.query.mealPlanId === 'string' ? route.query.mealPlanId : null

const mode = ref(prefillTitle ? 'paste' : 'url')
const url = ref('')
const title = ref(prefillTitle)
const description = ref('')
const ingredientsText = ref('')
const instructionsText = ref('')
const error = ref(null)
const submitting = ref(false)

const ERROR_MESSAGES = {
  no_structured_data: "We couldn't find recipe data on that page. Try \"Paste text\" instead.",
  fetch_failed: "We couldn't fetch that page. Check the URL and try again.",
  invalid_url: "That doesn't look like a URL we can fetch.",
}

async function relinkMealPlanIfNeeded(recipeId) {
  if (relinkMealPlanId) await mealPlans.relink(relinkMealPlanId, recipeId)
}

async function handleUrlSubmit() {
  submitting.value = true
  error.value = null

  const result = await recipes.importFromUrl(url.value)

  submitting.value = false
  if (result.ok) {
    await relinkMealPlanIfNeeded(result.recipe.id)
    router.push(`/recipes/${result.recipe.id}/review`)
  } else {
    error.value = ERROR_MESSAGES[result.error] || 'Import failed.'
  }
}

async function handleTextSubmit() {
  submitting.value = true
  error.value = null

  const result = await recipes.importFromText({
    title: title.value,
    description: description.value,
    ingredients_text: ingredientsText.value,
    instructions_text: instructionsText.value,
  })

  submitting.value = false
  if (result.ok) {
    await relinkMealPlanIfNeeded(result.recipe.id)
    const destination = result.recipe.instructions.length
      ? `/recipes/${result.recipe.id}/review`
      : `/recipes/${result.recipe.id}`
    router.push(destination)
  } else {
    error.value = 'Import failed.'
  }
}
</script>
