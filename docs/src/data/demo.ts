// The live-demo entry link, shared by every surface that offers it (the hero
// CTA and the nav button) so the fragment is built in exactly one place.
//
// The web client's auto-redeem path reads a URL FRAGMENT naming the demo
// server + invite code, posts `/invites/redeem`, and lands the visitor in a
// furnished workspace — no account, no install. The fragment is built at
// render time; point PUBLIC_DEMO_SERVER at wherever the demo container is
// deployed (default: the demo API subdomain).
//
// This lives apart from `site.ts` because `import.meta.env` is a Vite-only
// global: `site.ts` is also imported by the agentic modules that `node --test`
// loads directly, where reading it would throw.

// The demo deployment of the web client — a separate host from the normal web
// app (WEB_APP_URL in `site.ts`, app.usectrl.dev), which stays where it is and
// connects to your own server rather than the demo one.
export const DEMO_WEB_APP_URL = 'https://demo.usectrl.dev';

export const DEMO_SERVER =
  import.meta.env.PUBLIC_DEMO_SERVER ?? 'wss://demo-api.usectrl.dev/rpc';
export const DEMO_INVITE_CODE = 'demo';
export const DEMO_HREF = `${DEMO_WEB_APP_URL}/#${Buffer.from(
  JSON.stringify({ server: DEMO_SERVER, invite: DEMO_INVITE_CODE }),
).toString('base64url')}`;
