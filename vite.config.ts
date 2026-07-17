import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue(),
    tailwindcss(),
  ],
  server: {
    // Rails runs in Docker and reaches this dev server via host.docker.internal.
    allowedHosts: ['host.docker.internal'],
  },
})
