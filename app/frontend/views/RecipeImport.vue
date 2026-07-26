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
      <button
        v-if="auth.user?.tandoor_import_enabled"
        type="button"
        class="flex-1 rounded-full py-1.5 transition-colors cursor-pointer"
        :class="mode === 'tandoor' ? 'bg-white text-ink shadow-sm' : 'text-ink/60 hover:text-ink'"
        @click="mode = 'tandoor'"
      >
        From Tandoor
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

    <form v-else-if="mode === 'paste'" class="mt-6 space-y-5" @submit.prevent="handleTextSubmit">
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

    <form v-else-if="mode === 'tandoor' && auth.user?.tandoor_import_enabled" class="mt-6 space-y-5" @submit.prevent="handleTandoorSubmit">
      <div>
        <span class="text-sm font-medium text-ink/80">Tandoor export (.zip)</span>
        <div
          class="mt-2 flex flex-col items-center justify-center gap-1 rounded-lg border-2 border-dashed px-4 py-8 text-center transition-colors cursor-pointer"
          :class="isDraggingTandoor ? 'border-accent bg-accent-soft/40' : 'border-line hover:border-accent/50'"
          @click="triggerTandoorFilePicker"
          @dragover.prevent="isDraggingTandoor = true"
          @dragleave="isDraggingTandoor = false"
          @drop.prevent="handleTandoorDrop"
        >
          <p class="text-sm font-medium text-ink/70">
            {{ tandoorFile ? tandoorFile.name : 'Drop a Tandoor export .zip here, or click to choose a file' }}
          </p>
          <p class="text-xs text-ink/40">Works for a single recipe's export or a bulk export of many.</p>
          <input
            ref="tandoorFileInput"
            type="file"
            accept=".zip,application/zip"
            class="hidden"
            @change="handleTandoorFileInputChange"
            @click.stop
          />
        </div>
      </div>

      <p v-if="submitting" class="text-sm text-ink/60">
        {{ tandoorProgress && tandoorProgress.total
          ? `Importing ${tandoorProgress.processed} of ${tandoorProgress.total} recipes...`
          : 'Importing...' }}
      </p>

      <div v-if="importedRecipes && importedRecipes.length > 1">
        <p class="text-sm text-ink/70">Imported {{ importedRecipes.length }} recipes:</p>
        <ul class="mt-2 space-y-1">
          <li v-for="r in importedRecipes" :key="r.id">
            <router-link
              :to="`/recipes/${r.id}/review`"
              class="text-sm font-medium text-accent hover:text-accent-dark"
            >
              {{ r.title }}
            </router-link>
          </li>
        </ul>
      </div>
      <p v-if="importErrors.length" class="text-sm text-accent-dark">
        {{ importErrors.join(', ') }}
      </p>

      <button
        type="submit"
        :disabled="submitting || !tandoorFile"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
      >
        {{ submitting ? 'Importing...' : 'Import' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'
import { useMealPlansStore } from '../stores/mealPlans'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()
const mealPlans = useMealPlansStore()
const auth = useAuthStore()

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

const tandoorFile = ref(null)
const tandoorFileInput = ref(null)
const isDraggingTandoor = ref(false)
const importedRecipes = ref(null)
const importErrors = ref([])
const tandoorProgress = ref(null) // { processed, total } while a bulk import job runs
let tandoorPollTimer = null

onUnmounted(() => {
  if (tandoorPollTimer) clearTimeout(tandoorPollTimer)
})

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

function triggerTandoorFilePicker() {
  if (submitting.value) return
  tandoorFileInput.value?.click()
}

function handleTandoorFileInputChange(event) {
  const file = event.target.files?.[0]
  if (file) tandoorFile.value = file
  event.target.value = '' // allow re-selecting the same file next time
}

function handleTandoorDrop(event) {
  isDraggingTandoor.value = false
  if (submitting.value) return
  const file = event.dataTransfer?.files?.[0]
  if (file) tandoorFile.value = file
}

async function handleTandoorSubmit() {
  if (!tandoorFile.value) return

  submitting.value = true
  error.value = null
  importedRecipes.value = null
  importErrors.value = []
  tandoorProgress.value = null

  const result = await recipes.importFromTandoorZip(tandoorFile.value)

  if (!result.ok) {
    submitting.value = false
    error.value = result.errors.join(', ') || 'Import failed.'
    return
  }

  pollTandoorImport(result.importId)
}

// A bulk export runs as a background job (TandoorImportJob) since it can
// hold hundreds of recipes with images - too slow for one request. Poll
// until it's done, showing processed/total in the meantime. A single failed
// poll (e.g. a transient network blip) retries rather than giving up on the
// whole import - only a run of consecutive failures is treated as fatal.
const MAX_CONSECUTIVE_POLL_FAILURES = 5
let consecutivePollFailures = 0

async function pollTandoorImport(importId) {
  const { ok, status } = await recipes.fetchTandoorImport(importId)

  if (!ok) {
    consecutivePollFailures += 1
    if (consecutivePollFailures >= MAX_CONSECUTIVE_POLL_FAILURES) {
      submitting.value = false
      error.value = 'Lost track of the import - check your connection and try again.'
      return
    }
    tandoorPollTimer = setTimeout(() => pollTandoorImport(importId), 1500)
    return
  }
  consecutivePollFailures = 0

  tandoorProgress.value = { processed: status.processed_recipes, total: status.total_recipes }

  if (status.status === 'processing' || status.status === 'pending') {
    tandoorPollTimer = setTimeout(() => pollTandoorImport(importId), 1500)
    return
  }

  submitting.value = false
  tandoorProgress.value = null

  if (status.status === 'failed') {
    error.value = status.errors[0] || 'Import failed.'
    return
  }

  // A bulk export can create several recipes at once, unlike every other
  // import path here - only the single-recipe case has one obvious place to
  // go next, so that's the only case that auto-navigates.
  if (status.recipes.length === 1) {
    await relinkMealPlanIfNeeded(status.recipes[0].id)
    router.push(`/recipes/${status.recipes[0].id}/review`)
    return
  }

  importedRecipes.value = status.recipes
  importErrors.value = status.errors
}
</script>
