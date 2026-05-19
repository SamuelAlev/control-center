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
  pr_providers.dart         forge identity, open-PR snapshot, classified inbox
  calendar_providers.dart   agenda window, accounts, day grouping
  media_proxy.dart          signed /workspace/logo + /proxy/media URLs
  format.dart               relative time, clock, duration, churn
  external_link.dart        window.open with noopener (forge / article links)
  pairing/ pairing_store.dart (PairingRecord + IndexedDB + fragment consume)
  screens/ connect, workspace_switcher, inbox, tickets, messaging, pr (+detail),
           calendar (+event detail), newsfeed, settings
  widgets/ app_shell (header + banners + bottom tabs), connection_chip,
           pr_row, workspace_avatar, phone_markdown
web/ index.html, manifest.json (PWA), icons/
wrangler.jsonc             Cloudflare Pages SPA config
```

## Destinations

Six bottom tabs, in order: **Inbox** (blocked agents + the classified PR
sections — the landing route), **Tickets**, **Chat**, **PRs**, **Calendar**,
**News**. The bar divides the width evenly when every tab clears its readable
floor and scrolls horizontally when it cannot, rather than ellipsising labels
on a narrow phone.

The PR screen renders the real diff: each changed file expands to its unified
patch, parsed by `parseUnifiedDiff` from the shared kernel — the SAME function
the desktop viewer runs, so line numbering and hunk handling cannot drift
between the two clients. Three deliberate shapes:

- **Unified, never side-by-side.** A 44-character column cannot hold two
  columns of code.
- **Collapsed by default, and row-budgeted.** The file sections live inside the
  PR screen's own scroll view, so every row is built eagerly — a PR touching
  twenty files, or one lockfile with 30k lines, would otherwise be built before
  the reader looks at anything. The budget is `kDiffRowBudget`, and the "show
  the remaining N lines" affordance says exactly what is withheld.
- **No syntax highlighting.** The highlighter is a ~250-grammar TextMate
  registry the desktop tokenizes in a worker; downloading it into the most
  bandwidth-sensitive tier to colour a few changed lines is a bad trade. The
  +/− marker is a *character*, the gutter carries the numbers, and the row tint
  is third — so the diff still reads in greyscale.

What the phone still does NOT do, and why:

- **No inline commenting.** Anchoring a thread to a line needs a target you can
  hit precisely and a composer that does not cover the code it is about.
  Deciding (approve / request changes / comment / merge) IS portable and is all
  here.
- **No calendar grid.** The desktop calendar is a planning surface; the phone
  answers "what is next, where, what's the join link", so it renders an agenda
  with an up-next card.
- **No account connecting.** Forge and calendar OAuth store their tokens
  server-side and are driven from the desktop. The phone says so explicitly
  rather than rendering an empty week or an empty PR queue that reads as "all
  clear".

## Images, and why the logo goes over RPC

An HTTPS-served PWA cannot open a plaintext `ws://` LAN socket, so the phone's
normal route to the server is the **broker relay** — which carries JSON-RPC
frames and has no HTTP origin at all (`RelayPath.probeUri` is null). Every
signed media URL (`/workspace/logo`, `/proxy/media`) is therefore unbuildable
on the tier those URLs were written for.

So the **workspace logo** rides the RPC channel instead (`workspace.logo` →
base64 bytes, capped at 2 MB server-side, cached per workspace for the
session). It is one small identity-carrying mark per workspace, and it is the
difference between the switcher showing the workspace and showing a letter.
**Forge avatars** stay on the `/proxy/media` HTTP lane and degrade to monograms
on a relayed session: a PR list holds dozens of 22px faces, which is not worth
a base64 frame each.

Every workspace-scoped stream passes its `workspace_id` EXPLICITLY and watches
`activeWorkspaceIdProvider`. Both halves are required: `RemoteRpcClient` injects
its ambient workspace only into args that do not already name one, and a
subscription captures its args once — so a stream opened before a workspace
switch keeps re-registering with the old workspace for the rest of the session.
