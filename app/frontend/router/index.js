import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth'

const routes = [
  { path: '/', name: "Home", component: () =>  import ('../views/Home.vue') } ,
  { path: '/recipes', name: "Recipes", component: () =>  import ('../views/Recipes.vue') } ,
  { path: '/login', name: "Login", component: () => import('../views/Login.vue') },
  { path: '/signup', name: "Signup", component: () => import('../views/Signup.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to) => {
  if (to.path !== '/recipes') return true

  const auth = useAuthStore()
  if (!auth.checked) await auth.fetchCurrentUser()

  if (!auth.isLoggedIn) return { path: '/login' }

  return true
})

export default router;