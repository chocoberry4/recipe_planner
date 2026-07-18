<template>
  <div class="relative">
    <div
      class="mt-3 ml-9 flex items-center gap-1 rounded-full border border-line bg-white py-1 pl-3 pr-2 text-sm text-ink/70 focus-within:border-accent"
    >
      <input
        ref="inputEl"
        v-model="query"
        type="text"
        role="combobox"
        aria-autocomplete="list"
        :aria-expanded="open"
        :aria-label="ariaLabel"
        :placeholder="options.length ? placeholder : 'Nothing left to add'"
        :disabled="!options.length"
        class="w-40 min-w-0 flex-1 bg-transparent outline-none placeholder:text-ink/40 disabled:cursor-not-allowed"
        @focus="open = true"
        @blur="scheduleClose"
        @keydown.down.prevent="move(1)"
        @keydown.up.prevent="move(-1)"
        @keydown.enter.prevent="selectHighlighted"
        @keydown.escape="close"
      />
      <button
        v-if="options.length"
        type="button"
        tabindex="-1"
        class="flex h-4 w-4 shrink-0 cursor-pointer items-center justify-center text-ink/40"
        :aria-label="open ? 'Close ingredient list' : 'Open ingredient list'"
        @mousedown.prevent="toggle"
      >
        <svg viewBox="0 0 12 8" class="h-2.5 w-2.5 transition-transform duration-150" :class="{ 'rotate-180': open }">
          <path d="M1 1.5L6 6.5L11 1.5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </button>
    </div>

    <ul
      v-if="open && options.length"
      role="listbox"
      class="absolute z-10 mt-1 ml-9 max-h-48 w-56 overflow-auto rounded-lg border border-line bg-white py-1 text-sm shadow-lg"
    >
      <li v-if="filtered.length === 0" class="px-3 py-1.5 text-ink/40">No matches.</li>
      <li
        v-for="(opt, index) in filtered"
        :key="opt.id"
        role="option"
        :aria-selected="index === highlighted"
        class="cursor-pointer px-3 py-1.5"
        :class="index === highlighted ? 'bg-accent-soft text-accent-dark' : 'text-ink/80 hover:bg-cream'"
        @mousemove="highlighted = index"
        @mousedown.prevent="select(opt)"
      >
        {{ opt.label }}
      </li>
    </ul>
  </div>
</template>

<script setup>
// A typable, multi-add combobox: typing filters the option list, and picking
// an option keeps the list open (rather than a native <select>'s one-shot
// close-on-select) so several ingredients can be added to the same step in a
// row. Options are expected to already exclude anything assigned elsewhere -
// as the parent's assignment state changes, `options` shrinks and the list
// re-renders live.
import { ref, computed, watch, nextTick } from 'vue'

const props = defineProps({
  options: { type: Array, required: true }, // [{ id, label }]
  ariaLabel: { type: String, required: true },
  placeholder: { type: String, default: '+ Add ingredient…' }
})
const emit = defineEmits([ 'select' ])

const query = ref('')
const open = ref(false)
const highlighted = ref(0)
const inputEl = ref(null)
let closeTimer = null

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return props.options
  return props.options.filter((opt) => opt.label.toLowerCase().includes(q))
})

watch(filtered, () => { highlighted.value = 0 })

function toggle() {
  if (open.value) {
    close()
  } else {
    open.value = true
    inputEl.value?.focus()
  }
}

// Closing on blur has to be delayed, not immediate: clicking an option fires
// the input's blur before the option's own click/mousedown would otherwise
// land, which would close the list out from under the click. `.prevent` on
// the option's mousedown keeps focus on the input entirely, so in practice
// this timer only ever fires for a genuine click-away.
function scheduleClose() {
  closeTimer = setTimeout(close, 150)
}

function close() {
  clearTimeout(closeTimer)
  open.value = false
}

function move(delta) {
  if (!open.value) {
    open.value = true
    return
  }
  const max = filtered.value.length - 1
  if (max < 0) return
  highlighted.value = Math.min(max, Math.max(0, highlighted.value + delta))
}

function selectHighlighted() {
  const opt = filtered.value[highlighted.value]
  if (opt) select(opt)
}

function select(opt) {
  emit('select', opt.id)
  query.value = ''
  highlighted.value = 0
  nextTick(() => inputEl.value?.focus())
}
</script>
