import { createRouter, createWebHistory } from 'vue-router';

const routes = [
  { path: '/', name: "Home", component: () =>  import ('../views/Home.vue') } ,
  { path: '/recipes', name: "Recipes", component: () =>  import ('../views/Recipes.vue') } ,
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router;