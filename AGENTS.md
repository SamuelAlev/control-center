---
name: Control Center
description: Multi-agent developer control center for orchestrating AI agents across isolated Git worktrees
repository: https://github.com/SamuelAlev/control-center
---

# Control Center

You are working on the Control Center — a Flutter desktop application for orchestrating AI agents across isolated Git worktrees. The app provides a native GUI for multi-agent development with GitHub/Linear integration, PR review, and workspace management.

## Project structure

```
lib/
├── core/               # Cross-cutting infrastructure
│   ├── config/         # App and environment configuration
│   ├── constants/      # App-wide constants
│   ├── database/       # Drift SQLite database, tables, DAOs, migrations
│   ├── domain/         # Shared kernel: entities, repositories, ports, value objects, domain events
│   │   ├── entities/   # Agent, Workspace, Repo, AgentRunLog, ReviewChannelAssociation, MemoryFact, MemoryPolicy
│   │   ├── notifications/ # NotificationCategory, NotificationSound, AppNotification
│   │   ├── repositories/ # Shared repository interfaces
│   │   ├── ports/      # SandboxPort, WorkspaceFilesystemPort, GitRepoInspectorPort, EmbeddingPort, etc.
│   │   ├── services/   # SkillScanner, PromptCache, MemoryAccessPolicy, ActivityLogger
│   │   ├── events/     # DomainEventBus + events by category (agent, workspace, PR, task, pipeline, observability, analytics)
│   │   └── value_objects/ # AgentSkills, AgentCapabilities, AgentRole, ConversationMode, SandboxBackend, etc.
│   ├── errors/         # Sealed exception hierarchy (AppException, NetworkException, etc.)
│   ├── infrastructure/ # Platform services: embedding, speech, audio, file search
│   ├── network/        # Dio HTTP clients (GitHub REST/GraphQL, Linear) + error_mapper
│   │   └── models/     # API response models (GitHubPullRequest, etc.)
│   ├── notifications/  # NotificationEventMapper (maps domain events to AppNotification)
│   ├── providers/      # Infrastructure providers (database, DAOs, dio, auth, storage)
│   └── theme/          # Material 3 + FTheme definitions
├── di/                 # Composition root: binds repository ports to implementations
├── features/           # Feature modules (Clean Architecture with ports & adapters)
│   ├── agents/         # Agent management, doctor diagnostics, cost tracking
│   ├── analytics/      # Agent performance metrics, achievements/badges, leaderboards
│   ├── auth/           # GitHub/Linear authentication, onboarding, credentials repository
│   ├── dashboard/      # Global overview with system metrics, agent process matching
│   ├── focus_mode/     # Minimalist distraction-free PR review UI (ephemeral toggle)
│   ├── github_status/  # GitHub service health indicator (stateless HTTP polling)
│   ├── mcp/            # MCP server + typed tools (no Ref injection, use-case driven)
│   ├── memory/         # Knowledge management: facts, policies, domains, embeddings, knowledge graph
│   ├── messaging/      # Chat conversations + channels (merged chat + messaging bounded context)
│   ├── newsfeed/       # RSS/Atom feed aggregation with ad-blocking and content curation
│   ├── pipelines/      # Workflow orchestration: DAG-based automation, template management, execution engine
│   ├── pr_review/      # PR lifecycle + diff viewer + inline comments + review sessions
│   ├── repos/          # Git repository management with filesystem/git ports
│   ├── sandboxing/     # Process isolation: OS-native sandbox adapters, capability controls, credential brokering
│   ├── settings/       # App settings (agents, adapters, repos, teams, skills)
│   ├── shell/          # App shell layout (sidebar, title bar, content area)
│   ├── tasks/          # Agent task delegation with status tracking and MCP tools
│   ├── teams/          # Agent team grouping and coordinated dispatch
│   ├── user_profiles/  # GitHub user profile display with PR filtering (presentation-only)
│   ├── dispatch/       # Agent dispatch: run-process lifecycle, prompt assembly, conversation modes (absorbed agent_modes)
│   └── workspaces/     # Git worktree workspace management with event-driven CEO seeding
├── router/             # GoRouter config, route constants, guards (thin — no business logic)
├── shared/             # Shared widgets, domain services (mention parser, content extractor, compactor), utilities
└── main.dart           # Entry point, window manager, error boundary, event bus wiring
```

## Architecture rules

### Dependency Rule (enforced by architecture_constraints_test.dart)

```
Presentation → Application/Providers → Domain ← Infrastructure
```

- **Domain layer** must NOT import dio, drift, network models, or feature data layers. Zero infrastructure deps.
- **Presentation layer** must NOT import drift, DAOs, or feature data layers directly. All data access goes through Riverpod providers → repositories.
- **Core** must NOT import feature data directories.
- Domain entities use enums/sealed classes for status fields (no magic strings).
- All entities have `==`/`hashCode` overrides and constructor validation.
- Repository interfaces are in domain; implementations are in data layer.

### Shared kernel

`core/domain/` holds entities and repositories shared across 3+ features:

- `Agent`, `AgentRunLog`, `Workspace`, `Repo`, `ReviewChannelAssociation`, `GitRepoInfo` — shared entities
- `MemoryFact`, `MemoryPolicy`, `AgentWorkingMemory`, `MemoryAccessGrant` — memory subdomain entities
- `AgentCapabilities`, `AgentSkills`, `AgentRole`, `ConversationMode`, `SandboxBackend`, `SandboxSpec`, `SandboxHandle`, `SandboxEvent`, `ExecutionContract` — shared value objects
- `AgentRepository`, `WorkspaceRepository`, `RepoRepository`, `AgentRunLogRepository`, `ReviewChannelRepository` — shared repository interfaces
- `SandboxPort`, `WorkspaceFilesystemPort`, `GitRepoInspectorPort`, `CredentialBrokerPort`, `ConfirmationPort`, `NotificationPort`, `NotificationPreferencesPort`, `EmbeddingPort`, `ProcessControlPort`, `ConversationModeResolver` — shared ports
- `DomainEventBus` + event types — decoupled cross-feature communication
- `SkillScanner`, `PromptCache`, `MemoryAccessPolicy`, `ActivityLogger` — shared domain services
### Feature layer convention

Each feature follows this structure (when applicable):

```
feature_name/
├── data/          # Repository implementations, data sources, services, DTOs, mappers
│   ├── datasources/
│   ├── repositories/
│   ├── services/
│   └── mappers/
├── domain/        # Entities, repository interfaces (abstract), use cases
│   ├── entities/
│   ├── repositories/
│   └── usecases/  (where business logic complexity warrants)
├── presentation/  # Screens (<250 lines), widgets (<300 lines), notifiers
│   ├── screens/
│   ├── widgets/
│   └── notifiers/
└── providers/     # Riverpod providers for this feature
```

**Exception:** The `mcp` feature uses `application/` instead of `presentation/` because MCP tools are use-case logic (not UI). This is deliberate — tools are invoked by external MCP clients, not rendered as screens.

## Workspace isolation

Workspaces are isolated tenants. Data from one workspace must NEVER surface in another. We have had real cross-workspace leaks, so this is a hard invariant, not a nicety. When adding or changing anything that touches workspace-scoped data, follow these rules:

- **`workspaceId` is required, never optional.** Any operation that reads or mutates workspace-scoped data takes a **required** `workspaceId` (Dart) / `workspace_id` (MCP tool schema). Do NOT make it optional, nullable-with-a-default, or resolve a "current"/"active"/"default" workspace implicitly. A required parameter forces every new call site to consciously supply the workspace.
- **Entities own their workspace.** `Agent.workspaceId` is **non-null** — every agent belongs to exactly one workspace. When an operation already has the entity, source the workspace from it (e.g. `PromptBuilder.identity` and the dispatch/memory path read `agent.workspaceId`) rather than threading a separate, fallible parameter that could disagree. `CreateAgentUseCase` refuses to create a workspace-less agent.
- **Workspace-scoped tables.** Rows that belong to a workspace carry a `workspaceId` column: Agents, AgentRunLogs, AgentWorkingMemory, Channels, Caches, MemoryDomains, MemoryFacts, MemoryPolicies, MemoryAccessGrants, PipelineRuns, PipelineTemplates, PipelineTriggers, PullRequests, ReviewChannels, Teams, Tickets, WorkspaceRepos, WorktreeMergeLog, and the code-graph tables (CodeSymbols/CodeEdges/CodeFiles). Code symbols/edges/files are keyed by `(workspaceId, repoId)` because a repo can be checked out on different branches in different workspaces.
- **DAO/repository reads MUST filter by `workspaceId`.** Every `get*`/`watch*`/`find*`/list query on a workspace-scoped table filters on `workspaceId` in its `WHERE` clause. A `getAll`/`watchAll`/`list` with no workspace filter is a leak. An ID-only lookup (`forAgent(agentId)`, `forPipelineRun(runId)`) is also a leak even though the id is a UUID — scope it: `forAgent(workspaceId, agentId)`. Do not rely on UUID uniqueness as the isolation boundary.
- **ID-based access is not a substitute for scoping.** Looking an entity up by its id (`ticketId`, `factId`, `symbol_id`) does not prove it belongs to the caller's workspace. Either scope the query by `workspaceId` so a foreign row is simply not found, or fetch then validate `entity.workspaceId == workspaceId` and reject on mismatch.
- **MCP tools.** Every tool that touches workspace-scoped data declares `workspace_id` in its `required` array, reads it (`if (x is! String) return CallResult.error('Missing or invalid argument: workspace_id')`), and enforces ownership. For repo-scoped tools (code graph) check `WorkspaceRepository.isRepoLinkedToWorkspace`. Tools that genuinely span all workspaces (e.g. `list_workspaces`, `create_workspace`) are the only exemptions.
- **Reject cross-workspace access explicitly.** On a mismatch, deny loudly — never silently no-op (that hides the bug) and never proceed (that leaks). Domain/service code throws `WorkspaceMismatchException` (in `core/errors/app_exceptions.dart`); MCP tools return `CallResult.error('... belongs to a different workspace.')`. The thrown exception's message reaches the agent verbatim via the MCP error path.
- **Validate at a chokepoint.** When a service mutates entities by id, validate once at the single read/write chokepoint rather than per-method. See `TicketWorkflowService._mutate` / `_assertWorkspace`: every mutation threads `workspaceId`, the chokepoint loads the row and asserts `row.workspaceId == workspaceId` before applying.
- **Genuinely-global queries are the only exception — and must be documented.** A few surfaces legitimately span all workspaces: the dashboard's all-agents/all-channels view, analytics aggregation, startup reconcilers (orphan-run reaper, stranded-ticket reconciler, pipeline resume), the embedding backfill, and event routers (trigger dispatcher fans out then filters per-event). These keep their unscoped query, but the DAO method MUST carry a `CROSS-WORKSPACE BY DESIGN` doc comment explaining why and pointing to the workspace-scoped alternative. If you add an unscoped query without that comment, assume it is a bug.
- **Tests.** Cross-workspace denial is covered by `test/features/ticketing/domain/ticket_workflow_service_test.dart` ("workspace isolation" group) and the DAO scoping by `test/core/database/daos/ticket_dao_test.dart`. Add an analogous isolation test when you introduce a new workspace-scoped surface.

## State management

- **Riverpod** for all state management. Use `Notifier<T>`, `AsyncNotifier<T>`, `FutureProvider<T>`, and `Provider<T>`.
- Database-backed state returns `AsyncValue<List<T>>` from Drift `.watch()` streams.
- `core/providers/provider.dart` provides central infrastructure providers (database, DAOs, dio, API clients).
- `di/providers.dart` is the composition root binding repository interfaces to implementations.
- Feature-level providers live in `features/<name>/providers/`.
- **Never use `ProviderScope.containerOf()`** — use `ref.read()`/`ref.watch()` in the widget tree.
- MCP tools must NOT receive `Ref` — use typed constructor parameters.

## Database

- **Drift** (SQLite) with DAO pattern.
- Tables defined in `core/database/tables/` with foreign key constraints.
- DAOs defined in `core/database/daos/` with generated `.g.dart` files. AgentRunLogDao and ReviewDraftDao delegate to their aggregate DAOs.
- Migrations use `MigrationStep(from, to, migrate)` pattern in `core/database/migration_steps.dart`.
- Database instance provided via `databaseProvider` in `core/providers/provider.dart`.
- Tables: Workspaces, Repos, WorkspaceRepos, Agents, AgentRunLogs, PullRequests, ReviewDrafts, Caches, Channels, ChannelParticipants, ChannelMessages, ReviewChannels, RssFeeds, RssArticles, Achievements, AgentDailyStats, Streaks, ActivityLog, WorktreeMergeLog, BudgetPolicy, AgentWorkingMemory, MemoryDomains, MemoryFacts, MemoryPolicies, MemoryAccessGrants, PipelineRuns, PipelineStepRuns, PipelineTemplates, PipelineTriggers, Tasks, Teams, TeamMembers.

## Routing

- **go_router** with `ShellRoute` wrapping the app shell (`ControlCenterLayout`).
- Onboarding is outside the shell (full-screen).
- Auth guard redirects to `/onboarding` until GitHub auth + at least one workspace are set.
- Route constants in `router/routes.dart`.
- Router config in `router/app_router.dart`.
- Guard logic in `router/guards.dart`.
- Onboarding gate logic extracted to `features/auth/providers/onboarding_providers.dart`.

## Networking

- **dio** HTTP client factory in `core/network/app_network.dart` (`createDio()`).
- Specialized clients: `GitHubApiClient`, `GitHubPrClient`, `GitHubContentClient`, `GitHubGraphqlClient`, `LinearApiClient`.
- Auth token injection via dio interceptors, driven by Riverpod.
- All network errors mapped through `core/network/error_mapper.dart` → typed `AppException` subclasses.
- GitHub API base URL centralized in `core/constants/app_constants.dart` (`githubApiBaseUrl`).

## UI

- **forui** (`FTheme`, `FSidebar`, `FSidebarItem`, `FSidebarGroup`) for shell and navigation.
- **Material 3** theming (light/dark) with `ThemeMode` persistence via `shared_preferences` (non-sensitive only).
- **lucide_icons_flutter** for iconography.
- **flutter_markdown_plus** for markdown rendering in chat and PR descriptions.
- Custom diff viewer with syntax highlighting in `pr_review/presentation/`.
- Global error boundary via `PlatformDispatcher.instance.onError` + `ErrorWidget.builder`.

## Design context

Design is governed by two root files, managed by the `impeccable` skill. Read them before designing or reviewing any UI.

- **PRODUCT.md** — strategic: register, users, product purpose, brand personality, anti-references, and the principles below. Answers who/what/why.
- **DESIGN.md** — visual: color tokens, typography, elevation, components, do's and don'ts. Answers how it looks. The design system token system in `core/theme/` (`design_system_palette.dart`, `design_system_tokens.dart`) is the implementation of this spec; read tokens via `context.designSystem`.

Register: **product** (design serves the task), with earned brand moments (onboarding, the dashboard deck, the shader backgrounds). Accessibility bar: WCAG 2.1 AA, never status-by-color-alone, full reduced-motion alternatives.

Core design principles:

1. **Presence over decoration** — motion, color, and "life" must report real agent state (thinking, running, blocked, done, cost), or they are cut.
2. **Situational command in one glance** — surface status, ownership, and the next action by default; bury nothing essential a level deep.
3. **Distinctive through behavior, not skins** — escape the component-kit feel by making the agent model legible, not by adding decoration.
4. **Product discipline, earned brand moments** — day-to-day surfaces stay quiet, dense, and consistent; expression is reserved for a few thresholds.
5. **Team-ready, solo-first** — keep attribution and ownership legible so shared-agent/team use is additive, not a rewrite.

For any design work (new screens, redesigns, reviews, polish), use the `impeccable` skill: `/impeccable <command>`.

## Security

- API tokens stored via `flutter_secure_storage` (macOS keychain, Windows credential store, Linux libsecret).
- `shared_preferences` used only for non-sensitive preferences (theme, font).
- Credentials repository (`SecureCredentialsRepository`) abstracts storage from providers.
- Keychain access group entitlements configured for macOS release + debug.

## Domain Events

- `DomainEventBus` in `core/domain/events/` enables decoupled cross-feature communication.
- Workspace & Agent: `WorkspaceCreated`, `AgentRunCompleted`
- PR & Review: `PullRequestPublished`, `PrMerged`, `ExternalPrDetected`
- Messaging: `MessageReceived`
- Task lifecycle: `TaskCreated`, `TaskDelegated`, `TaskStarted`, `TaskCompleted`, `TaskFailed`, `TaskCancelled`
- Pipeline lifecycle: `PipelineRunStarted`, `PipelineStepStarted`, `PipelineStepCompleted`, `PipelineStepFailed`, `PipelineRunCompleted`, `PipelineRunFailed`
- Observability: `ActivityLogged`, `WorktreeMerged`, `BudgetThresholdCrossed`
- Analytics: `AchievementUnlocked`
- CEO agent seeding is event-driven (listens to `WorkspaceCreated`) instead of fire-and-forget in build().
- Event bus wired in `main.dart` via `ceoAgentSeedProvider` to keep listener alive.

## Build and code generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Required after changes to:

- Database tables/DAOs (drift)
- JSON serializable models (`*.g.dart`)

### Internationalization (i18n)

- **All user-facing strings MUST be internationalized** using Flutter's l10n system. NEVER hardcode English text in widgets, screens, or dialogs.
- Access translations via `final l10n = AppLocalizations.of(context)!;` then `l10n.keyName`.
- L10n keys are defined in ARB files under `lib/l10n/`. Source of truth: `app_en.arb`.
- When adding a new key, add it to ALL 7 ARB files: `app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_it.arb`, `app_de.arb`, `app_pt.arb`, `app_nl.arb`. Translate the values you are adding to the other languages.
- Key naming: camelCase, descriptive (e.g. `agentName`, `failedWithError`, `saveChanges`).
- After adding keys, run `flutter gen-l10n` to regenerate the Dart l10n files.
- For strings with parameters: `"keyName": "{param} some text"` with `"@keyName": { "placeholders": { "param": { "type": "String" } } }`.
- MCP tool titles and descriptions are API descriptions for AI agents — do NOT i18n them.
- Data-layer strings without BuildContext (e.g. default agent names, notification event titles) may remain hardcoded if no context is available. Prefer passing locale through the call chain when practical.
- Example placeholders like `hint: 'e.g. architect'` are acceptable to leave as-is.
- Run `flutter gen-l10n` after any ARB file changes.

### Copy/text conventions

- **All user-facing strings MUST use sentence case** (capitalize only the first word and proper nouns like "GitHub", "Linear", "Riverpod", "Dart").
  - Correct: "Add agent" / "Create new workspace" / "Connect to GitHub"
  - Wrong: "Add Agent" / "Create New Workspace" / "Connect To GitHub"
  - Buttons, labels, tooltips, dialogs, form labels, navigation items, badges, keybinding labels — all sentence case.
  - NEVER use title case in user-facing strings.

## Architecture enforcement

Architecture constraints are validated by `test/core/architecture_constraints_test.dart`.

## Git safety

- **NEVER run `git stash`, `git restore`, `git checkout`, `git reset`, `git clean`, `git stash drop`, or any other destructive git command** that modifies or discards uncommitted working-tree changes.
- If you need a clean tree for verification, create a new branch or worktree instead.
- If you need to inspect the state at HEAD, use `git show HEAD:<path>` or `git diff` — read-only operations only.
- Uncommitted changes are the user's property. Treat them as irreversible.
