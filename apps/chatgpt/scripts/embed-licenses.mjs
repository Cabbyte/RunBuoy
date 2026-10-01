import { readFile, writeFile } from "node:fs/promises";

// The server ships a single HTML resource, so carry Vite's complete bundled
// dependency notices in an inert template inside that resource.
const notices = await readFile(new URL("../dist/.vite/license.md", import.meta.url), "utf8");
if (!notices.includes("## react -") || !notices.includes("## @modelcontextprotocol/ext-apps -")) {
  throw new Error("Bundled dependency license notices are missing");
}
const htmlPath = new URL("../dist/index.html", import.meta.url);
const html = await readFile(htmlPath, "utf8");
const escaped = notices.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
await writeFile(htmlPath, html.replace("</body>", `<template id="third-party-licenses"><pre>${escaped}</pre></template></body>`));
