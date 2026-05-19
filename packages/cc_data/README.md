# cc_data

The **remote data layer**: repository adapters that satisfy the domain
repository/port interfaces (declared in `cc_domain`) by reading and writing
over `cc_rpc` instead of touching a database directly. Web-safe pure Dart.

## Responsibilities

- Implement `cc_domain` repository interfaces (`AgentRepository`,
  `WorkspaceRepository`, `WorkspaceFilesystemPort`, …) as RPC-backed adapters
  (e.g. `RpcWorkspaceFilesystemPort`). Reads map to `repo/call` + `sub/*`
  watch queries; writes map to the corresponding server ops.
- Let a thin client (web and increasingly the desktop) consume server-owned
  state through the _same_ domain interfaces the server implements against its
  DB — so presentation code never knows whether data came from a local DB or a
  remote server.

## Invariants

- No `drift`, no `dart:io`, no direct DB access — this is the RPC side of the
  repository split (the DB side is `cc_persistence`).
- Adapters are transport-detail-free at the seam: they return domain entities,
  never raw RPC payloads, so the domain layer stays transport-agnostic.

## Extending

New server-backed capability → add the op server-side, then implement (or
extend) the matching repository adapter here so clients reach it through the
domain interface. Prefer a `.watch()`-backed stream for anything the UI renders
reactively.
