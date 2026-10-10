import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { resolveDesktopDownload } from '../src/data/desktop-download.ts';
import { GET, HEAD } from '../src/pages/download/[platform].ts';

const version = '8.4.2';
const base = `https://github.com/SamuelAlev/control-center/releases/download/v${version}/`;
const asset = (name: string, changes = {}) => ({ name, state: 'uploaded', browser_download_url: `${base}${name}`, ...changes });
const installers = [
  asset(`Control-Center-${version}-arm64.dmg`),
  asset(`Control-Center-${version}-x64-setup.exe`),
  asset(`Control-Center-${version}-x86_64.AppImage`),
  asset(`Control-Center-${version}-arm64-setup.exe`),
];
const release = (assets: unknown[] = installers, changes = {}) => ({
  tag_name: `v${version}`, draft: false, prerelease: false, published_at: '2026-09-25T08:36:26Z', assets, ...changes,
});
const github = (body: unknown, status = 200): typeof fetch =>
  (async () => new Response(JSON.stringify(body), { status })) as typeof fetch;

describe('latest desktop installer resolution', () => {
  it('selects the uploaded installer for each OS, never a server bundle or another architecture', async () => {
    const assets = [
      asset(`cc_server-${version}-linux-x64.tar.gz`),
      asset(`Control-Center-${version}-linux-x64.tar.gz`),
      asset(`Control-Center-${version}-windows-x64.zip`),
      asset(`Control-Center-${version}-windows-arm64.zip`),
      asset(`Control-Center-${version}-x64.dmg`),
      ...installers,
    ];
    for (const [platform, expected] of [
      ['macos', installers[0]], ['windows', installers[1]], ['linux', installers[2]], ['windows-arm64', installers[3]],
    ] as const) {
      assert.deepEqual(await resolveDesktopDownload(platform, github(release(assets))), {
        status: 302, url: expected.browser_download_url,
      });
    }
  });

  it('returns an explicit absence, not another OS, release page or server artifact', async () => {
    const result = await resolveDesktopDownload('linux', github(release([
      asset(`cc_server-${version}-linux-x64.tar.gz`),
      asset(`Control-Center-${version}-arm64.dmg`),
    ])));
    assert.equal(result.status, 404);
  });

  it('rejects missing uploads, mismatched release tags and untrusted download URLs', async () => {
    const assets = [
      asset(`Control-Center-${version}-arm64.dmg`, { state: 'new' }),
      asset(`Control-Center-${version}-arm64.dmg`, { browser_download_url: 'https://example.net/malware.dmg' }),
      asset('Control-Center-1.0.0-arm64.dmg'),
      asset(`Control-Center-${version}-arm64.dmg`, { browser_download_url: `${base.replace(`v${version}`, 'v0.0.1')}Control-Center-${version}-arm64.dmg` }),
    ];
    assert.equal((await resolveDesktopDownload('macos', github(release(assets)))).status, 404);
    assert.equal((await resolveDesktopDownload('macos', github(release(assets, { prerelease: true })))).status, 502);
    assert.equal((await resolveDesktopDownload('macos', github(release(assets, { draft: true })))).status, 502);
  });

  it('denies an unknown platform without contacting GitHub', async () => {
    const neverFetch = (async () => { throw Error('Unexpected API request'); }) as typeof fetch;
    assert.equal((await resolveDesktopDownload('android', neverFetch)).status, 404);
    assert.equal((await resolveDesktopDownload('toString', neverFetch)).status, 404);
  });

  it('reports an unpublished release, failed upstream, bad payload and network failure distinctly', async () => {
    assert.equal((await resolveDesktopDownload('windows', github({ message: 'Not Found' }, 404))).status, 404);
    assert.equal((await resolveDesktopDownload('windows', github({ message: 'rate limited' }, 403))).status, 503);
    assert.equal((await resolveDesktopDownload('windows', github({ assets: [] }))).status, 502);
    const badJson = (async () => new Response('{', { status: 200 })) as typeof fetch;
    assert.equal((await resolveDesktopDownload('windows', badJson)).status, 502);
    const offline = (async () => { throw Error('network unavailable'); }) as typeof fetch;
    assert.equal((await resolveDesktopDownload('windows', offline)).status, 503);
  });
});

describe('download endpoint', () => {
  it('redirects GET and HEAD to the same installer without a HEAD response body', async () => {
    const originalFetch = globalThis.fetch;
    globalThis.fetch = github(release());
    try {
      const request = new Request('https://usectrl.dev/download/windows');
      const params = { platform: 'windows' };
      const get = await GET({ params, request } as Parameters<typeof GET>[0]);
      const head = await HEAD({ params, request: new Request(request.url, { method: 'HEAD' }) } as Parameters<typeof HEAD>[0]);
      assert.equal(get.status, 302);
      assert.equal(get.headers.get('Location'), installers[1].browser_download_url);
      assert.equal(head.status, 302);
      assert.equal(head.headers.get('Location'), get.headers.get('Location'));
      assert.equal(await head.text(), '');
      assert.equal(get.headers.get('Cache-Control'), 'no-store');
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  it('answers an unsupported OS with HTTP 404 and a bodyless HEAD response', async () => {
    const request = new Request('https://usectrl.dev/download/android');
    const params = { platform: 'android' };
    const get = await GET({ params, request } as Parameters<typeof GET>[0]);
    const head = await HEAD({ params, request: new Request(request.url, { method: 'HEAD' }) } as Parameters<typeof HEAD>[0]);
    assert.equal(get.status, 404);
    assert.equal(head.status, 404);
    assert.equal(await head.text(), '');
    assert.equal(head.headers.get('Content-Type'), 'text/plain; charset=utf-8');
  });
});
