import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { repoStarCount } from '../src/data/repo-stars.ts';

const github = (body: unknown, status = 200): typeof fetch =>
  (async () => new Response(JSON.stringify(body), { status })) as typeof fetch;

describe('Worker repository star count', () => {
  it('reads the public count with a five-minute edge TTL', async () => {
    let url: string | URL | Request | undefined;
    let options: RequestInit | undefined;
    const fetchRepo = (async (input: string | URL | Request, init?: RequestInit) => {
      url = input;
      options = init;
      return new Response(JSON.stringify({ stargazers_count: 1287, private: false, token: 'not-for-clients' }));
    }) as typeof fetch;
    assert.equal(await repoStarCount(fetchRepo), 1287);
    assert.equal(url, 'https://api.github.com/repos/SamuelAlev/control-center');
    assert.deepEqual((options as RequestInit & { cf: unknown }).cf, {
      cacheEverything: true, cacheTtlByStatus: { '200-299': 300, '400-599': 0 },
    });
  });

  it('accepts zero stars', async () => {
    assert.equal(await repoStarCount(github({ stargazers_count: 0 })), 0);
  });

  it('omits invalid counts and failed GitHub requests', async () => {
    for (const count of [-1, 2.4, Number.MAX_SAFE_INTEGER + 1, null, '200']) {
      assert.equal(await repoStarCount(github({ stargazers_count: count })), null);
    }
    assert.equal(await repoStarCount(github({ message: 'rate limited' }, 403)), null);
    assert.equal(await repoStarCount((async () => new Response('{')) as typeof fetch), null);
    const offline = (async () => { throw new Error('offline'); }) as typeof fetch;
    assert.equal(await repoStarCount(offline), null);
  });
});
