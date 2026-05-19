# Control Center

A multi-agent developer control center for orchestrating AI coding agents across isolated Git worktrees. Built with Flutter for desktop (macOS, Windows, Linux) and the web.

Agents run inside OS-native sandboxes, collaborate over messaging channels, review pull requests, execute DAG-based pipelines, orchestrate whole-team plans from a single goal, and share a workspace-scoped knowledge memory. The app also records and summarizes meetings on-device, syncs Google Calendar (events + RSVP), and pairs with your phone over a peer-to-peer link, all behind a native GUI with GitHub, Linear, and Google Calendar integration.

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
   phone (cc_remote) ──►  WebRTC data channel ── JSON-RPC ──► tool surface
   MCP clients       ──►  JSON-RPC 2.0 over stdio/SSE  ──► MCP tool registry
```

Four clients reach the server, each with a different trust profile:

| Client | Transport | What it runs |
|---|---|---|
| **Desktop app** (LOCAL) | loopback `ws://127.0.0.1` RPC | spawns a supervised `cc_server` on this machine that owns the DB; desktop is a pure renderer |
| **Desktop app** (REMOTE) | `wss://` RPC | dials a `cc_server` running elsewhere with a stored pairing key |
| **Web build** (`flutter build web`) | `wss://` RPC | always remote — a browser cannot spawn a subprocess; renders the full desktop UI |
| **Phone companion** (`cc_remote` PWA) | WebRTC data channel + JSON-RPC | a lighter, read-mostly client; a lower-privilege principal (default-deny tool policy) |
| **MCP clients** | JSON-RPC 2.0 | external tools that consume the MCP tool registry |

The boot resolver (`lib/bootstrap/server_backend.dart`) reads the user's persisted **server-connection choice** before Riverpod exists: first run shows a setup screen; LOCAL spawns a `cc_server` (owning the *same* `control_center.db` under the app-support root); REMOTE dials the configured URL with the keychain-stored pairing key. The resulting connected `RemoteRpcClient` overrides `rpcClientProvider`, so the whole UI and every feature provider read/write through the server instead of an in-process Drift host. The web build runs the same resolver but is forced to REMOTE (a browser can never self-serve).

### Workspace (single resolved `pubspec.lock`)

The repository is a **native Dart pub workspace**. The root app and its fifteen members share a single resolved lockfile. The server half is pure-Dart (no Flutter engine) so it compiles to a self-contained native binary; the client half is Flutter.

**Apps**

| Member | Role |
|---|---|
| `control_center` (root) | The Flutter **desktop + web app**: everything under `lib/` below. The thin client. |
| `apps/cc_server` | **Headless server** — a pure-Dart `dart build cli` binary (no Flutter). Owns the `cc_persistence` Drift/SQLite DB, serves repo-RPC over WebSocket. |
| `apps/cc_remote` | **Phone thin client** — a Flutter web PWA that remote-controls the fleet over a WebRTC DataChannel carrying JSON-RPC. |
| `apps/cc_signaling_server` | Pure-Dart, stateless WebSocket **signaling broker** for WebRTC pairing. A dumb relay — it never interprets SDP/ICE, holds no app data, and never sees the PSK. |
| `apps/cc_gallery` | A **Widgetbook** catalogue of `cc_ui` (the living design-system reference). |

**Packages**

| Member | Role |
|---|---|
| `packages/cc_ui` | The in-repo **design system**: tokens, theme, foundation primitives, and 30+ `Cc*` components. Built on `flutter/widgets.dart`, no Material or Cupertino. |
| `packages/cc_domain` | Pure-Dart **shared contracts**: JSON-RPC wire types and wire DTOs consumed by both the desktop app and the `cc_remote` PWA. Zero infrastructure deps (no drift/dio/dart:io/ffi) so it imports on native and web. |
| `packages/cc_rpc` | Transport-agnostic **JSON-RPC client + channel transports** (web-safe: no dart:io/ffi). The desktop in REMOTE mode, the full web build, and the `cc_remote` PWA all dial a `cc-server` through this. |
| `packages/cc_host` | **Server-side RPC kernel** — per-connection sessions, the repo-op dispatcher, reactive subscriptions, rate limiting, the remote tool policy, and the WSS server transport. VM-only. |
| `packages/cc_data` | **Remote data layer** — repository adapters that satisfy reads/writes over the `cc_rpc` client instead of a local database. Web-safe. |
| `packages/cc_persistence` | Pure-Dart **persistence** for the headless server — opens the Drift/SQLite DB over `package:sqlite3` (no Flutter, no `path_provider`). |
| `packages/cc_infra` | **Server-side VM-only infrastructure adapters** — pure `dart:io` implementations of ports (git, process, GitHub CLI, schema validation, adapter/ACP-model detection, rift/fff/tree-sitter natives via `cc_natives`). No Flutter, so it links into the Flutter-free server binary. |
| `packages/cc_mcp` | The **MCP tool surface** (server-side). |
| `packages/cc_server_core` | **App-server composition** for the headless server — the repo-RPC catalog (tickets/messaging/newsfeed), the `LocalRpcServer`, live event forwarding, and the paired-device secrets port. No Flutter. |
| `packages/cc_natives` | The **native FFI leaf** (rift copy-on-write worktrees, fff file finder, tree-sitter code indexing). Pure Dart FFI, no Flutter. |
| `packages/system_audio_capture` | Plugin: driver-free system-audio loopback capture (Core Audio taps / WASAPI / PipeWire). |

```
lib/
├── bootstrap/            # Platform bootstraps: desktop (bootstrap_io), web (bootstrap_web),
│   # server_backend (resolves the cc_server connection), thin_client_boot (local spawn)
├── core/                 # Cross-cutting infrastructure
│   ├── config/           # App and environment configuration
│   ├── constants/        # App-wide constants, log levels, keybindings
│   ├── database/         # Drift table definitions + FTS query utils shared with cc_persistence
│   ├── deep_link/        # Deep-link handler routing URL schemes into the app
│   ├── domain/           # Shared kernel: entities, repositories, ports, services, value objects, events
│   ├── errors/           # Sealed AppException hierarchy (network, workspace mismatch, …)
│   ├── infrastructure/   # Client-side platform services: audio, embeddings, file search, speech, skills
│   ├── network/          # dio HTTP clients (GitHub REST/GraphQL, Linear) + retry interceptor + error mapper
│   ├── notifications/    # Notification center, service, sounds, preferences, event→notification mapper
│   ├── observability/    # Sentry bootstrap
│   ├── providers/        # Central infrastructure Riverpod providers (rpc client, DAOs, dio, auth, storage)
│   ├── security/         # Command redaction (strips secrets from logged output)
│   ├── server/           # Desktop↔cc_server connection: config, process supervisor, endpoint
│   ├── storage/          # Local path resolution + non-sensitive preference storage
│   ├── theme/            # Material 3 + design system token system (palette, tokens, fonts)
│   └── utils/            # App-wide logging (AppLog)
├── features/             # Feature modules (Clean Architecture, ports & adapters)
│   ├── agents/           # Agent management, doctor diagnostics, cost tracking
│   ├── analytics/        # Performance metrics, achievements/badges, leaderboards
│   ├── auth/             # GitHub/Linear authentication, onboarding, credentials repository
│   ├── calendar/         # Google Calendar sync + RSVP (OAuth+PKCE) + month/week/agenda views + meeting alerts + record-and-link
│   ├── code_graph/       # Native code indexing → symbol/edge graph for search and code facts
│   ├── dashboard/        # Global overview with system metrics, agent process matching
│   ├── dispatch/         # Agent dispatch: run-process lifecycle, prompt assembly, conversation modes (absorbed agent_modes)
│   ├── focus_mode/       # Ephemeral distraction-free PR review UI
│   ├── github_status/    # GitHub service health indicator (stateless HTTP polling)
│   ├── mcp/              # MCP server + typed tools (uses application/ instead of presentation/)
│   ├── meetings/         # Local meeting notes: system+mic capture, on-device Whisper transcription, diarization, AI summary
│   ├── memory/           # Knowledge management: facts, policies, domains, embeddings, knowledge graph
│   ├── messaging/        # Chat conversations + channels (merged chat + messaging context)
│   ├── newsfeed/         # RSS/Atom aggregation with ad-blocking and content curation
│   ├── orchestration/    # One goal → a proposed whole-team plan (roles, sub-tickets, synthesis) → one approval → a materialized pipeline + tickets
│   ├── pipelines/        # DAG-based workflow orchestration + template editor + execution engine
│   ├── pr_review/        # PR lifecycle, diff viewer, inline comments, review sessions, IDE launch
│   ├── remote_control/   # Phone/browser companion over WebRTC P2P: QR pairing, default-deny tool policy, per-session workspace binding
│   ├── repos/            # Git repository management + per-conversation worktree provisioning
│   ├── sandboxing/       # Process isolation: OS-native sandbox adapters, capability controls, credential brokering
│   ├── settings/         # App settings (agents, adapters, repos, teams, skills, pipelines, server connection, devices)
│   ├── shell/            # App shell layout (sidebar, title bar, content area, command palette, breadcrumbs)
│   ├── teams/            # Agent team grouping and coordinated dispatch
│   ├── ticketing/        # Vendor-agnostic tickets (Local + Linear) + MCP tools (absorbed the tasks feature)
│   ├── user_profiles/    # GitHub user profile display with PR filtering
│   └── workspaces/       # Git worktree workspace management with event-driven CEO seeding
├── di/                   # Composition root: binds repository ports to implementations (local vs remote)
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

Three deliberate exceptions:

- **`mcp`** uses `application/` instead of `presentation/`. MCP tools are use-case logic invoked by external clients, not UI screens.
- **`ticketing`** and **`newsfeed`** add an `mcp_tools/` directory so their tools register into the shared MCP registry.
- **`remote_control`** adds an `application/` directory (RPC session, rate limiter, event forwarder) — the phone-side protocol logic, not UI.

### Dependency rule

```
Presentation → Application/Providers → Domain ← Infrastructure
```

Ports and adapters enforce Clean Architecture boundaries:

- **Domain layer:** zero infrastructure imports (no dio, drift, or network models).
- **Presentation layer:** no direct drift/DAO/data-layer access; everything goes through Riverpod providers → repositories.
- Infrastructure adapters implement domain ports; domain entities use enums/sealed classes for status fields (no magic strings).
- `DomainEventBus` enables decoupled cross-feature communication.

In the thin-client model, the **data-layer adapters split by connection mode**: LOCAL/REMOTE use `cc_data` remote repositories (RPC), wired through each feature's `*_server_providers.dart`. The composition root (`di/providers.dart` + `di/server_providers.dart`) binds repository ports to these RPC-backed implementations.

Boundaries are validated by `test/core/architecture_constraints_test.dart`.

### Workspace isolation

Workspaces are isolation tenants; data from one must never surface in another. Every workspace-scoped operation takes a **required** `workspaceId`; DAO reads filter by it; ID-only lookups are scoped or validated; cross-workspace access is denied loudly with `WorkspaceMismatchException` (domain) or an explicit MCP error. The few genuinely global queries (dashboard, analytics, startup reconcilers) carry a `CROSS-WORKSPACE BY DESIGN` doc comment. The RPC session enforces the same invariant: every server session is bound to exactly one workspace, so a remote client bound to workspace A cannot reach workspace B by passing a foreign id.

### Design system (cc_ui) & gallery

The app owns its entire visual layer through the `cc_ui` workspace package.
`cc_ui` exposes a token system (`DesignSystemTokens`,
`CcTypography`, `AppSpacing`, `AppRadii`, `AppShadows`/`CcElevation`, `CcMotion`),
a `CcTheme` (read via `context.designSystem`), foundation primitives, and 30+
`Cc*` components. Its purity (no Material/Cupertino/infrastructure imports) is
verified by the same `architecture_constraints_test.dart`.

`apps/cc_gallery` is the **living reference**, a Widgetbook catalogue with ~130
use-cases across **Components** (Buttons, Inputs, Feedback, Containers,
Navigation & Overlays, Layout) and **Foundations** (token specimens + primitives).
Toggle the Light/Dark theme addon to audit both palettes. See
`apps/cc_gallery/README.md` for the authoring workflow and
`packages/cc_ui/README.md` for the package API; the visual spec the system
implements is `DESIGN.md`.

### Stack

| Concern | Technology |
|---|---|
| State management | flutter_riverpod (Notifier / AsyncNotifier / Provider) |
| Routing | go_router (ShellRoute app shell + redirect guards) |
| Database | drift (SQLite) with DAO pattern + MigrationStep migrations; FTS5 + sqlite_vector |
| Client↔server RPC | cc_rpc (JSON-RPC client + WSS/in-process/WebRTC transports) · cc_host (server kernel: sessions, dispatcher, subscriptions, rate limiting) |
| Networking | dio (GitHub REST/GraphQL, Linear GraphQL, Google Calendar REST) + OAuth 2.0 PKCE (Google) + json_serializable models |
| UI components | **cc_ui** (in-repo design system: tokens, theme, 30+ `Cc*` components, no Material/Cupertino) over a token-based Material 3 base theme, google_fonts, fl_chart, flutter_flow_chart, kalender (calendar month/week views) |
| Markdown & code | flutter_markdown_plus, flutter_smooth_markdown, highlight (diff syntax highlighting) |
| Icons & graphics | lucide_icons_flutter, full_svg_flutter, GLSL fragment shaders |
| On-device ML | sherpa_onnx + onnxruntime_v2 (Whisper meeting transcription + pyannote speaker diarization, speech-to-text), sqlite_vector + dart_wordpiece (embeddings) |
| Audio & video | record (microphone), system_audio_capture (driver-free loopback: Core Audio taps / WASAPI / PipeWire), WebRTC AEC3, audioplayers, video_player + chewie |
| Terminal & FFI | xterm + flutter_pty (agent/Claude relay), ffi (rift worktrees, file finder, tree-sitter via cc_natives) |
| Desktop integration | window_manager, desktop_multi_window, local_notifier, file_selector, url_launcher |
| Remote control | flutter_webrtc (P2P data channels for the phone companion), qr_flutter (pairing QR), crypto (PSK pairing handshake) |
| Security | flutter_secure_storage (keychain/keystore), crypto |
| Internationalization | intl + flutter_localizations (7 languages, `generate: true`) |
| Code generation | build_runner, json_serializable, drift_dev, widgetbook_generator (cc_gallery navigation tree) |
| Architecture enforcement | architecture_constraints_test.dart |
| CI | GitHub Actions (ubuntu-latest): analyze, test, architecture test; plus deploy workflows for the web app, the Remote PWA, and the design system |

### Route map

The app shell (`ControlCenterLayout`) wraps every route via a `ShellRoute`. `/splash` and `/onboarding` render full-screen outside the shell. The auth guard keeps the user on `/onboarding` until GitHub auth (PAT or `gh` CLI) **and** at least one workspace exist.

| Path | Screen |
|---|---|
| `/splash` | Startup splash (resolves onboarding gate) |
| `/onboarding` | API keys + first workspace setup (full-screen) |
| `/dashboard` | Global dashboard |
| `/pull-requests` · `/pull-requests/compose` · `/pull-requests/:prNumber` | PR list · compose · PR detail with diff viewer |
| `/agents` | Agent registry |
| `/messaging` | Agent chat + channels |
| `/tickets` · `/tickets/:ticketId` | Ticket board · ticket master-detail |
| `/projects/:projectId` | Project overview |
| `/meetings` · `/meetings/record` · `/meetings/:meetingId` | Meetings list · live recording · meeting detail (notes/transcript) |
| `/calendar` · `/calendar/:eventId` | Calendar (month/week/agenda) · event detail |
| `/newsfeed` · `/newsfeed/settings` · `/newsfeed/article/:articleId` | Newsfeed list · settings · article webview |
| `/workspaces` · `/workspaces/:workspaceId` | Workspace list · workspace detail |
| `/analytics` · `/analytics/agents/:agentId` | Analytics · agent detail |
| `/pipelines` · `/pipelines/run` · `/pipelines/:runId` | Pipelines · run launcher · run detail |
| `/memory` | Workspace knowledge memory |
| `/users/:login` | GitHub user profile |
| `/api-keys` | API key management |
| `/settings/*` | Appearance, notifications, integrations, advanced, adapters, agents, repositories, skills, keybindings, sandboxing, pipelines, teams, devices (paired phones), remote control, server connection, voice profiles |

## Getting Started

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # after drift/JSON model changes
flutter gen-l10n                                                  # after ARB (l10n) changes
flutter run -d macos  # or windows, linux
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

See `apps/cc_server/README.md` for flags, pairing, and the `calendar connect` subcommand.

## Testing

```bash
flutter test
flutter test test/core/architecture_constraints_test.dart  # architecture validation
```

Tests cover network models, database DAOs (including workspace-isolation scoping), auth providers,
router and route guards, domain entities, domain services (with hand-rolled fakes), use cases,
the thin-client RPC parity surface (`InProcessRpcChannel`), and architecture constraints.
