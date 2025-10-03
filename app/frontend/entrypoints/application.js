// app/frontend/entrypoints/application.js
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from '../App.vue'  // Your root Vue component

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.mount('#app')