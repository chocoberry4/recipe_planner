import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth'

const routes = [
  { path: '/', name: "Home", component: () =>  import ('../views/Home.vue') } ,
  { path: '/recipes', name: "Recipes", component: () =>  import ('../views/Recipes.vue'), meta: { requiresAuth: true } } ,
  { path: '/recipes/import', name: "ImportRecipe", component: () => import('../views/RecipeImport.vue'), meta: { requiresAuth: true } },
  { path: '/recipes/:id', name: "RecipeDetail", component: () => import('../views/RecipeDetail.vue'), meta: { requiresAuth: true } },
  { path: '/recipes/:id/steps', name: "StepMode", component: () => import('../views/StepMode.vue'), meta: { requiresAuth: true } },
  { path: '/recipes/:id/edit', name: "EditRecipe", component: () => import('../views/RecipeReview.vue'), meta: { requiresAuth: true } },
  { path: '/recipes/:id/review', name: "RecipeReview", component: () => import('../views/RecipeReview.vue'), meta: { requiresAuth: true } },
  { path: '/settings', name: "Settings", component: () => import('../views/Settings.vue'), meta: { requiresAuth: true } },
  { path: '/login', name: "Login", component: () => import('../views/Login.vue') },
  { path: '/signup', name: "Signup", component: () => import('../views/Signup.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to) => {
  if (!to.meta.requiresAuth) return true

  const auth = useAuthStore()
  if (!auth.checked) await auth.fetchCurrentUser()

  if (!auth.isLoggedIn) return { path: '/login' }

  return true
})

export default router;