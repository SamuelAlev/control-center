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
    '/goals/goal-1?workspace_id=ws-1&conversation_id=c-1',
    '/goals/goal-1/edit?workspace_id=ws-1',
    '/goals/%2e%2e?workspace_id=ws-1',
    '/goals/goal-1',
    '/schedules/rule-1?workspace_id=ws-1&next=https://evil.test',
    '/schedules/a.b?workspace_id=ws-1',
    '/activity?workspace_id=ws-1&message_id=m-1',
    '/activity/x?workspace_id=ws-1',
    '/goals?workspace_id=ws-1',
  ];
  const w = worker();
  for (const route of bad) {
    await w.fire('push', { data: { json: () => ({ v: 1, route, kind: 'activity' }) } });
    await w.fire('notificationclick', { notification: { data: { route }, close() {} } });
  }
  assert.equal(w.notifications.length, 0);
  assert.equal(w.opened.length, 0);
});

test('goal, schedule and activity routes open with only the workspace', async () => {
  const routes = [
    '/goals/goal-1?workspace_id=ws-1',
    '/schedules/rule_2?workspace_id=ws-1',
    '/activity?workspace_id=ws-1',
  ];
  const w = worker();
  for (const route of routes) {
    await w.fire('push', { data: { json: () => ({ v: 1, route, kind: 'activity' }) } });
    await w.fire('notificationclick', { notification: { data: { route }, close() {} } });
  }
  assert.equal(w.notifications.length, 3);
  assert.deepEqual(w.opened, routes.map((r) => `https://app.example.test${r}`));
});

test('only a quiet push is silent: a new message sounds, a finished goal '
  + 'does not', async () => {
  const w = worker();
  // A message_received push: notify, not quiet.
  await w.fire('push', { data: { json: () => ({ v: 1,
    route: '/spaces/sp-1?workspace_id=ws-1', kind: 'activity',
    notification_kind: 'notify', quiet: false }) } });
  // A terminal goal_settled push: notify and quiet.
  await w.fire('push', { data: { json: () => ({ v: 1,
    route: '/goals/goal-1?workspace_id=ws-1', kind: 'activity',
    notification_kind: 'notify', quiet: true }) } });
  // No quiet field (an older server): sounds, whatever the kind.
  await w.fire('push', { data: { json: () => ({ v: 1,
    route: '/inbox?workspace_id=ws-1', kind: 'activity',
    notification_kind: 'notify' }) } });
  // Anything but a boolean true is not quiet.
  await w.fire('push', { data: { json: () => ({ v: 1,
    route: '/inbox?workspace_id=ws-1', kind: 'activity', quiet: 'true' }) } });
  assert.deepEqual(w.notifications.map((n) => n.options.silent),
    [false, true, false, false]);
  // A quiet one never takes the place of one that still needs the person:
  // it is shown under a tag of its own.
  assert.deepEqual(w.notifications.map((n) => n.options.tag),
    ['cc-background-update', 'cc-background-quiet', 'cc-background-update',
      'cc-background-update']);
});
