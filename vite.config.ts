import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue(),
  ],
  server: {
    // Rails runs in Docker and reaches this dev server via host.docker.internal.
    allowedHosts: ['host.docker.internal'],
  },
})
