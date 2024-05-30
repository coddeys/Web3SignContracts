import { defineConfig } from 'vite';
import elmPlugin from 'vite-plugin-elm';
import EnvironmentPlugin from 'vite-plugin-environment';

export default defineConfig({
  plugins: [
    elmPlugin(),
    EnvironmentPlugin('all')
  ],
  optimizeDeps: {
    esbuildOptions: {
        // Node.js global to browser globalThis
        define: {
            global: 'globalThis',
        },
    },
  }
})
