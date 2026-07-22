<template>
  <p v-if="loading" class="fixed inset-0 z-50 flex items-center justify-center bg-cream text-ink/50">Loading...</p>
  <p v-else-if="error" class="fixed inset-0 z-50 flex items-center justify-center bg-cream text-accent-dark">{{ error }}</p>

  <div v-else-if="recipe" class="fixed inset-0 z-50 flex flex-col bg-cream text-ink">
    <header class="flex shrink-0 items-center justify-between gap-4 border-b border-line px-4 py-3 sm:px-6">
      <div class="min-w-0">
        <p class="text-xs font-medium uppercase tracking-wide text-ink/50">Step mode</p>
        <h1 class="truncate font-display text-lg font-semibold text-ink">{{ recipe.title }}</h1>
      </div>
      <button
        type="button"
        class="shrink-0 rounded-full border border-line px-3.5 py-1.5 text-sm text-ink hover:border-accent-dark hover:text-accent-dark transition-colors cursor-pointer"
        @click="exitStepMode"
      >
        Close
      </button>
    </header>

    <div v-if="currentStep" class="flex min-h-0 flex-1">
      <button
        type="button"
        :disabled="isFirst"
        aria-label="Previous step"
        class="flex w-20 shrink-0 items-center justify-center border-r border-line text-4xl transition-colors sm:w-32 sm:text-5xl"
        :class="isFirst ? 'text-ink/20 cursor-not-allowed' : 'text-ink/70 hover:bg-accent-soft hover:text-accent-dark cursor-pointer'"
        @click="previous"
      >
        &#8592;
      </button>

      <div class="flex-1 overflow-y-auto px-6 py-8 sm:px-12 sm:py-12">
        <p class="text-sm font-semibold uppercase tracking-wide text-accent-dark">
          Step {{ currentIndex + 1 }} of {{ steps.length }}
        </p>

        <ul v-if="currentStepIngredients.length" class="mt-4 space-y-1.5">
          <li
            v-for="ri in currentStepIngredients"
            :key="ri.id"
            class="flex gap-2 text-lg text-ink/85"
          >
            <span class="text-accent">&bull;</span>
            <span>{{ ingredientLabel(ri) }}<span v-if="ri.preparation">, {{ ri.preparation }}</span></span>
          </li>
        </ul>

        <p class="mt-6 max-w-3xl text-2xl leading-relaxed text-ink sm:text-3xl">
          {{ currentStep.description }}
        </p>
      </div>

      <button
        type="button"
        :disabled="isLast"
        aria-label="Next step"
        class="flex w-20 shrink-0 items-center justify-center border-l border-line text-4xl transition-colors sm:w-32 sm:text-5xl"
        :class="isLast ? 'text-ink/20 cursor-not-allowed' : 'text-ink/70 hover:bg-accent-soft hover:text-accent-dark cursor-pointer'"
        @click="next"
      >
        &#8594;
      </button>
    </div>

    <div class="flex shrink-0 justify-center gap-1.5 border-t border-line px-4 py-3">
      <span
        v-for="(step, index) in steps"
        :key="step.id"
        class="h-1.5 w-1.5 rounded-full"
        :class="index === currentIndex ? 'bg-accent-dark' : 'bg-line'"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'
import { ingredientsById as buildIngredientsById, stepIngredients as stepIngredientsFor, ingredientLabel } from '../lib/recipeIngredients'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()

const loading = ref(true)
const error = ref(null)
const currentIndex = ref(0)
let wakeLock = null

const recipe = computed(() => recipes.current)
const steps = computed(() => recipe.value?.instructions || [])
const currentStep = computed(() => steps.value[currentIndex.value])
const isFirst = computed(() => currentIndex.value === 0)
const isLast = computed(() => currentIndex.value === steps.value.length - 1)

const ingredientsById = computed(() => recipe.value ? buildIngredientsById(recipe.value) : new Map())
const currentStepIngredients = computed(() => currentStep.value ? stepIngredientsFor(ingredientsById.value, currentStep.value) : [])

function previous() {
  if (!isFirst.value) currentIndex.value -= 1
}

function next() {
  if (!isLast.value) currentIndex.value += 1
}

function exitStepMode() {
  router.push(`/recipes/${route.params.id}`)
}

function handleKeydown(event) {
  if (event.key === 'ArrowLeft') previous()
  if (event.key === 'ArrowRight') next()
}

async function requestWakeLock() {
  if (!('wakeLock' in navigator)) return
  try {
    wakeLock = await navigator.wakeLock.request('screen')
  } catch {
    // unsupported, backgrounded, or denied - step mode still works, screen just may dim
  }
}

function handleVisibilityChange() {
  if (document.visibilityState === 'visible') requestWakeLock()
}

onMounted(async () => {
  if (!recipe.value || String(recipe.value.id) !== route.params.id) {
    const result = await recipes.fetchOne(route.params.id)
    if (!result.ok) error.value = 'Recipe not found'
  }
  loading.value = false

  requestWakeLock()
  document.addEventListener('visibilitychange', handleVisibilityChange)
  document.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
  document.removeEventListener('keydown', handleKeydown)
  wakeLock?.release()
})
</script>
