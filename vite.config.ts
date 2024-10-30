import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'
import inject from "@rollup/plugin-inject";
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
      inject({
        $: 'jquery',
        jQuery: 'jquery',
      }),
      ViteRails(),
      vue()
  ],
  resolve: {
    alias: {
      'vue': 'vue/dist/vue.esm-bundler',
    }
  },
  include: ['**/*.{test,spec}.?(c|m)[jt]s?(x)']
})
