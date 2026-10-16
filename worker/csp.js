// Cloudflare Worker for the Control Center web client.
//
// Decrypted resources use same-origin, memory-only Service Worker capabilities.
// Their URLs change on every connection, but never require a new CSP or a page
// reload. Remote origins are needed only for pre-connect identity probes and
// encrypted direct/relay WebSockets; media stays same-origin.

const CSP = [
    "default-src 'self'",
    // CanvasKit/skwasm WebAssembly + gstatic (Flutter fetches CanvasKit from
    // gstatic by default; self-host CanvasKit to drop that entry).
    "script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com",
    // Flutter injects inline <style>.
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    // Audio/video use the same-origin encrypted-resource facade.
    "media-src 'self'",
    // CanvasKit downloads its Noto fallback fonts — including Noto Color Emoji,
    // used for ANY glyph the bundled Manrope/Fira Code don't cover (every emoji,
    // plus CJK/etc.) — from fonts.gstatic.com via the CSS Font Loading API
    // (`new FontFace(family, "url(https://fonts.gstatic.com/s/...)")`). Those
    // requests have destination `font`, so they are governed by font-src, NOT
    // connect-src. Without this entry emoji render as tofu (▢) on the deployed,
    // CSP'd app while working locally (where no CSP applies). The bundled app
    // fonts load the same way from 'self'; `data:` covers inline font blobs.
    //
    // User-selected fonts arrive through the same-origin resource facade and
    // register from bytes rather than fetching a remote FontFace URL.
    "font-src 'self' data: https://fonts.gstatic.com",
    // The server address is unknown at page load. Identity probes need HTTPS
    // (or plaintext loopback); encrypted sessions use direct/relay WebSockets.
    "connect-src 'self' ws: wss: https: http://localhost:* http://127.0.0.1:* https://www.gstatic.com https://fonts.gstatic.com",
    "worker-src 'self' blob:",
    "manifest-src 'self'",
    "object-src 'none'",
    // 'self' (not 'none'): Flutter ships a same-origin <base href> in
    // index.html, so 'none' emits a harmless-but-noisy violation. 'self' still
    // blocks an off-origin <base> injection (the real attack).
    "base-uri 'self'",
    "frame-src 'self'",
    "frame-ancestors 'none'",
    "form-action 'none'",
  ].join("; ");

/// Entry files must always revalidate or a cached index.html / bootstrap /
/// service worker can pin an old bundle after a deploy (Flutter's main.dart.js
/// is not content-hashed, so the service worker owns versioning).
const NO_CACHE_PATHS = new Set([
  "/index.html",
  "/flutter_bootstrap.js",
  "/flutter_service_worker.js",
  "/cc_resource_bridge.js",
  "/cc_resource_worker.js",
  "/cc_resource_ws_shim.js",
  "/manifest.json",
  "/deploy.json",
]);

export default {
  async fetch(request, env) {
    const response = await env.ASSETS.fetch(request);
    const headers = new Headers(response.headers);
    headers.set("Content-Security-Policy", CSP);
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
