# cc_remote

Phone web PWA that renders server-owned state over JSON-RPC. It runs no database or repositories locally. [`cc_rpc`](../../packages/cc_rpc/README.md) resolves a v2 `ConnectionDescriptor` across reachable paths (LAN, tailnet, WSS or broker relay), handles PSK authentication and TOFU identity verification, and maintains one resilient RPC client whose subscriptions re-register with fresh snapshots after reconnect. In a browser, only TLS-compatible paths and the relay are usable. [`cc_data`](../../packages/cc_data/README.md) supplies the remote repositories.

```sh
# from apps/cc_remote
fvm flutter build web --release --wasm --enable-wasm-deferred-loading
node ../../tool/stage_resource_assets.mjs build/web
```

Run `fvm flutter test --concurrency=2` for the VM suite (including filesystem boundary checks). Folder interactions and approval scrolling require a browser: `fvm flutter test --platform chrome test/space_folders_test.dart test/space_folders_widget_test.dart test/approval_surface_test.dart --concurrency=2`. The filesystem checks in `material_free_test.dart` cannot run on Chrome.

Deploy `build/web` to Cloudflare Pages using `wrangler.jsonc` (SPA fallback). HTTPS is required for service workers and IndexedDB. The server-side pairing panel encodes the deployed PWA URL into its QR link. This app imports only web-safe `cc_ui`, `cc_domain`, `cc_rpc` and `cc_data`, never the root `control_center` app, `dart:io` or native plugins. It uses `WidgetsApp.router`, `CcTheme` and go_router, not Material widgets; `lib/app_icons.dart` avoids the large icon class that overflows web DDC.

## Pairing and session

`lib/pairing/pairing_store.dart` reads the v2 fragment payload (`{v:2, d:descriptor, i:deviceId, k:psk, x:expiry}`) and **waits for explicit confirmation** of the server name before pairing; a forged fragment must not auto-pair. It persists the device, descriptor, PSK and TOFU fingerprint in IndexedDB, then strips the secret-bearing URL fragment. `lib/app_connection.dart` manages connecting, retry, unpairing and active workspace state. A fingerprint mismatch is terminal: remove the pairing and re-scan, never continue past it. Reconnection refreshes the descriptor for changed network paths. The `cc_server pair` CLI prints a different v1 web-client link, **not** a phone v2 pairing payload. See [SECURITY.md](../../SECURITY.md) for shared trust rules.

## Phone-specific behavior

Bottom tabs are Inbox, Tickets, Chat, PRs, Calendar and News. PR diffs reuse `cc_domain`'s `parseUnifiedDiff`; they are unified, collapsed by default and capped by `kDiffRowBudget` so a large lockfile does not eagerly build every row. They have no syntax highlighting or inline comments, though review decisions remain available. Calendar is an agenda, not a grid. Forge and calendar account connections stay server-side, not in the phone UI.

Agent approvals use server-provided intent and risk text. The Chat thread shows only the oldest pending approval inline, with a waiting count for the rest; the Inbox keeps every pending request accessible. Both bound long explanations and full Bash scripts in a scrollable body with a visible scrollbar while leaving decisions visible. Scripts render as LTR code regardless of locale, preserve line boundaries with horizontal scrolling, and have a one-tap Copy command action that copies the exact source, including blank lines and trailing newlines.

The authenticated direct or relay session also supplies a local encrypted resource facade, so attachments, media and fonts do not require a reachable remote HTTP origin. Workspace logos retain their bounded `workspace.logo` RPC/session cache. Every workspace-scoped stream must pass `workspace_id` explicitly **and** watch `activeWorkspaceIdProvider`: otherwise a subscription re-registers with its old captured workspace after switching. Phone-local presentation code (scroll-to-latest, avatars, transcript rows, markdown wiring and formatting) stays local; diff parsing is shared. The shared worker/bridge/shim assets are linked from the root `web/` directory, not maintained as a separate implementation. See [ARCH.md](../../ARCH.md) for the cross-client data flow.
