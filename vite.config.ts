import { defineConfig } from 'vite'
import ViteRails from 'vite-plugin-rails'
import inject from "@rollup/plugin-inject";

export default defineConfig({
  plugins: [
      inject({
        $: 'jquery',
        jQuery: 'jquery',
      }),
    ViteRails(),
  ],
})