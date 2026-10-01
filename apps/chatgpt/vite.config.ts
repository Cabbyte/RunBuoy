import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { viteSingleFile } from "vite-plugin-singlefile";
export default defineConfig({
  // Keep intermediate chunks available to Vite's license collector. Deployment
  // still serves only index.html, which embeds both the code and notices.
  plugins: [react(), viteSingleFile({ deleteInlinedFiles: false })],
  build: { target: "es2022", cssCodeSplit: false, license: true },
});
