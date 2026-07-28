<template>
  <div class="py-12 text-center">
    <h1 class="font-display text-4xl sm:text-5xl font-semibold tracking-tight text-ink">
      Plan meals you'll actually cook.
    </h1>
    <p class="mt-4 text-lg text-ink/60 max-w-xl mx-auto">
      Keep your recipes organized, scale them to fit, and build shopping lists
      without the guesswork.
    </p>

    <p v-if="!auth.checked" class="mt-8 text-ink/50">Loading...</p>

    <div v-else-if="auth.isLoggedIn">
      <div v-if="summaryDays.length || monthGridDays.length" class="mt-10 text-left">
        <div class="flex items-center justify-between">
          <h2 class="font-display text-lg font-semibold text-ink">
            {{ auth.user.home_view === 'monthly' ? "This month" : "This week" }}
          </h2>
          <router-link to="/planner" class="text-sm font-medium text-accent hover:text-accent-dark">
            Open planner &rarr;
          </router-link>
        </div>

        <p v-if="plansLoading" class="mt-4 text-ink/50">Loading...</p>

        <div
          v-else-if="auth.user.home_view === 'monthly'"
          class="mt-6 grid grid-cols-7 gap-px overflow-hidden rounded-xl border border-line bg-line"
        >
          <div
            v-for="label in WEEKDAY_LABELS"
            :key="label"
            class="bg-cream px-2 py-1 text-center text-xs font-semibold uppercase tracking-wide text-ink/50"
          >
            {{ label }}
          </div>
          <div
            v-for="day in monthGridDays"
            :key="toISODate(day)"
            class="flex min-h-20 flex-col items-start gap-1 bg-white p-2 text-left"
            :class="isCurrentMonth(day) ? 'text-ink' : 'text-ink/30'"
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
          </div>
        </div>

        <div v-else class="mt-4 grid gap-3 sm:grid-cols-3">
          <div
            v-for="day in summaryDays"
            :key="toISODate(day)"
            class="min-w-0 rounded-xl border bg-white p-3 text-left"
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

            <div v-for="slot in visibleMealTypesList" :key="slot" class="mt-3">
              <p class="text-xs font-medium uppercase tracking-wide text-ink/40">{{ slotLabel(slot) }}</p>
              <ul v-if="plansFor(day, slot).length" class="mt-1 space-y-1">
                <li
                  v-for="plan in plansFor(day, slot)"
                  :key="plan.id"
                  class="truncate rounded-lg bg-sage/10 px-2 py-1 text-sm text-ink/80"
                  :class="{ italic: !plan.recipe }"
                >
                  <router-link v-if="plan.recipe" :to="`/recipes/${plan.recipe.id}`" class="hover:text-accent-dark hover:underline">
                    {{ plan.recipe.title }}
                  </router-link>
                  <template v-else>{{ plan.label }}</template>
                </li>
              </ul>
              <p v-else class="mt-1 text-xs text-ink/30">Nothing planned</p>
            </div>
          </div>
        </div>
      </div>

      <div v-else-if="ideas.length" class="mt-10 grid gap-4 text-left sm:grid-cols-3">
        <router-link
          v-for="recipe in ideas"
          :key="recipe.id"
          :to="`/recipes/${recipe.id}`"
          class="rounded-xl border border-line bg-white p-4 hover:border-accent hover:shadow-sm transition"
        >
          <img
            v-if="recipe.image_url"
            :src="recipe.image_url"
            alt=""
            class="mb-3 h-32 w-full rounded-lg object-cover"
          />
          <h2 class="font-display text-base font-semibold text-ink">{{ recipe.title }}</h2>
          <p class="mt-1 min-h-[2.5rem] text-sm text-ink/60 line-clamp-2">
            {{ recipe.description }}
          </p>
        </router-link>
      </div>

      <div class="mt-8">
        <router-link
          to="/recipes"
          class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors"
        >
          View all recipes
        </router-link>
      </div>
    </div>

    <div v-else class="mt-8 flex justify-center gap-3">
      <router-link
        to="/recipes"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors"
      >
        View recipes
      </router-link>
      <router-link
        to="/signup"
        class="rounded-full border border-line px-5 py-2.5 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors"
      >
        Create an account
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import { useMealPlansStore } from '../stores/mealPlans'
import { startOfWeek, toISODate, weekDays as weekDaysFn, monthGridWeeks } from '../lib/calendar'
import { visibleMealTypes, groupPlansBySlot, groupPlansByDate, MAX_MONTH_CELL_PLANS, slotLabel, weekdayLabel, dayNumberLabel } from '../lib/mealPlanSlots'

const WEEKDAY_LABELS = [ 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' ]

const auth = useAuthStore()
const mealPlans = useMealPlansStore()
const ideas = ref([])
const plansLoading = ref(true)

const IDEA_COUNT = 9

// Fisher-Yates - picks recipes at random each visit, rather than always the
// same first/last few, so the homepage surfaces variety over time.
function sampleRandom(list, count) {
  const copy = [ ...list ]
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[ copy[i], copy[j] ] = [ copy[j], copy[i] ]
  }
  return copy.slice(0, count)
}

const visibleMealTypesList = computed(() => visibleMealTypes(auth.user))

// Only "weekly_planner" and "monthly" (the Settings-configurable homepage
// modes) show anything here - "random_recipes" (the default) leaves both
// empty so the existing recipe-ideas grid renders instead.
const summaryDays = computed(() => {
  if (auth.user?.home_view === 'weekly_planner') return weekDaysFn(startOfWeek(new Date()))
  return []
})

const monthGridDays = computed(() => {
  if (auth.user?.home_view !== 'monthly') return []
  return monthGridWeeks(new Date()).flat()
})

const plansByKey = computed(() => groupPlansBySlot(mealPlans.items))
const plansByDate = computed(() => groupPlansByDate(mealPlans.items, visibleMealTypesList.value))

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
  return day.getMonth() === new Date().getMonth()
}

onMounted(async () => {
  if (!auth.checked) await auth.fetchCurrentUser()
  if (!auth.isLoggedIn) return

  if (summaryDays.value.length || monthGridDays.value.length) {
    const days = summaryDays.value.length ? summaryDays.value : monthGridDays.value
    await mealPlans.fetchRange(toISODate(days[0]), toISODate(days[days.length - 1]))
    plansLoading.value = false
    return
  }

  try {
    const response = await fetch('/api/v1/recipes', { credentials: 'include' })
    if (response.ok) ideas.value = sampleRandom(await response.json(), IDEA_COUNT)
  } catch {
    ideas.value = []
  }
})
</script>
