# cc_remote

Phone web PWA that renders server-owned state over JSON-RPC. It runs no database or repositories locally. [`cc_rpc`](../../packages/cc_rpc/README.md) resolves a v2 `ConnectionDescriptor` across reachable paths (LAN, tailnet, WSS or broker relay), handles PSK authentication and TOFU identity verification, and maintains one resilient RPC client whose subscriptions re-register with fresh snapshots after reconnect. In a browser, only TLS-compatible paths and the relay are usable. [`cc_data`](../../packages/cc_data/README.md) supplies the remote repositories.

```sh
# from apps/cc_remote
fvm flutter build web --release --wasm
```

Deploy `build/web` to Cloudflare Pages using `wrangler.jsonc` (SPA fallback). HTTPS is required for service workers and IndexedDB. The server-side pairing panel encodes the deployed PWA URL into its QR link. This app imports only web-safe `cc_ui`, `cc_domain`, `cc_rpc` and `cc_data`, never the root `control_center` app, `dart:io` or native plugins. It uses `WidgetsApp.router`, `CcTheme` and go_router, not Material widgets; `lib/app_icons.dart` avoids the large icon class that overflows web DDC.

## Pairing and session

`lib/pairing/pairing_store.dart` reads the v2 fragment payload (`{v:2, d:descriptor, i:deviceId, k:psk, x:expiry}`) and **waits for explicit confirmation** of the server name before pairing; a forged fragment must not auto-pair. It persists the device, descriptor, PSK and TOFU fingerprint in IndexedDB, then strips the secret-bearing URL fragment. `lib/app_connection.dart` manages connecting, retry, unpairing and active workspace state. A fingerprint mismatch is terminal: remove the pairing and re-scan, never continue past it. Reconnection refreshes the descriptor for changed network paths. The `cc_server pair` CLI prints a different v1 web-client link, **not** a phone v2 pairing payload. See [SECURITY.md](../../SECURITY.md) for shared trust rules.

## Phone-specific behavior

Bottom tabs are Inbox, Tickets, Chat, PRs, Calendar and News. PR diffs reuse `cc_domain`'s `parseUnifiedDiff`; they are unified, collapsed by default and capped by `kDiffRowBudget` so a large lockfile does not eagerly build every row. They have no syntax highlighting or inline comments, though review decisions remain available. Calendar is an agenda, not a grid. Forge and calendar account connections stay server-side, not in the phone UI.

Over a broker relay there is no HTTP origin (`RelayPath.probeUri` is null). Workspace logos therefore use the `workspace.logo` RPC (2 MB server cap, session cache); forge avatars use `/proxy/media` when direct HTTP is available and degrade to monograms on a relay. Every workspace-scoped stream must pass `workspace_id` explicitly **and** watch `activeWorkspaceIdProvider`: otherwise a subscription re-registers with its old captured workspace after switching. Phone-local presentation code (scroll-to-latest, avatars, transcript rows, markdown wiring and formatting) stays local; diff parsing is shared. See [ARCH.md](../../ARCH.md) for the cross-client data flow.
