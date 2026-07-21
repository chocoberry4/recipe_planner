<template>
  <div class="py-12 text-center">
    <h1 class="font-display text-4xl sm:text-5xl font-semibold tracking-tight text-ink">
      Plan meals you'll actually cook.
    </h1>
    <p class="mt-4 text-lg text-ink/60 max-w-xl mx-auto">
      Keep your recipes organized, scale them to fit, and build shopping lists
      without the guesswork.
    </p>

    <p v-if="!auth.checked" class="mt-8 text-ink/50">Loading...</p>

    <div v-else-if="auth.isLoggedIn">
      <div v-if="ideas.length" class="mt-10 grid gap-4 text-left sm:grid-cols-3">
        <router-link
          v-for="recipe in ideas"
          :key="recipe.id"
          :to="`/recipes/${recipe.id}`"
          class="rounded-xl border border-line bg-white p-4 hover:border-accent hover:shadow-sm transition"
        >
          <img
            v-if="recipe.image_url"
            :src="recipe.image_url"
            alt=""
            class="mb-3 h-32 w-full rounded-lg object-cover"
          />
          <h2 class="font-display text-base font-semibold text-ink">{{ recipe.title }}</h2>
          <p class="mt-1 min-h-[2.5rem] text-sm text-ink/60 line-clamp-2">
            {{ recipe.description }}
          </p>
        </router-link>
      </div>

      <div class="mt-8">
        <router-link
          to="/recipes"
          class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors"
        >
          View all recipes
        </router-link>
      </div>
    </div>

    <div v-else class="mt-8 flex justify-center gap-3">
      <router-link
        to="/recipes"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors"
      >
        View recipes
      </router-link>
      <router-link
        to="/signup"
        class="rounded-full border border-line px-5 py-2.5 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors"
      >
        Create an account
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const ideas = ref([])

const IDEA_COUNT = 9

// Fisher-Yates - picks recipes at random each visit, rather than always the
// same first/last few, so the homepage surfaces variety over time.
function sampleRandom(list, count) {
  const copy = [ ...list ]
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[ copy[i], copy[j] ] = [ copy[j], copy[i] ]
  }
  return copy.slice(0, count)
}

onMounted(async () => {
  if (!auth.checked) await auth.fetchCurrentUser()
  if (!auth.isLoggedIn) return

  try {
    const response = await fetch('/api/v1/recipes', { credentials: 'include' })
    if (response.ok) ideas.value = sampleRandom(await response.json(), IDEA_COUNT)
  } catch {
    ideas.value = []
  }
})
</script>
