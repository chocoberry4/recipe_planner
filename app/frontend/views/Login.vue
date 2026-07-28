<template>
  <div class="max-w-sm mx-auto">
    <h1 class="font-display text-2xl font-semibold text-ink text-center">Log in</h1>

    <form class="mt-8 space-y-4" @submit.prevent="handleSubmit">
      <p v-if="error" class="rounded-lg bg-accent-soft px-3 py-2 text-sm text-accent-dark">
        {{ error }}
      </p>

      <label class="block">
        <span class="text-sm font-medium text-ink/80">Email</span>
        <input
          v-model="email"
          type="email"
          required
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>

      <label class="block">
        <span class="text-sm font-medium text-ink/80">Password</span>
        <input
          v-model="password"
          type="password"
          required
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>

      <label class="flex items-center gap-2 text-sm text-ink/80">
        <input v-model="rememberMe" type="checkbox" class="rounded border-line text-accent focus:ring-accent/20" />
        Remember me
      </label>

      <button
        type="submit"
        :disabled="submitting"
        class="w-full rounded-full bg-accent px-4 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
      >
        Log in
      </button>
    </form>

    <p class="mt-6 text-center text-sm text-ink/60">
      <router-link to="/signup" class="text-accent hover:text-accent-dark">
        Need an account? Sign up
      </router-link>
    </p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const email = ref('')
const password = ref('')
const rememberMe = ref(false)
const error = ref(null)
const submitting = ref(false)

const router = useRouter()
const auth = useAuthStore()

async function handleSubmit() {
  submitting.value = true
  error.value = null

  const result = await auth.login({ email: email.value, password: password.value, rememberMe: rememberMe.value })

  submitting.value = false

  if (result.ok) {
    router.push('/recipes')
  } else {
    error.value = result.errors.join(', ')
  }
}
</script>
