<template>
  <div class="min-h-screen bg-cream text-ink flex flex-col">
    <header class="sticky top-0 z-10 border-b border-line bg-cream/90 backdrop-blur">
      <nav class="max-w-6xl mx-auto flex items-center justify-between px-4 py-3">
        <router-link to="/" class="font-display text-xl font-semibold tracking-tight">
          Plate.it
        </router-link>

        <div class="flex items-center gap-5 text-sm">
          <router-link to="/recipes" class="text-ink/70 hover:text-accent transition-colors">
            Recipes
          </router-link>

          <template v-if="auth.isLoggedIn">
            <router-link to="/planner" class="text-ink/70 hover:text-accent transition-colors">
              Planner
            </router-link>
            <router-link to="/settings" class="text-ink/70 hover:text-accent transition-colors">
              Settings
            </router-link>
            <span class="text-ink/40">{{ auth.user.username || auth.user.email }}</span>
            <button
              type="button"
              class="text-ink/70 hover:text-accent transition-colors cursor-pointer"
              @click="handleLogout"
            >
              Log out
            </button>
          </template>
          <template v-else>
            <router-link to="/login" class="text-ink/70 hover:text-accent transition-colors">
              Log in
            </router-link>
            <router-link
              to="/signup"
              class="rounded-full bg-accent px-3.5 py-1.5 text-white hover:bg-accent-dark transition-colors"
            >
              Sign up
            </router-link>
          </template>
        </div>
      </nav>
    </header>

    <main class="flex-1 w-full max-w-6xl mx-auto px-4 py-10">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from './stores/auth'

const auth = useAuthStore()
const router = useRouter()

onMounted(() => {
  if (!auth.checked) auth.fetchCurrentUser()
})

async function handleLogout() {
  await auth.logout()
  router.push('/')
}
</script>
