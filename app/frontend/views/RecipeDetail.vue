<template>
  <p v-if="loading" class="text-ink/50">Loading...</p>
  <p v-else-if="error" class="text-accent-dark">{{ error }}</p>
  <div v-else-if="recipe">
    <img
      v-if="recipe.image_url"
      :src="recipe.image_url"
      alt=""
      class="max-h-96 w-full rounded-xl bg-line/20 object-contain"
    />

    <div class="mt-6 flex items-start justify-between gap-4">
      <div>
        <h1 class="font-display text-3xl font-semibold text-ink">{{ recipe.title }}</h1>
        <p v-if="formattedDuration" class="mt-1 text-sm font-medium text-ink/50">
          {{ formattedDuration }}<span v-if="finishTime"> &middot; Finish by {{ finishTime }}</span>
        </p>
        <p v-if="recipe.description" class="mt-2 text-ink/60">{{ recipe.description }}</p>
        <ul v-if="recipe.tags.length" class="mt-3 flex flex-wrap gap-2">
          <li
            v-for="tag in recipe.tags"
            :key="tag.id"
            class="rounded-full bg-sage/15 px-3 py-1 text-xs font-medium text-ink/70"
          >
            {{ tag.name }}
          </li>
        </ul>
      </div>

      <div class="flex shrink-0 gap-2 text-sm">
        <router-link
          v-if="recipe.instructions.length"
          :to="stepModeLink"
          class="rounded-full bg-accent px-3.5 py-1.5 text-white hover:bg-accent-dark transition-colors"
        >
          Step mode
        </router-link>
        <template v-if="isOwner">
          <router-link
            v-if="recipe.instructions.length"
            :to="`/recipes/${recipe.id}/review`"
            class="rounded-full border border-line px-3.5 py-1.5 text-ink hover:border-accent hover:text-accent transition-colors"
          >
            Review ingredients
          </router-link>
          <router-link
            :to="`/recipes/${recipe.id}/edit`"
            class="rounded-full border border-line px-3.5 py-1.5 text-ink hover:border-accent hover:text-accent transition-colors"
          >
            Edit
          </router-link>
          <button
            type="button"
            class="rounded-full border border-line px-3.5 py-1.5 text-ink/70 hover:border-accent-dark hover:text-accent-dark transition-colors cursor-pointer"
            @click="handleDelete"
          >
            Delete
          </button>
        </template>
      </div>
    </div>

    <section
      v-if="recipe.recipe_ingredient_groups.length || recipe.ingredients.length"
      class="mt-8 border-t border-line pt-6"
    >
      <div class="flex flex-wrap items-center justify-between gap-3">
        <h2 class="font-display text-lg font-semibold text-sage">Ingredients</h2>
        <div v-if="recipe.servings" class="flex items-center gap-2 text-sm text-ink/70">
          <span>Servings</span>
          <button
            type="button"
            aria-label="Fewer servings"
            class="flex h-7 w-7 items-center justify-center rounded-full border border-line hover:border-accent hover:text-accent transition-colors cursor-pointer disabled:cursor-not-allowed disabled:opacity-40"
            :disabled="desiredServings <= 1"
            @click="adjustServings(-1)"
          >&minus;</button>
          <input
            v-model.number="desiredServings"
            type="number"
            min="1"
            aria-label="Servings"
            class="w-14 rounded-lg border border-line bg-white px-2 py-1 text-center text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20 [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
          />
          <button
            type="button"
            aria-label="More servings"
            class="flex h-7 w-7 items-center justify-center rounded-full border border-line hover:border-accent hover:text-accent transition-colors cursor-pointer"
            @click="adjustServings(1)"
          >+</button>
          <button
            v-if="factor !== 1"
            type="button"
            class="text-xs text-accent hover:underline cursor-pointer"
            @click="desiredServings = recipe.servings"
          >Reset (recipe makes {{ recipe.servings }})</button>
        </div>
      </div>

      <div v-for="group in recipe.recipe_ingredient_groups" :key="group.id" class="mt-4">
        <h3 class="text-sm font-semibold text-ink/70">{{ group.name }}</h3>
        <ul class="mt-2 space-y-1.5 text-ink/85">
          <li v-for="ri in group.recipe_ingredients" :key="ri.id" class="flex items-start gap-3">
            <label class="flex cursor-pointer items-start gap-2">
              <input
                type="checkbox"
                class="mt-1 h-4 w-4 shrink-0 accent-accent"
                :checked="checkedIngredientIds.has(ri.id)"
                @change="toggleChecked(ri.id)"
              />
              <span :class="{ 'text-ink/40 line-through': checkedIngredientIds.has(ri.id) }">
                {{ ingredientLabel(ri, factor) }}<span v-if="ri.preparation">, {{ ri.preparation }}</span>
              </span>
            </label>
            <a
              :href="ocadoSearchUrl(ri)"
              target="_blank"
              rel="noopener noreferrer"
              class="shrink-0 rounded-full border border-line px-2.5 py-0.5 text-xs text-ink/60 hover:border-accent hover:text-accent transition-colors"
              :aria-label="`Buy ${ri.name} on Ocado`"
            >Buy now</a>
            <button
              type="button"
              class="shrink-0 rounded-full border px-2.5 py-0.5 text-xs transition-colors cursor-pointer"
              :class="addedIds.has(ri.id) ? 'border-accent text-accent' : 'border-line text-ink/60 hover:border-accent hover:text-accent'"
              :aria-label="`Add ${ri.name} to shopping list`"
              @click="addToShoppingList(ri)"
            >{{ addedIds.has(ri.id) ? 'Added' : 'Add to list' }}</button>
          </li>
        </ul>
      </div>

      <ul v-if="recipe.ingredients.length" class="mt-4 space-y-1.5 text-ink/85">
        <li v-for="ri in recipe.ingredients" :key="ri.id" class="flex items-start gap-3">
          <label class="flex cursor-pointer items-start gap-2">
            <input
              type="checkbox"
              class="mt-1 h-4 w-4 shrink-0 accent-accent"
              :checked="checkedIngredientIds.has(ri.id)"
              @change="toggleChecked(ri.id)"
            />
            <span :class="{ 'text-ink/40 line-through': checkedIngredientIds.has(ri.id) }">
              {{ ingredientLabel(ri, factor) }}<span v-if="ri.preparation">, {{ ri.preparation }}</span>
            </span>
          </label>
          <a
            :href="ocadoSearchUrl(ri)"
            target="_blank"
            rel="noopener noreferrer"
            class="shrink-0 rounded-full border border-line px-2.5 py-0.5 text-xs text-ink/60 hover:border-accent hover:text-accent transition-colors"
            :aria-label="`Buy ${ri.name} on Ocado`"
          >Buy now</a>
          <button
            type="button"
            class="shrink-0 rounded-full border px-2.5 py-0.5 text-xs transition-colors cursor-pointer"
            :class="addedIds.has(ri.id) ? 'border-accent text-accent' : 'border-line text-ink/60 hover:border-accent hover:text-accent'"
            :aria-label="`Add ${ri.name} to shopping list`"
            @click="addToShoppingList(ri)"
          >{{ addedIds.has(ri.id) ? 'Added' : 'Add to list' }}</button>
        </li>
      </ul>
    </section>

    <section v-if="recipe.instructions.length" class="mt-8 border-t border-line pt-6">
      <h2 class="font-display text-lg font-semibold text-sage">Instructions</h2>
      <ol class="mt-4 space-y-3">
        <li v-for="step in recipe.instructions" :key="step.id" class="flex items-start gap-3">
          <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-accent-soft text-xs font-semibold text-accent-dark">
            {{ step.step_number }}
          </span>
          <div>
            <p v-if="stepIngredients(step).length" class="text-sm text-ink/60">
              {{ stepIngredients(step).map((ri) => ingredientLabel(ri, factor)).join(', ') }}
            </p>
            <span class="text-ink/85">{{ step.description }}</span>
            <img
              v-if="step.image_url"
              :src="step.image_url"
              alt=""
              class="mt-2 max-h-48 rounded-lg bg-line/20 object-contain"
            />
          </div>
        </li>
      </ol>
    </section>

    <p v-if="recipe.source_url" class="mt-8 border-t border-line pt-6 text-sm text-ink/50">
      Source:
      <a
        :href="recipe.source_url"
        target="_blank"
        rel="noopener noreferrer"
        class="text-accent hover:underline"
      >{{ recipe.source_url }}</a>
    </p>

    <ConfirmDialog
      :open="showDeleteConfirm"
      title="Delete this recipe?"
      message="This can't be undone."
      confirm-label="Delete"
      @confirm="confirmDelete"
      @cancel="showDeleteConfirm = false"
    />
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'
import { useAuthStore } from '../stores/auth'
import { ingredientsById as buildIngredientsById, stepIngredients as stepIngredientsFor, ingredientLabel, scaleFactor, ocadoSearchUrl } from '../lib/recipeIngredients'
import ConfirmDialog from '../components/ConfirmDialog.vue'
import { useShoppingListStore } from '../stores/shoppingList'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()
const auth = useAuthStore()

const loading = ref(true)
const error = ref(null)
const showDeleteConfirm = ref(false)
const recipe = computed(() => recipes.current)
const isOwner = computed(() => auth.isLoggedIn && recipe.value?.user_id === auth.user.id)

// Viewing-only scaling: the servings the viewer wants, seeded from the
// recipe's recommended servings once it loads. Never saved - it just
// multiplies the displayed quantities.
const desiredServings = ref(null)
const factor = computed(() => scaleFactor(recipe.value?.servings, desiredServings.value))

function adjustServings(delta) {
  desiredServings.value = Math.max(1, (Number(desiredServings.value) || 1) + delta)
}

// Carries a non-default servings choice into Step mode so its ingredient
// amounts match what was being viewed here.
const stepModeLink = computed(() => ({
  path: `/recipes/${recipe.value.id}/steps`,
  query: factor.value !== 1 ? { servings: desiredServings.value } : {}
}))

// Prep-checklist state only - not persisted, resets on reload.
const checkedIngredientIds = ref(new Set())

function toggleChecked(id) {
  if (checkedIngredientIds.value.has(id)) checkedIngredientIds.value.delete(id)
  else checkedIngredientIds.value.add(id)
}

// Adds an ingredient to the shopping list at the currently viewed (scaled)
// quantity. `addedIds` just drives the button's "Added" feedback for this
// visit - the server is the source of truth, and adding again tops the line up.
const shoppingList = useShoppingListStore()
const addedIds = ref(new Set())

async function addToShoppingList(ri) {
  // One click per visit - a second would top the line up again and double it.
  if (addedIds.value.has(ri.id)) return
  const hasQuantity = ri.quantity !== null && ri.quantity !== undefined && ri.quantity !== ''
  const scaled = hasQuantity ? Math.round(Number(ri.quantity) * factor.value * 100) / 100 : null
  const result = await shoppingList.add({ name: ri.name, quantity: scaled, unit: ri.unit })
  if (result.ok) addedIds.value = new Set([ ...addedIds.value, ri.id ])
}

const ingredientsById = computed(() => recipe.value ? buildIngredientsById(recipe.value) : new Map())

function stepIngredients(step) {
  return stepIngredientsFor(ingredientsById.value, step)
}

const formattedDuration = computed(() => {
  const minutes = recipe.value?.duration_minutes
  if (!minutes) return null

  const hours = Math.floor(minutes / 60)
  const remainder = minutes % 60
  if (hours && remainder) return `${hours} hr ${remainder} min`
  if (hours) return `${hours} hr`
  return `${remainder} min`
})

// Computed once per view (not a live-updating clock) - based on the system
// time when the recipe finishes loading, plus its duration.
const finishTime = computed(() => {
  const minutes = recipe.value?.duration_minutes
  if (!minutes) return null

  const finish = new Date(Date.now() + minutes * 60 * 1000)
  return finish.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
})

onMounted(async () => {
  const result = await recipes.fetchOne(route.params.id)
  if (!result.ok) error.value = 'Recipe not found'
  else desiredServings.value = recipes.current?.servings ?? null
  loading.value = false
})

function handleDelete() {
  showDeleteConfirm.value = true
}

async function confirmDelete() {
  showDeleteConfirm.value = false
  const result = await recipes.destroy(route.params.id)
  if (result.ok) router.push('/recipes')
}
</script>
