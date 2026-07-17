<template>
  <div class="max-w-sm mx-auto">
    <h1 class="font-display text-2xl font-semibold text-ink text-center">Sign up</h1>

    <form class="mt-8 space-y-4" @submit.prevent="handleSubmit">
      <p v-if="error" class="rounded-lg bg-accent-soft px-3 py-2 text-sm text-accent-dark">
        {{ error }}
      </p>

      <label class="block">
        <span class="text-sm font-medium text-ink/80">Username</span>
        <input
          v-model="username"
          type="text"
          required
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>

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
          minlength="6"
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>

      <button
        type="submit"
        :disabled="submitting"
        class="w-full rounded-full bg-accent px-4 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
      >
        Sign up
      </button>
    </form>

    <p class="mt-6 text-center text-sm text-ink/60">
      <router-link to="/login" class="text-accent hover:text-accent-dark">
        Already have an account? Log in
      </router-link>
    </p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const username = ref('')
const email = ref('')
const password = ref('')
const error = ref(null)
const submitting = ref(false)

const router = useRouter()
const auth = useAuthStore()

async function handleSubmit() {
  submitting.value = true
  error.value = null

  const result = await auth.signup({
    email: email.value,
    username: username.value,
    password: password.value,
  })

  submitting.value = false

  if (result.ok) {
    router.push('/recipes')
  } else {
    error.value = result.errors.join(', ')
  }
}
</script>
