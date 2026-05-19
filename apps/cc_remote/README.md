# cc_remote

Control Center phone client — a Flutter **web PWA** that remote-controls the
desktop app from a phone over a WebRTC DataChannel carrying JSON-RPC.

The phone is a **thin client**: it only renders UI and speaks JSON-RPC. The Mac
stays the single source of truth — every tool call runs through the desktop's
shared `McpToolDispatcher` (the same surface the MCP HTTP server and AI agents
use). The phone never runs the database, repositories, or a server.

## Architecture

```
PHONE (this PWA)                           MAC (existing app)
 PairingStore (IndexedDB) ──┐              RemoteControlServer
                            ▼               └ WebRtcPeerManager (answerer)
 SignalingClient (WebSocket) ◄── handshake only ──►  RemoteRpcSession
                            ▼                        └ shared McpToolDispatcher
 RtcTransport (WebRTC, offerer, DataChannel 'cc')
                            ▼  DTLS-encrypted JSON-RPC
 PskHandshake (PSK over DTLS fingerprints)
                            ▼
 JsonRpcClient ── tools/call, session/* ──► desktop repos / DB
```

- **WebRTC client** (`lib/rtc/rtc_transport.dart`) talks `package:web` +
  `dart:js_interop` directly — **not** `flutter_webrtc` (its native code breaks
  `flutter build web`). The phone is the offerer; the desktop is the answerer.
- **Signaling** (`lib/rtc/signaling_client.dart`) is a browser WebSocket client
  speaking the broker envelope `{type, room?, from?, to?, kind?, payload?}`.
  The broker is a stateless relay; it never sees app data or the PSK.
- **Pairing** (`lib/pairing/pairing_store.dart`) reads the base64url JSON from
  the URL fragment, persists a `PairingRecord` to IndexedDB, requests persistent
  storage, then strips the fragment so the PSK leaves the URL. Later opens
  reconnect from the stored record without re-scanning.
- **Auth** (`lib/auth/psk_handshake.dart`) runs a PSK challenge-response after
  the channel opens, bound to both DTLS fingerprints (HMAC-SHA256, constant-time
  compare). Reimplemented locally to mirror the desktop's `RemoteControlCrypto`
  (no desktop import — that package breaks web).
- **RPC** (`lib/net/json_rpc_client.dart`) is an id-correlated JSON-RPC client
  with exponential-backoff reconnect + workspace resync; server-pushed
  notifications feed a live broadcast stream.

## Hard constraints honoured

- Depends only on `cc_ui` and `cc_domain` from this repo — **never** the root
  `control_center` package (it pulls drift/sqlite3/`window_manager`/`dart:io`).
- Material-free root: `WidgetsApp.router` + `CcTheme` + go_router. No
  `MaterialApp`, `Scaffold`, or `Material`.
- All user-facing strings are sentence case.

## Build & deploy

```sh
flutter build web --release
```

Deploy the resulting `build/web` to **Cloudflare Pages** via `wrangler` (see
`wrangler.jsonc`, which sets `assets.directory` and the SPA
`not_found_handling: single-page-application` fallback). Cloudflare Pages gives
free auto-HTTPS — required because WebRTC, service workers, and IndexedDB are
secure-context-gated.

The desktop encodes this PWA's host as a config constant when building the
pairing QR (a `https://<pwa-host>/#<base64url payload>` deep link).

## Pairing flow

1. On the Mac: enable remote control → "Pair a device" shows a QR containing
   `{v, s:signalingWss, r:room, k:psk, i:appInstanceId, t:[stun], x:expiry}`.
2. On the phone: scan the QR with the native camera → opens this PWA with the
   payload in the URL fragment.
3. The PWA decodes + persists the record, strips the fragment, and connects:
   signaling → WebRTC offer/answer/ICE → PSK handshake → JSON-RPC ready.
4. Reconnects (same Wi-Fi or remote via STUN) need no re-scan.

> STUN-only (no TURN) cannot traverse ~10–20% of strict/symmetric NATs. On
> repeated ICE failure the UI shows "Couldn't connect remotely — try the same
> Wi-Fi as your Mac" and keeps retrying in the background.

## Layout

```
lib/
  main.dart                 WidgetsApp.router + CcTheme; starts the session
  app_router.dart           go_router (shell tabs + full-screen detail routes)
  app_connection.dart       RemoteSession: signaling+WebRTC+handshake glue,
                            UI connection-state stream
  providers.dart            Riverpod providers (session, uiState, router refresh)
  net/   rpc_channel.dart, json_rpc_client.dart
  rtc/   signaling_client.dart, rtc_transport.dart
  pairing/ pairing_store.dart
  auth/  psk_handshake.dart
  screens/ connect, workspace_switcher, tickets, messaging, newsfeed
  widgets/ app_shell (header + bottom tabs), connection_chip
web/ index.html, manifest.json (PWA), icons/
wrangler.jsonc             Cloudflare Pages SPA config
```
