<template>
  <div class="py-12 text-center">
    <h1 class="font-display text-4xl sm:text-5xl font-semibold tracking-tight text-ink">
      Plan meals you'll actually cook.
    </h1>
    <p class="mt-4 text-lg text-ink/60 max-w-xl mx-auto">
      Keep your recipes organized, scale them to fit, and build shopping lists
      without the guesswork.
    </p>
    <div class="mt-8 flex justify-center gap-3">
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
</script>
