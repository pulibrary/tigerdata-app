import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import inject from '@rollup/plugin-inject';

export default ({ command, mode }) => {
  let minifySetting;

  if (mode === 'development') {
    minifySetting = false;
  } else {
    minifySetting = 'esbuild';
  }

  return {
    server: {
      warmup: {
        clientFiles: [
          // List files you want to be pre-bundled here for faster dev server start
          // List frequently used components across multiple entry points
          'app/javascript/entrypoints/pulDataTables.js',
        ],
      },
    },
    build: {
      minify: minifySetting,
      skipCompatibilityCheck: true,
    },
    resolve: {
      alias: {
        vue: 'vue/dist/vue.esm-bundler',
      },
    },
    plugins: [
      inject({
        $: 'jquery',
        jQuery: 'jquery',
      }),
      RubyPlugin(),
      vue(),
    ],
    include: ['**/*.{test,spec}.?(c|m)[jt]s?(x)'],
  };
};
