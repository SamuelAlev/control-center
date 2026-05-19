# cc_server_core

The **app-server composition root**: wires the pure-Dart pieces
(`cc_persistence`, `cc_infra`, `cc_host`, `cc_mcp`, `cc_mcp_client`,
`cc_domain`) into a running server. This is what the headless `cc_server`
binary and the desktop's embedded server both boot.

## Responsibilities

- **`cc_server_runtime.dart`** — `runCcServer(...)`: opens the DB, builds every
  repository/service/DAO, starts the RPC server, wires the event bus,
  reconcilers, pipeline engine, sync, retention, and the periodic services.
- **`local_rpc_server.dart`** (`LocalRpcServer`) — the actual HTTP/WSS
  transport: the PSK handshake, the repo-RPC catalog, `/proxy/media` (SSRF-
  guarded, disk-cached via `media_cache.dart`'s `MediaCache` under
  `<dataDir>/media_cache/`), `/proxy/vscode`, webhooks, `/healthz`, and
  static web-bundle serving. Non-loopback binds require TLS (fail closed).
- **`cc_server_config.dart`** — CLI/env config resolution (`--data-dir`,
  `--port`, `--bind`, TLS, origins). Defaults the data dir to the platform
  app-support directory.
- MCP registry + repo-RPC catalog wiring (`remote_rpc_catalog.dart`).

## Invariants

- Single source of truth: only this layer (and the DB it opens) holds state;
  clients reach it over RPC.
- Loopback-or-TLS for any network bind; `/proxy/media` re-validates every
  redirect hop against the SSRF block-list (`isBlockedProxyTarget`).
- Every declared RPC op must have a handler (a missing one returns `opUnknown`
  — the classic "works in tests, not in the app" footgun; rebuild the binary
  after adding ops).

## Extending

New RPC op → register it in the repo-RPC catalog + provide its handler. New
periodic service → construct and `.start()` it in `cc_server_runtime` next to
the others. Rebuild the binary (`cd apps/cc_server && dart build cli`) so the
running app picks it up.
