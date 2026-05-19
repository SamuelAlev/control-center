// Cloudflare Worker for the Control Center WEB CLIENT.
//
// The web client is a thin client served here as static assets; it dials a
// cc-server whose host the user types into the connect form. That host is only
// known AFTER the page has loaded, so a static Content-Security-Policy cannot
// name it. This Worker runs first on every request (wrangler.jsonc
// `run_worker_first`), serves the asset through the ASSETS binding and stamps a
// per-request CSP that adds the connected cc-server origin — read from the
// `cc_proxy_origin` cookie the client writes on a successful connect — to
// `connect-src` + `img-src` + `media-src`. With no cookie (a fresh page load,
// before any host is connected) `img-src`/`media-src` stay strict, so an
// unpaired page renders no remote media. `connect-src` cannot be cookie-scoped
// the same way: the pre-connect `/healthz` probes and the invite POST happen
// before any cookie exists (see buildCsp).
//
// Why a header and not a `<meta>`: a `<meta http-equiv="Content-Security-Policy">`
// can only ever tighten the header policy, never relax it and JS-injected meta
// CSP tags are ignored by browsers anyway. So the only reliable place to add the
// host is the HTTP response header, which means a Worker.
//
// The cookie holds ONLY the cc-server origin (scheme + host + port) — never the
// pairing key (that stays in the browser's secure storage) — so it is not
// sensitive. A tampered cookie can at most widen one's OWN page's CSP for the
// proxy fetch, which the already-broad `wss:` socket already permits; and the
// value is parsed through `new URL().origin`, so it cannot smuggle extra CSP
// directives (`;`, quotes, etc. are rejected).

const COOKIE_NAME = "cc_proxy_origin";

/// Builds the CSP. `origin` is '' (pre-connect → no remote media) or a
/// validated absolute http(s) origin (e.g. 'https://cc.example.com:9030') added
/// to `connect-src` + `img-src` + `media-src` so CanvasKit's `fetch()` to
/// `/proxy/image` (governed by `connect-src`, not `img-src`), the `<img>` src,
/// and the `<audio>`/`<video>` src all resolve.
function buildCsp(origin) {
  const proxy = origin ? ` ${origin}` : "";
  return [
    "default-src 'self'",
    // CanvasKit/skwasm WebAssembly + gstatic (Flutter fetches CanvasKit from
    // gstatic by default; self-host CanvasKit to drop that entry).
    "script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com",
    // Flutter injects inline <style>.
    "style-src 'self' 'unsafe-inline'",
    `img-src 'self' data: blob:${proxy}`,
    // Audio and video are a SEPARATE directive from both img-src and
    // connect-src and omitting it falls back to `default-src 'self'` — which
    // silently blocks every remote-media surface on the web client, because all
    // three load through a real <audio>/<video> element on the paired host:
    // the soundscape stream (`/soundscape/stream`), meeting playback
    // (`/meeting/audio`) and proxied video attachments (`/proxy/media`, played
    // by video_player_web). Nothing throws — the player just never starts, so
    // the symptom is silence with a console violation.
    //
    // Cookie-scoped like img-src rather than broad like connect-src: media only
    // ever plays AFTER a successful connect, so unlike the pre-connect
    // `/healthz` probes there is no chicken-and-egg to break. `blob:`/`data:`
    // are deliberately absent — no client surface plays media from memory.
    `media-src 'self'${proxy}`,
    // CanvasKit downloads its Noto fallback fonts — including Noto Color Emoji,
    // used for ANY glyph the bundled Manrope/Fira Code don't cover (every emoji,
    // plus CJK/etc.) — from fonts.gstatic.com via the CSS Font Loading API
    // (`new FontFace(family, "url(https://fonts.gstatic.com/s/...)")`). Those
    // requests have destination `font`, so they are governed by font-src, NOT
    // connect-src. Without this entry emoji render as tofu (▢) on the deployed,
    // CSP'd app while working locally (where no CSP applies). The bundled app
    // fonts load the same way from 'self'; `data:` covers inline font blobs.
    //
    // A USER-SELECTED font needs nothing here, which is not obvious: those
    // families are fetched from the cc-server (`/proxy/font`) with an XHR, so
    // they are `connect-src` and `CcFontRegistry` then hands the BYTES to
    // Flutter's FontLoader — which constructs `new FontFace(family, Uint8List)`.
    // A FontFace built from a buffer performs no fetch, so no directive governs
    // it. Do not widen font-src for the font picker; it would grant nothing.
    "font-src 'self' data: https://fonts.gstatic.com",
    // `ws:`/`wss:` stay broad so the connect form can dial any host the user
    // types (the host is unknown until they connect).
    //
    // The HTTP schemes must be equally broad, because connecting is not only a
    // socket: `GET <server>/healthz` (identity probe + the resolver's per-path
    // reachability probe) and the invite redemption POST all run BEFORE the
    // socket, so the cc_proxy_origin cookie — written only on a SUCCESSFUL
    // connect — cannot gate them. Scoping them to the cookie deadlocks first
    // pairing: no probe, no connect; no connect, no cookie. Plaintext is
    // limited to loopback, mirroring the app's own TLS-or-loopback invariant
    // (`TransportSecurityPolicy`) — that is the local-dev case where the page
    // and the cc-server share a machine. This costs little: `wss:` already
    // permits egress to an arbitrary host, so a foothold is not newly enabled.
    //
    // This is also the lane a user-selected font's bytes ride: `/proxy/font` on
    // the connected cc-server, reached with an XHR (see font-src above). So
    // tightening the HTTP schemes here silently stops the font picker working,
    // not just remote media.
    //
    // www.gstatic.com (CanvasKit's wasm, fetched at STARTUP via fetch() →
    // connect-src) and fonts.gstatic.com (the engine's fallback-font index
    // probe; the font BYTES go through font-src above) are subsumed by `https:`
    // but stay named, so tightening `https:` later cannot silently break
    // startup. The paired origin is still layered on from the cookie — it is
    // what admits an `--insecure` plaintext LAN server, which the
    // loopback-only entries deliberately do not cover.
    `connect-src 'self' ws: wss: https: http://localhost:* http://127.0.0.1:* https://www.gstatic.com https://fonts.gstatic.com${proxy}`,
    "worker-src 'self' blob:",
    "manifest-src 'self'",
    "object-src 'none'",
    // 'self' (not 'none'): Flutter ships a same-origin <base href> in
    // index.html, so 'none' emits a harmless-but-noisy violation. 'self' still
    // blocks an off-origin <base> injection (the real attack).
    "base-uri 'self'",
    "frame-ancestors 'none'",
    "form-action 'none'",
  ].join("; ");
}

/// Parses the `cc_proxy_origin` cookie into a sanitized http(s) origin, or ''
/// when absent/invalid. Only an absolute http(s) URL is accepted and only its
/// `.origin` is returned, so a malicious value can never inject CSP syntax.
function readProxyOrigin(cookieHeader) {
  if (!cookieHeader) {
    return "";
  }
  for (const part of cookieHeader.split(/;\s*/)) {
    const eq = part.indexOf("=");
    if (eq < 0) {
      continue;
    }
    if (part.slice(0, eq).trim() !== COOKIE_NAME) {
      continue;
    }
    let value = part.slice(eq + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.slice(1, -1);
    }
    try {
      value = decodeURIComponent(value);
    } catch (_) {
      return "";
    }
    let url;
    try {
      url = new URL(value);
    } catch (_) {
      return "";
    }
    if ((url.protocol === "https:" || url.protocol === "http:") && url.host) {
      return url.origin;
    }
    return "";
  }
  return "";
}

/// Entry files must always revalidate or a cached index.html / bootstrap /
/// service worker can pin an old bundle after a deploy (Flutter's main.dart.js
/// is not content-hashed, so the service worker owns versioning).
const NO_CACHE_PATHS = new Set([
  "/index.html",
  "/flutter_bootstrap.js",
  "/flutter_service_worker.js",
  "/manifest.json",
  "/deploy.json",
]);

export default {
  async fetch(request, env) {
    const response = await env.ASSETS.fetch(request);
    const headers = new Headers(response.headers);
    headers.set(
      "Content-Security-Policy",
      buildCsp(readProxyOrigin(request.headers.get("cookie") || "")),
    );
    // `_headers` may not propagate to ASSETS subresponses when
    // `run_worker_first` is on, so re-assert the static security posture here.
    headers.set("X-Content-Type-Options", "nosniff");
    headers.set("Referrer-Policy", "no-referrer");
    // `microphone` + `display-capture` are enabled for self so the web meeting
    // recorder can `getUserMedia` the mic and `getDisplayMedia` system audio.
    headers.set(
      "Permissions-Policy",
      "camera=(), microphone=(self), display-capture=(self), geolocation=(), payment=(), usb=(), accelerometer=(), gyroscope=(), magnetometer=()",
    );
    // COOP + COEP make the page cross-origin isolated, which lets SkWasm use
    // SharedArrayBuffer and move rendering onto its worker. `credentialless`
    // preserves unsigned cross-origin resources without cookies; the app's
    // iframe seam opts into the matching credentialless browsing context.
    headers.set("Cross-Origin-Opener-Policy", "same-origin");
    headers.set("Cross-Origin-Embedder-Policy", "credentialless");
    if (NO_CACHE_PATHS.has(new URL(request.url).pathname)) {
      headers.set("Cache-Control", "no-cache");
    }
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  },
};
