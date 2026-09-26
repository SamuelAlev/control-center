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
| `packages/cc_infra` | VM adapters: git/process, dio integrations, dispatch, sandboxes, rigs, fleet, tunnels and CC-specific harness bridges |
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
Desktop local ── supervised cc_server ── loopback RPC
Desktop remote / web ── WSS RPC ─────── cc_server
Phone PWA ── E2E-sealed broker relay ── cc_server
MCP clients ── JSON-RPC ─────────────── tool registry
Fleet workers ── leases + events ────── cc_server
```

`lib/bootstrap/server_backend.dart` resolves the persisted local/remote choice before Riverpod starts. Local desktop spawns a supervised server; web is always remote. The connected `RemoteRpcClient` overrides `rpcClientProvider`; all client repository bindings use `cc_data`, including local desktop. Platform-specific bindings use the existing `*_bindings{,_io,_web}.dart` seams.

The server owns external APIs and background services. Dio adapters in `cc_infra` inject auth and map failures to domain `AppException`s. Workers execute leased jobs and stream events; they do not own databases, policy, approvals or budgets, and do not coordinate with each other. Architecture boundaries are enforced by `test/core/architecture_constraints_test.dart`.

### Identity and collaboration

`Principal` is `UserPrincipal | AgentPrincipal`; use it for attribution. Users are global; membership/roles and repo grants are workspace-scoped. See [authorization](SECURITY.md#authorization-and-isolation).

- Durable state: optimistic mutation + server rebase + per-field LWW. Allocate monotonic workspace `syncSeq` in the mutation transaction; receipt order, never client time, decides the last writer. Per-store kill switches restore snapshot mode.
- Presence: server-hubbed, ephemeral, never persisted; filter by repo grants before fan-out. Agent presence derives from run/lifecycle events. With one human the lane idles and roster chrome is absent.
- Follow/steer/interrupt/take-over and per-space autonomy use these lanes, not a CRDT.
- Agent peer messages use durable spaces, exact ID/unique-name resolution and no cross-workspace recipient search. `ask_agent` has a mandatory timeout (default ten minutes, workspace-capped) and pairwise cycle detection. Delegation inherits budget and autonomy ceilings, with cycle detection and a default depth cap of three. Agent-only spaces do not increment human unread badges or send OS notifications.
- `DomainEventBus` declarations under `cc_domain/lib/core/domain/events/` are authoritative. Device revocation watches `paired_devices`; there is no `UserDeviceRevoked` event. Workspace removal drops subscriptions without requiring the socket to close.

## Persistence

`cc_persistence` is pure Dart over `package:sqlite3`, without Flutter/path_provider. Only the server opens databases:

- `<dataDir>/global.db`: workspace registry, identity/preferences/devices, per-user newsfeed, fleet queue, routing and server policy/settings. The pinned global-table set is in `workspace_isolation_ratchet_test.dart`; additions require an isolation justification.
- `<dataDir>/<workspaceId>/workspace.db`: all workspace-owned data, including repos. `workspaceDatabasePath` defines the path; associated artifacts share this directory.
- `WorkspaceDatabaseManager.of(workspaceId)` synchronously returns a lazy database; disk opens on first query. Hold the manager, not a resolved DAO. `quick_check` runs on first workspace touch, not boot.
- `CrossWorkspaceQueries` is the only fan-out mechanism (`fanOut`, `fanOutKeyed`, `forEachWorkspace`, `mergeStreams`, `topN`). Its callers explain `CROSS-WORKSPACE BY DESIGN`.
- `workspace_routes` resolves pre-auth opaque IDs/secrets. Write the entity before its route; a route miss is not-found, never a workspace scan.
- The same checkout in two workspaces has two repo IDs. Cross-workspace repo identity is its path (`findByPath`), not its ID. Ordering/link time are `repos.position`/`linkedAt`.

### Schema changes

1. Put each table in exactly one database, defaulting to `WorkspaceDatabase`. DAOs extend the matching `DatabaseAccessor` and cannot declare the other database's tables. Override `tableName` with plain snake_case.
2. Read current schema versions from source. Both databases have squashed baselines; append `MigrationStep(from, to, migrate)` and bump the owning database version. Do not support pre-baseline files by silently opening them.
3. Update fresh-schema expectations in `workspace_baseline_schema_test.dart`. Regenerate Drift/JSON output with the root build_runner command in [AGENTS.md](AGENTS.md#build-and-verification).
4. FTS/vector virtual tables, external-content FTS triggers and sync-feed triggers are idempotently installed in `beforeOpen`. Partial-index changes must cover installed databases: `_createPipelineIndexes` runs only in `onCreate`, so migrations changing its predicates must explicitly drop/recreate those indexes.

`workspaceId` columns support sync/FTS/self-identification; separate files provide isolation. Vectors use sqlite_vector FLOAT32/384 dimensions with FTS-only degradation when the embedding model is unavailable, not when a required native is missing.

### Backup and restore

Snapshots are `backups/<ts>/{manifest.json,global.db,<workspaceId>/workspace.db}`, written using `VACUUM INTO`. `server.listBackups` includes incomplete snapshots and marks them incomplete. `workspace.export/import` operate on a single workspace file; restoring one from a snapshot uses the same import. Whole-install restore is a stopped-server copy-back, not another RPC operation.

RPC paths name files on the server. Remote byte transfer uses signed HTTP:

| Route | Authorization and lifecycle |
| --- | --- |
| `GET /backup/workspace` | Workspace admin; stream export, delete server copy |
| `GET /backup/snapshot` | Install owner; ZIP to a temporary file rather than buffering the installation |
| `POST /backup/restore` | Workspace owner; stream to staging, adopt, delete staging on success or refusal |

HTTP handlers enforce their own roles. Downloads use `no-store` and `Accept-Ranges: none`: every request creates a fresh export. Backups are absent in demo mode and disabled for relay-only clients without an HTTP origin. Transfer progress is throttled to 100 ms with a final byte count; upload progress means bytes handed to the socket, while the response confirms completion.

## Harness and indexing

### Repo skills

`RepoSkillCatalog` is the shared scan-gated discovery for projection and `skills.repoSkills`. `ActiveRepoTracker` observes paths at `DispatchSession.addEvent`: a write under `repos/<name>/` switches the active repo; reads only seed an unset repo. Only that repo's skills are prompt-resident.

`RepoSkillProjector` writes the overlay's `.claude/skills` and a real `AGENTS.md` for hot reload; the provisioner's `_ensureSymlink` restores its link on the next dispatch. Never project into overlay `.agents/skills`, which links to the agent-global directory. Announce swaps through **steering**, not aside: compaction drops system-role history, and `AgentLoopConfig.systemPrompt` is fixed for a run.

Invocation is `/skill:<name>` or `/skill:<repo>:<name>` (`skillNameFor`); old bare non-builtin invocations remain readable. The human composer can name any repo's skill, but a bare name must be unambiguous. Context loaders resolve symlinks only within caller-permitted roots (`resolvesInsideRoots`); the AGENTS walk never descends a linked directory. Scanning/security requirements are in [SECURITY.md](SECURITY.md#execution-and-untrusted-input).

### Deferred tool loading

- Keep external MCP `tools/list` complete. Only in-process harness schemas are deferred; tools remain callable from turn one, activating and executing in the same step.
- `HarnessToolSearchTool` uses BM25 and returns matches plus `HarnessToolResult.activateTools`. Activation is append-only after resident schemas; `toolCacheBreakpointIndex` stays at the last resident tool.
- Apply deferral after `ToolSurfaceSpec` filtering. Activation cannot add disallowed tools or bypass approval/action guards.
- Dispatch and `ContextInspectionService` share `materializeHarnessToolSurface`. Residency comes from `ModeToolPolicy` through `ModeCapabilityProfile.toToolResidencySpec()`; reserve it for tools used in most runs.
- `test/tooling/resident_tool_names_test.dart` checks real names and the under-40 budget. `--tool-deferral=off` / `CC_SERVER_TOOL_DEFERRAL` makes every admitted tool resident.

### Prompt caching

Keep sent prefixes byte-identical: append messages and tool schemas rather than mutating/reordering them. `pruneToolResults` batches rewrites at `CompactionConfig.pruneThresholdTokens` (default 2000); compaction forces pruning because it already rewrites history.

Anthropic uses four cache breakpoints: last resident tool and last system block with a one-hour TTL; previous and current request tails with short TTLs. The rolling pair (`cacheAnchorIndex`) survives wide parallel tool turns. `_subagentPilots` releases same-shape siblings on the first child's first event with a bounded wait, allowing its cache write to become readable. Subagent resident sets are profile-independent; model/effort differences fragment the prefix. `McpToolBridge` caches deterministic stripped schemas with stable key order.

Measure `cacheRead / (input + cacheRead + cacheWrite)` in `observability_metrics.dart`; cache writes belong in the denominator.

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

### Rendering assets

- [cc_ui](packages/cc_ui/README.md) and [gallery](apps/cc_gallery/README.md) own components; [DESIGN.md](DESIGN.md) owns visual rules. Do not create another kit.
- Vendor only `Phosphor-Regular.ttf`; `tool/gen_icon_seams.py` generates `AppIcons`/`CcIcons` with `fontPackage: 'cc_ui'`. An icon-package dependency loads unused styles on web and giant icon classes can overflow the DDC linker.
- Script companions are locale-loaded assets, not `fonts:` entries: Sarabun (Thai), Rubik (Hebrew), IBM Plex Sans Arabic (Arabic/Persian/Urdu); CJK uses the OS face. Do not bundle Noto CJK or eagerly load companions for English.
- Markdown uses `appMarkdownStyle`, `markdown_registries.dart`, `markdown_builders.dart` and `buildSharedCodeBlock` under `lib/shared/widgets/markdown/`. `GitHubMarkdownBody` serves forge content; `StyledMarkdownBody` tickets/meetings. Native mermaid ignores author styling in favor of `appMermaidStyle`; malformed/unsupported and unclosed streaming fences remain code. No WebView/JS diagram dependency.
- Syntax highlighting uses shiki_flutter via `lib/shared/syntax/`: shared `syntax_languages.dart`, native registry, curated web registry and deferred grammar packs (`tool/gen_grammar_packs.py`). Theme edits update `syntax_palette.dart` and bump `kCcThemeRevision`. The Flutter-free `package:shiki_flutter/engine.dart` feeds the generated diff worker. Its unmatched-token sentinel maps to inherited color; do not duplicate the magic value elsewhere.
- Global error boundaries are `PlatformDispatcher.instance.onError` and `ErrorWidget.builder`.

### Media cache

Clients fetch external media through signed `/proxy/media` (`MediaProxyConfig`). `MediaCache` persists non-ranged images under `<dataDir>/media_cache`, keyed by `(url,w)`: upstream max-age clamped to 1 hour–7 days (default 24 hours), conditional ETag/Last-Modified refresh, stale-on-refresh-failure and same-key single-flight. Bucket requested widths **up** with `bucketMediaWidth` in `lib/shared/utils/media_width_ladder.dart` to share entries.
