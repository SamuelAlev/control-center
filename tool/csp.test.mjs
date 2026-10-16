import assert from 'node:assert/strict';
import {test} from 'node:test';
import worker from '../worker/csp.js';

async function responseFor(cookie = '') {
  const request = new Request('https://app.example/index.html', {
    headers: cookie ? {cookie} : {},
  });
  return worker.fetch(request, {
    ASSETS: {fetch: async () => new Response('<html></html>', {
      headers: {'Content-Type': 'text/html'},
    })},
  });
}

function directives(response) {
  return new Map(response.headers.get('Content-Security-Policy')
    .split(';').map(value => {
      const [name, ...sources] = value.trim().split(/\s+/);
      return [name, sources];
    }));
}

test('remembered proxy cookies cannot authorize off-origin decrypted media', async () => {
  const response = await responseFor(
    `cc_proxy_origin=${encodeURIComponent('https://foreign.example:9030')}`,
  );
  const policy = directives(response);
  assert.deepEqual(policy.get('media-src'), ["'self'"]);
  assert.ok(policy.get('img-src').includes("'self'"));
  assert.ok(!policy.get('img-src').some(source => source.startsWith('http')));
  assert.ok(!response.headers.get('Content-Security-Policy').includes('foreign.example'));
});

test('a fresh page permits encrypted session bootstrap and same-origin resource workers', async () => {
  const policy = directives(await responseFor());
  const connect = policy.get('connect-src');
  assert.ok(connect.includes("'self'"));
  assert.ok(connect.includes('wss:'));
  assert.ok(connect.includes('ws:'));
  assert.ok(connect.includes('https:'));
  assert.ok(connect.includes('http://localhost:*'));
  assert.ok(connect.includes('http://127.0.0.1:*'));
  assert.ok(!connect.includes('http:'));
  assert.ok(policy.get('worker-src').includes("'self'"));
  assert.ok(policy.get('frame-src').includes("'self'"));
  assert.ok(policy.get('font-src').includes("'self'"));
  assert.ok(policy.get('font-src').includes('https://fonts.gstatic.com'));
});
