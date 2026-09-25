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

- Every remote tool call is resolved against the registered MCP tool. Its mutation
  metadata determines the stricter rate limit and whether the member needs
  workspace write permission; unknown tools fail closed. The phone's
  `RemoteToolPolicy` remains the explicit allow-list, and
  `cc_server_core/test/remote_tool_metadata_test.dart` keeps its read/write sets
  aligned with the registered tools.
- Fail closed: an unauthenticated/over-limit request is denied, never served.

## Extending

Add a new remote-invokable tool → add it to `RemoteToolPolicy.readOnly` or
`.mutating`, declare its mutation effects on the MCP tool, and update the
metadata inventory test. New watch query → register it in the
`WatchQueryRegistry`. The transport itself lives in `cc_server_core`
(`LocalRpcServer`); this package is transport-agnostic behind `RpcDispatcher`.
