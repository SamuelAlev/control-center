/**
 * The open-source components Control Center ships, read from the same files the
 * release pipeline uses.
 *
 * There is deliberately no second copy of this list. `scripts/lib/third_party.sh`
 * is the source of truth that `gen_third_party_licenses.sh` turns into the
 * `THIRD-PARTY-LICENSES.txt` inside every artifact; this module parses that same
 * table so the website and the shipped binaries can never disagree about what is
 * in the product. A component added to the build appears on the site at the next
 * deploy without anyone editing a page.
 *
 * Node-only, and BUILD-time only. The Cloudflare adapter prerenders pages inside
 * a sandbox with no filesystem (its cwd is `/bundle`), so a page cannot import
 * this: `astro.config.mjs` runs it on the real build host and bakes the result
 * into the `virtual:third-party` module the pages import instead.
 */
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

/**
 * Repo root, found by walking up from the working directory until the manifest
 * is there — so it works whether the build runs from `docs/` or the repo root.
 */
function findRoot() {
  let dir = process.cwd();
  for (let i = 0; i < 6; i++) {
    if (existsSync(resolve(dir, 'scripts/lib/third_party.sh'))) return dir + '/';
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  throw new Error(
    `could not locate the repository root from ${process.cwd()} — ` +
      'scripts/lib/third_party.sh was not found in any parent directory',
  );
}

const ROOT = findRoot();

function read(relative) {
  return readFileSync(ROOT + relative, 'utf8');
}

/** `KEY=value  # comment` pairs from the pinned-sources file. */
function nativePins() {
  const pins = new Map();
  for (const line of read('scripts/lib/native_pins.env').split('\n')) {
    const match = /^([A-Z0-9_]+)=(.*)$/.exec(line.trim());
    if (!match) continue;
    pins.set(match[1], match[2].replace(/\s+#.*$/, '').trim());
  }
  return pins;
}

/** Mirrors `cc_third_party_version` in scripts/lib/third_party.sh. */
function resolveVersion(raw, pins) {
  if (raw === '@codeServerVersion') {
    const source = read('packages/cc_infra/lib/src/ide/code_server_service.dart');
    return /const String codeServerVersion\s*=\s*'([^']+)'/.exec(source)?.[1] ?? 'unknown';
  }
  if (!raw.startsWith('@')) return raw;
  const value = pins.get(raw.slice(1));
  if (!value) return 'unknown';
  // A 40-hex git pin is shown short; a plain version prints whole.
  return /^[0-9a-f]{40}$/.test(value) ? value.slice(0, 12) : value;
}

/** The `name|version|spdx|homepage|license_file|linkage|roles` rows. */
function manifestRows() {
  const body = /CC_THIRD_PARTY=\(([\s\S]*?)\n\)/.exec(read('scripts/lib/third_party.sh'))?.[1];
  if (!body) throw new Error('CC_THIRD_PARTY not found in scripts/lib/third_party.sh');
  return body
    .split('\n')
    .map((line) => /^\s*"([^"]+)"\s*$/.exec(line)?.[1])
    .filter(Boolean)
    .map((row) => row.split('|'));
}

/**
 * Every component redistributed inside a shipped artifact, with its full
 * license text, in the order the manifest lists them.
 */
export function bundledComponents() {
  const pins = nativePins();
  return manifestRows().map(([name, version, license, homepage, file, linkage, roles]) => ({
    slug: name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, ''),
    name,
    version: resolveVersion(version, pins),
    license,
    homepage,
    linkage,
    roles: roles.split(','),
    text: read(`third_party/licenses/${file}`).trimEnd(),
  }));
}

/**
 * The DIRECT Dart/Flutter dependencies, from the workspace's single lockfile.
 *
 * Direct only, on purpose: the full transitive closure is hundreds of packages
 * and reads as noise rather than credit. Each ships under its own license,
 * reproduced in the `NOTICES` file Flutter writes into the app bundle.
 *
 * Parsed line-wise rather than with a YAML dependency — `pubspec.lock` has a
 * fixed shape the generator always emits, and the docs site has no YAML parser.
 */
export function dartDependencies() {
  const out = [];
  let name = null;
  let direct = false;
  let url = 'https://pub.dev';

  for (const line of read('pubspec.lock').split('\n')) {
    const pkg = /^ {2}([a-z0-9_]+):\s*$/.exec(line);
    if (pkg) {
      name = pkg[1];
      direct = false;
      url = 'https://pub.dev';
      continue;
    }
    if (!name) continue;
    if (/^\s+dependency:\s*"direct main"\s*$/.test(line)) direct = true;
    const hosted = /^\s+url:\s*"?(https?:\/\/[^"\s]+)"?\s*$/.exec(line);
    if (hosted) url = hosted[1];
    const version = /^\s{4}version:\s*"?([^"\s]+)"?\s*$/.exec(line);
    if (version && direct) {
      out.push({
        name,
        version: version[1],
        url: url.includes('pub.dev') ? `https://pub.dev/packages/${name}` : url,
      });
      name = null;
    }
  }
  return out.sort((a, b) => a.name.localeCompare(b.name));
}

/**
 * License texts on disk that the manifest never references — a component was
 * removed from the table but its text was left behind. The repo test
 * `test/tooling/third_party_licenses_test.dart` fails on this too; the site
 * should not silently under-report either.
 */
export function orphanLicenseFiles() {
  const referenced = new Set(manifestRows().map((row) => row[4]));
  return readdirSync(ROOT + 'third_party/licenses').filter((f) => !referenced.has(f));
}
