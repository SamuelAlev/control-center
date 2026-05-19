/// What a browser rig shows and may reach by default.
///
/// A browser rig used to boot to `about:blank` with an empty egress
/// allowlist — a bare white rectangle with no way to tell "working, showing
/// nothing" from "broken". The fix was to point it at the product site
/// (`https://usectrl.dev`), but that reintroduced the same white screen for a
/// different reason: the site is behind a CDN (Cloudflare, IPv6) and smolvm's
/// `--allow-host` pins the IPs resolved at VM start, so a rotated CDN IP is
/// refused by the egress gate and the navigation silently fails — the rig
/// reports "Ready", the stream connects, and the page is blank. Depending on
/// an EXTERNAL site rendering behind a deny-by-default egress gate is
/// inherently fragile.
///
/// So the boot page is now a SELF-CONTAINED local page served from inside the
/// guest ([kBrowserRigHomeHtml]). It always renders, needs zero egress, and
/// gives an immediate "this is a working enclosed browser" signal. Navigating
/// anywhere real is then an explicit action with an explicit allowlist.
///
/// In the DOMAIN (not `cc_infra`) because two independent callers open
/// browser rigs — the `rig.open` RPC op and the `browser_use` MCP tool — and
/// when the default lived infra-side only the RPC path applied it: an
/// agent-opened browser rig booted with egress NOTHING and every navigation
/// was refused while the tool's description promised browsing.
library;

/// Where the local welcome page is written inside the guest, and the URL the
/// browser boots to. `/tmp` is tmpfs and always writable in the headless
/// image; `file://` needs no egress and no DNS.
const String kBrowserRigHomePath = '/tmp/cc-home.html';

/// The `file://` URL the browser rig opens on boot.
const String kBrowserRigHomeUrl = 'file://$kBrowserRigHomePath';

/// The self-contained welcome page. No external assets, no scripts, no fonts —
/// it renders identically with the egress gate fully closed, which is the
/// whole point. Dark by default (the enclosed Chromium has no theme chrome),
/// and it names what the machine is so a connected-but-idle rig is legible.
const String kBrowserRigHomeHtml = '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Enclosed browser</title>
<style>
  :root { color-scheme: dark; }
  html, body { height: 100%; margin: 0; }
  body {
    display: flex; align-items: center; justify-content: center;
    background: #0e0f12; color: #e8e8ea;
    font: 15px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  .card { max-width: 30rem; padding: 2.5rem; text-align: center; }
  .dot {
    display: inline-block; width: .55rem; height: .55rem; border-radius: 50%;
    background: #3fb950; margin-right: .5rem; vertical-align: middle;
  }
  h1 { font-size: 1.35rem; font-weight: 600; margin: 0 0 .5rem; }
  p { color: #9aa0aa; margin: .35rem 0; }
  code {
    background: #1b1d22; color: #cdd3dc; padding: .1rem .4rem;
    border-radius: .3rem; font-size: .85em;
  }
</style>
</head>
<body>
  <div class="card">
    <p><span class="dot"></span>Enclosed browser ready</p>
    <h1>A disposable browser, isolated from your machine</h1>
    <p>Nothing here touches the host. Navigate with the address bar or an
    agent's <code>browser_use</code> tool. Ports opened in the Terminal (VM)
    are reachable here at <code>localhost:&lt;port&gt;</code>.</p>
  </div>
</body>
</html>
''';

/// The egress allowlist for a browser rig.
///
/// The home page is local now, so the boot no longer depends on this. It still
/// admits the product's own site so an agent (or a person) that navigates to
/// it works out of the box; everything else stays refused until a caller
/// passes its own allowlist — a browser rig is an enclosure first and a
/// browser second. smolvm's host entries match subdomains, so the apex also
/// admits `app.usectrl.dev` / `remote.usectrl.dev`.
List<String> browserRigEgressAllowlist() => const ['usectrl.dev'];
