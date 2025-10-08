import { defineConfig } from 'vite';
import ViteRails from 'vite-plugin-rails';
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
    plugins: [
      inject({
        $: 'jquery',
        jQuery: 'jquery',
      }),
      ViteRails(),
    ],
    include: ['**/*.{test,spec}.?(c|m)[jt]s?(x)'],
  };
};
