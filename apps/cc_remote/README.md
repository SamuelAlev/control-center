# cc_remote

Control Center phone client — a Flutter **web PWA** that remote-controls a
`cc_server` over the best reachable path, carrying JSON-RPC.

The phone is a **thin client**: it only renders UI and speaks JSON-RPC.
`cc_server` stays the single source of truth — the phone never runs the
database, repositories, or a server.

## Architecture

```
PHONE (this PWA)                              cc_server
 PairingStore (IndexedDB) ────┐
   descriptor + deviceId +    ▼
   psk + TOFU fingerprint   RemoteSession (app_connection.dart)
                              ▼
 cc_rpc ServerConnectionSupervisor
   └ ReachabilityResolver: probes every descriptor path in parallel
     (LAN / tailnet / wss / broker relay) and connects the best one ──► /rpc
   └ PSK auth + Ed25519 identity verify (TOFU pin) — mismatch is terminal
   └ health pings + auto-reconnect + descriptor refresh (connection.describe)
                              ▼
 cc_rpc ResilientRpcClient — ONE stable client; subscriptions survive
   reconnects (re-register + fresh snapshot)
                              ▼
 cc_data remote repositories ── repo/call + sub/subscribe ──► server DB/ops
```

- **Connectivity** lives entirely in `package:cc_rpc` (PRD 15). The phone holds
  a `ConnectionDescriptor` — a _set of paths_ plus the server's identity
  fingerprint — and lets the resolver pick loopback/LAN/tailnet/WSS/relay at
  connect time. On web only TLS paths and the broker relay are usable.
- **Pairing** (`lib/pairing/pairing_store.dart`) reads the v2 `PairingPayload`
  (`{v:2, d: descriptor, i: deviceId, k: psk, x: expiry}`, from cc_domain) out
  of the URL fragment, holds it for explicit user confirmation (VULN-004 — a
  forged `#<payload>` must never auto-pair), then persists a `PairingRecord`
  to IndexedDB and strips the fragment so the PSK leaves the URL. The record
  also stores the TOFU-pinned fingerprint (seeded from the QR, updated by the
  supervisor) and is re-saved whenever the server re-publishes its descriptor.
- **Session** (`lib/app_connection.dart`) maps supervisor phases onto the UI
  states (connecting / connected / failed-with-retry / identity-mismatch) and
  owns the initial-connect retry loop, unpair and the persisted
  active-workspace selection. An identity mismatch is a terminal state: the
  UI tells the user to remove the pairing and re-scan — no "continue anyway".
- **Data** flows through the shared `cc_data` remote repositories over the
  stable client; feature providers bind once and survive reconnects.

## Hard constraints honoured

- Web-safe only: no `dart:io`, no native plugins. Connectivity is
  `WebSocketChannel` + the broker relay (both web-safe in cc_rpc).
- Never imports the giant icon class (DDC StackOverflow on web) —
  `lib/app_icons.dart` declares just the needed codepoints.
- Depends only on `cc_ui`, `cc_domain`, `cc_rpc`, `cc_data` from this repo —
  **never** the root `control_center` package.
- Material-free root: `WidgetsApp.router` + `CcTheme` + go_router. No
  `MaterialApp`, `Scaffold`, or `Material`.
- All user-facing strings are sentence case.

## Build & deploy

```sh
fvm flutter build web --release --wasm
```

Deploy the resulting `build/web` to **Cloudflare Pages** via `wrangler` (see
`wrangler.jsonc`, which sets `assets.directory` and the SPA
`not_found_handling: single-page-application` fallback). Cloudflare Pages gives
free auto-HTTPS — required because service workers and IndexedDB are
secure-context-gated.

The desktop encodes this PWA's host as a config constant when building the
pairing QR (a `https://<pwa-host>/#<base64url payload>` deep link).

## Pairing flow

1. In a first-party client: settings → paired clients → pair a phone. The
   server mints a device id + PSK; the QR embeds the v2 payload with the
   server's full connection descriptor.
2. On the phone: scan the QR with the native camera → opens this PWA with the
   payload in the URL fragment.
3. The PWA decodes the offer, asks the user to confirm the server by name
   (VULN-004 gate), persists the record, strips the fragment and connects:
   probe paths → connect best → PSK auth + identity verify → JSON-RPC ready.
4. Reconnects need no re-scan; the descriptor self-refreshes over live
   connections, so rotated tunnel URLs and moved LAN IPs keep working. The
   broker relay is the guaranteed fallback when no direct path is reachable.

## Layout

```
lib/
  main.dart                 WidgetsApp.router + CcTheme; starts the session
  app_router.dart           go_router (shell tabs + full-screen detail routes)
  app_connection.dart       RemoteSession: supervisor glue + UI state stream
  providers.dart            Riverpod providers (session, uiState, rpc client)
  pairing/ pairing_store.dart (PairingRecord + IndexedDB + fragment consume)
  screens/ connect, workspace_switcher, tickets, messaging, newsfeed, settings
  widgets/ app_shell (header + banners + bottom tabs), connection_chip
web/ index.html, manifest.json (PWA), icons/
wrangler.jsonc             Cloudflare Pages SPA config
```
