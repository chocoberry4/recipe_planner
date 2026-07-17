<template>
  <h1>Sign up</h1>

  <form @submit.prevent="handleSubmit">
    <p v-if="error">{{ error }}</p>

    <label>
      Username
      <input v-model="username" type="text" required />
    </label>

    <label>
      Email
      <input v-model="email" type="email" required />
    </label>

    <label>
      Password
      <input v-model="password" type="password" required minlength="6" />
    </label>

    <button type="submit" :disabled="submitting">Sign up</button>
  </form>

  <router-link to="/login">Already have an account? Log in</router-link>
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
