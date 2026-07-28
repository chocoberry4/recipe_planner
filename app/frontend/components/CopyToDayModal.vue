<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4"
      @click.self="$emit('close')"
      @keydown.escape="$emit('close')"
    >
      <div class="w-full max-w-sm rounded-xl bg-cream p-6 shadow-xl" role="dialog" aria-modal="true" aria-label="Copy to another day">
        <h2 class="font-display text-lg font-semibold text-ink">Copy to another day</h2>
        <p v-if="itemLabel" class="mt-1 truncate text-sm text-ink/60">{{ itemLabel }}</p>

        <div class="mt-5 flex justify-between gap-2">
          <button
            v-for="day in days"
            :key="toISODate(day)"
            type="button"
            :disabled="toISODate(day) === sourceDate"
            class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border text-sm font-semibold transition-colors"
            :class="circleClass(day)"
            :title="weekdayFullName(day)"
            :aria-label="`Copy to ${weekdayFullName(day)}`"
            @click="handleClick(day)"
          >
            {{ weekdayInitial(day) }}
          </button>
        </div>

        <div class="mt-6 flex justify-end">
          <button
            ref="closeButton"
            type="button"
            class="rounded-full border border-line px-4 py-2 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors cursor-pointer"
            @click="$emit('close')"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, nextTick, watch } from 'vue'
import { toISODate } from '../lib/calendar'

const props = defineProps({
  open: { type: Boolean, default: false },
  days: { type: Array, default: () => [] },
  sourceDate: { type: String, default: null },
  itemLabel: { type: String, default: '' },
})
const emit = defineEmits([ 'copy', 'close' ])

const closeButton = ref(null)
// Tracks which circles were clicked this time the modal is open, purely so
// they can show a filled "copied" state - not a guard against copying to
// the same day twice, since a second copy is a legitimate thing to want.
const copiedDates = ref(new Set())

watch(() => props.open, async (isOpen) => {
  if (!isOpen) return
  copiedDates.value = new Set()
  await nextTick()
  closeButton.value?.focus()
})

function weekdayInitial(day) {
  return day.toLocaleDateString('en-US', { weekday: 'narrow' })
}

function weekdayFullName(day) {
  return day.toLocaleDateString('en-US', { weekday: 'long' })
}

function circleClass(day) {
  const iso = toISODate(day)
  if (iso === props.sourceDate) return 'border-line text-ink/20 cursor-not-allowed'
  if (copiedDates.value.has(iso)) return 'border-accent bg-accent text-white'
  return 'border-line text-ink/70 hover:border-accent hover:text-accent-dark cursor-pointer'
}

function handleClick(day) {
  const iso = toISODate(day)
  if (iso === props.sourceDate) return
  copiedDates.value.add(iso)
  emit('copy', day)
}
</script>
