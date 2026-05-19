# Control Center

A multi-agent developer control center for orchestrating AI coding agents across isolated Git worktrees. Built with Flutter for desktop (macOS, Windows, Linux) and the web.

Agents run inside OS-native sandboxes, collaborate over messaging channels, review pull requests, execute DAG-based pipelines, orchestrate whole-team plans from a single goal and share a workspace-scoped knowledge memory. The app also records and summarizes meetings on-device, syncs Google Calendar (events + RSVP) and pairs with your phone over a peer-to-peer link, all behind a native GUI with GitHub, Linear and Google Calendar integration.

## Architecture

Feature-first Clean Architecture (ports & adapters) with Riverpod state management and Drift (SQLite) persistence.

### Thin-client / server model

Control Center is a **thin-client architecture**. No client opens the database — a `cc_server` process owns the data and serves it over WebSocket RPC. Every client is a renderer over that one RPC connection.

```
                         ┌─────────────────────────────┐
   desktop (LOCAL)  ──►  │  spawns cc_server here,      │
   (loopback RPC)        │  talks over 127.0.0.1        │
                         └─────────────────────────────┘
                                                         cc_server
   desktop (REMOTE) ──►  ┌─────────────────────────────┐  owns the Drift/SQLite DB,
   web client       ──►  │  dials a cc_server elsewhere │  serves repo-RPC + subscriptions
   (WSS RPC)             │  over wss://…/rpc            │  over ws://…/rpc, runs the
                         └─────────────────────────────┘  background services
                                                         (pipelines, MCP, reconcilers).
   phone (cc_remote) ──►  brokered WS relay (E2E-sealed JSON-RPC) ──► tool surface
   MCP clients       ──►  JSON-RPC 2.0 over stdio/SSE  ──► MCP tool registry
```

Four clients reach the server, each with a different trust profile:

| Client                                                              | Transport                     | What it runs                                                                                                                      |
| ------------------------------------------------------------------- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Desktop app** (LOCAL)                                             | loopback `ws://127.0.0.1` RPC | spawns a supervised `cc_server` on this machine that owns the DB; desktop is a pure renderer                                      |
| **Desktop app** (REMOTE)                                            | `wss://` RPC                  | dials a `cc_server` running elsewhere with a stored pairing key                                                                   |
| **Web build** (`scripts/build_web.sh`, SkWasm + CanvasKit fallback) | `wss://` RPC                  | always remote — a browser cannot spawn a subprocess; renders the full desktop UI                                                  |
| **Phone companion** (`cc_remote` PWA)                               | brokered relay + JSON-RPC     | a lighter, read-mostly client; a lower-privilege principal (default-deny tool policy)                                             |
| **Fleet executor** (`cc_worker`)                                    | `wss://` RPC (leased jobs)    | a headless pure-Dart binary that pulls leased jobs from a `cc_server`, executes them, streams events back; holds no durable state |
| **MCP clients**                                                     | JSON-RPC 2.0                  | external tools that consume the MCP tool registry                                                                                 |

The boot resolver (`lib/bootstrap/server_backend.dart`) reads the user's persisted **server-connection choice** before Riverpod exists: first run shows a setup screen; LOCAL spawns a `cc_server` (owning the _same_ `control_center.db` under the app-support root); REMOTE dials the configured URL with the keychain-stored pairing key. The resulting connected `RemoteRpcClient` overrides `rpcClientProvider`, so the whole UI and every feature provider read/write through the server instead of an in-process Drift host. The web build runs the same resolver but is forced to REMOTE (a browser can never self-serve).

### Workspace (single resolved `pubspec.lock`)

The repository is a **native Dart pub workspace**. The root app and its twenty members (5 apps + 15 packages) share a single resolved lockfile. The server half is pure-Dart (no Flutter engine) so it compiles to a self-contained native binary; the client half is Flutter.

**Apps**

| Member                     | Role                                                                                                                                                                                                                                                                                                                                                                           |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `control_center` (root)    | The Flutter **desktop + web app**: everything under `lib/` below. The thin client.                                                                                                                                                                                                                                                                                             |
| `apps/cc_server`           | **Headless server** — a pure-Dart `dart build cli` binary (no Flutter). Owns the `cc_persistence` databases (`global.db` + one directory per workspace), serves repo-RPC over WebSocket.                                                                                                                                                                                       |
| `apps/cc_worker`           | **Headless fleet executor** — a pure-Dart `dart build cli` binary. Pairs with a `cc_server`, declares its host capabilities, pulls leased jobs, executes them and streams process events back. Holds **no durable state** (no DB, auth, approvals, or budgets — those never leave `cc_server`); one authoritative server, N dumb limbs, no consensus/worker-to-worker traffic. |
| `apps/cc_remote`           | **Phone thin client** — a Flutter web PWA that remote-controls the fleet over the brokered relay (E2E-sealed JSON-RPC frames).                                                                                                                                                                                                                                                 |
| `apps/cc_signaling_server` | Pure-Dart, stateless WebSocket **relay broker** hosting N-capacity invite-gated rooms. A dumb relay — it never interprets frames, holds no app data and never sees the PSK.                                                                                                                                                                                                    |
| `apps/cc_gallery`          | A **Widgetbook** catalogue of `cc_ui` (the living design-system reference).                                                                                                                                                                                                                                                                                                    |

**Packages**

| Member                          | Role                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages/cc_ui`                | The in-repo **design system**: tokens, theme, foundation primitives and 30+ `Cc*` components. Built on `flutter/widgets.dart`, no Material or Cupertino.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `packages/cc_domain`            | Pure-Dart **shared kernel**: all domain entities, value objects, ports, repositories, events and services, plus every feature's `domain/` layer. Zero infrastructure deps (no drift/dio/dart:io/ffi) so it imports on native and web.                                                                                                                                                                                                                                                                                                                                                                                        |
| `packages/cc_harness`           | Pure-Dart **agent-loop kernel** — the built-in agent runtime core: messages, provider port, tools, compaction, steering, hooks, subagents, slash commands. Web-safe (no dart:io, no other cc\_\* dep), embeddable by `cc_server`, `cc_worker`, tests and third parties.                                                                                                                                                                                                                                                                                                                                                      |
| `packages/cc_harness_runtime`   | **VM-only batteries** for the `cc_harness` kernel — Anthropic/OpenAI/Ollama streaming providers, OAuth/PKCE credential brokering, file/env credential stores, the generic tool set, AGENTS.md + skills context loaders, watchdog advisor. The CC-coupled adapters (sandboxed command runner, MCP bridge, apply_patch) stay in `cc_infra`.                                                                                                                                                                                                                                                                                    |
| `packages/cc_rpc`               | Transport-agnostic **JSON-RPC client + channel transports** (web-safe: no dart:io/ffi). The desktop in REMOTE mode, the full web build and the `cc_remote` PWA all dial a `cc-server` through this.                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `packages/cc_host`              | **Server-side RPC kernel** — per-connection sessions, the repo-op dispatcher, reactive subscriptions, rate limiting, the remote tool policy, the presence hub and the WSS server transport. VM-only.                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `packages/cc_data`              | **Remote data layer** — repository adapters that satisfy reads/writes over the `cc_rpc` client instead of a local database. Web-safe.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `packages/cc_persistence`       | Pure-Dart **persistence** for the headless server over `package:sqlite3` (no Flutter, no `path_provider`). **Two databases:** `GlobalDatabase` (`global.db` — the workspace registry, identity, newsfeed, fleet queue, pre-auth routing) and `WorkspaceDatabase` (one file per workspace, holding everything else including repos), handed out by `WorkspaceDatabaseManager`; `CrossWorkspaceQueries` is the only sanctioned way to span workspaces. The split makes workspace isolation a compile-time property rather than a WHERE-clause convention.                                                                      |
| `packages/cc_infra`             | **Server-side VM-only infrastructure adapters** — pure `dart:io` implementations of ports: git/process, the dio HTTP clients (the three forge adapters — GitHub REST/GraphQL, GitLab REST v4, Bitbucket Cloud REST 2.0 — plus Linear and Google Calendar), agent dispatch + sandboxing + the CC-coupled harness adapters (sandboxed command runner, MCP bridge, apply_patch), meetings ML (Whisper/diarization), schema validation, adapter/ACP-model detection, fleet execution and supervised tunnel binaries, plus the rift/fff/tree-sitter natives via `cc_natives`. No Flutter, so it links into the Flutter-free server binary.                                                                      |
| `packages/cc_mcp`               | The **MCP tool surface** (server-side): Ref-free typed tools (~80 wired) + the JSON-RPC tool dispatcher.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `packages/cc_mcp_client`        | **MCP client** — connects to _external_ MCP servers (stdio / HTTP / SSE + OAuth) and bridges their tools/resources/prompts into CC's registry.                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `packages/cc_server_core`       | **App-server composition** for the headless server — the repo-RPC catalog (tickets/messaging/newsfeed), the MCP registry wiring, the `LocalRpcServer`, live event forwarding and the identity, presence, fleet and evals runtime. No Flutter.                                                                                                                                                                                                                                                                                                                                                                                |
| `packages/cc_markdown`          | The in-repo **markdown engine** — a custom typed-AST parser + widget renderer (`CcMarkdown` one-shot, `CcStreamingMarkdown` for LLM streaming) plus a native **mermaid diagram engine** (`CcMermaidView`: pure-Dart dialect parsers → layered/sequence/chart layout → `CustomPainter`, no WebView, no JS). Widgets-only except the selection island.                                                                                                                                                                                                                                                                         |
| `packages/cc_natives`           | The **native FFI leaf** (rift copy-on-write worktrees, fff file finder, tree-sitter code indexing + grammars, `cc_watcher` file watching, `ccpty` terminals, aec echo cancellation, lame MP3 and the onnx/sherpa inference runtimes). Pure Dart FFI, no Flutter; the one crate whose native source lives here is `native/watcher/`. **Every native is REQUIRED** — loaders throw a `NativeLibraryUnavailable`, `cc_server` refuses to boot on a miss and the build/packaging scripts fail rather than shipping a degraded artifact; `rift` on Windows is the single platform exemption. See `packages/cc_natives/README.md`. |
| `packages/system_audio_capture` | Plugin: driver-free system-audio loopback capture (Core Audio taps / WASAPI / PipeWire).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

```
lib/
├── bootstrap/            # Platform bootstraps: desktop (bootstrap_io), web (bootstrap_web),
│   # server_backend (resolves the cc_server connection), thin_client_boot (local spawn)
├── core/                 # Cross-cutting CLIENT infrastructure (the domain + DB + network live in packages)
│   ├── config/           # App and environment configuration
│   ├── constants/        # App-wide constants, log levels
│   ├── deep_link/        # Deep-link handler routing URL schemes into the app
│   ├── domain/           # Nearly empty — the shared kernel moved to cc_domain; a few client-only services remain
│   ├── infrastructure/   # Client-side platform services: audio, embeddings, file search, speech, skills
│   ├── keybindings/      # Keybinding registry + dispatcher (command palette / shortcuts)
│   ├── notifications/    # Notification center, service, sounds, preferences, event→notification mapper
│   ├── observability/    # Sentry bootstrap
│   ├── offline/          # Offline mutation queue (buffers writes while the server is unreachable)
│   ├── providers/        # Central infrastructure Riverpod providers (rpc client, server connection, storage, event bus, sync engine, locale)
│   ├── server/           # Desktop↔cc_server connection: config, process supervisor, endpoint
│   ├── storage/          # Local path resolution + non-sensitive preference storage
│   ├── sync/             # Optimistic-mutation client helpers for the durable sync lane
│   ├── theme/            # Material 3 base theme + design-system token re-export shims (tokens live in cc_ui)
│   ├── undo/             # Universal undo: the client-side action journal
│   └── utils/            # App-wide logging (AppLog)
├── features/             # Feature modules (presentation + client providers; each feature's domain/ lives in cc_domain)
│   ├── agents/           # Agent registry screen (roster + per-agent config), doctor diagnostics, cost tracking
│   ├── artifacts/        # Native renderer for typed work-product blocks (charts, tables, mermaid, code, JSON trees — deliberately no HTML)
│   ├── auth/             # GitHub/Linear authentication, onboarding, credentials repository
│   ├── calendar/         # Google Calendar sync + RSVP (OAuth+PKCE) + month/week/agenda views + meeting alerts + record-and-link
│   ├── dashboard/        # Global overview with system metrics, agent process matching
│   ├── dispatch/         # Agent dispatch: run-process lifecycle, prompt assembly, modes (absorbed agent_modes)
│   ├── focus_mode/       # Ephemeral distraction-free PR review UI
│   ├── identity/         # Multi-user identity, membership, roles, invites, per-user device registry
│   ├── inbox/            # Unified cross-pillar inbox + ⌘K omnibox
│   ├── mcp/              # MCP settings/status UI (the tool surface itself lives in the cc_mcp package)
│   ├── meetings/         # Local meeting notes: system+mic capture, on-device Whisper transcription, diarization, AI summary
│   ├── memory/           # Knowledge management: facts, policies, domains, embeddings, knowledge graph
│   ├── messaging/        # Chat channels + channels (merged chat + messaging context); agent peer messaging + delegation
│   ├── newsfeed/         # RSS/Atom aggregation with ad-blocking and content curation
│   ├── observability/    # Live Agent Hub + cost/usage/quota/behavior/model/goal/benchmark analytics
│   ├── orchestration/    # One goal → a proposed whole-team plan (roles, sub-tickets, synthesis) → one approval → a materialized pipeline + tickets
│   ├── pipelines/        # DAG-based workflow orchestration + template editor + execution engine
│   ├── plan_studio/      # Editable DAG plan canvas: per-step cost/time/risk estimates, plan diff versioning, partial approval, Playbooks
│   ├── presence/         # Real-time collaboration: presence/awareness, follow-mode, steer/take-over/hand-back, autonomy dial
│   ├── pr_review/        # PR lifecycle, diff viewer, inline comments, review sessions, IDE launch; Review Studio (semantic cohorts, per-axis gates, API-contract + visual diffs) is a tab in PR detail
│   ├── remote_control/   # Phone/browser companion over the brokered relay: QR pairing, default-deny tool policy, per-session workspace binding
│   ├── rigs/             # Enclosures: live viewer for the disposable VMs agents drive (computer / browser / mobile use), take-over controls, host↔guest clipboard and file drag-and-drop
│   ├── repos/            # Git repository management + per-channel worktree provisioning
│   ├── sandboxing/       # Process isolation: OS-native sandbox adapters, capability controls, credential brokering; terminals can run inside an enclosure (rig) and accept dropped files as guest paths
│   ├── session_review/   # Session-diff viewer (git changes for a run) with imported VS Code syntax colors
│   ├── service_status/   # External service health flyout (GitHub / Claude / Codex / Kimi; server-side Statuspage polling, worst-of chip)
│   ├── settings/         # The settings SHELL: routes, nav model, page scaffold, generic cards. Feature-owned
│                         #   pages/sections arrive through settings_extensions.dart, aggregated in di/settings_registry.dart
│   ├── shell/            # App shell layout (sidebar, title bar, content area, command palette, breadcrumbs, banner rail)
│   ├── soundscape/       # Generative ambient audio (weather + clock + mood folded into a soundscape context)
│   ├── subscriptions/    # AI-plan usage pill (Claude Code / Codex / z.ai): most-constrained provider + reset countdowns
│   ├── teams/            # Agent team grouping and coordinated dispatch
│   ├── ticketing/        # Vendor-agnostic tickets (Local + Linear; Jira/GitHub sync) + projects + MCP tools (absorbed the tasks feature)
│   ├── todos/            # Per-channel task checklists behind the todo_write tool (agents + user), watched live
│   ├── user_profiles/    # GitHub user profile display with PR filtering
│   ├── vscode_theme/     # Imports VS Code editor themes → lightweight color set for diff/code surfaces
│   └── workspaces/       # Git worktree workspace management with event-driven CEO seeding
├── di/                   # Composition root: binds repository ports to implementations (providers.dart + provider_bindings{,_io,_web}.dart)
├── l10n/                 # Internationalization: ARB source files (7 languages) + generated localizations
├── router/               # GoRouter config, route constants, auth guards, splash
├── shared/               # Shared widgets, domain services, extensions, utilities
└── main.dart             # Entry point: selects bootstrap_io (VM) vs bootstrap_web (web)
```

### Feature layer convention

```
feature_name/
├── data/          # Repository implementations, data sources, services, DTOs, mappers
│   ├── datasources/
│   ├── repositories/
│   ├── services/
│   └── mappers/
├── domain/        # Entities, repository interfaces (abstract), ports, use cases
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/  # Screens (<250 lines), widgets (<300 lines), notifiers
│   ├── screens/
│   └── widgets/
└── providers/     # Riverpod providers for this feature
```

### Dependency rule

```
Presentation → Application/Providers → Domain ← Infrastructure
```

Ports and adapters enforce Clean Architecture boundaries:

- **Domain layer:** zero infrastructure imports (no dio, drift, or network models).
- **Presentation layer:** no direct drift/DAO/data-layer access; everything goes through Riverpod providers → repositories.
- Infrastructure adapters implement domain ports; domain entities use enums/sealed classes for status fields (no magic strings).
- `DomainEventBus` enables decoupled cross-feature communication.

In the thin-client model, every feature's data layer is remote: LOCAL/REMOTE/web all use the `cc_data` RPC-backed repositories over the connected `cc_server`. The composition root (`di/providers.dart` + the `di/provider_bindings{,_io,_web}.dart` platform seam) binds repository ports to these implementations; a feature that needs platform-specific binding bodies carries its own `<feature>_bindings{,_io,_web}.dart` seam (e.g. `ticketing/ticketing_bindings.dart`).

Boundaries are validated by `test/core/architecture_constraints_test.dart`.

### Workspace isolation

Workspaces are isolation tenants; data from one must never surface in another. Every workspace-scoped operation takes a **required** `workspaceId`; DAO reads filter by it; ID-only lookups are scoped or validated; cross-workspace access is denied loudly with `WorkspaceMismatchException` (domain) or an explicit MCP error. The few genuinely global queries (dashboard, observability aggregation, startup reconcilers) carry a `CROSS-WORKSPACE BY DESIGN` doc comment. The RPC session enforces the same invariant: every server session is bound to exactly one workspace, so a remote client bound to workspace A cannot reach workspace B by passing a foreign id.

### Identity & multiplayer

Control Center is multi-user: humans and agents are co-equal actors. A `Principal` (sealed `UserPrincipal` | `AgentPrincipal`) in the shared kernel is the abstraction every attribution, message, ticket, review, plan and run log resolves through. `User` is global (cross-workspace); membership is a workspace-scoped `workspace_members` row at a `WorkspaceRole` (`owner`/`admin`/`member`/`viewer`/`guest`) held in that workspace's own database file. **Membership is the access test — holding a pairing key is no longer the boundary; being a member is.** Per-repo grants (`workspace_member_repo_grants`: `none`/`read`/`review`/`write`) keep workspace membership from silently out-privileging the forge. Rate limits are per-principal (one user across N devices shares one budget); revocation is live — a revoked device/member's sessions terminate within seconds, not on next reconnect (`UserDeviceRevoked`, `WorkspaceMemberRemoved`). Self-hosted-first identity: first user is admin, invite by link, passkeys, OIDC optional.

Real-time collaboration is **authoritative-server + per-field last-writer-wins (LWW), not a CRDT** — the consensus across Figma/Linear/Replicache and a Dart CRDT would mean Rust-via-`cc_natives` FFI (reserved for one possible future co-editing surface only). Two lanes never mix:

- **Durable lane** — optimistic-mutation + server-rebase + per-field LWW, on a monotonic per-workspace `syncSeq` allocated inside the same DB transaction as the mutation (`sync_changes` table). Ordering never trusts a client clock; "last writer" = server receipt order. Per-store flags revert to snapshot mode (the kill-switch); staged store-by-store.
- **Ephemeral lane** — presence/awareness (`ParticipantPresence`: status, locus, cursor, typing, agent live-status + running cost), server-hubbed and **never persisted**. Repo-grant filtering applies at the server before fan-out, so presence never leaks content a viewer can't open.

Humans and agents share one roster (agent presence is synthesized server-side from run/lifecycle events); follow-mode (incl. "watch an agent work"), steer/interrupt/take-over/hand-back and a per-channel autonomy dial (`propose-only`/`act-with-approval`/`act-freely`) sit on top. Solo-mode zero-regression: with one human the presence lane idles and no roster chrome appears.

### Action guardrails & agent interaction

- **Unified action guardrails** generalize the former bash-only `CommandPolicy` into a closed **`ActionClass`** taxonomy (~12 effect classes). Resolution is `channel > agent > workspace > mode preset > built-in default` (most-specific scope wins; within a scope, longest-prefix then most-restrictive). Every mutating tool declares its ActionClass(es); `prompt` with no approver connected is **denied** (fail-closed). The autonomy dial is a named profile over this same store.
- **Agent peer messaging & delegation** ride channels (durable, roster-visible) — the old in-memory IRC bus was deleted. `ask_agent` is request/reply with a **mandatory timeout** and cycle detection; `delegate_task` is guarded by depth cap, cycle detection, budget-envelope inheritance and an autonomy ceiling, all enforced server-side at a chokepoint.
- **Skills supply-chain scanning** is a fail-closed gate between fetch and write: no skill content reaches disk or an agent prompt without a verdict (`pass`/`warn`/`quarantine`). The scanner is inert by construction; trust tiers are provenance, never a scan substitute.

### Design system (cc_ui) & gallery

The app owns its entire visual layer through the `cc_ui` workspace package.
`cc_ui` exposes a token system (`DesignSystemTokens`,
`CcTypography`, `AppSpacing`, `AppRadii`, `AppShadows`/`CcElevation`, `CcMotion`),
a `CcTheme` (read via `context.designSystem`), foundation primitives and 30+
`Cc*` components. Its purity (no Material/Cupertino/infrastructure imports) is
verified by the same `architecture_constraints_test.dart`.

`apps/cc_gallery` is the **living reference**, a Widgetbook catalogue with ~165
use-cases across **Components** (Buttons, Inputs, Feedback, Containers,
Navigation & Overlays, Layout) and **Foundations** (token specimens + primitives).
Toggle the Light/Dark theme addon to audit both palettes. See
`apps/cc_gallery/README.md` for the authoring workflow and
`packages/cc_ui/README.md` for the package API; the visual spec the system
implements is `DESIGN.md`.

### Stack

| Concern                  | Technology                                                                                                                                                                                                                                                                                                 |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| State management         | flutter_riverpod (Notifier / AsyncNotifier / Provider)                                                                                                                                                                                                                                                     |
| Routing                  | go_router (ShellRoute app shell + redirect guards)                                                                                                                                                                                                                                                         |
| Database                 | drift (SQLite) with DAO pattern, **split by workspace**: `GlobalDatabase` (`global.db`, schema v1) + one `WorkspaceDatabase` per workspace (`<workspaceId>/workspace.db`, schema v2), squashed baseline + `MigrationStep` chain, ~110 tables, owned by `cc_persistence`; FTS5 + sqlite_vector, server-only |
| Client↔server RPC        | cc_rpc (JSON-RPC client + WSS/in-process/brokered-relay transports) · cc_host (server kernel: sessions, dispatcher, subscriptions, rate limiting, presence hub)                                                                                                                                            |
| Networking               | dio (GitHub REST/GraphQL, GitLab REST v4, Bitbucket Cloud REST 2.0, Linear GraphQL, Google Calendar REST) + OAuth 2.0 PKCE (Google) + json_serializable models                                                                                                                                                                                       |
| UI components            | **cc_ui** (in-repo design system: tokens, theme, 30+ `Cc*` components, no Material/Cupertino) over a token-based Material 3 base theme, fl_chart, kalender (calendar month/week views); the Plan Studio canvas is custom-drawn                                                                             |
| Markdown & code          | **cc_markdown** (in-repo typed-AST parser + widget renderer: `CcMarkdown` / `CcStreamingMarkdown`, plus the native mermaid engine `CcMermaidView`), shiki_flutter (TextMate-grammar syntax highlighting for code blocks and diffs, themed by the custom CC theme in `lib/shared/syntax/`)                  |
| Icons & graphics         | Phosphor Regular, vendored into cc_ui and reached through the AppIcons/CcIcons codepoint seams (no icon package dependency — see `test/tooling/icon_font_bundle_test.dart`), flutter_svg, GLSL fragment shaders                                                                                            |
| On-device ML             | sherpa_onnx + onnxruntime_v2 (Whisper meeting transcription + pyannote speaker diarization, speech-to-text), sqlite_vector + dart_wordpiece (embeddings)                                                                                                                                                   |
| Audio & video            | record (microphone), system_audio_capture (driver-free loopback: Core Audio taps / WASAPI / PipeWire), WebRTC AEC3, audioplayers, video_player + chewie                                                                                                                                                    |
| Terminal & FFI           | xterm + flutter_pty (sandboxed terminal), ffi (rift worktrees, file finder, tree-sitter, native file watcher via cc_natives)                                                                                                                                                                               |
| Desktop integration      | nativeapi (windowing incl. multi-window, plain storage, URL launching — consolidates what used to be four separate plugins), local_notifier, file_selector                                                                                                                                                 |
| Off-main-thread compute  | isolate_manager (real isolates on native; generated Web Workers on web — diff parsing, large markdown, graph layout)                                                                                                                                                                                       |
| Embedded web             | flutter_inappwebview (article webview, code-server panes)                                                                                                                                                                                                                                                  |
| Remote control           | Brokered WebSocket relay (cc_rpc `RelayClientChannel` + E2E frame crypto), qr_flutter (pairing QR), crypto (PSK pairing handshake)                                                                                                                                                                         |
| Security                 | flutter_secure_storage (keychain/keystore), crypto                                                                                                                                                                                                                                                         |
| Internationalization     | intl + flutter_localizations (7 languages, `generate: true`)                                                                                                                                                                                                                                               |
| Code generation          | build_runner, json_serializable, drift_dev, widgetbook_generator (cc_gallery navigation tree)                                                                                                                                                                                                              |
| Architecture enforcement | architecture_constraints_test.dart                                                                                                                                                                                                                                                                         |
| CI                       | GitHub Actions (ubuntu-latest): analyze, test, architecture test; plus deploy workflows for the web app, the Remote PWA and the design system                                                                                                                                                              |

### Route map

The app shell (`ControlCenterLayout`) wraps every route via a `ShellRoute`. **Every in-shell destination is workspace-prefixed — `/workspaces/:workspaceId/…` — and the workspace id in the URL is the single source of truth for the active workspace** (`activeWorkspaceIdProvider` is driven from the route). `/splash`, `/onboarding` and the bare `/workspaces` picker render full-screen outside the shell. The auth guard keeps the user on `/onboarding` until GitHub auth (PAT or `gh` CLI) **and** at least one workspace exist. Paths below omit the `/workspaces/:workspaceId` prefix for brevity.

| Path (under `/workspaces/:workspaceId`)                                               | Screen                                                                                                                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/splash` · `/onboarding` · `/workspaces`                                             | Startup splash · first-run setup · workspace picker (all full-screen, no prefix)                                                                                                                                                                                                                        |
| `/dashboard`                                                                          | Global dashboard (the workspace root redirects here)                                                                                                                                                                                                                                                    |
| `/inbox`                                                                              | Unified inbox: PRs by review lifecycle + everything else blocking the operator                                                                                                                                                                                                                          |
| `/pull-requests` · `/pull-requests/compose` · `/pull-requests/:owner/:repo/:prNumber` | PR list · compose · PR detail with diff viewer                                                                                                                                                                                                                                                          |
| `/channels` · `/channels/:channelId`                                                  | Agent chat + channels, deep-linkable to a message via `?m=`                                                                                                                                                                                                                                             |
| `/tickets` · `/tickets/:ticketId`                                                     | Ticket board · ticket master-detail                                                                                                                                                                                                                                                                     |
| `/projects/:projectId`                                                                | Project overview (grouped tickets + progress)                                                                                                                                                                                                                                                           |
| `/observability`                                                                      | Observability hub: live Agent Hub + cost/usage/quota/behavior analytics + fleet panel                                                                                                                                                                                                                   |
| `/meetings` · `/meetings/record` · `/meetings/:meetingId`                             | Meetings list · live recording · meeting detail (notes/transcript)                                                                                                                                                                                                                                      |
| `/calendar` · `/calendar/:eventId`                                                    | Calendar (month/week/agenda) · event detail                                                                                                                                                                                                                                                             |
| `/newsfeed` · `/newsfeed/article/:articleId`                                          | Newsfeed list · article webview (feed management lives at `/settings/you/newsfeed`)                                                                                                                                                                                                                                                              |
| `/pipelines` · `/pipelines/run` · `/pipelines/:runId`                                 | Pipelines · run launcher · run detail                                                                                                                                                                                                                                                                   |
| `/plans` · `/plans/:kind/:id`                                                         | Plan Studio hub (active plans, plan documents, playbooks) · Plan Studio for one plan (`kind` = `orchestration`\|`document`)                                                                                                                                                                             |
| `/memory`                                                                             | Workspace knowledge memory                                                                                                                                                                                                                                                                              |
| `/users/:login`                                                                       | GitHub user profile                                                                                                                                                                                                                                                                                     |
| `/api-keys`                                                                           | API key management                                                                                                                                                                                                                                                                                      |
| `/settings/*` (incl. `/settings/you/newsfeed`)                                       | `/settings` redirects to `/settings/appearance`; then appearance, notifications, accounts, members, mcp, remote-control, advanced, voice-meetings, security, guardrails, adapters, agents, repositories, skills, keybindings, pipelines (+ template editor at `/settings/pipelines/:templateId`), teams |

## Getting Started

```bash
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs  # after drift/JSON model changes
fvm flutter gen-l10n                                                  # after ARB (l10n) changes
fvm flutter run -d macos  # or windows, linux
```

### Run the headless server

The `cc_server` binary is a pure-Dart native executable (no Flutter engine):

```bash
cd apps/cc_server
dart build cli
# provision a thin client before first start:
./build/cli/<os_arch>/bundle/bin/cc_server pair --data-dir ./data --port 9030
./build/cli/<os_arch>/bundle/bin/cc_server --data-dir ./data --port 9030
```

See `apps/cc_server/README.md` for flags, pairing and the `calendar connect` subcommand.

## Testing

```bash
fvm flutter test --concurrency=1                                     # root app suite (other suites: --concurrency=2)
fvm flutter test test/core/architecture_constraints_test.dart --concurrency=1  # architecture validation
```

Always cap test concurrency (`--concurrency=2`; `--concurrency=1` for the root app suite): an uncapped `flutter test` spawns one `flutter_tester` per CPU core, each loading the whole app plus a `frontend_server` compiler and can exhaust machine memory.

Tests cover network models, database DAOs (including workspace-isolation scoping and cross-workspace denial), auth + identity/membership, router and route guards, domain entities, domain services (with hand-rolled fakes), use cases, the deterministic sync/presence lanes, the action-guardrail policy resolver, the thin-client RPC parity surface (`InProcessRpcChannel`) and architecture constraints.
