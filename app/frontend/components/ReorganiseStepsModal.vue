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
        aria-label="Reorganise ingredients by step"
        @keydown.escape="$emit('cancel')"
      >
        <div class="border-b border-line px-6 py-4">
          <h2 class="font-display text-lg font-semibold text-ink">Reorganise ingredients by step</h2>
          <p class="mt-1 text-sm text-ink/60">
            Drag an ingredient onto the step that uses it, or pick a step from its dropdown. Each ingredient belongs to one step.
          </p>
        </div>

        <div class="flex-1 space-y-4 overflow-y-auto px-6 py-4">
          <section
            v-for="(section, s) in sections"
            :key="section.key"
            class="rounded-xl border bg-white p-3 transition-colors"
            :class="dropSection === s ? 'border-accent bg-accent-soft/30' : 'border-line'"
            @dragover.prevent="onDragOver(s)"
            @drop.prevent="onDrop(s)"
          >
            <header>
              <h3 class="text-sm font-semibold text-ink/70">{{ section.title }}</h3>
              <p v-if="section.snippet" class="mt-0.5 line-clamp-2 text-xs text-ink/50">{{ section.snippet }}</p>
            </header>

            <ul class="mt-2 min-h-8 space-y-1">
              <li
                v-for="item in section.items"
                :key="item.id"
                draggable="true"
                class="flex items-center gap-2 rounded-lg border border-line bg-cream px-2 py-1.5 text-sm text-ink/85 transition-opacity"
                :class="dragging && dragging.id === item.id ? 'opacity-40' : 'cursor-grab'"
                @dragstart="onDragStart(s, item, $event)"
                @dragend="resetDrag"
              >
                <span class="select-none text-ink/30" aria-hidden="true">&#8942;&#8942;</span>
                <span class="flex-1 truncate">{{ label(item) }}</span>
                <select
                  :value="s"
                  :aria-label="`Move ${item.name} to`"
                  class="w-32 shrink-0 rounded-lg border border-line bg-white px-2 py-1 text-xs text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
                  @change="moveTo(s, item, Number($event.target.value))"
                >
                  <option v-for="(target, t) in sections" :key="target.key" :value="t">{{ target.title }}</option>
                </select>
              </li>
              <li v-if="!section.items.length" class="px-2 py-1.5 text-sm text-ink/40">
                {{ section.key === UNASSIGNED ? 'Nothing left unassigned' : 'Drop an ingredient here' }}
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
import { ref, watch, nextTick } from 'vue'
import { formatQuantity } from '../lib/recipeIngredients'

// Edits a throwaway copy (`sections`) and only emits it on Apply, so Cancel
// leaves the page's step assignments untouched. Only saved steps and saved
// ingredients (those with real ids) appear - an unsaved one can't be
// assigned yet, the same restriction the rest of the edit page has.
const props = defineProps({
  open: { type: Boolean, default: false },
  instructions: { type: Array, required: true },
  assignments: { type: Object, required: true },
  ingredients: { type: Array, required: true }
})
const emit = defineEmits([ 'apply', 'cancel' ])

const UNASSIGNED = 'unassigned'

const panel = ref(null)
const sections = ref([])
const dragging = ref(null)
const dropSection = ref(null)

watch(() => props.open, async (isOpen) => {
  if (!isOpen) return

  const byId = new Map(props.ingredients.map((ri) => [ ri.id, ri ]))
  // Numbered by position in the full list (unsaved steps still count), so
  // "Step 3" here is the same "Step 3" as on the page.
  const steps = props.instructions
    .map((ins, i) => ({ ins, number: i + 1 }))
    .filter(({ ins }) => ins.id)
    .map(({ ins, number }) => ({
      key: ins.id,
      title: `Step ${number}`,
      snippet: ins.description,
      items: (props.assignments[ins.id] || []).map((id) => byId.get(id)).filter(Boolean)
    }))

  const assigned = new Set(steps.flatMap((s) => s.items.map((ri) => ri.id)))
  const unassigned = props.ingredients.filter((ri) => ri.name && !assigned.has(ri.id))

  sections.value = [ { key: UNASSIGNED, title: 'Unassigned', snippet: '', items: unassigned }, ...steps ]
  resetDrag()
  await nextTick()
  panel.value?.focus()
})

function label(ri) {
  const text = [ formatQuantity(ri.quantity), ri.unit, ri.name ].filter((part) => part !== null && part !== undefined && part !== '').join(' ')
  return ri.preparation ? `${text}, ${ri.preparation}` : text
}

function resetDrag() {
  dragging.value = null
  dropSection.value = null
}

function onDragStart(s, item, event) {
  dragging.value = { s, id: item.id }
  event.dataTransfer.effectAllowed = 'move'
  // Firefox won't start a drag without data set.
  event.dataTransfer.setData('text/plain', String(item.id))
}

function onDragOver(s) {
  if (dragging.value) dropSection.value = s
}

function onDrop(s) {
  if (dragging.value) {
    const item = sections.value[dragging.value.s].items.find((ri) => ri.id === dragging.value.id)
    if (item) moveTo(dragging.value.s, item, s)
  }
  resetDrag()
}

function moveTo(fromS, item, toS) {
  if (fromS === toS) return
  const from = sections.value[fromS].items
  from.splice(from.indexOf(item), 1)
  sections.value[toS].items.push(item)
}

function apply() {
  emit('apply', sections.value
    .filter((section) => section.key !== UNASSIGNED)
    .map((section) => ({ instructionId: section.key, ingredientIds: section.items.map((ri) => ri.id) })))
}
</script>
