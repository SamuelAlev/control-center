import {copyFile} from 'node:fs/promises';
import path from 'node:path';

const directory = process.argv[2];
if (!directory) {
  throw new Error('Usage: node tool/stage_resource_assets.mjs <web-output-directory>');
}

// Phone development uses symlinks; package the canonical bytes even when a
// build tool does not follow symlinks while traversing its web directory.
for (const name of [
  'cc_resource_bridge.js',
  'cc_resource_worker.js',
  'cc_resource_ws_shim.js',
]) {
  await copyFile(new URL(`../web/${name}`, import.meta.url),
    path.join(directory, name));
}
console.log(`Staged encrypted resource assets in ${directory}`);
