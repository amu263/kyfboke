import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  site: 'http://localhost:4321',
  devToolbar: { enabled: false },
  server: {
    host: '127.0.0.1',
    port: 4321,
  },
  markdown: {
    shikiConfig: {
      // Use the same theme family we use for the site
      theme: 'github-dark-dimmed',
      wrap: true,
    },
  },
});