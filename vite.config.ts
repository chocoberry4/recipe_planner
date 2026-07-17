import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  server: {
    // Rails runs in Docker and reaches this dev server via host.docker.internal.
    allowedHosts: ['host.docker.internal'],
  },
})
