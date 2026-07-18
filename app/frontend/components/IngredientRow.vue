<template>
  <div class="mt-2 flex flex-wrap items-center gap-2">
    <input
      v-model="row.quantity"
      type="number"
      step="any"
      min="0"
      placeholder="Qty"
      aria-label="Quantity"
      class="w-16 rounded-lg border border-line bg-white px-2 py-1 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    />
    <input
      v-model="row.unit"
      type="text"
      placeholder="Unit"
      aria-label="Unit"
      class="w-20 rounded-lg border border-line bg-white px-2 py-1 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    />
    <input
      v-model="row.name"
      type="text"
      placeholder="Ingredient"
      aria-label="Ingredient name"
      class="min-w-32 flex-1 rounded-lg border border-line bg-white px-2 py-1 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    />
    <input
      v-model="row.preparation"
      type="text"
      placeholder="Preparation (optional)"
      aria-label="Preparation"
      class="min-w-32 flex-1 rounded-lg border border-line bg-white px-2 py-1 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    />
    <select
      v-model="row.groupId"
      aria-label="Ingredient group"
      class="rounded-lg border border-line bg-white px-2 py-1 text-sm text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
    >
      <option :value="null">Ungrouped</option>
      <option v-for="g in groups" :key="g._key" :value="g._key">{{ g.name || 'Untitled group' }}</option>
    </select>
    <button
      type="button"
      class="text-ink/40 hover:text-accent-dark cursor-pointer"
      aria-label="Remove ingredient"
      @click="$emit('remove')"
    >
      &times;
    </button>
  </div>
</template>

<script setup>
// `row` is mutated directly (quantity/unit/name/preparation/groupId) rather
// than emitting updates back up - it's already the same reactive object
// living in the parent's `ingredients` array, so this is just editing it in
// place, the same "lifted local state" pattern the parent uses throughout.
defineProps({
  row: { type: Object, required: true },
  groups: { type: Array, required: true }
})
defineEmits([ 'remove' ])
</script>
