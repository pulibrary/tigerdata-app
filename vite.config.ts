import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import ViteRails from 'vite-plugin-rails'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    ViteRails(),
  ],
})
