---
name: Control Center
description: Flutter clients and a pure-Dart server for multi-agent developer operations
repository: https://github.com/SamuelAlev/control-center
---

# Working in Control Center

Read only the references relevant to the change:

- [ARCH.md](ARCH.md): package ownership, persistence, harness/cache/indexing, rigs and client integration contracts.
- [SECURITY.md](SECURITY.md): authorization, credentials, untrusted input and network boundaries. Required for changes touching these surfaces.
- [PRODUCT.md](PRODUCT.md) + [DESIGN.md](DESIGN.md): strategy and visual rules. Required for UI work; use the `impeccable` skill.
- App/package READMEs: local APIs, commands and limitations. [RELEASING.md](RELEASING.md): packaging/release procedures. [GLOSSARY.md](GLOSSARY.md): domain terms.

Keep this file for cross-cutting coding rules. Put subsystem details in the owning reference, not another copy here. `CLAUDE.md` points to this file.

## Boundaries

- `cc_server` owns persistence, external APIs, business logic and execution. Desktop/web/phone clients render server state and forward actions; no database, forge API, sandbox or process logic in `lib/`. A local desktop hosts the server, not a second implementation. Fleet workers execute leased jobs without durable state, auth, approvals or budgets.
- Dependency direction: presentation → providers/application → domain ← infrastructure. `cc_domain` is pure Dart: no Flutter, rhttp, drift, `dart:io` or FFI. Presentation never imports DAOs or feature data layers; core never imports feature data directories.
- Domain owns repository interfaces, entities and ports; adapters implement them. Entities validate construction, implement equality/hashCode and use enums/sealed status types.
- Shared domain lives in `packages/cc_domain/lib/core/domain/`; feature domain in `packages/cc_domain/lib/features/<name>/domain/`. Client features own `presentation/` and `providers/`. Keep screens under 250 lines and widgets under 300.
- Riverpod owns client state (`Notifier`, `AsyncNotifier`, `FutureProvider`, `Provider`). Use `ref.read/watch`, never `ProviderScope.containerOf()`. Central infrastructure is in `lib/core/providers/`; repository bindings in `lib/di/`. MCP tools take typed dependencies, never `Ref`.
- Settings is a shell. Feature-owned `presentation/settings/` and `settings_contributions.dart` implement `settings_extensions.dart`; `lib/di/settings_registry.dart` composes them. Settings must not import another feature's presentation. Contribution IDs are unique and `<feature>.`-namespaced; destinations resolve against `kSettingsNav`.
- Use declared `DomainEventBus` events, not assumed ones. Workspace seeding reacts to `WorkspaceCreated`, never fire-and-forget from widget `build()`.
- People act on a provider only through their own sign-in (`GitHubClients.asPerson`, `LinearClients.personAuthorization`); automation only through one-repository tokens bounded by an accountable human (`GitHubClients.mintScoped`/`forOwner`) or an app actor. No PAT, server-owner or environment fallback; build no other authenticated GitHub client. See [ARCH.md](ARCH.md#provider-credentials-and-connect).
- Commit identity is decided in one place (`AgentCommitIdentity`, resolved by `AgentCommitIdentities`): work a person started is theirs (author, committer, their own opt-in signing key), automation is the bot's and unsigned, and co-author credit follows `agent_commit_attribution`. Set no `GIT_AUTHOR_*`/`GIT_COMMITTER_*`, signer or trailer anywhere else; a run's commits are signed only by the gateway and checked by `PushedCommitInspector`. See [SECURITY.md](SECURITY.md#agent-run-gateway).
- The host belongs to the server owner, and a workspace admin is not the server owner. Nothing runs on the host outside a sandbox unless the owner started it or approved that kind of host execution: an op that reaches the host's shell, files, display or restore path declares `serverAuthority: ServerAuthority.serverOwner`, a definition that runs on the host needs the current owner's recorded approval, and a missing sandbox is a refusal (`sandbox_unavailable`), never a bare-host fallback. Server code spawns through `ChildProcess` (inside a run, the run's tool launcher), never a raw `Process.start/run`. See [SECURITY.md](SECURITY.md#sandboxes-and-rigs).
- Code mode scripts run only in the `cc_codemode` runner at full lockdown, never on a fallback path. A script reaches tools only through the loop's reentry gate (`ToolReentry`) or `McpToolDispatcher.callNested`, never by calling a tool directly. Every new tool decides `scriptCallable` on purpose, in `script_callable_pin_test.dart`, which fails on an undecided tool and on a declaration it cannot read. A script is recorded before it starts and its record is finished at most once (when the finish and the fallback close both fail, it stays `running` until the boot sweep finishes it); nothing edits a finished record or a call row. See [SECURITY.md](SECURITY.md#code-mode).
- Every run the server starts without a person typing is an `agent_wakes` row with a typed `WakeContext`: insert a wake (`WakeQueueService.enqueue`, with a dedup key), never call `dispatchAgentRun` from a listener. Text from any source rides inside the wake-data envelope. See [ARCH.md](ARCH.md#wakes-and-long-running-work) and [SECURITY.md](SECURITY.md#wakes-goals-and-peers).
- React to a run's end through `AgentRunSettled` (published once, after the terminal write, with a `RunEndReason`), never `AgentRunCompleted` plus a status read; a `serverStopped` end is not a failure.
- No tool the wake, goal, peer or background-command work adds joins the direct set (`ModeToolPolicy.directTools`): each is script-callable or deferred, decided in `script_callable_pin_test.dart`.
- A goal closes only through verification (checks, then a read-only review) or a person (`agentGoalRuns.approveCompletion`); `complete_goal` is a claim, never a completion.
- Code follows the forge: a repository grant alone opens no code. Ops that expose a repository's files, or a space's content, go through the shared gates (`repoForgeReadCheck`, `SpaceRepoAccess` via `PrDataGate.requireSpace`); mutations need the write grant. Refusals carry a `data.kind` the clients localize; add a kind, never a second message to parse. See [SECURITY.md](SECURITY.md#authorization-and-isolation).

## Workspace isolation

- Every workspace operation requires `workspaceId` / MCP `workspace_id`; no implicit current/default workspace. When an entity owns its workspace, derive it from the entity rather than accepting a conflicting second value.
- Resolve `WorkspaceDatabaseManager.of(workspaceId)` per call. Never cache a workspace DAO in a repository. Each workspace has its own database; new tables default there, not `global.db`.
- Validate the registered, non-deleted workspace **before** membership lookup or opening its database. Then enforce membership at RPC, subscription, MCP and HTTP entry points. A paired device is not a workspace grant.
- Scope ID lookups or verify ownership at the mutation chokepoint. Mismatch throws `WorkspaceMismatchException`; MCP returns an explicit error. Repo tools also check `isRepoLinkedToWorkspace`.
- Cross-workspace reads use `CrossWorkspaceQueries` with a `CROSS-WORKSPACE BY DESIGN` explanation. Filter streams/events per subscriber. Pre-auth opaque IDs route through `workspace_routes`; no scan fallback.
- Add behavioral isolation coverage for new workspace surfaces. Structural checks live in `packages/cc_persistence/test/workspace_isolation_ratchet_test.dart`; authorization details are in [SECURITY.md](SECURITY.md).

## UI and localization

- Use the in-repo `Cc*` components. `cc_ui` imports `flutter/widgets.dart`, never Material/Cupertino; root `MaterialApp` is separate. Read tokens via `context.designSystem`, full configuration via `context.ccTheme`, fonts via `CcFonts.ui/code`.
- Root-overlay content needs a complete `DefaultTextStyle` (size, token color, `TextDecoration.none`); do not inherit the WidgetsApp error fallback. Use `showCcDialog` for dialogs.
- Use the shared markdown and syntax seams, not new renderers. See [ARCH.md](ARCH.md#client-conventions) for fonts, icons, highlighting and route/onboarding invariants.
- All widget/screen/dialog copy is localized with `AppLocalizations.of(context)!` and sentence case. MCP API descriptions and context-free data-layer strings need not be translated; example hints may remain literal.
- `lib/l10n/app_en.arb` is the source. New camelCase keys need translated values in every language-base ARB, including `app_zh_TW.arb` and `app_zh_HK.arb`: Hong Kong inherits from Simplified `zh`, so it needs every key to stay Traditional. Sparse variants (`en_GB`, `es_MX`, `fr_CA`, `pt_PT`) only override divergent wording. Declare typed placeholders; regenerate after any ARB change.
- Mirror UI with `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `BorderDirectional`, `BorderRadiusDirectional`, and `TextAlign.start/end`. No hardcoded app-level `Directionality`.
- LTR carve-outs: code, diffs, terminals, paths, branches, URLs, logs, mermaid, sequence lanes and DAG canvases. Mark with `// RTL carve-out:`. Physical geometry is also valid for actual viewport/painter coordinates.
- Navigation glyphs use `matchTextDirection: true`; physical/semantic glyphs stay unmirrored. Resolve splitter gestures and prev/next keys through directionality; guest input remains physical. Calendar columns mirror too.
- Format dates/numbers with the active locale. Use FSI/PDI around an ARB placeholder only when an LTR token demonstrably scrambles under RTL. Cover RTL with `testWrap(textDirection: TextDirection.rtl)` or `ccTestApp`; remove fixed files from the shrinking physical-geometry allowlist, never add exceptions.

## Build and verification

Use `fvm` for **every** Dart/Flutter invocation. The user owns `fvm flutter run`; do not launch the app yourself.

```bash
fvm flutter pub get
fvm dart run patchwork apply   # after every pub get: wires patches/*.patch
fvm flutter analyze
fvm flutter test --concurrency=1  # root app; other suites use --concurrency=2
fvm flutter test test/core/architecture_constraints_test.dart --concurrency=1
```

Never run two test suites in parallel or omit the concurrency cap.

| Changed surface | Required regeneration/build |
| --- | --- |
| Drift tables/DAOs or JSON/codegen models | `fvm dart run build_runner build --delete-conflicting-outputs` from root for the app, inside the package (`packages/<name>`) for a member package (a root run writes nothing for members); shared pub workspace/lockfile |
| ARB files | `fvm flutter gen-l10n` |
| Server-side code | Build/stage natives, then `scripts/build_server.sh` (raw `dart build cli` leaves out the media the server needs to boot); desktop prefers the prebuilt binary |
| Worker entry or transitive source | `tool/gen_workers.sh`; commit generated `web/*.js`, check with `tool/check_workers.sh` |

Worker entries (`@isolateManagerCustomWorker` / `@isolateManagerWorker`) must remain Flutter-free. The generator is a global build tool, not a dev_dependency; adding it conflicts with the workspace analyzer constraints.

### Native and worktree safety

- Run `scripts/natives/build_natives.sh` before server builds. Required libraries and platform exemptions are defined once in `scripts/lib/natives.sh`; see [cc_natives](packages/cc_natives/README.md). It also builds the code mode runner (`build_codemode.sh`), which the server needs to boot; run the runner only with stdout and stderr on pipes (a file kills it with `SIGXFSZ`).
- Missing natives fail loading, server preflight and packaging. Never add a fallback. `.cc_natives_allow_missing` is a repo-root **file** for compile-only work, not a shipping/runtime mode. Missing downloaded ML models may allow FTS-only search; missing native libraries may not.
- `cc_inference` owns speech and embeddings with one statically linked ONNX Runtime. Do not add Flutter/pub inference dependencies or a second ONNX Runtime.
- Rift copy-on-write is the sole provisioning backend where supported; operational/CoW failures are errors. Keep data and repo on the same CoW volume. Never run git against the source checkout during provisioning, including branch probes; inspect the copy. Windows uses git worktrees. Preserve teardown of existing worktree registrations on all platforms.

## Git safety

Uncommitted changes belong to the user. Never run `git stash`, `restore`, `checkout`, `reset`, `clean`, `stash drop`, or another command that discards/modifies them. Use read-only `git show`/`diff` for inspection; use a separate branch/worktree if verification requires a clean tree.
