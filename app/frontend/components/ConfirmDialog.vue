<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4"
      @click.self="$emit('cancel')"
      @keydown.escape="$emit('cancel')"
    >
      <div class="w-full max-w-sm rounded-xl bg-cream p-6 shadow-xl" role="alertdialog" aria-modal="true" :aria-label="title">
        <h2 class="font-display text-lg font-semibold text-ink">{{ title }}</h2>
        <p v-if="message" class="mt-2 text-sm text-ink/70">{{ message }}</p>
        <div class="mt-6 flex justify-end gap-2">
          <button
            ref="cancelButton"
            type="button"
            class="rounded-full border border-line px-4 py-2 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors cursor-pointer"
            @click="$emit('cancel')"
          >
            {{ cancelLabel }}
          </button>
          <button
            type="button"
            class="rounded-full bg-accent-dark px-4 py-2 text-sm font-medium text-white hover:opacity-90 transition-colors cursor-pointer"
            @click="$emit('confirm')"
          >
            {{ confirmLabel }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, nextTick, watch } from 'vue'

const props = defineProps({
  open: { type: Boolean, default: false },
  title: { type: String, default: 'Are you sure?' },
  message: { type: String, default: '' },
  confirmLabel: { type: String, default: 'Confirm' },
  cancelLabel: { type: String, default: 'Cancel' },
})
defineEmits([ 'confirm', 'cancel' ])

const cancelButton = ref(null)

watch(() => props.open, async (isOpen) => {
  if (!isOpen) return
  await nextTick()
  cancelButton.value?.focus()
})
</script>
