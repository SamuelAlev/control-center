'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

function worker() {
  const handlers = new Map();
  const notifications = [];
  const opened = [];
  const source = fs.readFileSync(path.join(__dirname, '../web/cc_push_worker.js'), 'utf8');
  const scope = {
    URL, self: {
      location: { origin: 'https://app.example.test' },
      registration: { showNotification: async (title, options) => {
        notifications.push({ title, options });
      } },
      clients: {
        matchAll: async () => [],
        openWindow: async (url) => { opened.push(url); },
      },
      addEventListener: (event, handler) => handlers.set(event, handler),
    },
  };
  vm.runInNewContext(source, scope, { filename: 'cc_push_worker.js' });
  const fire = async (kind, event) => {
    let pending;
    handlers.get(kind)({ ...event, waitUntil: (promise) => { pending = promise; } });
    await pending;
  };
  return { fire, notifications, opened };
}

test('background push shows only generic brand and opaque route', async () => {
  const w = worker();
  const route = '/spaces/space-1?workspace_id=ws-1&conversation_id=convo-1&message_id=msg-1';
  await w.fire('push', { data: { json: () => ({ v: 1, route, kind: 'attention',
    body: 'secret command and credential', title: 'private repo' }) } });
  assert.equal(w.notifications.length, 1);
  assert.equal(w.notifications[0].title, 'Control Center');
  assert.equal(w.notifications[0].options.body, undefined);
  assert.equal(JSON.stringify(w.notifications[0]).includes('secret command'), false);
  await w.fire('notificationclick', { notification: {
    data: { route }, close() {},
  } });
  assert.deepEqual(w.opened, [`https://app.example.test${route}`]);
});

test('worker rejects cross-origin redirects and unknown paths on both paths', async () => {
  const bad = [
    '//evil.test/inbox?workspace_id=ws-1',
    '/%2f%2fevil.test?workspace_id=ws-1',
    'https://evil.test/inbox?workspace_id=ws-1',
    '/inbox?workspace_id=ws-1&next=https://evil.test',
    '/inbox?workspace_id=ws-1&workspace_id=ws-2',
    '/spaces/%2fadmin?workspace_id=ws-1',
    '/settings?workspace_id=ws-1',
  ];
  const w = worker();
  for (const route of bad) {
    await w.fire('push', { data: { json: () => ({ v: 1, route, kind: 'activity' }) } });
    await w.fire('notificationclick', { notification: { data: { route }, close() {} } });
  }
  assert.equal(w.notifications.length, 0);
  assert.equal(w.opened.length, 0);
});
