<template>
  <p v-if="loading" class="text-ink/50">Loading...</p>
  <p v-else-if="error" class="text-accent-dark">{{ error }}</p>
  <div v-else-if="recipe">
    <div class="flex items-start justify-between gap-4">
      <div>
        <h1 class="font-display text-3xl font-semibold text-ink">{{ recipe.title }}</h1>
        <p v-if="recipe.description" class="mt-2 text-ink/60">{{ recipe.description }}</p>
      </div>

      <div v-if="auth.isLoggedIn" class="flex shrink-0 gap-2 text-sm">
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
      </div>
    </div>

    <section
      v-if="recipe.recipe_ingredient_groups.length || recipe.ingredients.length"
      class="mt-8 border-t border-line pt-6"
    >
      <h2 class="font-display text-lg font-semibold text-sage">Ingredients</h2>

      <div v-for="group in recipe.recipe_ingredient_groups" :key="group.id" class="mt-4">
        <h3 class="text-sm font-semibold text-ink/70">{{ group.name }}</h3>
        <ul class="mt-2 space-y-1.5 text-ink/85">
          <li v-for="ri in group.recipe_ingredients" :key="ri.id" class="flex gap-2">
            <span class="text-accent">&bull;</span>
            <span>
              {{ ri.quantity }} {{ ri.unit }} {{ ri.name }}<span v-if="ri.preparation">, {{ ri.preparation }}</span>
            </span>
          </li>
        </ul>
      </div>

      <ul v-if="recipe.ingredients.length" class="mt-4 space-y-1.5 text-ink/85">
        <li v-for="ri in recipe.ingredients" :key="ri.id" class="flex gap-2">
          <span class="text-accent">&bull;</span>
          <span>
            {{ ri.quantity }} {{ ri.unit }} {{ ri.name }}<span v-if="ri.preparation">, {{ ri.preparation }}</span>
          </span>
        </li>
      </ul>
    </section>

    <section v-if="recipe.instructions.length" class="mt-8 border-t border-line pt-6">
      <h2 class="font-display text-lg font-semibold text-sage">Instructions</h2>
      <ol class="mt-4 space-y-3">
        <li v-for="step in recipe.instructions" :key="step.id" class="flex gap-3">
          <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-accent-soft text-xs font-semibold text-accent-dark">
            {{ step.step_number }}
          </span>
          <span class="text-ink/85">{{ step.description }}</span>
        </li>
      </ol>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const recipes = useRecipesStore()
const auth = useAuthStore()

const loading = ref(true)
const error = ref(null)
const recipe = computed(() => recipes.current)

onMounted(async () => {
  const result = await recipes.fetchOne(route.params.id)
  if (!result.ok) error.value = 'Recipe not found'
  loading.value = false
})

async function handleDelete() {
  if (!confirm('Delete this recipe?')) return

  const result = await recipes.destroy(route.params.id)
  if (result.ok) router.push('/recipes')
}
</script>
