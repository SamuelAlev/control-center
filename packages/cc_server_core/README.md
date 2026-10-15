# cc_server_core

The **app-server composition root**: wires the pure-Dart pieces
(`cc_persistence`, `cc_infra`, `cc_host`, `cc_mcp`, `cc_mcp_client`,
`cc_domain`) into a running server. This is what the headless `cc_server`
binary and the desktop's embedded server both boot.

## Responsibilities

- **`cc_server_runtime.dart`** — `runCcServer(...)`: opens the DB, builds every
  repository/service/DAO, starts the RPC server, wires the event bus,
  reconcilers, pipeline engine, sync, retention and the periodic services.
  Focused wiring lives in same-library `runtime/` parts; for example,
  `server_viewer_activity_wiring.dart` constructs the owner's GitHub activity
  poller, while the composition root owns its startup and shutdown.
- **`local_rpc_server.dart`** (`LocalRpcServer`) — the HTTP/WSS listener,
  signed-identity Noise sessions, repo-RPC catalog, webhooks, `/healthz` and
  static web-bundle serving. Sensitive media/editor/transfer HTTP routes return
  `426` publicly; `secure_resource_host.dart` dispatches authenticated resource
  streams through a capability-scoped private loopback gateway. Media remains
  SSRF-guarded and disk-cached by `MediaCache` under `<dataDir>/media_cache/`.
  Non-loopback binds require TLS (fail closed).
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

## Skill evaluation campaigns

The Skills evaluation panel launches a budgeted, revision-pinned campaign; Observability → Quality shows its progress, paired outcomes, loading observations and bounded attempt evidence. `server_skill_evaluation_wiring.dart` constructs the production `SkillEvaluationService`, including workspace/repository authorization, action-policy admission, model pricing and controlled execution.

The `evals.*` campaign operations are `skillCorpora`, `startSkillCampaign`, `cancelCampaign`, `watchCampaign`, `watchCampaignsForSkill`, `listAttempts`, `getAttempt`, `exportCampaign`, `skillPolicy` and `setSkillPolicy`. Every operation requires explicit workspace scope. Attempt lists contain metadata; `getAttempt` retrieves one bounded, redacted record. Starting/cancelling requires the workspace `member` role or higher; changing automatic policies requires workspace administrator permission. No evaluation-specific MCP or HTTP download endpoint is provided.

Durable campaign state lives in workspace databases, not `global.db`. Artifacts live at `<dataDir>/skill-evaluations/<sha256(workspaceId)>/campaigns/<campaignId>/`, retaining the plan, manifest, corpus, attempts and report. Content-addressed package history lives beside `campaigns/` under `snapshots/`. RPCs return scoped, redacted evidence rather than arbitrary host paths.

The controlled built-in harness and native Claude Code adapters are supported. Claude uses the default managed account, pins its CLI version and concrete model ID, and exposes only a private authenticated MCP bridge into the guest; no ambient login or host native tools are borrowed. Provider access remains on the server; guest tools have no external network or provider credentials. Model identifiers are native catalog IDs: keep vendor namespaces intact and add a provider qualifier only at the harness factory boundary. Codex authenticates its own account, independently of OpenAI catalog enablement.

Claude Code and Codex OAuth budgets are API-equivalent usage stopping thresholds, not invoice ceilings: a `100`-cent subscription run can start, an in-flight call may exceed its budget, then further calls stop. API-key providers still reserve a documented worst-case call, using the highest applicable context-tier prices, and reject insufficient budgets before spending. Observed estimates use the pinned input-context tier. Missing containment, credentials, required pricing or observed accounting refuses further work instead of falling back to a host shell or a zero-cost result.

Automatic paid reevaluation is off by default. Enabled policies capture current revisions without spending, then deduplicate subsequent authorized changes. Disabling/replacing a policy invalidates its queued admissions. On restart, unfinished campaigns become interrupted; historical evidence and unknown spend remain visible.

See the [operator workflow](https://usectrl.dev/manual/guides/manage-skills/#evaluate-a-skill), [evaluation protocol](https://usectrl.dev/manual/concepts/evals-and-quality/), and [containment limits](../../SECURITY.md#controlled-skill-evaluation). These campaigns do not implement the separate generic suite-runner interface.

## Extending

New RPC op → register it in the repo-RPC catalog + provide its handler. New
periodic service → construct and `.start()` it in `cc_server_runtime` next to
the others. Rebuild the binary (`cd apps/cc_server && fvm dart build cli`) so
the running app picks it up.
