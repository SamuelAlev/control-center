# cc_host

Server-side **RPC kernel** for Control Center: the in-process machinery that
serves a connected client (desktop, web, or `cc_remote` phone) over a single
transport. Pure Dart — no Flutter.

## Responsibilities

- **Sessions** (`src/session/`) — one `RemoteRpcSession` per connected client.
  Pumps inbound JSON-RPC frames through the shared `RpcDispatcher` and sends
  responses back. Stateless: every workspace-scoped request carries its own
  `workspace_id`; there is no per-session "current workspace".
- **Repo-op dispatch** (`src/repo_rpc/`) — the `repo/call` + `op/list` surface
  and the reactive `sub/subscribe` watch-query registry that proxies repository
  `.watch()` streams to the client.
- **Policy** (`src/policy/`) — `RemoteToolPolicy` (default-deny allow-list of
  MCP tools a *phone* may invoke) and `SessionCapability` (phone vs full
  client). A paired phone is authenticated but **untrusted**.
- **Rate limiting** (`src/session/remote_rate_limiter.dart`) — per-session
  sliding-window cap on `tools/call`, with a tighter sub-limit for mutating
  verbs (abuse/flood guard on the untrusted channel).

## Invariants

- Every mutating tool call passes through `RemoteRateLimiter.tryAcquire` before
  dispatch; a new mutating op must be classified in `RemoteToolPolicy.mutating`
  (enforced by `test/remote_rate_limiter_test.dart`).
- Fail closed: an unauthenticated/over-limit request is denied, never served.

## Extending

Add a new remote-invokable tool → add it to `RemoteToolPolicy.allowed` (and
`.mutating` if it writes). New watch query → register it in the
`WatchQueryRegistry`. The transport itself lives in `cc_server_core`
(`LocalRpcServer`); this package is transport-agnostic behind `RpcDispatcher`.
