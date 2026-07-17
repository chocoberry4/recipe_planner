<template>
  <p v-if="loading" class="text-ink/50">Loading...</p>
  <p v-else-if="error" class="text-accent-dark">{{ error }}</p>
  <div v-else-if="recipe">
    <div>
      <h1 class="font-display text-3xl font-semibold text-ink">{{ recipe.title }}</h1>
      <p class="mt-1 text-sm text-ink/50">
        Review the ingredients autosort assigned to each step, then fix anything that's wrong.
      </p>
    </div>

    <section class="mt-8 space-y-5">
      <div
        v-for="instruction in recipe.instructions"
        :key="instruction.id"
        class="rounded-xl border border-line bg-white p-4"
      >
        <div class="flex gap-3">
          <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-accent-soft text-xs font-semibold text-accent-dark">
            {{ instruction.step_number }}
          </span>
          <p class="text-ink/85">{{ instruction.description }}</p>
        </div>

        <ul class="mt-3 ml-9 flex flex-wrap gap-2">
          <li
            v-for="ri in assignedFor(instruction.id)"
            :key="ri.id"
            class="flex items-center gap-1.5 rounded-full bg-sage/15 px-3 py-1 text-sm text-ink/85"
          >
            {{ ingredientLabel(ri) }}
            <button
              type="button"
              class="text-ink/40 hover:text-accent-dark cursor-pointer"
              :aria-label="`Remove ${ri.name} from this step`"
              @click="removeFromStep(instruction.id, ri.id)"
            >
              &times;
            </button>
          </li>
          <li v-if="assignedFor(instruction.id).length === 0" class="text-sm text-ink/40">
            No ingredients assigned.
          </li>
        </ul>

        <select
          class="mt-3 ml-9 rounded-full border border-line bg-white px-3 py-1 text-sm text-ink/70 outline-none focus:border-accent"
          :aria-label="`Add ingredient to step ${instruction.step_number}`"
          @change="onAddSelect(instruction.id, $event)"
        >
          <option value="">+ Add ingredient&hellip;</option>
          <option v-for="ri in unresolved" :key="ri.id" :value="ri.id">
            {{ ingredientLabel(ri) }}
          </option>
        </select>
      </div>
    </section>

    <section class="mt-8 border-t border-line pt-6">
      <h2 class="font-display text-lg font-semibold text-sage">Unresolved ingredients</h2>
      <p v-if="unresolved.length === 0" class="mt-2 text-sm text-ink/50">
        Everything's assigned to a step.
      </p>
      <ul v-else class="mt-3 flex flex-wrap gap-2">
        <li
          v-for="ri in unresolved"
          :key="ri.id"
          class="rounded-full border border-line px-3 py-1 text-sm text-ink/70"
        >
          {{ ingredientLabel(ri) }}
        </li>
      </ul>
    </section>

    <p v-if="saveError" class="mt-6 rounded-lg bg-accent-soft px-3 py-2 text-sm text-accent-dark">
      {{ saveError }}
    </p>

    <div class="mt-8 flex gap-3">
      <button
        type="button"
        :disabled="saving"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
        @click="handleSave"
      >
        {{ saving ? 'Saving...' : 'Save' }}
      </button>
      <router-link
        :to="`/recipes/${recipe.id}`"
        class="rounded-full border border-line px-5 py-2.5 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors"
      >
        Cancel
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { reactive, computed, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()

const loading = ref(true)
const error = ref(null)
const saving = ref(false)
const saveError = ref(null)
const recipe = computed(() => recipes.current)

// { [instructionId]: [recipe_ingredient_id, ...] } - a local editable draft,
// seeded from the autosorter's result and only persisted on Save.
const assignments = reactive({})

onMounted(async () => {
  const result = await recipes.fetchOne(route.params.id)
  loading.value = false
  if (!result.ok) {
    error.value = 'Recipe not found'
    return
  }

  recipe.value.instructions.forEach((instruction) => {
    assignments[instruction.id] = [ ...instruction.recipe_ingredient_ids ]
  })
})

const allIngredients = computed(() => {
  if (!recipe.value) return []
  const grouped = recipe.value.recipe_ingredient_groups.flatMap((g) => g.recipe_ingredients)
  return [ ...recipe.value.ingredients, ...grouped ]
})

const ingredientsById = computed(() => new Map(allIngredients.value.map((ri) => [ ri.id, ri ])))

const assignedIds = computed(() => new Set(Object.values(assignments).flat()))

const unresolved = computed(() => allIngredients.value.filter((ri) => !assignedIds.value.has(ri.id)))

function assignedFor(instructionId) {
  return (assignments[instructionId] || []).map((id) => ingredientsById.value.get(id)).filter(Boolean)
}

function removeFromStep(instructionId, recipeIngredientId) {
  assignments[instructionId] = (assignments[instructionId] || []).filter((id) => id !== recipeIngredientId)
}

// An ingredient lives in at most one step at a time, so adding it to a new
// step first removes it from wherever it currently is - this is how "moving"
// an ingredient between steps works, without needing drag gestures.
function addToStep(instructionId, recipeIngredientId) {
  const id = Number(recipeIngredientId)
  Object.keys(assignments).forEach((key) => {
    assignments[key] = assignments[key].filter((existingId) => existingId !== id)
  })
  assignments[instructionId] = [ ...(assignments[instructionId] || []), id ]
}

function onAddSelect(instructionId, event) {
  const value = event.target.value
  if (value) addToStep(instructionId, value)
  event.target.value = ''
}

function ingredientLabel(ri) {
  return [ ri.quantity, ri.unit, ri.name ].filter(Boolean).join(' ')
}

async function handleSave() {
  saving.value = true
  saveError.value = null

  const result = await recipes.saveAssignments(route.params.id, { ...assignments })

  saving.value = false
  if (result.ok) {
    router.push(`/recipes/${route.params.id}`)
  } else {
    saveError.value = result.error || 'Failed to save.'
  }
}
</script>
