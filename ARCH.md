# Control Center

A multi-agent developer control center for orchestrating AI agents across isolated Git worktrees. Built with Flutter for desktop (macOS, Windows, Linux).

Agents run inside OS-native sandboxes, collaborate over messaging channels, review pull requests, execute DAG-based pipelines, and share a workspace-scoped knowledge memory. The app also records and summarizes meetings on-device and syncs Google Calendar (events + RSVP) — all behind a native GUI with GitHub, Linear, and Google Calendar integration.

## Architecture

Feature-first Clean Architecture (ports & adapters) with Riverpod state management and Drift (SQLite) persistence.

The repository is a **native Dart pub workspace** (single resolved `pubspec.lock`) with four members:

| Member | Role |
|---|---|
| `control_center` (root) | The Flutter desktop app — everything under `lib/` below. |
| `packages/cc_ui` | The in-repo **design system**: tokens, theme, foundation primitives, and 30+ `Cc*` components. Built directly on `flutter/widgets.dart` — no Material or Cupertino. |
| `apps/cc_gallery` | A **Widgetbook** catalogue of `cc_ui` (the living design-system reference). |
| `packages/system_audio_capture` | Plugin: driver-free system-audio loopback capture (Core Audio taps / WASAPI / PipeWire). |

```
lib/
├── core/                 # Cross-cutting infrastructure
│   ├── config/           # App and environment configuration
│   ├── constants/        # App-wide constants, log levels, keybindings
│   ├── database/         # Drift SQLite database, tables, DAOs, migration steps, FTS query utils
│   ├── deep_link/        # Deep-link handler routing URL schemes into the app
│   ├── domain/           # Shared kernel: entities, repositories, ports, services, value objects, events
│   │   ├── entities/     # Agent, Workspace, Repo, AgentRunLog, IsolatedRepo, ReviewChannelAssociation, memory entities
│   │   ├── repositories/ # Shared repository interfaces
│   │   ├── ports/        # Sandbox, credential broker, git, notifications, embedding, repo-isolation ports
│   │   ├── services/     # MemoryAccessPolicy, ActivityLogger, AgentLoopGuard, mention resolver
│   │   ├── events/       # DomainEventBus + event types by category
│   │   └── value_objects/# AgentCapabilities, AgentRole, ConversationMode, SandboxSpec, RunCost, …
│   ├── errors/           # Sealed AppException hierarchy (network, workspace mismatch, …)
│   ├── infrastructure/   # Platform services: audio, code indexing (tree-sitter), embeddings, file search, rift FFI, skills, speech
│   ├── network/          # Dio HTTP clients (GitHub REST/GraphQL, Linear) + retry interceptor + error mapper
│   ├── notifications/    # Notification center, service, sounds, preferences, event→notification mapper
│   ├── providers/        # Central infrastructure Riverpod providers (database, DAOs, dio, auth, storage)
│   ├── security/         # Command redaction (strips secrets from logged output)
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
│   ├── mcp/              # MCP server + 71 typed tools (uses application/ instead of presentation/)
│   ├── meetings/         # Local meeting notes: system+mic capture, on-device Whisper transcription, diarization, AI summary
│   ├── memory/           # Knowledge management: facts, policies, domains, embeddings, knowledge graph
│   ├── messaging/        # Chat conversations + channels (merged chat + messaging context)
│   ├── newsfeed/         # RSS/Atom aggregation with ad-blocking and content curation
│   ├── pipelines/        # DAG-based workflow orchestration + template editor + execution engine
│   ├── pr_review/        # PR lifecycle, diff viewer, inline comments, review sessions
│   ├── repos/            # Git repository management + per-conversation worktree provisioning
│   ├── sandboxing/       # Process isolation: OS-native sandbox adapters, capability controls, credential brokering
│   ├── settings/         # App settings (agents, adapters, repos, teams, skills, pipelines)
│   ├── shell/            # App shell layout (sidebar, title bar, content area)
│   ├── teams/            # Agent team grouping and coordinated dispatch
│   ├── ticketing/        # Vendor-agnostic tickets (Local + Linear) + MCP tools (absorbed the tasks feature)
│   ├── user_profiles/    # GitHub user profile display with PR filtering
│   └── workspaces/       # Git worktree workspace management with event-driven CEO seeding
├── di/                   # Composition root: binds repository ports to implementations
├── l10n/                 # Internationalization: ARB source files (7 languages) + generated localizations
├── router/               # GoRouter config, route constants, auth guards, splash
├── shared/               # Shared widgets, domain services, extensions, utilities
└── main.dart             # Entry point: window manager, error boundary, event bus wiring
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

Two deliberate exceptions:

- **`mcp`** uses `application/` instead of `presentation/` — MCP tools are use-case logic invoked by external clients, not UI screens.
- **`ticketing`** adds an `mcp_tools/` directory so its ticket/project tools register into the shared MCP registry.

### Dependency rule

```
Presentation → Application/Providers → Domain ← Infrastructure
```

Ports and adapters enforce Clean Architecture boundaries:

- **Domain layer:** zero infrastructure imports (no dio, drift, or network models).
- **Presentation layer:** no direct drift/DAO/data-layer access — everything goes through Riverpod providers → repositories.
- Infrastructure adapters implement domain ports; domain entities use enums/sealed classes for status fields (no magic strings).
- `DomainEventBus` enables decoupled cross-feature communication.

Boundaries are validated by `test/core/architecture_constraints_test.dart`.

### Workspace isolation

Workspaces are isolation tenants — data from one must never surface in another. Every workspace-scoped operation takes a **required** `workspaceId`; DAO reads filter by it; ID-only lookups are scoped or validated; cross-workspace access is denied loudly with `WorkspaceMismatchException` (domain) or an explicit MCP error. The few genuinely global queries (dashboard, analytics, startup reconcilers) carry a `CROSS-WORKSPACE BY DESIGN` doc comment.

### Design system (cc_ui) & gallery

The app owns its entire visual layer through the `cc_ui` workspace package.
`cc_ui` exposes a token system (`DesignSystemTokens`,
`CcTypography`, `AppSpacing`, `AppRadii`, `AppShadows`/`CcElevation`, `CcMotion`),
a `CcTheme` (read via `context.designSystem`), foundation primitives, and 30+
`Cc*` components. Its purity (no Material/Cupertino/infrastructure imports) is
verified by the same `architecture_constraints_test.dart`.

`apps/cc_gallery` is the **living reference** — a Widgetbook catalogue with ~130
use-cases across **Components** (Buttons, Inputs, Feedback, Containers,
Navigation & Overlays, Layout) and **Foundations** (token specimens + primitives).
It is annotation-driven: each component's states are `@widgetbook.UseCase`
functions under `apps/cc_gallery/lib/use_cases/`, and `widgetbook_generator`
emits the navigation tree into `main.directories.g.dart`. Toggle the Light/Dark
theme addon to audit both palettes. See `apps/cc_gallery/README.md` for the
authoring workflow and `packages/cc_ui/README.md` for the package API; the visual
spec the system implements is `DESIGN.md`.

### Stack

| Concern | Technology |
|---|---|
| State management | flutter_riverpod (Notifier / AsyncNotifier / Provider) |
| Routing | go_router (ShellRoute app shell + redirect guards) |
| Database | drift (SQLite) with DAO pattern + MigrationStep migrations; FTS5 + sqlite_vector |
| Networking | dio (GitHub REST/GraphQL, Linear GraphQL, Google Calendar REST) + OAuth 2.0 PKCE (Google) + json_serializable models |
| UI components | **cc_ui** (in-repo design system: tokens, theme, 30+ `Cc*` components — no Material/Cupertino) over a token-based Material 3 base theme, google_fonts, fl_chart, flutter_flow_chart, kalender (calendar month/week views) |
| Markdown & code | flutter_markdown_plus, flutter_smooth_markdown, highlight (diff syntax highlighting) |
| Icons & graphics | lucide_icons_flutter, full_svg_flutter, GLSL fragment shaders |
| On-device ML | sherpa_onnx + onnxruntime_v2 (Whisper meeting transcription + pyannote speaker diarization, speech-to-text), sqlite_vector + dart_wordpiece (embeddings) |
| Audio & video | record (microphone), system_audio_capture (driver-free loopback: Core Audio taps / WASAPI / PipeWire), WebRTC AEC3, audioplayers, video_player + chewie |
| Terminal & FFI | xterm + flutter_pty (agent/Claude relay), ffi (rift worktrees, file finder) |
| Desktop integration | window_manager, desktop_multi_window, local_notifier, file_selector, url_launcher |
| Security | flutter_secure_storage (keychain/keystore), crypto |
| Internationalization | intl + flutter_localizations (7 languages, `generate: true`) |
| Code generation | build_runner, json_serializable, drift_dev, widgetbook_generator (cc_gallery navigation tree) |
| Architecture enforcement | architecture_constraints_test.dart |
| CI | GitHub Actions (ubuntu-latest): analyze, test, architecture test |

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
| `/settings/*` | Appearance, notifications, integrations, advanced, adapters, agents, repositories, skills, keybindings, sandboxing, pipelines, teams |

## Getting Started

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs  # after drift/JSON model changes
flutter gen-l10n                                                  # after ARB (l10n) changes
flutter run -d macos  # or windows, linux
```

## Testing

```bash
flutter test
flutter test test/core/architecture_constraints_test.dart  # architecture validation
```

Tests cover network models, database DAOs (including workspace-isolation scoping), auth providers,
router and route guards, domain entities, domain services (with hand-rolled fakes), use cases,
and architecture constraints.
