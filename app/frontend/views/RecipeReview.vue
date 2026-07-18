<template>
  <p v-if="loading" class="text-ink/50">Loading...</p>
  <p v-else-if="error" class="text-accent-dark">{{ error }}</p>
  <div v-else-if="recipe">
    <div class="space-y-4">
      <label class="block">
        <span class="text-sm font-medium text-ink/80">Title</span>
        <input
          v-model="title"
          type="text"
          required
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 font-display text-xl font-semibold text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>
      <label class="block">
        <span class="text-sm font-medium text-ink/80">Description</span>
        <textarea
          v-model="description"
          rows="2"
          class="mt-1 w-full rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
        ></textarea>
      </label>
      <p class="text-sm text-ink/50">
        Edit any part of this recipe - ingredients, steps, and which ingredients belong to which step - then save.
      </p>
    </div>

    <section class="mt-8 border-t border-line pt-6">
      <h2 class="font-display text-lg font-semibold text-sage">Ingredients</h2>

      <div v-for="group in groups" :key="group._key" class="mt-4 rounded-xl border border-line bg-white p-4">
        <div class="flex items-center gap-2">
          <input
            v-model="group.name"
            type="text"
            placeholder="Group name"
            class="flex-1 rounded-lg border border-line bg-white px-2 py-1 text-sm font-semibold text-ink/80 outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
          />
          <button
            type="button"
            class="text-sm text-ink/40 hover:text-accent-dark cursor-pointer"
            :aria-label="`Remove group ${group.name}`"
            @click="removeGroup(group._key)"
          >
            Remove group
          </button>
        </div>

        <IngredientRow
          v-for="ri in ingredientsInGroup(group._key)"
          :key="ri._key"
          :row="ri"
          :groups="groups"
          @remove="removeIngredient(ri._key)"
        />

        <button
          type="button"
          class="mt-3 text-sm font-medium text-accent hover:text-accent-dark cursor-pointer"
          @click="addIngredient(group._key)"
        >
          + Add ingredient
        </button>
      </div>

      <div class="mt-4 rounded-xl border border-line bg-white p-4">
        <h3 class="text-sm font-semibold text-ink/70">Ingredients</h3>

        <IngredientRow
          v-for="ri in ingredientsInGroup(null)"
          :key="ri._key"
          :row="ri"
          :groups="groups"
          @remove="removeIngredient(ri._key)"
        />

        <button
          type="button"
          class="mt-3 text-sm font-medium text-accent hover:text-accent-dark cursor-pointer"
          @click="addIngredient(null)"
        >
          + Add ingredient
        </button>
      </div>

      <button
        type="button"
        class="mt-3 text-sm font-medium text-ink/60 hover:text-accent-dark cursor-pointer"
        @click="addGroup"
      >
        + Add ingredient group
      </button>
    </section>

    <section class="mt-8 space-y-5 border-t border-line pt-6">
      <h2 class="font-display text-lg font-semibold text-sage">Steps</h2>
      <div
        v-for="(instruction, index) in instructions"
        :key="instruction._key"
        class="rounded-xl border border-line bg-white p-4"
      >
        <ul v-if="instruction.id" class="flex flex-wrap gap-2">
          <li
            v-for="ri in assignedFor(instruction.id)"
            :key="ri._key"
            class="flex items-center gap-1.5 rounded-full bg-sage/15 px-3 py-1 text-sm text-ink/85"
          >
            {{ ingredientLabel(ri) }}
            <button
              type="button"
              class="text-ink/40 hover:text-accent-dark cursor-pointer"
              :aria-label="`Remove ${ri.name} from this step`"
              @click="removeFromStep(instruction.id, ri.id)"
            >
              &times;
            </button>
          </li>
          <li v-if="assignedFor(instruction.id).length === 0" class="text-sm text-ink/40">
            No ingredients assigned.
          </li>
        </ul>

        <div class="mt-3 flex items-start gap-3">
          <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-accent-soft text-xs font-semibold text-accent-dark">
            {{ index + 1 }}
          </span>
          <textarea
            v-model="instruction.description"
            rows="2"
            class="flex-1 rounded-lg border border-line bg-white px-3 py-2 text-ink outline-none focus:border-accent focus:ring-2 focus:ring-accent/20"
          ></textarea>
          <div class="flex shrink-0 flex-col gap-1">
            <button
              type="button"
              class="text-ink/40 hover:text-accent-dark disabled:opacity-30 cursor-pointer disabled:cursor-not-allowed"
              aria-label="Move step up"
              :disabled="index === 0"
              @click="moveInstruction(instruction._key, -1)"
            >
              &uarr;
            </button>
            <button
              type="button"
              class="text-ink/40 hover:text-accent-dark disabled:opacity-30 cursor-pointer disabled:cursor-not-allowed"
              aria-label="Move step down"
              :disabled="index === instructions.length - 1"
              @click="moveInstruction(instruction._key, 1)"
            >
              &darr;
            </button>
          </div>
          <button
            type="button"
            class="shrink-0 text-sm text-ink/40 hover:text-accent-dark cursor-pointer"
            aria-label="Remove step"
            @click="removeInstruction(instruction._key)"
          >
            Remove
          </button>
        </div>

        <IngredientCombobox
          v-if="instruction.id"
          :options="unresolvedOptions"
          :aria-label="`Add ingredient to step ${index + 1}`"
          @select="(id) => addToStep(instruction.id, id)"
        />
        <p v-else class="mt-3 ml-9 text-sm text-ink/40">Save to assign ingredients to this step.</p>
      </div>

      <button
        type="button"
        class="text-sm font-medium text-accent hover:text-accent-dark cursor-pointer"
        @click="addInstruction"
      >
        + Add step
      </button>
    </section>

    <section class="mt-8 border-t border-line pt-6">
      <h2 class="font-display text-lg font-semibold text-sage">Unresolved ingredients</h2>
      <p v-if="unresolved.length === 0" class="mt-2 text-sm text-ink/50">
        Everything's assigned to a step.
      </p>
      <ul v-else class="mt-3 flex flex-wrap gap-2">
        <li
          v-for="ri in unresolved"
          :key="ri._key"
          class="rounded-full border border-line px-3 py-1 text-sm text-ink/70"
        >
          {{ ingredientLabel(ri) }}
        </li>
      </ul>
    </section>

    <p v-if="saveError" class="mt-6 rounded-lg bg-accent-soft px-3 py-2 text-sm text-accent-dark">
      {{ saveError }}
    </p>
    <p v-if="saveMessage" class="mt-6 rounded-lg bg-sage/15 px-3 py-2 text-sm text-sage">
      {{ saveMessage }}
    </p>

    <div class="mt-8 flex gap-3">
      <button
        type="button"
        :disabled="saving"
        class="rounded-full bg-accent px-5 py-2.5 text-sm font-medium text-white hover:bg-accent-dark transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
        @click="handleSave"
      >
        {{ saving ? 'Saving...' : 'Save' }}
      </button>
      <router-link
        :to="`/recipes/${recipe.id}`"
        class="rounded-full border border-line px-5 py-2.5 text-sm font-medium text-ink hover:border-accent hover:text-accent transition-colors"
      >
        Done
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { reactive, computed, ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useRecipesStore } from '../stores/recipes'
import IngredientCombobox from '../components/IngredientCombobox.vue'
import IngredientRow from '../components/IngredientRow.vue'

const route = useRoute()
const recipes = useRecipesStore()

const loading = ref(true)
const error = ref(null)
const saving = ref(false)
const saveError = ref(null)
const saveMessage = ref(null)
const recipe = computed(() => recipes.current)

const title = ref('')
const description = ref('')
const groups = ref([])
const ingredients = ref([])
const instructions = ref([])

// Rows removed locally just disappear from the arrays above, but the
// backend only destroys what's explicitly marked - anything simply absent
// from a save payload is left untouched. These track ids to send as
// { id, _destroy: true } on the next save, and are cleared once seeded
// fresh from a server response that no longer contains them.
const removedGroupIds = ref([])
const removedIngredientIds = ref([])
const removedInstructionIds = ref([])

// { [instructionId]: [recipe_ingredient_id, ...] } - a local editable draft
// of step assignments, seeded from the server and only persisted on Save.
const assignments = reactive({})

let keySeq = 0
function nextKey() {
  keySeq += 1
  return `local-${keySeq}`
}

// Seeds every editable array from the server's recipe shape. Called on
// mount and again after a successful save (the response carries real ids
// for anything that was just created, which is what lets newly-added
// ingredients/steps become assignable in a second pass).
function seedFromRecipe(data) {
  title.value = data.title
  description.value = data.description

  groups.value = data.recipe_ingredient_groups.map((g) => ({
    _key: String(g.id), id: g.id, name: g.name
  }))

  ingredients.value = [
    ...data.recipe_ingredient_groups.flatMap((g) =>
      g.recipe_ingredients.map((ri) => ({ ...ri, _key: String(ri.id), groupId: String(g.id) }))
    ),
    ...data.ingredients.map((ri) => ({ ...ri, _key: String(ri.id), groupId: null }))
  ]

  instructions.value = data.instructions.map((ins) => ({
    _key: String(ins.id),
    id: ins.id,
    description: ins.description,
    recipe_ingredient_group_id: ins.recipe_ingredient_group_id
  }))

  Object.keys(assignments).forEach((key) => delete assignments[key])
  data.instructions.forEach((ins) => {
    assignments[ins.id] = [ ...ins.recipe_ingredient_ids ]
  })

  removedGroupIds.value = []
  removedIngredientIds.value = []
  removedInstructionIds.value = []
}

onMounted(async () => {
  const result = await recipes.fetchOne(route.params.id)
  loading.value = false
  if (!result.ok) {
    error.value = 'Recipe not found'
    return
  }

  seedFromRecipe(recipe.value)
})

function ingredientsInGroup(groupKey) {
  return ingredients.value.filter((ri) => ri.groupId === groupKey)
}

function addGroup() {
  groups.value.push({ _key: nextKey(), id: null, name: '' })
}

function removeGroup(groupKey) {
  const group = groups.value.find((g) => g._key === groupKey)
  if (group?.id) removedGroupIds.value.push(group.id)

  ingredients.value.forEach((ri) => {
    if (ri.groupId === groupKey) ri.groupId = null
  })
  // Instructions can carry a structural tie to a group (set by the
  // autosorter's Tier 0, see recipe_autosorter.rb) that isn't shown as an
  // editable field here - if the group they point to is going away, that
  // tie has to be cleared too, or the save would resend a now-nonexistent
  // group id and hit the recipe_ingredient_group_id foreign key.
  if (group?.id) {
    instructions.value.forEach((ins) => {
      if (ins.recipe_ingredient_group_id === group.id) ins.recipe_ingredient_group_id = null
    })
  }
  groups.value = groups.value.filter((g) => g._key !== groupKey)
}

function addIngredient(groupKey) {
  ingredients.value.push({
    _key: nextKey(), id: null, name: '', quantity: null, unit: null, preparation: null, groupId: groupKey
  })
}

function removeIngredient(key) {
  const row = ingredients.value.find((ri) => ri._key === key)
  if (!row) return

  if (row.id) {
    removedIngredientIds.value.push(row.id)
    Object.keys(assignments).forEach((instructionId) => {
      assignments[instructionId] = assignments[instructionId].filter((id) => id !== row.id)
    })
  }
  ingredients.value = ingredients.value.filter((ri) => ri._key !== key)
}

function addInstruction() {
  instructions.value.push({ _key: nextKey(), id: null, description: '', recipe_ingredient_group_id: null })
}

function removeInstruction(key) {
  const row = instructions.value.find((ins) => ins._key === key)
  if (row?.id) {
    removedInstructionIds.value.push(row.id)
    delete assignments[row.id]
  }
  instructions.value = instructions.value.filter((ins) => ins._key !== key)
}

function moveInstruction(key, direction) {
  const index = instructions.value.findIndex((ins) => ins._key === key)
  const target = index + direction
  if (target < 0 || target >= instructions.value.length) return

  const copy = [ ...instructions.value ]
  ;[ copy[index], copy[target] ] = [ copy[target], copy[index] ]
  instructions.value = copy
}

// Only already-persisted ingredients can be assigned to a step - a
// brand-new, not-yet-saved row has no recipe_ingredient id for
// instruction_ingredients to reference yet.
const assignableIngredients = computed(() => ingredients.value.filter((ri) => ri.id))
const ingredientsById = computed(() => new Map(assignableIngredients.value.map((ri) => [ ri.id, ri ])))
const assignedIds = computed(() => new Set(Object.values(assignments).flat()))
const unresolved = computed(() => assignableIngredients.value.filter((ri) => !assignedIds.value.has(ri.id)))
const unresolvedOptions = computed(() => unresolved.value.map((ri) => ({ id: ri.id, label: ingredientLabel(ri) })))

function assignedFor(instructionId) {
  return (assignments[instructionId] || []).map((id) => ingredientsById.value.get(id)).filter(Boolean)
}

function removeFromStep(instructionId, recipeIngredientId) {
  assignments[instructionId] = (assignments[instructionId] || []).filter((id) => id !== recipeIngredientId)
}

// An ingredient lives in at most one step at a time, so adding it to a new
// step first removes it from wherever it currently is - this is how "moving"
// an ingredient between steps works, without needing drag gestures.
function addToStep(instructionId, recipeIngredientId) {
  const id = Number(recipeIngredientId)
  Object.keys(assignments).forEach((key) => {
    assignments[key] = assignments[key].filter((existingId) => existingId !== id)
  })
  assignments[instructionId] = [ ...(assignments[instructionId] || []), id ]
}

function ingredientLabel(ri) {
  return [ ri.quantity, ri.unit, ri.name ].filter(Boolean).join(' ')
}

function toIngredientPayload(ri, position) {
  return {
    id: ri.id,
    name: ri.name,
    quantity: ri.quantity === '' ? null : ri.quantity,
    unit: ri.unit || null,
    preparation: ri.preparation || null,
    position
  }
}

function buildPayload() {
  return {
    title: title.value,
    description: description.value,
    recipe_ingredient_groups: [
      ...groups.value.map((g) => ({
        id: g.id,
        name: g.name,
        recipe_ingredients: ingredientsInGroup(g._key).map((ri, i) => toIngredientPayload(ri, i + 1))
      })),
      ...removedGroupIds.value.map((id) => ({ id, _destroy: true }))
    ],
    ingredients: [
      ...ingredientsInGroup(null).map((ri, i) => toIngredientPayload(ri, i + 1)),
      ...removedIngredientIds.value.map((id) => ({ id, _destroy: true }))
    ],
    instructions: [
      ...instructions.value.map((ins, i) => ({
        id: ins.id,
        description: ins.description,
        step_number: i + 1,
        recipe_ingredient_group_id: ins.recipe_ingredient_group_id
      })),
      ...removedInstructionIds.value.map((id) => ({ id, _destroy: true }))
    ]
  }
}

async function handleSave() {
  saving.value = true
  saveError.value = null
  saveMessage.value = null

  const result = await recipes.update(route.params.id, buildPayload())
  if (!result.ok) {
    saving.value = false
    saveError.value = (result.errors || []).join(', ') || 'Failed to save.'
    return
  }

  // Step-ingredient assignments (the ADR-0004 tray) go through a separate
  // endpoint from the rest of the recipe's fields - save them second, using
  // the *current* local `assignments` draft rather than re-seeding from the
  // update response first, or the user's in-progress tray edits would be
  // overwritten by the pre-save assignment state.
  const assignmentsResult = await recipes.saveAssignments(route.params.id, { ...assignments })

  saving.value = false
  if (assignmentsResult.ok) {
    seedFromRecipe(assignmentsResult.recipe)
    saveMessage.value = 'Saved.'
  } else {
    seedFromRecipe(result.recipe)
    saveError.value = assignmentsResult.error || 'Failed to save step assignments.'
  }
}
</script>
