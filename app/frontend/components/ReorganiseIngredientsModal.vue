<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4 py-6"
      @click.self="$emit('cancel')"
    >
      <div
        ref="panel"
        tabindex="-1"
        class="flex max-h-full w-full max-w-2xl flex-col rounded-xl bg-cream shadow-xl outline-none"
        role="dialog"
        aria-modal="true"
        aria-label="Reorganise ingredients"
        @keydown.escape="$emit('cancel')"
      >
        <div class="border-b border-line px-6 py-4">
          <h2 class="font-display text-lg font-semibold text-ink">Reorganise ingredients</h2>
          <p class="mt-1 text-sm text-ink/60">
            Drag ingredients to reorder them or move them between groups. The arrows do the same without dragging.
          </p>
        </div>

        <div class="flex-1 space-y-4 overflow-y-auto px-6 py-4">
          <section
            v-for="(section, s) in sections"
            :key="section.key ?? 'ungrouped'"
            class="rounded-xl border bg-white p-3 transition-colors"
            :class="dropSection === s && dropIndex === null ? 'border-accent bg-accent-soft/30' : 'border-line'"
            @dragover.prevent="onDragOverSection(s)"
            @drop.prevent="onDrop(s, section.items.length)"
          >
            <header class="flex items-center gap-2">
              <h3 class="flex-1 truncate text-sm font-semibold text-ink/70">
                {{ section.key === null ? 'Ungrouped' : (section.name || 'Untitled group') }}
              </h3>
              <template v-if="section.key !== null">
                <button
                  type="button"
                  class="arrow"
                  :disabled="s === 0"
                  aria-label="Move group up"
                  @click="moveSection(s, -1)"
                >&uarr;</button>
                <button
                  type="button"
                  class="arrow"
                  :disabled="s >= lastGroupIndex"
                  aria-label="Move group down"
                  @click="moveSection(s, 1)"
                >&darr;</button>
              </template>
            </header>

            <ul class="mt-2 min-h-8 space-y-1">
              <li
                v-for="(item, i) in section.items"
                :key="item._key"
                draggable="true"
                class="flex items-center gap-2 rounded-lg border bg-cream px-2 py-1.5 text-sm text-ink/85 transition-colors"
                :class="[
                  dropSection === s && dropIndex === i ? 'border-accent' : 'border-line',
                  dragging && dragging.s === s && dragging.i === i ? 'opacity-40' : 'cursor-grab'
                ]"
                @dragstart="onDragStart(s, i, $event)"
                @dragend="resetDrag"
                @dragover.prevent.stop="onDragOverRow(s, i)"
                @drop.prevent.stop="onDrop(s, i)"
              >
                <span class="select-none text-ink/30" aria-hidden="true">&#8942;&#8942;</span>
                <span class="flex-1 truncate">{{ label(item) }}</span>
                <button
                  type="button"
                  class="arrow"
                  :disabled="s === 0 && i === 0"
                  aria-label="Move ingredient up"
                  @click="moveItem(s, i, -1)"
                >&uarr;</button>
                <button
                  type="button"
                  class="arrow"
                  :disabled="s === sections.length - 1 && i === section.items.length - 1"
                  aria-label="Move ingredient down"
                  @click="moveItem(s, i, 1)"
                >&darr;</button>
              </li>
              <li v-if="!section.items.length" class="px-2 py-1.5 text-sm text-ink/40">
                Drop an ingredient here
              </li>
            </ul>
          </section>
        </div>

        <div class="flex justify-end gap-2 border-t border-line px-6 py-4">
          <button
            type="button"
            class="rounded-full border border-line px-4 py-2 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors cursor-pointer"
            @click="$emit('cancel')"
          >
            Cancel
          </button>
          <button
            type="button"
            class="rounded-full bg-accent px-4 py-2 text-sm font-medium text-white hover:bg-accent-dark transition-colors cursor-pointer"
            @click="apply"
          >
            Apply
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { formatQuantity } from '../lib/recipeIngredients'

// Works on a throwaway copy of the arrangement (`sections`) and only hands
// it back on Apply, so Cancel leaves the edit page's ingredients untouched.
// The ingredient row objects themselves are shared with the parent (same
// _key/id), only their order and group membership change - so step
// assignments, which key off recipe_ingredient ids, are unaffected.
const props = defineProps({
  open: { type: Boolean, default: false },
  groups: { type: Array, required: true },
  ingredients: { type: Array, required: true }
})
const emit = defineEmits([ 'apply', 'cancel' ])

const panel = ref(null)
const sections = ref([])
const dragging = ref(null)
const dropSection = ref(null)
const dropIndex = ref(null)

// The "Ungrouped" section (key null) is always last and can't be moved.
const lastGroupIndex = computed(() => sections.value.length - 2)

watch(() => props.open, async (isOpen) => {
  if (!isOpen) return
  sections.value = [
    ...props.groups.map((g) => ({
      key: g._key,
      name: g.name,
      items: props.ingredients.filter((ri) => ri.groupId === g._key)
    })),
    { key: null, name: 'Ungrouped', items: props.ingredients.filter((ri) => ri.groupId == null) }
  ]
  resetDrag()
  await nextTick()
  panel.value?.focus()
})

function label(ri) {
  const text = [ formatQuantity(ri.quantity), ri.unit, ri.name ].filter((part) => part !== null && part !== undefined && part !== '').join(' ')
  const base = text || 'New ingredient'
  return ri.preparation ? `${base}, ${ri.preparation}` : base
}

function resetDrag() {
  dragging.value = null
  dropSection.value = null
  dropIndex.value = null
}

function onDragStart(s, i, event) {
  dragging.value = { s, i }
  event.dataTransfer.effectAllowed = 'move'
  // Firefox won't start a drag without data set.
  event.dataTransfer.setData('text/plain', String(i))
}

function onDragOverRow(s, i) {
  if (!dragging.value) return
  dropSection.value = s
  dropIndex.value = i
}

function onDragOverSection(s) {
  if (!dragging.value) return
  dropSection.value = s
  dropIndex.value = null
}

function onDrop(s, i) {
  if (dragging.value) moveTo(dragging.value.s, dragging.value.i, s, i)
  resetDrag()
}

// Removes the item and re-inserts it before `toIndex` in the destination
// section (toIndex === length means "at the end"). Dropping further down the
// same list shifts left by one since the item is no longer ahead of it.
function moveTo(fromS, fromI, toS, toIndex) {
  const [ item ] = sections.value[fromS].items.splice(fromI, 1)
  const adjusted = fromS === toS && fromI < toIndex ? toIndex - 1 : toIndex
  sections.value[toS].items.splice(adjusted, 0, item)
}

// Arrow buttons: step through the list, spilling into the neighbouring
// section at either end so every ingredient is reachable without dragging.
function moveItem(s, i, direction) {
  const list = sections.value[s].items
  if (direction < 0) {
    if (i > 0) moveTo(s, i, s, i - 1)
    else if (s > 0) moveTo(s, i, s - 1, sections.value[s - 1].items.length)
  } else if (i < list.length - 1) {
    moveTo(s, i, s, i + 2)
  } else if (s < sections.value.length - 1) {
    moveTo(s, i, s + 1, 0)
  }
}

function moveSection(s, direction) {
  const target = s + direction
  if (target < 0 || target > lastGroupIndex.value) return
  const [ section ] = sections.value.splice(s, 1)
  sections.value.splice(target, 0, section)
}

function apply() {
  emit('apply', sections.value.map((s) => ({ key: s.key, items: s.items })))
}
</script>

<style scoped>
.arrow {
  display: flex;
  height: 1.5rem;
  width: 1.5rem;
  flex-shrink: 0;
  cursor: pointer;
  align-items: center;
  justify-content: center;
  border-radius: 9999px;
  color: color-mix(in srgb, currentColor 50%, transparent);
  font-size: 0.8rem;
}
.arrow:hover:not(:disabled) {
  color: var(--color-accent, #c2562b);
}
.arrow:disabled {
  cursor: not-allowed;
  opacity: 0.25;
}
</style>
