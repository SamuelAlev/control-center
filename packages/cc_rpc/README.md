# cc_rpc

Transport-agnostic **JSON-RPC client**, authenticated encrypted sessions and
resource transports for Control Center. Web-safe pure Dart (no `dart:io`, no
Flutter) shared by desktop, web and phone clients.

## Responsibilities

- **`RemoteRpcClient`** — the client half of the protocol: `initialize`,
  `call(op, args)` and subscriptions. Injects `activeWorkspaceId` into requests;
  workspace authorization remains server-owned.
  `subscribe` shares and replays replaceable snapshots; `subscribeEvents` opens
  an independent event stream for each listener: seed-and-delta for transcripts,
  live-only for terminal bytes. Events are never snapshot-cached or coalesced,
  including events preceding the subscribe acknowledgement. Reconnection
  re-subscribes; the query supplies a fresh seed when its protocol has one.
  Outbound requests wait for the preceding transport send to finish, so a
  subscription burst cannot exhaust the encrypted frame queue and disconnect
  the client. Requests cancelled or timed out before dispatch are not sent;
  in-flight mutations are never replayed after reconnect.
- **`SecureRpcChannel` / `NoiseSession`** — mandatory signed-identity
  `Noise_NNpsk0_25519_ChaChaPoly_SHA256` above raw direct WebSocket and relay
  adapters. Shared directional counters, bounded fragmentation/credits, fresh
  keys on reconnect, rekeying and fail-closed replay/tamper handling.
- **`RemoteResources` / `LocalResourceProxy`** — streamed HTTP bodies, Range
  metadata and text/binary WebSockets on that same authenticated channel.
  The browser facade uses Service Workers and MessagePorts without caching
  plaintext. Native loopback hosting is implemented in the client's platform
  infrastructure (`lib/core/server/local_resource_proxy_io.dart`), not here.
- **`RemoteControlCrypto` / `CredentialSeal`** — high-entropy device credentials,
  broker admission and signed resource targets; recipient-sealed bootstrap
  credentials. These are not alternate application encryption protocols.
- **`RpcSnapshotCache` / `ResilientRpcClient`** — optional bounded, persisted
  stale-while-revalidate snapshots for allowlisted presentation subscriptions
  and explicit `watchCall` reads. Callers supply storage isolated by verified
  server/user identity. Full request arguments isolate workspace/entity/range
  variants; outages retain data, authoritative denials invalidate it. Ordinary
  RPC calls and mutations are never answered from snapshots.
  Revalidation is listener-owned: the last listener leaving cancels pending
  requests, retry timers and reconnect waiters, without removing cached data.
  Identical active `watchCall` reads share work; one listener cannot cancel
  another's read. Cancellation sends `$/cancelRequest` with the original id.

## Invariants

- Web-safe: must not import `dart:io`, Flutter, or any VM-only package — it is
  compiled into the web bundle. (Guarded by the package-purity tests.)
- Handshake and record crypto are shared by every transport; never fork them.
- An authenticated network client receives a `SecureRpcChannel`. Raw transport
  adapters enter client setup only through the shared secure handshake.
- Session-local resource IDs, bounded buffers and cancellation are mandatory.
  Reconnect may restore subscriptions, but must not replay a transfer or upload.
  HTTP bodies stream in 32 KiB fragments; WebSocket messages are bounded at
  4 MiB, including real code-server extension-host startup frames.
  Closing a client cancels its peer's resource work even when the transport is
  owned separately; the transport owner remains responsible for closing it.
  Callers must consume or close HTTP responses and close tunneled WebSockets.
  Releasing a transfer also releases its upload and response-body subscriptions.
- Trusted browser editors share the app origin and use connection-owned
  resource capabilities. The Service Worker/MessagePort facade carries their
  HTTP/WebSocket traffic through the encrypted session; see
  [SECURITY.md](../../SECURITY.md#network-boundaries).

## Extending

New transport → implement the raw channel port, authenticate it with the shared
secure handshake, then hand the resulting channel to `RemoteRpcClient`.
New RPC op → it's dispatched server-side (`cc_host`/`cc_server_core`); the
client just calls it by name.
