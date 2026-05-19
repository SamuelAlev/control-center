// Cloudflare Worker for the Control Center WEB CLIENT.
//
// The web client is a thin client served here as static assets; it dials a
// cc-server whose host the user types into the connect form. That host is only
// known AFTER the page has loaded, so a static Content-Security-Policy cannot
// name it. This Worker runs first on every request (wrangler.jsonc
// `run_worker_first`), serves the asset through the ASSETS binding, and stamps a
// per-request CSP that adds the connected cc-server origin — read from the
// `cc_proxy_origin` cookie the client writes on a successful connect — to
// `connect-src` + `img-src`. With no cookie (a fresh page load, before any host
// is connected) the policy stays strict: no proxy egress, so a page that hasn't
// been paired yet leaks nothing.
//
// Why a header and not a `<meta>`: a `<meta http-equiv="Content-Security-Policy">`
// can only ever tighten the header policy, never relax it, and JS-injected meta
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

/// Builds the CSP. `origin` is '' (pre-connect → strict, no proxy egress) or a
/// validated absolute http(s) origin (e.g. 'https://cc.example.com:9030') added
/// to `connect-src` + `img-src` so CanvasKit's `fetch()` to `/proxy/image`
/// (governed by `connect-src`, not `img-src`) and the `<img>` src both resolve.
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
    // CanvasKit downloads its Noto fallback fonts — including Noto Color Emoji,
    // used for ANY glyph the bundled Manrope/Fira Code don't cover (every emoji,
    // plus CJK/etc.) — from fonts.gstatic.com via the CSS Font Loading API
    // (`new FontFace(family, "url(https://fonts.gstatic.com/s/...)")`). Those
    // requests have destination `font`, so they are governed by font-src, NOT
    // connect-src. Without this entry emoji render as tofu (▢) on the deployed,
    // CSP'd app while working locally (where no CSP applies). The bundled app
    // fonts load the same way from 'self'; `data:` covers inline font blobs.
    "font-src 'self' data: https://fonts.gstatic.com",
    // `ws:`/`wss:` stay broad so the connect form can dial any host the user
    // types (the host is unknown until they connect). www.gstatic.com serves
    // CanvasKit's wasm (fetched at STARTUP via fetch() → connect-src);
    // fonts.gstatic.com is kept here too for the engine's fallback-font index
    // probe, but the font BYTES are fetched through font-src above. The
    // connected cc-server origin is layered on top once a host is paired (the
    // only proxy egress allowed).
    `connect-src 'self' ws: wss: https://www.gstatic.com https://fonts.gstatic.com${proxy}`,
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
/// when absent/invalid. Only an absolute http(s) URL is accepted, and only its
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
    headers.set("Cross-Origin-Opener-Policy", "same-origin");
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
