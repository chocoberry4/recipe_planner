<template>
  <div class="flex flex-wrap items-center justify-between gap-3">
    <h1 class="font-display text-3xl font-semibold text-ink">Shopping list</h1>
    <button
      v-if="checkedCount"
      type="button"
      class="rounded-full border border-line px-3.5 py-1.5 text-sm text-ink hover:border-accent hover:text-accent transition-colors cursor-pointer"
      @click="list.clearChecked()"
    >
      Clear {{ checkedCount }} checked
    </button>
  </div>

  <form class="mt-6 flex flex-wrap gap-2" @submit.prevent="addItem">
    <input
      v-model.number="form.quantity"
      type="number"
      min="0"
      step="any"
      placeholder="Qty"
      aria-label="Quantity"
      class="w-20 rounded-lg border border-line bg-white px-3 py-2 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    />
    <input
      v-model="form.unit"
      type="text"
      placeholder="Unit"
      aria-label="Unit"
      class="w-24 rounded-lg border border-line bg-white px-3 py-2 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    />
    <input
      v-model="form.name"
      type="text"
      placeholder="Add an item..."
      aria-label="Item name"
      class="min-w-0 flex-1 rounded-lg border border-line bg-white px-3 py-2 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    />
    <button
      type="submit"
      class="rounded-full bg-accent px-4 py-2 text-sm font-medium text-white hover:bg-accent-dark transition-colors cursor-pointer disabled:cursor-not-allowed disabled:opacity-50"
      :disabled="!form.name.trim()"
    >
      Add
    </button>
  </form>
  <p v-if="error" class="mt-2 text-sm text-red-600" role="alert">{{ error }}</p>

  <p v-if="loading" class="mt-8 text-ink/60">Loading...</p>
  <p v-else-if="!list.items.length" class="mt-8 text-ink/60">
    Nothing on your list yet. Add items above, or use "Add to list" next to an ingredient on any recipe.
  </p>

  <ul v-else class="mt-6 divide-y divide-line rounded-xl border border-line bg-white">
    <li v-for="item in list.items" :key="item.id" class="flex items-center gap-3 px-4 py-3">
      <label class="flex min-w-0 flex-1 cursor-pointer items-center gap-3">
        <input
          type="checkbox"
          class="h-4 w-4 shrink-0 accent-accent"
          :checked="item.checked"
          @change="list.setChecked(item.id, $event.target.checked)"
        />
        <span class="truncate text-ink/85" :class="{ 'text-ink/40 line-through': item.checked }">
          {{ itemLabel(item) }}
        </span>
      </label>
      <a
        :href="ocadoSearchUrl(item)"
        target="_blank"
        rel="noopener noreferrer"
        class="shrink-0 rounded-full border border-line px-2.5 py-0.5 text-xs text-ink/60 hover:border-accent hover:text-accent transition-colors"
        :aria-label="`Buy ${item.name} on Ocado`"
      >Buy now</a>
      <button
        type="button"
        class="flex h-6 w-6 shrink-0 cursor-pointer items-center justify-center rounded-full text-ink/40 hover:text-accent transition-colors"
        :aria-label="`Remove ${item.name}`"
        @click="list.remove(item.id)"
      >&times;</button>
    </li>
  </ul>
</template>

<script setup>
import { ref, computed, reactive, onMounted } from 'vue'
import { useShoppingListStore } from '../stores/shoppingList'
import { formatQuantity, ocadoSearchUrl } from '../lib/recipeIngredients'

const list = useShoppingListStore()
const loading = ref(true)
const error = ref(null)
const form = reactive({ quantity: '', unit: '', name: '' })

const checkedCount = computed(() => list.items.filter((item) => item.checked).length)

onMounted(async () => {
  await list.fetch()
  loading.value = false
})

function itemLabel(item) {
  return [ formatQuantity(item.quantity), item.unit, item.name ].filter(Boolean).join(' ')
}

async function addItem() {
  error.value = null
  // A cleared number input leaves '' behind with v-model.number.
  const quantity = form.quantity === '' || form.quantity === null ? null : form.quantity
  const result = await list.add({ name: form.name, quantity, unit: form.unit })
  if (result.ok) {
    form.quantity = ''
    form.unit = ''
    form.name = ''
  } else {
    error.value = result.errors.join(', ')
  }
}
</script>
