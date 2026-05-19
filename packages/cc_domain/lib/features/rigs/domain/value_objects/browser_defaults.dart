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
/// guest ([browserRigHomeHtml]). It always renders, needs zero egress, and
/// gives an immediate "this is a working enclosed browser" signal. Navigating
/// anywhere real is then an explicit action with an explicit allowlist.
///
/// In the DOMAIN (not `cc_infra`) because two independent callers open
/// browser rigs — the `rig.open` RPC op and the `browser_use` MCP tool — and
/// when the default lived infra-side only the RPC path applied it: an
/// agent-opened browser rig booted with egress NOTHING and every navigation
/// was refused while the tool's description promised browsing.
library;

import 'package:cc_domain/features/rigs/domain/value_objects/browser_engine_marks.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';

/// Where the local welcome page is written inside the guest, and the URL the
/// browser boots to. `/tmp` is tmpfs and always writable in the headless
/// image; `file://` needs no egress and no DNS.
const String kBrowserRigHomePath = '/tmp/cc-home.html';

/// The `file://` URL the browser rig opens on boot.
const String kBrowserRigHomeUrl = 'file://$kBrowserRigHomePath';

/// The `server_settings` key remembering the last home-page theme a client
/// named on `rig.open`. An agent-opened rig (the `browser_use` tool carries
/// no client theme) then follows the theme the human's app last used instead
/// of the page's static default.
const String kRigHomeThemeSettingKey = 'rig_home_theme';

/// The color scheme of a browser rig's self-hosted home page.
///
/// The page is written into the guest at boot, so the scheme travels with the
/// open call: a dark page inside a light app (or the reverse) reads as a bug,
/// not a mood. An open that names no theme falls back server-side to the last
/// theme any client named, then to dark — the historical look.
enum RigBrowserHomeTheme {
  /// Light page.
  light('light'),

  /// Dark page.
  dark('dark');

  const RigBrowserHomeTheme(this.wire);

  /// Stable wire/storage string.
  final String wire;

  /// Parses [value] back into a theme, or null when unknown.
  static RigBrowserHomeTheme? fromWire(String? value) {
    for (final t in RigBrowserHomeTheme.values) {
      if (t.wire == value) {
        return t;
      }
    }
    return null;
  }
}

/// The self-contained welcome page — the rig's "new tab" — for [engine].
///
/// Per engine, not shared: a conversation holds one rig PER engine because
/// the engines are the things being compared, so the first thing a tab shows
/// must say WHICH browser it is. The page says just that — the engine's mark,
/// its name and that the machine is connected — plus one concrete example of
/// what the enclosure is for. The logos are inline SVG (the Chromium wheel
/// drawn from its published geometry, the WebKit slab-stack from the
/// project's own 2015 mark, the Firefox flame from the CC0 Simple Icons set)
/// precisely so the page stays self-contained: no external assets, no
/// scripts, no fonts — it renders identically with the egress gate fully
/// closed, which is the whole point.
///
/// [theme] follows the opening app's brightness; the engine-tinted glow rides
/// both schemes.
String browserRigHomeHtml(
  RigBrowserEngine engine, {
  RigBrowserHomeTheme? theme,
}) {
  final logo = browserRigEngineMark(engine);
  final accent = switch (engine) {
    RigBrowserEngine.chromium => '#4e8bf5',
    RigBrowserEngine.firefox => '#ff980e',
    RigBrowserEngine.webkit => '#dfb041',
  };
  final light = theme == RigBrowserHomeTheme.light;
  final (scheme, background, glow, foreground, muted) = light
      ? ('light', '#f7f7f5', '${accent}29', '#1b1c1e', '#5d6169')
      : ('dark', '#0e0f12', '${accent}21', '#e8e8ea', '#9aa0aa');
  return '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Enclosed ${engine.label}</title>
<style>
  :root { color-scheme: $scheme; }
  html, body { height: 100%; margin: 0; }
  body {
    display: flex; align-items: center; justify-content: center;
    background: radial-gradient(42rem 26rem at 50% 32%, $glow, transparent 70%), $background;
    color: $foreground;
    font: 15px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  .card { max-width: 30rem; padding: 2.5rem; text-align: center; }
  .logo { width: 64px; height: 64px; margin: 0 auto 1.25rem; }
  .logo svg { width: 100%; height: 100%; display: block; }
  h1 { font-size: 1.35rem; font-weight: 600; margin: 0 0 .35rem; }
  .status { margin: 0 0 1rem; color: $muted; font-size: .95rem; }
  .dot {
    display: inline-block; width: .55rem; height: .55rem; border-radius: 50%;
    background: #3fb950; margin-right: .5rem; vertical-align: middle;
  }
  .hint { color: $muted; margin: 0; }
</style>
</head>
<body>
  <div class="card">
    <div class="logo">$logo</div>
    <h1>${engine.label}</h1>
    <p class="status"><span class="dot"></span>Connected</p>
    <p class="hint">Ask an agent to open a page, fill a form or take a
    screenshot here — or run the same page in another engine and compare
    them side by side.</p>
  </div>
</body>
</html>
''';
}

/// The full-color mark of [engine], as a self-contained inline `<svg>`
/// fragment (no `xmlns`, no external references).
///
/// One source of truth for two surfaces that must agree: the guest's own
/// new-tab page ([browserRigHomeHtml]) and the client's boot screen, which
/// breathes this same mark while the machine comes up — so the boot animation
/// settles into an identical mark on the page the browser opens to.
///
/// The artwork itself lives in `assets/browser_logos/<engine>_color.svg`,
/// where a designer can open it; `tool/gen_browser_marks.dart` bakes it into
/// the consts below because a page written INSIDE a VM cannot read a Flutter
/// asset. Edit the SVG, re-run the generator — never edit the generated file.
String browserRigEngineMark(RigBrowserEngine engine) => switch (engine) {
  RigBrowserEngine.chromium => chromiumEngineMark,
  RigBrowserEngine.firefox => firefoxEngineMark,
  RigBrowserEngine.webkit => webkitEngineMark,
};

/// The egress allowlist for a browser rig.
///
/// The home page is local now, so the boot no longer depends on this. It still
/// admits the product's own site so an agent (or a person) that navigates to
/// it works out of the box; everything else stays refused until a caller
/// passes its own allowlist — a browser rig is an enclosure first and a
/// browser second. smolvm's host entries match subdomains, so the apex also
/// admits `app.usectrl.dev` / `remote.usectrl.dev`.
List<String> browserRigEgressAllowlist() => const ['usectrl.dev'];
