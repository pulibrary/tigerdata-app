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
