# Architecture

Control Center uses Flutter clients, a pure-Dart authoritative server, Riverpod, and Drift/SQLite. Coding/build rules are in [AGENTS.md](AGENTS.md); access control and credentials in [SECURITY.md](SECURITY.md). Read the subsystem below when changing it, rather than loading every package document.

## Repository map

The root [pubspec.yaml](pubspec.yaml) defines the native Dart pub workspace; all members share `pubspec.lock`.

| Location | Owns |
| --- | --- |
| `lib/` | Desktop/web thin client: bootstrap, shared client infrastructure, feature presentation/providers, DI, l10n, routing |
| [apps/cc_server](apps/cc_server/README.md) | Headless server entrypoint and native CLI bundle |
| [apps/cc_worker](apps/cc_worker/README.md) | Stateless leased-job executor; see README for runner limitations |
| [apps/cc_remote](apps/cc_remote/README.md) | Phone PWA over encrypted brokered RPC |
| [apps/cc_signaling_server](apps/cc_signaling_server/README.md) | Stateless, invite-gated WebSocket relay |
| [apps/cc_gallery](apps/cc_gallery/README.md) | Widgetbook component reference |
| [apps/cc_demo_server](apps/cc_demo_server/README.md) | Separate public demo binary with restricted mutations |
| `packages/cc_domain` | Shared entities, ports, repositories, events and feature domain; no infrastructure |
| `packages/cc_harness` | Web-safe agent loop, messages, provider port, tools, compaction, steering, hooks, subagents, commands; no other cc package dependency |
| `packages/cc_harness_runtime` | VM providers, credentials/OAuth, generic tools and context loaders |
| [packages/cc_rpc](packages/cc_rpc/README.md) | Web-safe JSON-RPC client and transports |
| [packages/cc_host](packages/cc_host/README.md) | Server sessions, dispatcher, subscriptions, rate limiting, presence and WSS |
| [packages/cc_data](packages/cc_data/README.md) | Web-safe RPC repository adapters |
| `packages/cc_persistence` | Server-only Drift/SQLite, global and per-workspace databases |
| `packages/cc_infra` | VM adapters: git/process, rhttp integrations, dispatch, sandboxes, rigs, fleet, tunnels and CC-specific harness bridges |
| `packages/cc_mcp` | Typed server MCP tools and dispatcher; no Riverpod `Ref` |
| [packages/cc_mcp_client](packages/cc_mcp_client/README.md) | External MCP connections and tool/resource/prompt bridges |
| [packages/cc_server_core](packages/cc_server_core/README.md) | Server composition, RPC catalog, MCP registry, identity and background services |
| [packages/cc_ui](packages/cc_ui/README.md) | Widgets-only design system, tokens and theme |
| [packages/cc_markdown](packages/cc_markdown/README.md) | Typed-AST Markdown and native mermaid rendering |
| [packages/cc_natives](packages/cc_natives/README.md) | Required FFI libraries; in-repo Rust watcher, inference and SAML |
| `packages/system_audio_capture` | Core Audio taps, WASAPI and PipeWire loopback plugin |
| [docs](docs/README.md) | Astro/Starlight marketing site and manual |

Client features are under `lib/features/<name>/{presentation,providers}`; their domain lives in `cc_domain`, adapters in server packages. Shared client infrastructure is in `lib/core`, composition in `lib/di`, reusable rendering in `lib/shared`. `mcp` is providers-only; its settings UI lives under settings. `orchestration` and `plan_studio` have presentation/providers only. Settings contribution rules are in [AGENTS.md](AGENTS.md#boundaries).

## Runtime and data flow

```text
Desktop local ── supervised cc_server ── Noise over loopback WS
Desktop remote / web ── Noise over WSS ── cc_server
Phone PWA ── Noise over direct WS / broker relay ── cc_server
MCP clients ── JSON-RPC ─────────────── tool registry
Fleet workers ── leases + events ────── cc_server
```

`lib/bootstrap/server_backend.dart` resolves the persisted local/remote choice before Riverpod starts. Local desktop spawns a supervised server; web is always remote. The connected `RemoteRpcClient` overrides `rpcClientProvider`; all client repository bindings use `cc_data`, including local desktop. Platform-specific bindings use the existing `*_bindings{,_io,_web}.dart` seams.

`SecureRpcChannel` is the shared encryption boundary above the raw direct/relay adapters. It carries JSON-RPC and `RemoteResources` HTTP/WebSocket streams with independent bounded credit windows. Native clients expose a capability-scoped loopback URL facade; web clients use the shared Service Worker/MessagePort bridge. Browser editors are trusted client code on the Flutter app's origin. Their capability-scoped HTTP/WebSocket requests travel through the encrypted session to `cc_server`, which owns the code-server process and files. `SecureResourceHost` invokes existing server HTTP handlers over private loopback with device/user binding, preserving route-specific authorization. The editor extension's open/dirty reports and command SSE use a separate server-only private bridge, not client proxy capabilities.

Desktop mounts the localized `DesktopBootApp` in the existing setup window after essential preferences/native-window setup, then yields a frame before media initialization, secure storage and backend connection. This surface has no provider container, cached workspace data or session actions. Authentication and workspace admission still precede `DesktopBackendSession` adoption; a failed session build disposes its container and the initial backend.

The server owns external APIs and background services. `rhttp` adapters in `cc_infra` inject auth and classify failures through `network/error_mapper.dart`; unhandled transport errors are mapped at the RPC boundary. Workers execute leased jobs and stream events; they do not own databases, policy, approvals or budgets, and do not coordinate with each other. Architecture boundaries are enforced by `test/core/architecture_constraints_test.dart`.

HTTP uses rhttp's native reqwest engine, not a Flutter plugin. `cc_natives.initializeRhttp` loads the required library before client creation in each isolate. `createHttpClient` provides platform certificate roots, a default `ControlCenter` User-Agent (required by APIs such as GitHub), request normalization, retries, identity-aware deduplication and logging. Explicit client and per-request User-Agent values take precedence. Downloads use streamed bodies with receive-idle deadlines rather than a whole-transfer timeout. The headless dependency patch and native build contract are documented in [cc_natives](packages/cc_natives/README.md).

### Identity and collaboration

`Principal` is `UserPrincipal | AgentPrincipal`; use it for attribution. Users are global; membership/roles and repo grants are workspace-scoped. See [authorization](SECURITY.md#authorization-and-isolation).

- Durable state: clients render full-snapshot `*.watch*` subscriptions; there is no client delta mirror. Per-field ticket edits use `tickets.patch` (per-column LWW): server receipt order, never client time, decides the last writer.
- Presence: server-hubbed, ephemeral, never persisted; filter by repo grants before fan-out. Agent presence derives from run/lifecycle events. With one human the lane idles and roster chrome is absent.
- Follow/steer/interrupt/take-over and per-space autonomy use these lanes, not a CRDT.
- Agent peer messages use durable spaces, exact ID/unique-name resolution and no cross-workspace recipient search. `ask_agent` has a mandatory timeout (default ten minutes, workspace-capped) and pairwise cycle detection. Delegation inherits budget and autonomy ceilings, with cycle detection and a default depth cap of three. Agent-only spaces do not increment human unread badges or send OS notifications.
- `DomainEventBus` declarations under `cc_domain/lib/core/domain/events/` are authoritative. Device revocation watches `paired_devices`; there is no `UserDeviceRevoked` event. Workspace removal drops subscriptions without requiring the socket to close.

### Agent run gateway

Agents carry no permission flags: what a run may push, open, publish, write to a tracker or reach is action policy (`ActionClass` rules), the same for every adapter. `AgentRunGateway` (`packages/cc_infra/lib/src/dispatch/agent_run_gateway.dart`) is how that policy reaches code running inside an agent's sandbox. `cc_server_runtime.dart` constructs it over the action guard and credential broker and mounts it on the MCP surface's `/agent/` routes (`McpRequestHandler.agentRoutes`), so it rides the loopback port agents already dial for MCP.

- Dispatch mints the run a `ForgeTokenScope.read` token (GitHub App installation: contents read, pull requests write; it cannot push) and opens a gateway lease. The lease's `GIT_CONFIG_*` entries set `url.<gateway>/agent/git/github.com/.pushInsteadOf` for `https://github.com/`, `git@github.com:` and `ssh://git@github.com/`, so every GitHub push lands on `/agent/git/…`; fetches stay direct. The gateway parses the ref updates, asks `gitPush` with the refs (branch constraints apply), checks the target is the worktree's repo or a GitHub repo linked to the workspace, then forwards on a `write` token it mints and keeps. A refusal is a `report-status` `ng`, shown by git as `! [remote rejected] <ref> (Control Center policy: …)`.
- A policy deny during ref discovery is audited before returning `403`, just like a deny after the refs arrive. Unprompted guard denials publish `AgentActionBlocked` to the workspace-filtered live notifications and durable bell feed; answered approvals do not generate a second block notification. The “Agent needs attention” preference controls these notices. A block still notifies while its space is open because, unlike a pending approval, it has no inline approval card.
- Claude Code is launched with `--settings` registering an HTTP PreToolUse hook on `Bash` → `/agent/hooks/pre-tool-use`. `ShellActionClassifier` (`cc_domain/features/guardrails/domain/services/`) maps the command line to classes (commit, PR create/publish, tracker write, package install, `curl`/`wget` egress); the built-in harness `bash` runner uses the same classifier. This is the soft gate; credential possession is the hard one, so `git push` is deliberately not classified and was dropped, with `gh pr create|merge|close|review`, from the harness approve-command list (read-only modes still deny them).
- `networkEgress` is resolved once at run start into `SandboxSpec.networkEnabled`: deny turns the sandbox network off, allow/ask leave it on (the harness web tools still ask per call). GitHub domains are always on the egress allowlist while the network is on. No ticketing key enters a sandbox; agents write tickets through MCP tools gated by `vendorSyncWrite`.
- Teardown closes the lease and revokes every write token minted for it. With no GitHub App the broker falls back to an unnarrowable PAT: the rule still binds `git push`, but is advisory for code using the token directly.
- Rigs fix the scope at open (`RigSpec.forgeTokenScope`): a human-opened terminal rig gets `write`, bounded by that member's forge access; an agent-opened rig gets `read`, because a guest credential helper cannot tell a push from a fetch.

### Disposable worktree permissions

`SandboxExecGrantService` grants execution inside server-provisioned conversation overlays and shared worktrees without a startup question or a stored allow row per conversation. Dispatch derives the managed space root from the provisioner layout and excludes roots overlapping protected source checkouts. Claude Code and the builtin harness use the same resolver; the harness resolves these server-owned roots per command, never a model-supplied `cwd`.

Stored decisions still take precedence. An explicit denied descendant withholds an implicit parent grant rather than reopening the denied subtree. Read-only mounts, original checkouts and unmanaged/fallback directories are not implicitly granted; genuine unmanaged grants keep their approval flow. Changing working directories cannot widen execution authority.


## Persistence

`cc_persistence` is pure Dart over `package:sqlite3`, without Flutter/path_provider. Only the server opens databases:

- `<dataDir>/global.db`: workspace registry, identity/preferences/devices, per-user newsfeed, fleet queue, routing and server policy/settings. The pinned global-table set is in `workspace_isolation_ratchet_test.dart`; additions require an isolation justification.
- `<dataDir>/<workspaceId>/workspace.db`: all workspace-owned data, including repos. `workspaceDatabasePath` defines the path; associated artifacts share this directory.
- `WorkspaceDatabaseManager.of(workspaceId)` synchronously returns a lazy database; disk opens on first query. Hold the manager, not a resolved DAO. `quick_check` runs on first workspace touch, not boot.
- `CrossWorkspaceQueries` is the only fan-out mechanism (`fanOut`, `fanOutKeyed`, `forEachWorkspace`, `mergeStreams`, `topN`). Its callers explain `CROSS-WORKSPACE BY DESIGN`.
- `workspace_routes` resolves pre-auth opaque IDs/secrets. Write the entity before its route; a route miss is not-found, never a workspace scan.
- The same checkout in two workspaces has two repo IDs. Cross-workspace repo identity is its path (`findByPath`), not its ID. Ordering/link time are `repos.position`/`linkedAt`.

### Stored files and composer uploads

- `catalog_files` lives in each workspace database. It records logical file IDs, workspace/uploader/creator identity, original name, media type, byte count, storage reference, source, lifecycle state and timestamps. Uploads and server-managed artifacts are cataloged; repository files and disposable PR image caches are not.
- Dropping, pasting or picking a local composer attachment starts its upload immediately through the encrypted resource facade's `POST /blob`. The URI-encoded `x-cc-file-name` header preserves the original name. The server returns `file_id` only after both bytes and catalog metadata are durable. Files are bounded to 24 MiB; failures remain visible with retry/remove controls, and sending waits for every upload to be ready.
- Sending, steering and provisioning queues reuse `fileId` plus the existing `blob:sha256:…` reference, never a client-local path or another upload. Repository-file mentions remain server-side references. The server validates workspace, uploader and blob identity before promoting an upload from `draft` to `attached`.
- Each upload has a separate logical ID even when identical bytes share one workspace-local blob. `files.discard` is uploader-only and rejects attached files. Removal leaves a `discarded` tombstone and reclaims bytes only when no active catalog entry or message needs them; pre-catalog bytes are conservatively retained. There is no age-based draft expiry: a provisioning queue may still need an upload.
- Generated blobs, workspace logos, meeting audio and review snapshots retain their existing storage locations and are recorded as artifacts. The v20 migration backfills old message attachments; a one-time, background `CrossWorkspaceQueries` inventory covers historical artifacts without pinning every workspace database. Cache eviction protects cataloged files and waits for successful historical inventory.


### Schema changes

1. Put each table in exactly one database, defaulting to `WorkspaceDatabase`. DAOs extend the matching `DatabaseAccessor` and cannot declare the other database's tables. Override `tableName` with plain snake_case.
2. Read current schema versions from source. Both databases have squashed baselines; append `MigrationStep(from, to, migrate)` and bump the owning database version. Do not support pre-baseline files by silently opening them.
3. Update fresh-schema expectations in `workspace_baseline_schema_test.dart`. Regenerate Drift/JSON output with the root build_runner command in [AGENTS.md](AGENTS.md#build-and-verification).
4. FTS/vector virtual tables, external-content FTS triggers and sync-feed triggers are idempotently installed in `beforeOpen`. Partial-index changes must cover installed databases: `_createPipelineIndexes` runs only in `onCreate`, so migrations changing its predicates must explicitly drop/recreate those indexes.

`workspaceId` columns support sync/FTS/self-identification; separate files provide isolation. Vectors use sqlite_vector FLOAT32/384 dimensions with FTS-only degradation when the embedding model is unavailable, not when a required native is missing.

### Backup and restore

Snapshots are `backups/<ts>/{manifest.json,global.db,<workspaceId>/workspace.db}`, written using `VACUUM INTO`. `server.listBackups` includes incomplete snapshots and marks them incomplete. `workspace.export/import` operate on a single workspace file; restoring one from a snapshot uses the same import. Whole-install restore is a stopped-server copy-back, not another RPC operation.

The install owner can remove a listed snapshot (including incomplete ones) by
its timestamp name via `server.deleteBackup`; the server refuses paths and
symlinked directories. Built-in **Workspace backup** pipelines instead write
`backups/workspace-backups/<workspaceId>/<ts>/workspace.db` for the current
workspace only. An enabled weekly schedule runs once on recovery after missed
cron slots, then prunes only that workspace's backups older than 30 days by
default; it never prunes install snapshots or other workspaces.

RPC paths name files on the server. Remote byte transfer uses signed requests inside the authenticated encrypted resource tunnel:

| Route | Authorization and lifecycle |
| --- | --- |
| `GET /backup/workspace` | Workspace admin; stream export, delete server copy |
| `GET /backup/snapshot` | Install owner; ZIP to a temporary file rather than buffering the installation |
| `POST /backup/restore` | Workspace owner; stream to staging, adopt, delete staging on success or refusal |

HTTP handlers enforce their own roles behind the private resource gateway; the public versions of these routes return `426`. Downloads use `no-store` and `Accept-Ranges: none`: every request creates a fresh export. Backups are absent in demo mode and work through direct or relay sessions without a separate remote HTTP origin. Transfer progress is throttled to 100 ms with a final byte count; upload progress means bytes handed to the tunnel, while the response confirms completion. Reconnect cancels an in-flight transfer rather than replaying a restore.

## Harness and indexing

### Claude Code checklists

With a Control Center MCP config, `ClaudeCliBackend` appends explicit `todo_read`/`todo_write` instructions for multi-step work, including tool discovery, recovery after compaction and live status updates. Native `TodoWrite`, `TaskCreate`, `TaskUpdate`, `TaskGet` and `TaskList` are disabled with `--disallowedTools`: their private lists do not populate the conversation's checklist. Subagent execution tools remain available.

Without an MCP config, the launcher leaves Claude's native tool surface unchanged and adds no Control Center checklist instruction. The appended prompt and native-tool restrictions are part of the resume-policy fingerprint, so sessions created under the old policy start fresh rather than retain stale instructions.

### Native Claude sessions and accounting

`ClaudeNativeSessionStore` scopes explicit session IDs by workspace, agent, conversation, account/config directory, cwd and branch/fork policy. Resume also requires a matching standing-instruction/policy revision. Only a successful terminal result followed by normal process exit advances the delivered-context cursor; interrupted or failed turns must not suppress undelivered messages. Fresh launches receive complete context; resumed launches receive the new request and changed, authorized context entries. Ordinary idle gaps do not require keeping a CLI process alive.

Pass configured effort through the actual launch builder, constrained by the selected model and detected CLI capabilities. Preserve strict MCP configuration and action-policy hooks; do not use `--bare` to bypass them. Parse `system/init` for the observed session, model, CLI version, tools and MCP status. Discovery caching remains opt-in and requires a stable authorized catalog/configuration; it does not replace Claude's native tool discovery.

Claude's main-loop `usage` is per-turn; `total_cost_usd` and per-model whole-tree counters are cumulative. Delta those counters against the correct restorable baseline, without attributing an earlier dispatch's spend to its successor. Missing model counters retain observed main-loop usage and reconcile it once when full counters return. Counter resets, account switches and forks establish new baselines without erasing this dispatch's totals. Subscription figures are API-equivalent consumption, not invoices.

Runner settings report Claude credential expiry independently of `loggedIn`: the CLI can still report a present credential after its access token expires. Each expired account shows a **Sign-in expired** warning badge. Any expired managed account also gives the installed Claude Code runner a warning dot and status tag, including when that account is not the default. Checking/missing CLI states retain precedence. These warnings do not disable dispatch or change Claude's next-run refresh behavior; refreshed account data clears them once the credential is current.


### Repo skills

`RepoSkillCatalog` is the shared scan-gated discovery for projection and `skills.repoSkills`. `ActiveRepoTracker` observes paths at `DispatchSession.addEvent`: a write under `repos/<name>/` switches the active repo; reads only seed an unset repo. Only that repo's skills are prompt-resident.

`RepoSkillProjector` writes the overlay's `.claude/skills` and a real `AGENTS.md` for hot reload; the provisioner's `_ensureSymlink` restores its link on the next dispatch. Never project into overlay `.agents/skills`, which links to the agent-global directory. Announce swaps through **steering**, not aside: `AgentLoopConfig.systemPrompt` is fixed for a run, while subsequent authoritative system-role constraints are preserved through compaction.

Invocation is `/skill:<name>` or `/skill:<repo>:<name>` (`skillNameFor`); old bare non-builtin invocations remain readable. The human composer can name any repo's skill, but a bare name must be unambiguous. Context loaders resolve symlinks only within caller-permitted roots (`resolvesInsideRoots`); the AGENTS walk never descends a linked directory. Scanning/security requirements are in [SECURITY.md](SECURITY.md#execution-and-untrusted-input).

### Skill evaluation campaigns

`SkillEvaluationService` owns revision-specific campaigns under `evals.*`; `DaoEvalsRepository` persists campaigns, attempts and opt-in policies in the owning workspace database. The server captures scan-gated, content-addressed skill packages and pins the corpus, adapter, provider/native model identifier, protocol, tool schemas and ambient inventory. Native Claude campaigns also pin the managed account and observed CLI version. Clients only select settings, observe snapshots and request actions.

`ControlledSkillEvaluation` reuses the paired evaluation engine with fresh fixtures, context and home directories. Supported executors are the built-in harness with enclosed file/process tools and native Claude Code with built-in tools disabled and an authenticated MCP bridge into that same enclosure. Executor choice is explicit; neither path falls back to the other or to fleet jobs. Claude Code and Codex OAuth use an API-equivalent usage stopping threshold that may be exceeded by one in-flight call; API-key providers retain conservative reservations. Unknown usage stops further calls. Absent, previous-revision, forced-load diagnostic and pinned-composition comparisons remain distinct. The local corpora are authored pilot cases, not imported public benchmark scores.

Campaign progress and bounded attempt evidence survive reconnects. Cancellation stops future attempts and active guest processes; restart marks unfinished campaigns interrupted rather than inventing results or known spend. `SkillUpdated` and periodic, authorized repository revision reconciliation mark historical evidence stale. Paid reruns require an explicitly enabled, revision-bound policy; changing or disabling that policy invalidates older queued admissions.

Reports retain every attempted outcome in the primary denominator, cluster repeated trials by task, and withhold recommendations when coverage, identity or cost is insufficient. Direct body/reference/script observations are not proof that a model followed the skill. Synthetic safety artifacts are separate from observed policy denials and are not evidence of real exfiltration.

Skills settings and Observability → Quality share typed campaign clients. This service is separate from the generic suite executor contract; adding skill campaigns does not supply an executor for arbitrary existing evaluation suites. See the [evaluation protocol](https://usectrl.dev/manual/concepts/evals-and-quality/) and [SECURITY.md](SECURITY.md#controlled-skill-evaluation) for containment limits.

### Deferred tool loading

- Keep external MCP `tools/list` complete. Only in-process harness schemas are deferred; tools remain callable from turn one, activating and executing in the same step.
- `HarnessToolSearchTool` uses BM25. Compatible Anthropic requests send the stable admitted catalog with `defer_loading` and search results with replayable `tool_reference` blocks. Other providers retain append-only schema activation after resident tools. A fixed resident-tool breakpoint alone does **not** preserve downstream system/history caches when an ordinary tool catalog changes.
- Apply deferral after `ToolSurfaceSpec` filtering. Activation cannot add disallowed tools or bypass approval/action guards.
- Dispatch and `ContextInspectionService` share `materializeHarnessToolSurface`. Residency comes from `ModeToolPolicy` through `ModeCapabilityProfile.toToolResidencySpec()`; reserve it for tools used in most runs.
- `test/tooling/resident_tool_names_test.dart` checks real names and the under-40 budget. `--tool-deferral=off` / `CC_SERVER_TOOL_DEFERRAL` makes every admitted tool resident.

### Prompt caching

Keep sent prefixes byte-identical where possible. `pruneToolResults` batches rewrites at `CompactionConfig.pruneThresholdTokens` (default 2000); compaction forces pruning because it already rewrites history. Opt-in stale-observation masking also accounts for provider/cache prices, rewritten-prefix size and expected remaining calls. It protects active edit targets, unresolved diagnostics and non-recoverable evidence. Calibrate prompt estimates against observed provider usage rather than treating the character heuristic as an exact tokenizer.

Anthropic uses four cache breakpoints: last resident tool and last system block with a one-hour TTL; previous and current request tails with short TTLs. The rolling pair (`cacheAnchorIndex`) survives wide parallel tool turns. `_subagentPilots` releases same-shape siblings on the first child's first event with a bounded wait, allowing its cache write to become readable. Subagent resident sets are profile-independent; model/effort differences fragment the prefix. `McpToolBridge` caches deterministic stripped schemas with stable key order.

Measure `cacheRead / (input + cacheRead + cacheWrite)` in `observability_metrics.dart`; cache writes belong in the denominator.

### Context, tool execution and measurement

Compaction input retains bounded, attributed evidence: original requirements, system steering, tool arguments/results, exact active edit anchors, verification outcomes and references to recoverable observations. Tool-output storage is workspace-authorized; ranged `read_output` retrieves bounded slices without injecting the full original into every request. Format search/file/build observations at their tool boundary, never by globally rewriting machine-consumed shell stdout.

Independent parallel-safe regions use a bounded rolling scheduler: a completed call releases its slot immediately, UI completion events stream as tools finish, and model-facing results retain deterministic order. Mutations, approvals, dependencies and relevant hooks remain barriers. Fully parsed, authorized read-only execution may overlap generation only under the explicit experiment; cancellation and retry rules prevent duplicate or late work.

Text compaction is the default. Snapshot/image compaction is opt-in, requires vision, checks page/source/image/context limits including reserved output, and retains source text for repeated folds and later text fallback. Source containing non-ASCII glyphs, tabs or control codes is refused before rendering because the fixed font would normalize or lose it; the host takes the text path instead. Local rendering/fit checks do not establish model OCR fidelity or end-to-end savings.

`HarnessRunAccounting` observes physical provider attempts, including main, compaction, advisor, side-request, subagent and failed/retried work. Attribute child usage to the child's own row and roll its cost into ancestor budgets once. Flush call records and atomic own/child cost updates before terminal completion. Store micro-USD; round only for presentation. Missing usage/pricing is unknown spend, not zero-cost work. Reasoning tokens are a subset of output unless a provider explicitly reports disjoint axes.

Latency stages distinguish dispatch/context readiness, runtime/MCP readiness, physical request send, first HTTP response-body byte, first model event, useful text/action, auxiliary work and verified completion. Provider intervals require matching request/attempt identity and provider/transport provenance. CLI stdout and `system/init` are startup observations, not HTTP TTFB.

`packages/cc_infra/bin/cc_eval.dart` runs pinned paired campaigns, independent behavioral verification, artifact replay and reports. The canonical corpus distinguishes synthetic smoke tasks from pinned real Control Center source tasks. Plans cover masking, snapshots, effort/routing, native resume, MCP discovery and read-only overlap; unsupported/no-op interventions are refused before spend. Repeated trials of one task do not substitute for independent task pairs. Keep the quality default until eligible, priced evidence satisfies the non-inferiority gate. Generic local campaigns execute trusted developer fixtures; they are not a security boundary for untrusted skill packages.


### Code graph

- Before walking or reading file state, `RepoStateProbe` fingerprints HEAD, `git status --porcelain -z -uall`, and dirty-path mtime/size; `codeIndexerFingerprint` covers extractor version, queries and grammar libraries. Matching `code_index_checkpoints` returns `CodeIndexResult.unchanged()`. Worktrees also compare base `generation`. A null probe never skips; watcher events force indexing.
- Enumeration/hashing (`walkAndHash`), tree-sitter (`ExtractionWorker`) and embedding (`TextEmbedderWorker`, owning its FFI session) run off the main isolate. Use one long-lived extraction isolate per run; kill/replace a wedged parser.
- Embed batches outside transactions, then write 32 files per transaction. Prune with chunked `IN` lists in one transaction. `resolvePendingReferences` probes indexed COUNT and projects names, not full embedding blobs.
- Start `codeGraphWatch` after the ready banner; defer the first sweep with `--code-index-defer`. Desktop kills a server that misses its 20-second ready deadline. `--code-index off` disables indexing; `/healthz` exposes watching/indexing/pending state.
- Native `cc_watcher` is required: kernel-recursive on macOS/Windows; ignore-aware inotify setup on its own Linux thread. No scanning fallback or arm stagger. An unwatchable checkout is logged/retried by reconciliation, not fatal to the service. Share `SourceFileWalker.watchIgnoredDirs` with `affectsIndex`. See [watcher](packages/cc_natives/native/watcher/README.md).

## Enclosures

Rig domain is `cc_domain/lib/features/rigs`, adapters `cc_infra/lib/src/rigs`, viewers `lib/features/rigs`. Desktop uses QEMU/HVF or KVM with qcow2 images; exec/browser use smolvm/libkrun with pinned OCI images; Android and iOS are host-managed exceptions, not enclosed networking. Backend selection follows `RigSpec`, never availability or a silent host-shell downgrade. Enforcement rules are in [SECURITY.md](SECURITY.md#execution-and-untrusted-input).

### Browser engines

`RigBrowserEngine` selects Chromium/CDP (`CdpClient`), Firefox/BiDi (`BidiClient`) or WebKit/W3C (`WebDriverClient`). `BrowserRigDriver` depends only on `BrowserEngineClient`; shared page scripts/action vocabulary live in `browser_engine_client.dart`. A rig keeps one engine for life; conversation reuse, in-flight open, tab dedup and provider keys all include the engine.

- Create Firefox's `--profile` directory before launch. Send the guest-side authority in its WebSocket Host header; the forwarded host port fails validation.
- Classic WebDriver POSTs require a body; GETs must not carry one (`dart:io` fixes GET content-length to zero).
- Only Chromium screencasts; others poll at at most 6 fps. WebKit PNG stills need host ffmpeg for its live lane. Firefox/WebKit cannot bypass cache on reload, expose platform accessibility trees or perform real file drops; label DOM-derived accessibility accurately.
- Use distribution Chromium, not upstream `headless-shell`, which omits audio backends. Browser workloads start system PulseAudio with a `ccout` null sink, a pulse-owned socket directory and successful `pactl` sink observation. Never mask startup failure with `|| true`. ffmpeg encodes `ccout.monitor`; packs are keyed by image, engine and audio revision.

### Input, display and worktrees

QEMU input uses QMP (`input-send-event`/`send-key`) and `virtio-tablet`; the unprivileged guest agent only captures/mode-sets and scales frames. The human display lane relays bytes at panel resolution with adaptive fps/quality; the server never decodes frames on the RPC path. The agent lane is at most 1280×800 with one image per result (`capToolImages`); compaction discards old images but keeps text.

The host worktree remains authoritative. Tar streams sync in; git bundles are fetched into `refs/rigs/<rigId>/*`, never pushed or checked out. Uncommitted changes return as a reviewable diff. `WorktreeTransport` uses SSH for QEMU and `smolvm machine exec` for microVMs.

Clipboard policy is per-user and per-direction: paste into rig defaults on, copy out defaults off and prompts before reading. Temporary grants last ten minutes for one rig/direction; persistent grants are synced user preferences. `ensureRigClipboardPermission` gates `RigInputSurface` before `/rig/clipboard`. Denial still forwards guest-local Ctrl+C/X/V on Windows/Linux so copy, paste and terminal interrupts work.

`RigService.act` rejects agent mutations while a human has control but allows observations. Log inputs with `Principal` and a per-rig monotonic `seq` in the insert transaction. Hard TTL, idle→park→close and resident-MB LRU bound resource use; parked VMs retain RAM. Shutdown tears down all owned machines.

### Boot and recovery

- Desktop qcow2 downloads are user-initiated, checksum-pinned and stored in `<dataDir>/rigs/images`. `scripts/rigs/build_image.sh` bakes the guest agent; Settings imports images. `kSmolvmExecImage`/`kSmolvmDebianBrowserImage` pin OCI digests; browser engines warm gated apt installs into per-engine packs.
- Android SDK/emulator/images come from Google (`setup_android.sh` reuses Android Studio); distinguish no SDK, no emulator, no AVD and no running device. iOS requires macOS, Xcode/runtime and checksum-verified WebDriverAgent installed through owner-only `rig.installBackendSetup`. Register uniquely named owned devices atomically; teardown/orphan recovery stop WDA and delete only those devices. iOS streams fixed-size MJPEG and supports typed point/key/app actions, not file drop/audio/mic/enclosed egress. Mobile developer commands are argv-shaped device commands, never a host shell.
- `buildRigSocketPath` selects the first fitting XDG_RUNTIME_DIR/TMPDIR/`/tmp` root; Unix socket limits are 104 bytes on macOS/BSD, 108 on Linux. Keep full rig IDs, create 0700 directories, reject symlinked `ccrig` namespaces. Durable files remain under the data directory; teardown/recovery clear both trees.
- Stock Ubuntu QEMU cloud images need a `cidata` cloud-init seed creating `cc` and its SSH key, not the built-image `CCRIG` format. Readiness is sshd's banner, not a bare forwarded TCP connection or a nonexistent guest agent.
- Guest seed permissions are `0640 root:cc`; both the `User=cc` guest service and git credential helper need read access.
- A successful cloud-init exit does not prove customization. The builder requires the guest completion marker and deletes failed output. Discover firmware via `qemu -L help`, not paths derived from a symlinked binary. `verify_image.sh` must boot the output with a real seed and observe `/health` before publication; its diagnostic seed dumps the guest journal.
- Rig viewers belong to space/PR tabs, not global navigation; tools share the conversation's machine. Settings → Server → Enclosures owns setup/capabilities/sessions. Never auto-start rigs on layout restore. Restored microVM terminal tabs carry `EditorLayoutCodec.deferStartArg` and wait for “Open the shell”; host-shell terminals may attach on mount.

## Client conventions

### Routes and onboarding

`go_router` uses `ShellRoute(ControlCenterLayout)`. In-shell routes start `/workspaces/:workspaceId/`; that URL drives `activeWorkspaceIdProvider` and `context.currentWorkspaceId`. Builders take workspace ID first. `/splash`, `/onboarding`, `/signed-out`, and `/workspaces` are full-screen pre-context routes. See `lib/router/{routes,app_router,guards}.dart` and `features/auth/providers/onboarding_providers.dart` for the actual route inventory.

Setup requires a forge connected for the signed-in user and a workspace. Missing credentials lead to `/signed-out` only if that user's `users.onboarding_finished_at` says setup finished; otherwise onboarding. Never infer this from workspace existence or device preferences: invited users and shared devices invalidate that inference. Hold splash while the value is unknown. `users.markOnboardingFinished` is self-targeting, idempotent and monotonic; mark on completion and when observing a complete setup. Snapshot the step list once: invited members skip workspace creation but still do personal setup.

Space sidebar folders are personal navigation organization, not workspace space entities or shared policy. `space_folder_providers.dart` reads `prefs.watchOwn` and writes a JSON folder list under `space_folders.<workspaceId>` with `prefs.set`; expanded and rail-mode sidebars share it. Workspace-specific keys prevent mixing a user's arrangements, while the workspace's visible-space stream remains the authority for which rows can be shown. Space-row and header archive actions remove the archived space from personal folder membership, so restore leaves it unfiled. Deleting a nonempty folder defaults to removing only its folder record; an explicit confirmation checkbox instead deletes its existing workspace spaces through the messaging service before removing the folder record. Folder deletion and space deletion have different scopes: the former is personal, the latter is workspace-wide.

`SpaceFoldersList` handles workspace-scoped drag payloads: folder rows accept visible spaces, space rows open the existing folder-name dialog when another space lands on them, and a filed space dropped in free sidebar space becomes unfiled. During a filed-space drag, both desktop sidebars show a bordered "Remove from folder" target between folders and unfiled spaces; its accent border confirms an eligible hover, and dropping moves only a visible space in the same workspace. Drops outside the sidebar do nothing. `SpaceFolderActions.create(spaceIds:)` moves both spaces out of previous folders and into the new one in a single personal-preference write; direct folder and unfile drops use `SpaceFolderActions.move`. The menu remains a non-drag alternative. Folder overflow uses the space row's hover-revealed trailing control; its caret appears only when visible members exist.

The phone PWA reads the same `space_folders.<workspaceId>` preference over `prefs.watchOwn` and writes through `prefs.set`, so folders follow the user between clients without adding shared workspace entities. Its Chat tab groups only active spaces from the selected workspace and offers touch-sized create, rename, move, unfile and delete controls instead of drag-only interactions. Permanent deletion verifies listed space ownership in that workspace; removing the folder alone leaves its spaces intact.

### Rendering assets

- [cc_ui](packages/cc_ui/README.md) and [gallery](apps/cc_gallery/README.md) own components; [DESIGN.md](DESIGN.md) owns visual rules. Do not create another kit.
- Vendor only `Phosphor-Regular.ttf`; `tool/gen_icon_seams.py` generates `AppIcons`/`CcIcons` with `fontPackage: 'cc_ui'`. An icon-package dependency loads unused styles on web and giant icon classes can overflow the DDC linker.
- Script companions are locale-loaded assets, not `fonts:` entries: Sarabun (Thai), Rubik (Hebrew), IBM Plex Sans Arabic (Arabic/Persian/Urdu); CJK uses the OS face. Do not bundle Noto CJK or eagerly load companions for English.
- Markdown uses `appMarkdownStyle`, `markdown_registries.dart`, `markdown_builders.dart` and `buildSharedCodeBlock` under `lib/shared/widgets/markdown/`. `GitHubMarkdownBody` serves forge content; `StyledMarkdownBody` tickets/meetings. Non-streaming Markdown uses the bounded shared parse cache directly; do not queue a duplicate worker parse from widget initialization when the same build immediately parses and caches the source. Native mermaid ignores author styling in favor of `appMermaidStyle`; malformed/unsupported and unclosed streaming fences remain code. No WebView/JS diagram dependency.
- Pipeline run and GitHub Actions graphs share `GraphCanvasViewport` under `lib/shared/widgets/canvas/`: a retained scene with wheel pan, pinch/modifier zoom and the shared zoom/fit controls. Camera changes do not rebuild graph widgets or rerun layout; sidebar resizing and scene-origin changes preserve a navigated view. Node widgets have stable graph-ID keys and separate repaint boundaries. The pipeline editor owns an incremental `PipelineEdgeGeometryCache`; moving one node rebuilds only its incident curves.
- Syntax highlighting uses shiki_flutter via `lib/shared/syntax/`: shared `syntax_languages.dart`, native registry, curated web registry and deferred grammar packs (`tool/gen_grammar_packs.py`). Common-grammar warmup starts after the first frame, one scheduler-idle task at a time; on-demand highlighting remains authoritative. Theme edits update `syntax_palette.dart` and bump `kCcThemeRevision`. The Flutter-free `package:shiki_flutter/engine.dart` feeds the generated diff worker. Its unmatched-token sentinel maps to inherited color; do not duplicate the magic value elsewhere.
- Diff highlights use `DiffWorkerPool`: native concurrency is CPU − 1 clamped to 2–12, web concurrency is four. With no active or in-flight work, a 60-second idle timer tears down workers; the next job recreates them. Completed-token LRU storage is bounded by 128 entries, an estimated 8 MiB total and 2 MiB per result, not by process RSS.
- Keyboard-first dialogs use `showCcDialog` with `CcDialogPresentation.immediate`: no entrance/exit transition or backdrop blur, with the same dismissal, focus trapping and focus restoration as standard dialogs.
- `RigBrowserToolbar` polls only while visible, tick-enabled and resumed. Its one-shot cadence allows one request in flight, refreshes on reveal, rejects stale workspace/rig replies and publishes only changed state. This gate does not suspend server execution or security/liveness work.
- `TerminalSessionController` keeps a UTF-8 decoder per output subscription and drains at most 16,384 UTF-16 code units per event-loop turn, preserving surrogate pairs and lifecycle ordering. A 65,536-unit high-water mark pauses the decoded subscription, not the shared RPC transport: upstream buffering and a single large emission can exceed it. Hidden terminals keep consuming the live-only stream; scrollback, PTY ownership and input forwarding are unchanged.
- Shortcode consumers share the lazy parser in `lib/shared/emoji_parser.dart`; do not reconstruct its dataset while editing text.
- Global error boundaries are `PlatformDispatcher.instance.onError` and `ErrorWidget.builder`.
- `macos/Runner/SurfaceCacheGuard.swift` patches the engine-private `FlutterBackBufferCache`, which can hand a frame a wrong-size surface after an A → B → A resize or display replug while a platform view is on screen; Impeller then dereferences a null color texture on the raster thread ([flutter#185394](https://github.com/flutter/flutter/issues/185394)). It installs before the engine runs, verifies every private class/selector/type encoding and stays inert if they change (`log stream --predicate 'category == "SurfaceCacheGuard"'`). On a `.fvmrc` bump, delete it once `removeSurfaceForSize:` checks the returned surface's size.
- `macos/Runner/WindowCloseGuard.swift` patches the engine-private `-[FlutterWindowController closeAllWindows]`, which on hot restart disposes each view controller and closes its window without clearing the window's delegate; closing the key window then sends `windowDidResignKey:` to a `FlutterWindowOwner` that reads the disposed controller's `viewIdentifier` and aborts ("This view controller is not attached."). The guard detaches every owner first, as `destroyWindow:` does, with the same verify-or-stay-inert checks (`log stream --predicate 'category == "WindowCloseGuard"'`). On a `.fvmrc` bump, delete it once `closeAllWindows` clears `window.delegate` before `close`.

### Client read snapshots

Desktop and web attach a bounded `RpcSnapshotCache` to `ResilientRpcClient` after the server handshake and an uncached `identity.me` read. The namespace includes the verified server fingerprint and authenticated user; each entry includes the query/read operation and complete arguments, including workspace, repo, entity and range. Eligible subscriptions replay their snapshot before attaching to the live stream. UI-only one-shot reads opt into `watchCall`; ordinary `call`/`callResult`, mutations, credentials, presence and live control remain uncached.

Snapshots survive navigation and restart: desktop uses owner-private atomic files under `<appSupport>/client_rpc_snapshots`, web uses dedicated IndexedDB storage, with a 16 MiB per-identity working set. Fresh results, including empty results, replace stale data. Transport loss retains readable snapshots; reconnect revalidates. Storage corruption or quota failures do not block live reads. Forget/disconnect clears the server's snapshots, and authenticated membership refresh or explicit authorization rejection invalidates affected data. The old workspace-only calendar preference snapshots are removed at startup.

This is a read cache, not an offline server or a source of mutation authority. A cold launch still requires a reachable server for authentication and workspace admission; an admitted session can continue viewing previously loaded data during an outage. Messaging keeps its snapshot refresh attached while seeding the delta mirror, resolves existing conversations from the cached list, and caches finalized transcript reads separately from live turn events.

### Media cache

Clients fetch external media through signed `/proxy/media` (`MediaProxyConfig`). `MediaCache` persists non-ranged images under `<dataDir>/media_cache`, keyed by `(url,w)`: upstream max-age clamped to 1 hour–7 days (default 24 hours), conditional ETag/Last-Modified refresh, stale-on-refresh-failure and same-key single-flight. Bucket requested widths **up** with `bucketMediaWidth` in `lib/shared/utils/media_width_ladder.dart` to share entries.

Server raster transforms cap decoded input at `8192 × 8192` pixels; ICO conversion caps it at `4096 × 4096`. These are pixel budgets, not byte/heap limits. Over-budget images retain the existing no-transform/original-stream behavior, and animated images are not flattened into thumbnails.

Newsfeed grid and list layouts use `ScrollCacheExtent.viewport(1)` to build one viewport of nearby tiles before and after the visible region, not the whole feed. `ProxiedImage` resolves only the tiny preview while a tile is in that cache region; its first paint enables the full-size request. Both variants keep the signed proxy, disk/image caches and existing cross-fade behavior. A changed URL or target width resets the full-size paint gate.
