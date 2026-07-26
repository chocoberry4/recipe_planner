<template>
  <div ref="rootEl" class="relative inline-block">
    <button
      type="button"
      class="text-xs font-medium text-ink/40 hover:text-accent-dark cursor-pointer"
      @click="open = !open"
    >
      + Add
    </button>

    <div
      v-if="open"
      class="absolute z-20 mt-1 w-56 rounded-lg border border-line bg-white p-2 shadow-lg"
    >
      <input
        ref="inputEl"
        v-model="query"
        type="text"
        placeholder="Search or type a meal..."
        class="w-full rounded-md border border-line px-2 py-1 text-sm outline-none focus:border-accent"
        @keydown.escape="close"
        @keydown.enter="handleEnter"
      />
      <ul class="mt-1 max-h-40 overflow-auto">
        <li v-if="filtered.length === 0 && !showAddAsText" class="px-2 py-1 text-xs text-ink/40">No matches.</li>
        <li
          v-for="opt in filtered"
          :key="opt.id"
          class="cursor-pointer rounded px-2 py-1 text-sm text-ink/80 hover:bg-cream"
          @click="select(opt)"
        >
          {{ opt.label }}
        </li>
        <li
          v-if="showAddAsText"
          class="cursor-pointer rounded px-2 py-1 text-sm text-accent-dark hover:bg-cream"
          @click="addAsText"
        >
          + Add "{{ trimmedQuery }}"
        </li>
      </ul>

      <div v-if="options.length" class="mt-2 border-t border-line pt-2">
        <div class="flex items-center gap-1.5">
          <select
            v-model="suggestTag"
            class="min-w-0 flex-1 rounded-md border border-line px-1.5 py-1 text-xs text-ink/80 outline-none focus:border-accent"
          >
            <option value="">Any tag</option>
            <option v-for="name in allTagNames" :key="name" :value="name">{{ name }}</option>
          </select>
          <button
            type="button"
            class="shrink-0 rounded-md bg-sage/15 px-2 py-1 text-xs font-medium text-ink/70 hover:bg-sage/25 disabled:cursor-not-allowed disabled:opacity-40 cursor-pointer"
            :disabled="suggestionPool.length === 0"
            @click="suggest"
          >
            Suggest
          </button>
        </div>

        <p v-if="suggestionPool.length === 0" class="mt-1 text-[11px] text-ink/40">No recipes with this tag.</p>

        <div v-if="suggestedOption" class="mt-1.5 rounded-md bg-cream px-2 py-1.5">
          <p class="truncate text-sm font-medium text-ink">{{ suggestedOption.label }}</p>
          <div class="mt-1 flex gap-2">
            <button
              type="button"
              class="text-xs font-medium text-ink/50 hover:text-accent-dark cursor-pointer"
              @click="suggest"
            >
              Try another
            </button>
            <button
              type="button"
              class="text-xs font-medium text-accent-dark hover:underline cursor-pointer"
              @click="useSuggestion"
            >
              Use this
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onUnmounted } from 'vue'

const props = defineProps({
  options: { type: Array, required: true }, // [{ id, label, tags: string[] }]
})
const emit = defineEmits([ 'select', 'add-text' ])

const open = ref(false)
const query = ref('')
const rootEl = ref(null)
const inputEl = ref(null)
const suggestTag = ref('')
const suggestedOption = ref(null)

const trimmedQuery = computed(() => query.value.trim())

const allTagNames = computed(() => {
  const names = new Set()
  props.options.forEach((opt) => (opt.tags || []).forEach((name) => names.add(name)))
  return [ ...names ].sort()
})

const suggestionPool = computed(() => {
  if (!suggestTag.value) return props.options
  return props.options.filter((opt) => (opt.tags || []).includes(suggestTag.value))
})

const filtered = computed(() => {
  const q = trimmedQuery.value.toLowerCase()
  if (!q) return props.options
  return props.options.filter((opt) => opt.label.toLowerCase().includes(q))
})

// Typing something that isn't a saved recipe (a one-off like "leftovers" or
// "eating out") is still a valid thing to schedule - offered whenever the
// query doesn't exactly name an existing recipe, so it doesn't crowd out a
// genuine near-match the user probably meant to click instead.
const showAddAsText = computed(() =>
  trimmedQuery.value.length > 0
  && !props.options.some((opt) => opt.label.toLowerCase() === trimmedQuery.value.toLowerCase())
)

function select(opt) {
  emit('select', opt.id)
  close()
}

function addAsText() {
  emit('add-text', trimmedQuery.value)
  close()
}

function handleEnter() {
  if (showAddAsText.value) addAsText()
  else if (filtered.value.length === 1) select(filtered.value[0])
}

// Avoids re-rolling the same recipe back-to-back when the pool has other
// options, so clicking "Try another" reliably changes the suggestion.
function suggest() {
  const pool = suggestionPool.value
  if (pool.length === 0) return
  let pick = pool[Math.floor(Math.random() * pool.length)]
  if (pool.length > 1 && suggestedOption.value) {
    while (pick.id === suggestedOption.value.id) {
      pick = pool[Math.floor(Math.random() * pool.length)]
    }
  }
  suggestedOption.value = pick
}

function useSuggestion() {
  select(suggestedOption.value)
}

function close() {
  open.value = false
  query.value = ''
  suggestTag.value = ''
  suggestedOption.value = null
}

// A stale suggestion from a different tag filter shouldn't linger once the
// filter changes - the pool it was drawn from no longer matches.
watch(suggestTag, () => {
  suggestedOption.value = null
})

function handleDocumentMousedown(event) {
  if (rootEl.value && !rootEl.value.contains(event.target)) close()
}

watch(open, (isOpen) => {
  if (isOpen) {
    nextTick(() => inputEl.value?.focus())
    document.addEventListener('mousedown', handleDocumentMousedown)
  } else {
    document.removeEventListener('mousedown', handleDocumentMousedown)
  }
})

onUnmounted(() => document.removeEventListener('mousedown', handleDocumentMousedown))
</script>
