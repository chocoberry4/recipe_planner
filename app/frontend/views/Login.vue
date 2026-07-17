<template>
  <h1>Log in</h1>

  <form @submit.prevent="handleSubmit">
    <p v-if="error">{{ error }}</p>

    <label>
      Email
      <input v-model="email" type="email" required />
    </label>

    <label>
      Password
      <input v-model="password" type="password" required />
    </label>

    <button type="submit" :disabled="submitting">Log in</button>
  </form>

  <router-link to="/signup">Need an account? Sign up</router-link>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const email = ref('')
const password = ref('')
const error = ref(null)
const submitting = ref(false)

const router = useRouter()
const auth = useAuthStore()

async function handleSubmit() {
  submitting.value = true
  error.value = null

  const result = await auth.login({ email: email.value, password: password.value })

  submitting.value = false

  if (result.ok) {
    router.push('/recipes')
  } else {
    error.value = result.errors.join(', ')
  }
}
</script>
