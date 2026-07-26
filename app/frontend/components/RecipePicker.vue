<template>
  <button
    type="button"
    class="text-xs font-medium text-ink/40 hover:text-accent-dark cursor-pointer"
    v-bind="$attrs"
    @click="openModal"
  >
    + Add
  </button>

  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4 py-8"
      @click.self="close"
      @keydown.escape="close"
    >
      <div
        class="flex max-h-full w-full max-w-3xl flex-col overflow-hidden rounded-xl bg-cream shadow-xl"
        role="dialog"
        aria-modal="true"
        aria-label="Add a recipe"
      >
        <div class="flex items-center justify-between border-b border-line px-5 py-4">
          <h2 class="font-display text-lg font-semibold text-ink">Add a recipe</h2>
          <button
            type="button"
            class="text-ink/40 hover:text-accent-dark cursor-pointer"
            aria-label="Close"
            @click="close"
          >
            &times;
          </button>
        </div>

        <div class="space-y-3 border-b border-line px-5 py-3">
          <input
            ref="inputEl"
            v-model="query"
            type="text"
            placeholder="Search or type a meal..."
            class="w-full rounded-md border border-line bg-white px-3 py-2 text-sm outline-none focus:border-accent"
            @keydown.enter="handleEnter"
          />

          <div v-if="allTagNames.length" class="flex flex-wrap gap-1.5">
            <button
              v-for="name in allTagNames"
              :key="name"
              type="button"
              class="rounded-full px-2.5 py-1 text-xs font-medium transition-colors cursor-pointer"
              :class="selectedTags.has(name)
                ? 'bg-accent text-white'
                : 'bg-sage/15 text-ink/70 hover:bg-sage/25'"
              :aria-pressed="selectedTags.has(name)"
              @click="toggleTag(name)"
            >
              {{ name }}
            </button>
          </div>

          <div v-if="options.length" class="flex items-center gap-2">
            <button
              type="button"
              class="shrink-0 rounded-md bg-sage/15 px-2.5 py-1 text-xs font-medium text-ink/70 hover:bg-sage/25 disabled:cursor-not-allowed disabled:opacity-40 cursor-pointer"
              :disabled="filteredOptions.length === 0"
              @click="suggest"
            >
              Suggest
            </button>
            <template v-if="suggestedOption">
              <span class="min-w-0 flex-1 truncate text-sm font-medium text-ink">{{ suggestedOption.label }}</span>
              <button
                type="button"
                class="shrink-0 text-xs font-medium text-ink/50 hover:text-accent-dark cursor-pointer"
                @click="suggest"
              >
                Try another
              </button>
              <button
                type="button"
                class="shrink-0 text-xs font-medium text-accent-dark hover:underline cursor-pointer"
                @click="useSuggestion"
              >
                Use this
              </button>
            </template>
          </div>
        </div>

        <div class="flex-1 overflow-auto px-5 py-4">
          <p v-if="filteredOptions.length === 0 && !showAddAsText" class="text-sm text-ink/40">No matches.</p>

          <div v-else class="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
            <button
              v-for="opt in pagedOptions"
              :key="opt.id"
              type="button"
              class="flex flex-col rounded-lg border border-line bg-white p-2 text-left hover:border-accent hover:shadow-sm transition cursor-pointer"
              @click="select(opt)"
            >
              <img
                v-if="opt.image"
                :src="opt.image"
                alt=""
                class="aspect-square w-full rounded-md object-cover"
              />
              <div v-else class="flex aspect-square w-full items-center justify-center rounded-md bg-sage/10 text-ink/25">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="h-8 w-8">
                  <rect x="3" y="3" width="18" height="18" rx="2" />
                  <circle cx="8.5" cy="8.5" r="1.5" />
                  <path d="M21 15l-5-5-9 9" />
                </svg>
              </div>
              <p class="mt-1.5 truncate text-sm font-medium text-ink">{{ opt.label }}</p>
            </button>
          </div>

          <div v-if="totalPages > 1" class="mt-4 flex items-center justify-center gap-3">
            <button
              type="button"
              class="rounded-full border border-line px-3 py-1 text-xs font-medium text-ink hover:border-accent-dark hover:text-accent-dark transition-colors disabled:cursor-not-allowed disabled:opacity-40 cursor-pointer"
              :disabled="currentPage === 1"
              @click="currentPage--"
            >
              &#8592; Previous
            </button>
            <span class="text-xs text-ink/50">Page {{ currentPage }} of {{ totalPages }}</span>
            <button
              type="button"
              class="rounded-full border border-line px-3 py-1 text-xs font-medium text-ink hover:border-accent-dark hover:text-accent-dark transition-colors disabled:cursor-not-allowed disabled:opacity-40 cursor-pointer"
              :disabled="currentPage === totalPages"
              @click="currentPage++"
            >
              Next &#8594;
            </button>
          </div>

          <button
            v-if="showAddAsText"
            type="button"
            class="mt-3 w-full rounded-lg border border-dashed border-accent/50 px-3 py-2 text-sm font-medium text-accent-dark hover:bg-accent-soft/40 cursor-pointer"
            @click="addAsText"
          >
            + Add "{{ trimmedQuery }}"
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'

const props = defineProps({
  options: { type: Array, required: true }, // [{ id, label, tags: string[], image }]
  mealType: { type: String, default: '' }, // slot this picker opened from - used to prefilter a matching tag
})
const emit = defineEmits([ 'select', 'add-text' ])

// The template's root is the trigger button plus a Teleport (a fragment),
// so a caller's class="..." can't be auto-inherited onto a single root
// element the way it could before - bound explicitly onto the button below.
defineOptions({ inheritAttrs: false })

const PAGE_SIZE = 12 // 4 columns x 3 rows at the grid's widest breakpoint

const open = ref(false)
const query = ref('')
const inputEl = ref(null)
const selectedTags = ref(new Set())
const suggestedOption = ref(null)
const currentPage = ref(1)

const trimmedQuery = computed(() => query.value.trim())

const allTagNames = computed(() => {
  const names = new Set()
  props.options.forEach((opt) => (opt.tags || []).forEach((name) => names.add(name)))
  return [ ...names ].sort()
})

const filteredOptions = computed(() => {
  const q = trimmedQuery.value.toLowerCase()
  return props.options.filter((opt) => {
    const matchesSearch = !q || opt.label.toLowerCase().includes(q)
    const tagNames = new Set(opt.tags || [])
    const matchesTags = [ ...selectedTags.value ].every((name) => tagNames.has(name))
    return matchesSearch && matchesTags
  })
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredOptions.value.length / PAGE_SIZE)))

const pagedOptions = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return filteredOptions.value.slice(start, start + PAGE_SIZE)
})

// Typing something that isn't a saved recipe (a one-off like "leftovers" or
// "eating out") is still a valid thing to schedule - offered whenever the
// query doesn't exactly name an existing recipe, so it doesn't crowd out a
// genuine near-match the user probably meant to click instead. Checked
// against every recipe, not just the tag-filtered ones, so an existing
// recipe hidden by the current tag filter still isn't offered as "new".
const showAddAsText = computed(() =>
  trimmedQuery.value.length > 0
  && !props.options.some((opt) => opt.label.toLowerCase() === trimmedQuery.value.toLowerCase())
)

function toggleTag(name) {
  const next = new Set(selectedTags.value)
  if (next.has(name)) next.delete(name)
  else next.add(name)
  selectedTags.value = next
}

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
  else if (filteredOptions.value.length === 1) select(filteredOptions.value[0])
}

// Avoids re-rolling the same recipe back-to-back when the pool has other
// options, so clicking "Try another" reliably changes the suggestion.
function suggest() {
  const pool = filteredOptions.value
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

// A stale suggestion shouldn't linger once the pool it was drawn from
// changes - search text and tag chips both narrow that pool. The page
// resets for the same reason - page 3 of an unfiltered grid is very
// unlikely to still be page 3 once a search/tag narrows the results.
watch([ query, selectedTags ], () => {
  suggestedOption.value = null
  currentPage.value = 1
})

function openModal() {
  query.value = ''
  suggestedOption.value = null
  currentPage.value = 1

  // Deselectable: this just seeds the initial filter from the slot's meal
  // type (e.g. a "breakfast" tag on a Breakfast slot) when one happens to
  // exist among the recipes' tags - the chip can be clicked off like any
  // other.
  const matched = allTagNames.value.find((name) => name.toLowerCase() === props.mealType.toLowerCase())
  selectedTags.value = matched ? new Set([ matched ]) : new Set()

  open.value = true
  nextTick(() => inputEl.value?.focus())
}

function close() {
  open.value = false
  query.value = ''
  suggestedOption.value = null
}
</script>
