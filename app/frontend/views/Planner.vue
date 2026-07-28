<template>
  <div class="flex items-center justify-between gap-4">
    <button
      type="button"
      class="shrink-0 rounded-full border border-line px-3.5 py-1.5 text-sm text-ink hover:border-accent-dark hover:text-accent-dark transition-colors cursor-pointer"
      @click="goPrevious"
    >
      &#8592; {{ view === 'week' ? 'Previous week' : 'Previous month' }}
    </button>

    <div class="flex flex-col items-center gap-2">
      <h1 class="font-display text-xl font-semibold text-ink">{{ headerLabel }}</h1>
      <button
        type="button"
        class="rounded-full bg-sage/15 px-3 py-1 text-xs font-medium text-ink/70 hover:bg-sage/25 transition-colors cursor-pointer"
        @click="toggleView"
      >
        {{ view === 'week' ? 'Show month' : 'Show week' }}
      </button>
    </div>

    <button
      type="button"
      class="shrink-0 rounded-full border border-line px-3.5 py-1.5 text-sm text-ink hover:border-accent-dark hover:text-accent-dark transition-colors cursor-pointer"
      @click="goNext"
    >
      {{ view === 'week' ? 'Next week' : 'Next month' }} &#8594;
    </button>
  </div>

  <p v-if="loading" class="mt-8 text-ink/50">Loading...</p>

  <div v-else-if="view === 'week'" class="mt-6 grid gap-3 sm:grid-cols-3">
    <div
      v-for="day in weekDaysList"
      :key="toISODate(day)"
      class="min-w-0 rounded-xl border bg-white p-3"
      :class="isToday(day) ? 'border-accent' : 'border-line'"
    >
      <div class="flex items-center gap-2">
        <p class="text-xs font-semibold uppercase tracking-wide text-ink/50">{{ weekdayLabel(day) }}</p>
        <span
          v-if="isToday(day)"
          class="rounded-full bg-accent px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-white"
        >
          Today
        </span>
      </div>
      <p class="font-display text-base font-semibold text-ink">{{ dayNumberLabel(day) }}</p>

      <div
        v-for="slot in MEAL_TYPES"
        :key="slot"
        class="mt-3 rounded-lg transition-colors"
        :class="{ 'bg-accent-soft': isDragOver(day, slot) }"
        @dragover.prevent="dragOverKey = slotKey(day, slot)"
        @dragleave="clearDragOver(day, slot)"
        @drop.prevent="handleDrop(day, slot)"
      >
        <p class="text-xs font-medium uppercase tracking-wide text-ink/40">{{ slotLabel(slot) }}</p>
        <ul v-if="plansFor(day, slot).length" class="mt-1 space-y-1">
          <li
            v-for="plan in plansFor(day, slot)"
            :key="plan.id"
            draggable="true"
            class="flex cursor-grab items-center justify-between gap-1 rounded-lg bg-sage/10 px-2 py-1 text-sm text-ink/80 active:cursor-grabbing"
            :class="{ 'opacity-40': draggedPlanId === plan.id }"
            @dragstart="handleDragStart(plan)"
            @dragend="handleDragEnd"
          >
            <router-link
              v-if="plan.recipe"
              :to="`/recipes/${plan.recipe.id}`"
              class="min-w-0 truncate hover:text-accent-dark hover:underline"
            >
              {{ plan.recipe.title }}
            </router-link>
            <span v-else class="min-w-0 truncate italic">{{ plan.label }}</span>
            <span class="flex shrink-0 items-center gap-2">
              <router-link
                v-if="!plan.recipe"
                :to="{ path: '/recipes/import', query: { title: plan.label, mealPlanId: plan.id } }"
                class="rounded-full border border-ink/15 px-2 py-0.5 text-xs font-medium text-ink/40 hover:border-accent-dark hover:bg-accent-soft hover:text-accent-dark transition-colors"
                title="Create or import a recipe for this"
              >
                Add
              </router-link>
              <button
                type="button"
                class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full border border-ink/15 text-ink/40 hover:border-accent-dark hover:bg-accent-soft hover:text-accent-dark cursor-pointer transition-colors"
                aria-label="Remove"
                @click="removePlan(plan)"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" class="h-3 w-3">
                  <path d="M6 6l12 12M18 6L6 18" />
                </svg>
              </button>
            </span>
          </li>
        </ul>
        <RecipePicker
          class="mt-1"
          :options="recipeOptions"
          :meal-type="slot"
          @select="(recipeId) => addPlan(day, slot, { recipeId })"
          @add-text="(label) => addPlan(day, slot, { label })"
        />
      </div>
    </div>
  </div>

  <div v-else class="mt-6 grid grid-cols-7 gap-px overflow-hidden rounded-xl border border-line bg-line">
    <div
      v-for="label in WEEKDAY_LABELS"
      :key="label"
      class="bg-cream px-2 py-1 text-center text-xs font-semibold uppercase tracking-wide text-ink/50"
    >
      {{ label }}
    </div>
    <button
      v-for="day in monthGridDays"
      :key="toISODate(day)"
      type="button"
      class="flex min-h-20 flex-col items-start gap-1 bg-white p-2 text-left transition-colors hover:bg-cream cursor-pointer"
      :class="isCurrentMonth(day) ? 'text-ink' : 'text-ink/30'"
      @click="selectDay(day)"
    >
      <span class="text-sm font-medium" :class="{ 'rounded-full bg-accent px-1.5 text-white': isToday(day) }">
        {{ day.getDate() }}
      </span>
      <div v-if="plansForDay(day).length" class="w-full space-y-0.5">
        <p
          v-for="plan in plansForDay(day).slice(0, MAX_MONTH_CELL_PLANS)"
          :key="plan.id"
          class="w-full truncate text-[11px] leading-tight text-ink/70"
          :class="{ italic: !plan.recipe }"
        >
          {{ plan.recipe ? plan.recipe.title : plan.label }}
        </p>
        <p v-if="plansForDay(day).length > MAX_MONTH_CELL_PLANS" class="text-[11px] leading-tight text-ink/40">
          +{{ plansForDay(day).length - MAX_MONTH_CELL_PLANS }} more
        </p>
      </div>
    </button>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useMealPlansStore } from '../stores/mealPlans'
import { useAuthStore } from '../stores/auth'
import { startOfWeek, addDays, addMonths, toISODate, weekDays as weekDaysFn, monthGridWeeks, weekRangeLabel, monthLabel } from '../lib/calendar'
import { visibleMealTypes, groupPlansBySlot, groupPlansByDate, MAX_MONTH_CELL_PLANS, slotLabel, weekdayLabel, dayNumberLabel } from '../lib/mealPlanSlots'
import RecipePicker from '../components/RecipePicker.vue'

const WEEKDAY_LABELS = [ 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' ]

const mealPlans = useMealPlansStore()
const auth = useAuthStore()

const MEAL_TYPES = computed(() => visibleMealTypes(auth.user))

const view = ref('week')
const currentDate = ref(new Date())
const allRecipes = ref([])
const loading = ref(true)
const draggedPlanId = ref(null)
const dragOverKey = ref(null)

const weekStart = computed(() => startOfWeek(currentDate.value))
const weekDaysList = computed(() => weekDaysFn(weekStart.value))

const monthGridDays = computed(() => monthGridWeeks(currentDate.value).flat())

const visibleRange = computed(() => {
  if (view.value === 'week') return { start: weekStart.value, end: addDays(weekStart.value, 6) }
  const days = monthGridDays.value
  return { start: days[0], end: days[days.length - 1] }
})

const headerLabel = computed(() =>
  view.value === 'week' ? weekRangeLabel(weekStart.value) : monthLabel(currentDate.value)
)

const recipeOptions = computed(() =>
  allRecipes.value
    .map((r) => ({ id: r.id, label: r.title, tags: r.tags.map((tag) => tag.name), image: r.image_url }))
    .sort((a, b) => a.label.localeCompare(b.label))
)

const plansByKey = computed(() => groupPlansBySlot(mealPlans.items))

const plansByDate = computed(() => groupPlansByDate(mealPlans.items, MEAL_TYPES.value))

function plansFor(day, slot) {
  return plansByKey.value.get(`${toISODate(day)}|${slot}`) || []
}

function plansForDay(day) {
  return plansByDate.value.get(toISODate(day)) || []
}

function isToday(day) {
  return toISODate(day) === toISODate(new Date())
}

function isCurrentMonth(day) {
  return day.getMonth() === currentDate.value.getMonth()
}

function goPrevious() {
  currentDate.value = view.value === 'week' ? addDays(currentDate.value, -7) : addMonths(currentDate.value, -1)
}

function goNext() {
  currentDate.value = view.value === 'week' ? addDays(currentDate.value, 7) : addMonths(currentDate.value, 1)
}

function toggleView() {
  view.value = view.value === 'week' ? 'month' : 'week'
}

function selectDay(day) {
  currentDate.value = day
  view.value = 'week'
}

async function addPlan(day, slot, payload) {
  await mealPlans.create({ ...payload, date: toISODate(day), mealType: slot })
}

async function removePlan(plan) {
  await mealPlans.destroy(plan.id)
}

function slotKey(day, slot) {
  return `${toISODate(day)}|${slot}`
}

function isDragOver(day, slot) {
  return dragOverKey.value === slotKey(day, slot)
}

function clearDragOver(day, slot) {
  if (dragOverKey.value === slotKey(day, slot)) dragOverKey.value = null
}

function handleDragStart(plan) {
  draggedPlanId.value = plan.id
}

function handleDragEnd() {
  draggedPlanId.value = null
  dragOverKey.value = null
}

async function handleDrop(day, slot) {
  const id = draggedPlanId.value
  dragOverKey.value = null
  draggedPlanId.value = null
  if (id == null) return
  await mealPlans.move(id, { date: toISODate(day), mealType: slot })
}

async function loadRange() {
  loading.value = true
  const { start, end } = visibleRange.value
  await mealPlans.fetchRange(toISODate(start), toISODate(end))
  loading.value = false
}

watch([ view, currentDate ], loadRange)

onMounted(async () => {
  const response = await fetch('/api/v1/recipes', { credentials: 'include' })
  if (response.ok) allRecipes.value = await response.json()
  await loadRange()
})
</script>
