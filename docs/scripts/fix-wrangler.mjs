import { readFile, writeFile } from "node:fs/promises";

const CONFIG_PATH = "dist/client/wrangler.json";

const raw = await readFile(CONFIG_PATH, "utf8");
const cfg = JSON.parse(raw);

const stripSession = (arr) =>
  Array.isArray(arr) ? arr.filter((b) => b?.binding !== "SESSION") : arr;

let removed = 0;

if (Array.isArray(cfg.kv_namespaces)) {
  const before = cfg.kv_namespaces.length;
  cfg.kv_namespaces = stripSession(cfg.kv_namespaces);
  removed += before - cfg.kv_namespaces.length;
}

if (cfg.previews?.kv_namespaces) {
  const before = cfg.previews.kv_namespaces.length;
  cfg.previews.kv_namespaces = stripSession(cfg.previews.kv_namespaces);
  removed += before - cfg.previews.kv_namespaces.length;
}

await writeFile(CONFIG_PATH, JSON.stringify(cfg), "utf8");

console.log(`[fix-wrangler] SESSION KV binding(s) cleared: ${removed} items.`);
