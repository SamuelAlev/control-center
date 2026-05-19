import { readFile, writeFile } from "node:fs/promises";

// The adapter's generated deploy config carries a SESSION KV binding for a
// namespace this site does not have — strip it or Cloudflare rejects the
// deploy. Where that config lives depends on the worker entry: the default
// entry deploys an assets-only stub (dist/client/wrangler.json); the custom
// negotiating entry (src/worker.ts) deploys the real bundle
// (dist/server/wrangler.json). Patch whichever exists.
const CANDIDATES = ["dist/server/wrangler.json", "dist/client/wrangler.json"];

const stripSession = (arr) =>
  Array.isArray(arr) ? arr.filter((b) => b?.binding !== "SESSION") : arr;

let totalRemoved = 0;
let patched = 0;

for (const path of CANDIDATES) {
  let raw;
  try {
    raw = await readFile(path, "utf8");
  } catch {
    continue;
  }
  const cfg = JSON.parse(raw);
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

  await writeFile(path, JSON.stringify(cfg), "utf8");
  patched += 1;
  totalRemoved += removed;
  console.log(`[fix-wrangler] ${path}: SESSION KV binding(s) cleared: ${removed} items.`);
}

if (patched === 0) {
  throw new Error("[fix-wrangler] no generated wrangler config found — did `astro build` run?");
}
