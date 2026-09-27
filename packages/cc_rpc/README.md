# cc_rpc

Transport-agnostic **JSON-RPC client** and channel transports for Control
Center. Web-safe pure Dart (no `dart:io`, no Flutter) so it links into every
client tier — desktop, web PWA and the `cc_remote` phone.

## Responsibilities

- **`RemoteRpcClient`** — the client half of the protocol: `initialize`,
  `call(op, args)`, subscriptions and the PSK handshake. Injects
  `activeWorkspaceId` into every request (the server is stateless).
- **Channel transports** — pluggable framed-JSON transports behind a common
  port for direct WebSocket connections or the sealed broker relay.
- **`src/crypto/remote_control_crypto.dart`** — the shared pairing crypto:
  `generatePsk` (32 bytes / 256-bit), `generateRoomCode` (16 bytes / 128-bit),
  the mutual HMAC challenge/response and `verifyProxyTarget` (the signed
  media-proxy URL check). Both the client and the server (`cc_host`,
  `cc_server_core`) use this one implementation so both sides agree.
- **`RpcSnapshotCache` / `ResilientRpcClient`** — optional bounded, persisted
  stale-while-revalidate snapshots for allowlisted presentation subscriptions
  and explicit `watchCall` reads. Callers supply storage isolated by verified
  server/user identity. Full request arguments isolate workspace/entity/range
  variants; outages retain data, authoritative denials invalidate it. Ordinary
  RPC calls and mutations are never answered from snapshots.

## Invariants

- Web-safe: must not import `dart:io`, Flutter, or any VM-only package — it is
  compiled into the web bundle. (Guarded by the package-purity tests.)
- The crypto here is the single source of truth for handshake/room/PSK formats;
  never fork it per transport.

## Extending

New transport → implement the channel port and hand it to `RemoteRpcClient`.
New RPC op → it's dispatched server-side (`cc_host`/`cc_server_core`); the
client just calls it by name.
