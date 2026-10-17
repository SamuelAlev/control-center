'use strict';

// Push payloads are intentionally devoid of project content, credentials and
// commands. This independent worker remains alive when Flutter/PWA is closed.
// Never import the Flutter worker: neither one owns the other's lifecycle.
function safeRoute(route) {
  if (typeof route !== 'string' || !route.startsWith('/') ||
      route.startsWith('//') || route.length > 900 || route.includes('\\')) return null;
  let parsed;
  try { parsed = new URL(route, self.location.origin); } catch (_) { return null; }
  if (parsed.origin !== self.location.origin || parsed.hash ||
      parsed.username || parsed.password) return null;
  const segments = parsed.pathname.split('/').slice(1);
  const allowedPath = parsed.pathname === '/inbox' ||
      (segments.length === 2 && segments[0] === 'spaces' &&
       /^[a-zA-Z0-9_-]{1,128}$/.test(segments[1]));
  if (!allowedPath) return null;
  const keys = [...parsed.searchParams.keys()];
  if (!parsed.searchParams.has('workspace_id') ||
      !parsed.searchParams.get('workspace_id') ||
      keys.some((key) => !['workspace_id', 'conversation_id', 'message_id'].includes(key) ||
          parsed.searchParams.getAll(key).length !== 1)) return null;
  if (parsed.pathname === '/inbox' && keys.some((key) => key !== 'workspace_id')) return null;
  if (keys.some((key) => (parsed.searchParams.get(key) || '').length > 128)) return null;
  return parsed.pathname + parsed.search;
}

self.addEventListener('push', (event) => {
  event.waitUntil((async () => {
    let data;
    try { data = event.data && event.data.json(); } catch (_) { return; }
    if (!data || data.v !== 1) return;
    const route = safeRoute(data.route);
    if (!route || !['attention', 'activity'].includes(data.kind)) return;
    await self.registration.showNotification('Control Center', {
      // No notification text that needs a locale or exposes a workspace.
      tag: 'cc-background-update',
      data: { route },
    });
  })());
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const route = safeRoute(event.notification.data && event.notification.data.route);
    if (!route) return;
    const target = new URL(route, self.location.origin).href;
    const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const window of windows) {
      if (new URL(window.url).origin !== self.location.origin) continue;
      if ('navigate' in window) {
        const navigated = await window.navigate(target);
        if (navigated) { await navigated.focus(); return; }
      }
    }
    await self.clients.openWindow(target);
  })());
});
