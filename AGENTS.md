---
name: Control Center
description: Multi-agent developer control center for orchestrating AI agents across isolated Git worktrees
repository: https://github.com/SamuelAlev/control-center
---

# Control Center

You are working on the Control Center, a Flutter desktop application for orchestrating AI agents across isolated Git worktrees. The app provides a native GUI for multi-agent development with GitHub/Linear integration, PR review and workspace management.

## Project structure

The repository is a **native Dart pub workspace** (single resolved `pubspec.lock`) of a root Flutter app plus **5 apps and 15 packages**. The server half is pure-Dart (no Flutter engine) so it compiles to a self-contained native binary; the client half is Flutter. See `ARCH.md` for the exhaustive map.

```
apps/
├── cc_server/          # Headless pure-Dart server binary (dart build cli). Owns the DB, serves repo-RPC.
├── cc_worker/          # Headless fleet executor binary. Pairs with cc_server, declares capabilities,
│                       #   heartbeats, pulls leased jobs, executes them, streams events back. Holds no durable state.
├── cc_remote/          # Phone thin client — Flutter web PWA, remote-controls the fleet over the brokered relay.
├── cc_signaling_server/# Stateless WebSocket relay broker (N-way invite-gated rooms; a dumb relay).
└── cc_gallery/         # Widgetbook catalogue of cc_ui (the living design-system reference).

packages/
├── cc_ui/              # In-repo design system: tokens, theme, 30+ Cc* components (flutter/widgets.dart only).
├── cc_domain/          # Pure-Dart SHARED KERNEL: all domain entities, value objects, ports, repositories,
│                       #   events, services + every feature's domain/ layer. Zero infra deps (no drift/dio/dart:io).
├── cc_harness/         # Pure-Dart agent-loop KERNEL (the built-in agent runtime core): messages, provider port,
│                       #   tools, compaction, steering, hooks, subagents, slash commands. Web-safe; embeddable by cc_server/cc_worker.
├── cc_harness_runtime/ # VM-only BATTERIES for the kernel: Anthropic/OpenAI/Ollama streaming providers,
│                       #   OAuth/PKCE credential brokering, generic tool set, AGENTS.md + skills loaders.
├── cc_rpc/             # Transport-agnostic JSON-RPC client + channel transports (web-safe).
├── cc_host/            # Server-side RPC kernel: sessions, repo-op dispatcher, subscriptions, rate limiting, WSS transport, presence hub.
├── cc_data/            # Remote data layer: repository adapters that satisfy reads/writes over cc_rpc.
├── cc_persistence/     # Server-side Drift/SQLite (package:sqlite3, no Flutter). SPLIT BY WORKSPACE:
│                       #   GlobalDatabase (global.db) + one WorkspaceDatabase per workspace file.
├── cc_infra/           # Server-side VM-only adapters (dart:io): git, process, GitHub/Linear dio clients, dispatch, sandbox, meetings ML, fleet, tunnels.
├── cc_mcp/             # The MCP tool surface (server-side, Ref-free typed tools, ~80 wired) + JSON-RPC dispatcher.
├── cc_mcp_client/      # MCP CLIENT: connects to EXTERNAL MCP servers and bridges their tools into the registry.
├── cc_server_core/     # App-server composition: the repo-RPC catalog, LocalRpcServer, MCP registry wiring, identity/presence/fleet/evals runtime.
├── cc_markdown/        # In-repo markdown engine: typed-AST parser + widget renderer (CcMarkdown / CcStreamingMarkdown)
│                       #   + native mermaid diagrams (CcMermaidView, no WebView/JS). widgets-only.
├── cc_natives/         # Native FFI leaf (ALL REQUIRED, no degraded mode): rift CoW worktrees, fff file
│                       #   finder, tree-sitter + grammars, ccpty, aec, lame, plus two in-repo Rust
│                       #   crates: cc_watcher (native/watcher/) and cc_inference (native/inference/:
│                       #   sherpa-onnx speech + ONNX Runtime embeddings, statically linked).
└── system_audio_capture/ # Plugin: driver-free system-audio loopback capture (Core Audio taps / WASAPI / PipeWire).

lib/                    # The root Flutter THIN CLIENT (desktop + web). Renders state; holds no business logic.
├── bootstrap/          # Platform bootstraps (io/web), server_backend resolver, thin_client_boot (local cc_server spawn)
├── core/               # Cross-cutting CLIENT infrastructure
│   ├── config/ constants/ deep_link/ infrastructure/ keybindings/
│   ├── domain/         # Nearly empty — the shared kernel moved to cc_domain (a few client-only services remain)
│   ├── notifications/  # NotificationEventMapper (maps domain events to AppNotification, principal-aware)
│   ├── observability/  # Sentry bootstrap
│   ├── offline/        # Offline mutation queue (buffers writes while the server is unreachable)
│   ├── providers/      # Central infra providers (rpc client, server connection, storage, event bus, sync engine, locale)
│   ├── server/         # Desktop↔cc_server connection: config, process supervisor, endpoint, connection descriptor
│   ├── storage/ sync/ theme/ undo/ utils/
├── di/                 # Composition root: binds repository ports to RPC-backed implementations
├── features/           # Feature modules (presentation + client providers; domain lives in cc_domain)
│   ├── agents/ artifacts/ auth/ calendar/ dashboard/ dispatch/ focus_mode/
│   ├── identity/ inbox/ mcp/ meetings/ memory/ messaging/ newsfeed/
│   ├── observability/ orchestration/ pipelines/ plan_studio/ presence/ pr_review/
│   ├── remote_control/ repos/ rigs/ sandboxing/ service_status/ session_review/ settings/ shell/
│   ├── soundscape/ subscriptions/ teams/ ticketing/ todos/ user_profiles/ vscode_theme/ workspaces/
├── l10n/               # ARB source files (7 languages) + generated localizations
├── router/             # GoRouter config, workspace-prefixed route constants, guards, splash (thin, no business logic)
├── shared/             # Shared widgets, extensions, utilities
└── main.dart           # Entry point: selects bootstrap_io (VM) vs bootstrap_web (web)
```

Notable recent additions: **identity** + **presence** (multi-user identity/membership/roles and real-time collaboration/presence — supersedes the old "no multi-user" decision), **plan_studio** (editable DAG plans), **inbox** (unified cross-pillar inbox + ⌘K omnibox), the **evals** / **fleet** / **guardrails** subdomains in `cc_domain`, agent peer messaging + delegation (`send_to_agent`/`ask_agent`/`delegate_task`/`todo_read`; the old IRC bus was deleted), skills supply-chain scanning, plus the earlier **observability**, **orchestration**, **todos**, **subscriptions**, **session_review** + **vscode_theme** and the **governance**, **model_routing** and **skills** subdomains. The built-in agent runtime is the two standalone workspace packages **cc_harness** (web-safe pure-Dart agent-loop kernel) + **cc_harness_runtime** (VM-only batteries: providers, credential brokering, tool set). The former `tasks` feature was absorbed into `ticketing`. The companion design-system and markdown packages `cc_ui` / `cc_markdown` are first-party.

## Client / server architecture

Control Center is a client/server product with three client tiers and a single server. Each tier has a strict responsibility boundary.

- **Thin clients (desktop / web).** These clients hold **no** business logic. They must NOT contain database access, API calls (GitHub, Linear, …), environment/process execution, sandboxing, or any other heavyweight logic. They render state received from the server and forward user actions to it. All persistence, network I/O and execution live in `cc_server`.
- **Thick client (desktop only).** The desktop app is the only tier permitted to embed `cc_server` in-process. It hosts the server locally so it can run standalone, but it does not duplicate the server's logic; it delegates to it.
- **Remote client (`cc_remote`, mobile).** `cc_remote` is a lightweight client whose only job is to connect to a `cc_server` instance and display a curated, mobile-friendly subset of information. It does not embed the server, does not run agents or pipelines and never touches the database or external APIs directly.
- **Server (`cc_server`).** `cc_server` is the single source of truth. It holds all state, runs all database access, makes all external API calls and executes agents/pipelines/sandboxes. Because every client (thin, thick, remote) talks to the same server, the experience is identical across all of them: the server, not the client, owns the data and the behavior.
- **Fleet executors (`cc_worker`).** A headless pure-Dart binary that pairs with a `cc_server`, declares its capabilities, pulls leased jobs, executes them and streams process events back. It holds **no durable state** (no DB, no auth, no approvals, no budgets — those never leave `cc_server`); "a worker is a limb, not a second brain." One authoritative server, N dumb limbs; no consensus, no worker-to-worker traffic. The implicit local worker is an in-process seam so a solo desktop stays byte-identical to today.

### Identity & multiplayer

Control Center is now **multi-user**: humans and agents are co-equal actors. A `Principal` (sealed union: `UserPrincipal` | `AgentPrincipal`) in the shared kernel is the abstraction every attribution, message, ticket, review, plan and run log resolves through. `User` is global (cross-workspace, like `repos`); membership (`workspace_members` at a `WorkspaceRole`: owner/admin/member/viewer/guest) is workspace-scoped and is the access test — **holding a pairing key is no longer the access boundary; being a member is.** The old `'user'` sentinel for human messages was removed in favor of real user ids. Per-repo grants (`workspace_member_repo_grants`) keep workspace membership from silently out-privileging the forge. Rate limits are per-principal (one user across N devices shares one budget); revocation is live (sessions drop within seconds on device/member revocation).

Real-time collaboration is **authoritative-server + per-field last-writer-wins, NOT a CRDT** (the consensus across Figma/Linear/Replicache; a Dart CRDT would mean Rust-via-`cc_natives` FFI, reserved for one future co-editing surface only). Presence is a **separate ephemeral lane that is never persisted** (status/locus/cursor/typing); durable state rides an optimistic-mutation + server-rebase + per-field LWW backbone with a monotonic per-workspace `syncSeq` allocated in the same DB transaction as the mutation. Ordering never trusts a client clock — "last writer" = server receipt order. Humans and agents share one roster (agent presence is synthesized server-side from run/lifecycle events); follow-mode (incl. "watch an agent work"), steer/interrupt/take-over/hand-back and a per-channel autonomy dial (`propose-only` / `act-with-approval` / `act-freely`) sit on top. Solo-mode zero-regression: with one human, the presence lane idles and no roster chrome appears.

The hard rule: **never push logic that belongs in `cc_server` into any client.** If a feature needs the database, an API, or process execution, it belongs in the server. Clients consume the result.

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

`packages/cc_domain/lib/core/domain/` holds entities and repositories shared across 3+ features (and each feature's own `domain/` layer lives under `packages/cc_domain/lib/features/<name>/domain/`). It is pure Dart with zero infrastructure deps, so both the Flutter client and the Flutter-free server binary import it:

- `Agent`, `AgentRunLog`, `Workspace`, `Repo`, `ReviewChannelAssociation`, `GitRepoInfo`, shared entities
- `User`, `Principal` (sealed `UserPrincipal` | `AgentPrincipal`), `WorkspaceRole` — the identity/multiplayer unification
- `MemoryFact`, `MemoryPolicy`, `AgentWorkingMemory`, `MemoryAccessGrant`, memory subdomain entities
- `AgentCapabilities`, `AgentSkills`, `AgentRole`, `Mode`, `SandboxBackend`, `SandboxSpec`, `SandboxHandle`, `SandboxEvent`, `ExecutionContract`, shared value objects
- `AgentRepository`, `WorkspaceRepository`, `RepoRepository`, `AgentRunLogRepository`, `ReviewChannelRepository`, shared repository interfaces
- `SandboxPort`, `WorkspaceFilesystemPort`, `GitRepoInspectorPort`, `CredentialBrokerPort`, `ConfirmationPort`, `NotificationPort`, `NotificationPreferencesPort`, `EmbeddingPort`, `ProcessControlPort`, `ModeResolver`, shared ports
- `DomainEventBus` + event types, decoupled cross-feature communication
- `SkillScanner`, `MemoryAccessPolicy`, `ActivityLogger`, `CacheStats`, shared domain services

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
│   ├── notifiers/
│   ├── settings/                   # This feature's settings page + its sections (when it has one)
│   └── settings_contributions.dart # What it contributes to settings, and where
└── providers/     # Riverpod providers for this feature
```

**Exception:** the `mcp` feature is providers-only (no `presentation/`) — the MCP settings/status UI lives under `settings/` and the tool surface itself lives in the `cc_mcp` package. `orchestration` and `plan_studio` carry only `presentation/` + `providers/`.

### Settings is a shell, not an integration point

`features/settings/` owns the **routes, the nav model (`settings_nav.dart`), the page scaffold (`SettingsPage`) and the generic cards** — nothing else. It had become the app's de-facto integration point: one screen imported presentation code from five other features, and `agents` had been hollowed out into a bag of widgets with no screen of its own. The dependency is now inverted.

- **A feature owns its settings surface.** The page lives in `features/<x>/presentation/settings/` and `features/<x>/presentation/settings_contributions.dart` declares what it contributes: a `SettingsBody` (a whole destination, keyed by `SettingsNavItem.id`), a `SettingsSectionContribution` (a card on a `SettingsSlot` page), an `AgentSettingsTab` or an `AgentRegistryView`.
- **The contract is `features/settings/settings_extensions.dart`** — contract-only (`flutter/widgets.dart` + the shared kernel + l10n), so declaring a contribution pulls in no settings UI and there is no cycle. A test pins that it stays that way.
- **`lib/di/settings_registry.dart` is the one file that knows every feature.** That is a composition root's job, the same way `di/providers.dart` binds every repository port. It only concatenates the features' lists, so adding a card never means editing a screen.
- **Nothing under `lib/features/settings/` may import another feature's `presentation/`.** Enforced by `architecture_constraints_test.dart` against an intentionally EMPTY allowlist (`settings_feature_importers.txt`). The reverse direction is fine and deliberately unchecked: a feature may import settings' card vocabulary (`settings_shared.dart`, `scope_badge.dart`, `SettingsPage`) so a contributed card looks native.
- **Wiring is pinned by `test/features/settings/settings_registry_test.dart`**: every `navItemId` resolves against `kSettingsNav`, no two features claim one destination, ids are unique and `<feature>.`-namespaced. A registry trades a compile-time reference for a string, so a typo would otherwise be a silently blank page rather than a build error.

## Agent interaction tools & guardrails

- **Agent peer messaging & delegation** (`send_to_agent`, `ask_agent`, `delegate_task`, `todo_read` + the re-implemented `consult_agent`). Agents talk to each other over **channels** (durable, roster-visible), not a separate bus — the old in-memory IRC bus was deleted. `ask_agent` is request/reply with a **mandatory timeout** (no configuration removes it; default 10 min, capped by a workspace ceiling) and pair-wise cycle detection; `delegate_task` creates a child ticket/plan node guarded by depth cap (default 3), cycle detection, budget-envelope inheritance and an autonomy ceiling, all enforced server-side at a chokepoint (never by prompt instructions). Recipient resolution is exact (by id or unique name; no fuzzy, no cross-workspace). Agent-to-agent channels are muted by default and never bump the human unread badge or fire an OS notification.
- **Unified action guardrails** generalize the former bash-only `CommandPolicy` into a closed **`ActionClass`** taxonomy (13 effect classes: `fileDelete`, `fileWriteOutsideWorktree`, `gitCommit`, `gitPush`, `prCreate`, `prPublish`, `vendorSyncWrite`, `networkEgress`, `secretAccess`, `packageInstall`, `processSpawn`, `workspaceMutation`, `enclosureControl`). Resolution order is `channel > agent > workspace > mode preset > built-in default` (most-specific scope wins; within a scope, longest-prefix then most-restrictive). The flat `allow > deny > prompt` precedence was replaced by specificity-then-restrictiveness. Every mutating tool declares its ActionClass(es); undeclared new tools fail the ratchet test. `prompt` with no approver connected is **denied** (fail-closed). The per-channel autonomy dial (`propose-only`/`act-with-approval`/`act-freely`) is a named profile over this same store.
- **Skills supply-chain scanning** is a **fail-closed gate** invoked between fetch and write in `SkillBundleService`: no skill content reaches disk or an agent prompt without a verdict (`pass`/`warn`/`quarantine`). The scanner is inert by construction (executes nothing from the skill); Layer 1 static rules + Layer 2 capability manifest are the mandatory gate, Layer 3 LLM review is additive. Trust tiers (`firstParty`/`workspace`/`verified`/`community`) are provenance metadata, never a scan substitute. TOCTOU invariant: bytes scanned = bytes written = bytes hash-locked.

## Enclosures (rigs)

A **rig** is a disposable VM an agent drives in real time — a desktop, a headless
browser or an Android device — watched live by a human who can take over. The
same enclosure platform hosts the interactive terminals, so shell work stops
running on the host. `packages/cc_domain/lib/features/rigs/` is the domain,
`packages/cc_infra/lib/src/rigs/` the mechanism, `lib/features/rigs/` the viewer.

There are two local backends, split by surface: the **desktop** boots on QEMU
(HVF/KVM) from qcow2 base images, and **exec (terminal) and browser rigs** boot
on the **smolvm** microVM (libkrun over the host hypervisor) from digest-pinned
OCI images. The routing is by spec, not by availability: an exec or browser
spec always lands on smolvm and a desktop spec always lands on QEMU — naming a
backend the surface does not run on (`RigSpec.backend`) is an error, never a
silent downgrade. The Android emulator remains its own host-managed backend.

- **Enclosure-only execution, enforced by the command line.** Each backend's
  argv is built by a pure function precisely so its security flags can be
  pinned by a test. For QEMU (`buildQemuArgv`, `qemu_argv_test.dart`):
  `restrict=on` on the user-mode netdev, every `hostfwd` bound to `127.0.0.1`
  explicitly, the base image opened read-only behind a per-session qcow2
  overlay, and no `-virtfs`/`-fsdev` at all. For smolvm
  (`buildSmolvmCreateArgs`, `smolvm_enclosure_backend_test.dart`):
  `--outbound-localhost-only` is always present and bare `--net` never is,
  every allowlist entry becomes its own `--allow-host`, and the broker secret
  travels by `--secret-file` reference, never as an env value smolvm would
  persist in its machine record. A missing flag fails no behavioural test —
  the rig boots, the agent drives it, and the enclosure is simply not one.
- **Egress is deny-by-default.** On QEMU the guest's ONLY routes out are
  `guestfwd` holes to the existing `SandboxHttpProxy`/`SandboxSocksProxy` on
  host loopback. On smolvm the gate is the VMM's own: loopback-only outbound
  (which is what reaches the credential broker) plus exactly the allowlisted
  hosts — the Docker Hub pull path is unioned in as image maintenance, because
  smolvm's guest agent pulls the machine's image through the same gate. The
  mobile surface is the honest exception: an Android emulator owns its
  networking, so its egress is NOT fully enforced and the capability note says
  so rather than implying parity.
- **Input goes through the hypervisor, capture goes through the guest.** QMP
  (`input-send-event`/`send-key`) injects keyboard and pointer events, so the
  guest never runs a privileged daemon that can synthesize input; the small
  unprivileged guest agent only captures and mode-sets, scaling in the guest so
  a full framebuffer never crosses the wire. A `virtio-tablet` is always present
  — a relative mouse cannot implement "click at (412, 180)".
- **Two display lanes, decoupled on purpose.** The HUMAN lane is full-resolution
  at the viewer's panel size (adaptive fps/quality under a bitrate ceiling),
  relayed as bytes — the server never decodes a frame, because a video decoder
  on the request path is what stops it answering RPCs. The AGENT lane is
  downscaled to ≤1280×800 with a one-image-per-result budget applied by the loop
  (`capToolImages`). Compaction sheds stale images and keeps their text.
- **The host worktree is authoritative; the guest copy is a satellite.** A rig
  is synced IN by a tar stream and commits come back as a `git bundle` FETCHED
  into `refs/rigs/<rigId>/*` — never a push, never a checkout. Uncommitted work
  is read out as a diff for a person to look at. The command vocabulary is the
  same on every enclosure; the carrier is a `WorktreeTransport` — an SSH
  channel on a QEMU rig, `smolvm machine exec` on a microVM rig. Without this
  the in-VM terminal would silently become a scratch copy while the UI looked
  identical.
- **No durable credential inside an enclosure.** The guest holds a per-VM secret
  that only buys the right to ASK the host's loopback credential broker for a
  short-lived scoped token, per operation, rate-limited, bounded by the same
  allowlist as egress, and revoked when the rig closes. That is what makes
  `git push` work from an in-VM terminal.
- **Take-over is enforced at a chokepoint, not by a prompt.** `RigService.act`
  refuses an agent's MUTATING action while a human holds control; observation
  (screenshots, extraction) stays allowed so the agent can still narrate. Every
  input event lands in `rig_action_log` with its `Principal` and a monotonic
  per-rig `seq` allocated in the same transaction as the insert.
- **Everything extracted from a guest is untrusted content**, fenced by
  `wrapUntrustedRigContent` with a standing "data, never instructions" rule. The
  fence is framing; the egress allowlist is the enforcement.
- **Bounded by construction.** Hard TTL the guest cannot extend, idle → park
  (QMP `stop`) → close, and an LRU that counts RESIDENT MEGABYTES rather than
  sessions, because a parked VM frees CPU and keeps every byte of its RAM. The
  service tears every machine down on shutdown — an orphaned hypervisor outlives
  the server, holds gigabytes and answers to nobody.
- **`ActionClass.enclosureControl`** is the guardrail class (13 now). Read-only
  modes deny it wholesale; `SandboxBackend.microvm` is probe-gated and NEVER a
  silent fallback — asking for a VM and getting a host shell is the one
  degradation this feature cannot afford, so it fails loudly instead.
- **Boot artifacts are pinned and fetched at runtime, two kinds.** The desktop
  surface's qcow2 base images are user-initiated downloads, checksum-pinned (an
  unpinned entry is refused, not installed), stored under
  `<dataDir>/rigs/images/`, removable with the store;
  `scripts/rigs/build_image.sh` builds the desktop image (the guest agent must
  be baked in) and Settings imports it. The microVM surfaces boot digest-pinned
  OCI images (`kSmolvmExecImage`, `kSmolvmBrowserImage`) that smolvm pulls on
  first use through the machine's own gated egress — the browser image bakes in
  both headless-shell and the socat relay its loopback-bound DevTools needs
  (current Chromium ignores `--remote-debugging-address`, full stop), so
  nothing is installed at boot and there is no first-start package race.
- **Mobile has no base image and never will.** The desktop surface boots a
  qcow2 we control; Android runs on Google's emulator, whose system images ship
  under their licence through their SDK. So `setup_android.sh` installs that
  SDK (reusing an existing Android Studio one rather than downloading a second
  copy) and the probe reports WHICH of the four states the host is in — no SDK
  / no emulator / no AVD / no running device — because they have four different
  fixes and only one is a download. The android backend is reported in EVERY
  state, including "nothing installed": a backend that vanishes when it is
  missing is indistinguishable from one we do not support, which leaves a
  greyed-out Phone tab with nowhere to find out what it needs.
- **Control sockets live OUTSIDE the data directory.** A unix socket path is
  hard-capped at 104 bytes (`sockaddr_un.sun_path` on macOS/BSD; 108 on Linux)
  and the rig runtime dir sits under an operator-chosen `dataDir` whose length
  we do not control — running from source put the QMP socket at 112 bytes and
  QEMU refused to start, so NO rig booted on any surface. `buildRigSocketPath`
  picks the first of `XDG_RUNTIME_DIR` / `TMPDIR` / `/tmp` that fits, which
  self-heals: a root that would overflow is skipped rather than truncated. The
  rig id is never shortened (two rigs sharing a prefix would share a control
  channel), the directory is created 0700 because QMP can stop the VM and
  inject input, and a symlink planted at the `ccrig` namespace is refused
  rather than followed. Durable artifacts (overlay, seed, key) stay in the
  runtime dir, where length does not matter — but teardown and the orphan
  sweep must now clear BOTH trees.
- **The exec rig is seeded with cloud-init, not with our own format.** It
  boots the STOCK Ubuntu cloud image (downloaded and checked against
  Canonical's published hash, which is worth more than an image only we vouch
  for), so it carries none of our units: no `cc-rig-seed` to read a `CCRIG`
  volume, no guest agent, not even the `cc` user the terminal SSHes in as.
  Handing it the built-image seed format configures nothing and the rig is
  unreachable. So exec rigs get a `cidata` seed that creates the user,
  installs the key and writes the same JSON — and their readiness signal is
  sshd's banner, NOT the guest agent, which that image was never supposed to
  answer with. Reading the banner matters: QEMU's user-mode networking accepts
  on a forwarded port before anything in the guest listens, so a bare TCP
  connect reports ready mid-boot.
- **The guest seed is 0640 root:cc, never 0600 root.** Both consumers run
  unprivileged: the guest agent (`User=cc` so a compromised capture process
  cannot synthesize input — that is the hypervisor's job via QMP) and the git
  credential helper, which git invokes as whoever runs it. At 0600 root the
  agent dies with `PermissionError` on every start, `Restart=always` turns
  that into a crash loop, nothing listens on :7811, and the host burns its
  whole 120s agent timeout before reporting "the image may be wrong for this
  surface" — a message that blames the image for a permission bit. Group-read
  by `cc` keeps the broker secret off world-readable while letting the two
  processes that need it work.
- **A built image is verified by BOOTING it, not by trusting the build.**
  `verify_image.sh` boots the finished image with a real per-VM seed and polls
  `/health` exactly as the host does, and `build_image.sh` refuses to publish
  an image whose agent does not answer. "cloud-init applied every line" and
  "the agent serves" are different claims, and only the second is what a rig
  needs — the first one passed for the image that crash-looped. The verify
  boot also attaches a `cidata` seed that dumps the guest's own journal to the
  console, so a failure names itself instead of requiring the whole
  boot-and-probe dance by hand.
- **The image builder verifies that it built something.** cloud-init treats a
  seed it never found as "no work to do": it exits 0 and yields a pristine
  stock image that boots fine and has none of the guest agent in it, failing
  much later inside a rig as a mystery. So the guest echoes a marker to the
  console as its last act and the builder greps for it, deletes the output on
  a miss, and names the usual cause (the seed volume label must be exactly
  `cidata`). The same reasoning covers the host side: firmware is located by
  asking `qemu -L help` rather than guessing distro paths (a Homebrew/Nix
  binary on PATH is a symlink into a versioned store, so `dirname $(command -v
  qemu)/..` finds the profile, not the firmware).
- **Where it lives in the UI.** Rigs are NOT a global destination: the live view
  of a machine belongs beside the work it is doing, so it is a TAB in a channel
  and on a PR page (`Computer/Browser/Phone (VM)`, scoped to the conversation so
  the human's tab and the agent's `*_use` calls address one machine). Whether a
  rig can boot at all is a host property, so capabilities, images and the
  running-machine list are Settings → Server → Enclosures. A rig tab never
  auto-starts, including on layout restore — three VMs booting at launch is an
  expensive surprise. **That rule reaches the adjacent TERMINAL path too**: a
  terminal tab persists its `backend`, and a `microvm` one restored from a
  layout snapshot boots the conversation's exec rig the moment it attaches. The
  layout codec stamps `EditorLayoutCodec.deferStartArg` on those tabs at decode
  time and the hosts render an "Open the shell" affordance instead — the badge
  comes back, the machine does not. A host-shell terminal costs a process and
  still attaches on mount; only the enclosed one waits for a press.

## Code-graph indexing cost model

Indexing is background work that must leave the machine — and the server — usable. Five invariants keep it that way; breaking any of them reintroduces a measured regression:

- **Boot pays nothing for an unchanged repo.** Every run first probes the checkout (`RepoStateProbe`: `git rev-parse HEAD` + `git status --porcelain -z -uall` + an mtime/size fold over the dirty paths) and the extraction toolchain (`codeIndexerFingerprint`: extractor version + `.scm` queries + grammar libs). A match against the partition's `code_index_checkpoints` row returns `CodeIndexResult.unchanged()` before any file-state read, walk, hash, prune, or reference resolution. A worktree additionally compares the base partition's `generation`, because a base re-index invalidates the worktree's delta. `probe == null` (not a git tree, git missing, huge dirty set) **never** skips and a watcher event passes `force: true` — the digest is a fingerprint, not a proof.
- **Nothing CPU-bound runs on the server's main isolate.** Enumeration+hashing (`walkAndHash`), tree-sitter extraction (`ExtractionWorker`, ONE long-lived isolate per run — a wedged parse is killed and respawned) and ONNX embedding (`TextEmbedderWorker`, owning the session because FFI handles can't cross isolates) are all off-isolate. Embedding used to run inline: measured, the RPC server accepted connections but could not answer a request for 40s while a repo indexed.
- **Writes are batched.** `ingestFiles` embeds a whole batch first (outside any transaction — the server has ONE shared DB connection and holding a write txn across inference queues every RPC read behind it), then writes 32 files per transaction. Pruning is one transaction with chunked `IN` lists. `resolvePendingReferences` probes an indexed `COUNT` first and, when work exists, reads a projection of only the needed names (a full-row read dragged along every symbol's 384-float embedding blob).
- **Indexing starts after the ready banner.** `codeGraphWatch.start()` is the last thing `runCcServer` does and the service holds its first sweep for `--code-index-defer` seconds. The desktop parses that banner with a hard 20s timeout and **kills the child** on expiry (`cc_server_process.dart`), so anything heavy on the path to it risks the app dropping to an error screen. `--code-index off` is the field kill switch; `/healthz` reports a `codeGraph` block (watching/indexing/pending).
- **Watching costs nothing to arm and the native is REQUIRED.** The native `cc_watcher` (in-repo Rust crate over `notify`; see `packages/cc_natives/native/watcher/README.md`) watches kernel-recursively on macOS/Windows and installs ignore-aware inotify watches on its own thread on Linux, so arming is O(1) and the arm stagger is zero. There is deliberately **no `package:watcher` fallback** — its `DirectoryWatcher` constructor scans the whole tree and cannot skip `node_modules`, which froze the server isolate for a measured 65 seconds across 4 repos + 72 worktrees, so a silent degrade to it is worse than a loud failure: `create` throws `WatcherUnavailable`, `cc_server`'s native preflight refuses to boot and one unwatchable checkout is logged and retried by the reconcile sweep rather than taking the service down. The native's ignore list is fed from `SourceFileWalker.watchIgnoredDirs`, the same set `affectsIndex` gates on (a test pins them together).

## Workspace isolation

Workspaces are isolated tenants. Data from one workspace must NEVER surface in another. We have had real cross-workspace leaks, so this is a hard invariant, not a nicety. When adding or changing anything that touches workspace-scoped data, follow these rules:

- **`workspaceId` is required, never optional.** Any operation that reads or mutates workspace-scoped data takes a **required** `workspaceId` (Dart) / `workspace_id` (MCP tool schema). Do NOT make it optional, nullable-with-a-default, or resolve a "current"/"active"/"default" workspace implicitly. A required parameter forces every new call site to consciously supply the workspace — and since the split, it is also what picks the database file, so there is nowhere for an unscoped call to go.
- **Entities own their workspace.** `Agent.workspaceId` is **non-null**. Every agent belongs to exactly one workspace. When an operation already has the entity, source the workspace from it (e.g. `PromptBuilder.identity` and the dispatch/memory path read `agent.workspaceId`) rather than threading a separate, fallible parameter that could disagree. `CreateAgentUseCase` refuses to create a workspace-less agent. A write whose entity carries a `workspaceId` uses it to pick the database, so an entity with no workspace now fails loudly at the write instead of landing in an unowned row.
- **Isolation is enforced by the database split, not by WHERE clauses.** A workspace's rows live in that workspace's own SQLite file (`<dataDir>/<workspaceId>/workspace.db`), reached through `WorkspaceDatabaseManager.of(workspaceId)`. A `WorkspaceDatabase` does not declare `users`, `workspaces`, or any other workspace's tables, so a cross-workspace read does not compile. The `workspaceId` columns still exist and are still written (they keep the sync triggers/FTS indexes unchanged and make a file self-describing) but they are no longer what keeps workspaces apart. See the **Database** section for the full picture.
- **Only these tables are shared across workspaces** (they live in `global.db`): `workspaces` (the registry), `users`, `user_preferences`, `paired_devices`, `rss_feeds`/`rss_articles`, `workers`/`jobs`/`placement_log`, `workspace_routes`, `server_meta`. Each is documented `CROSS-WORKSPACE BY DESIGN` and the routing ratchet test pins the set — adding to it is an isolation decision that has to be argued for in review.
- **The one way to reintroduce a leak: caching a resolved DAO.** `final AgentDao _dao;` on a repository can only have come from _some_ workspace and every later call is then answered from that workspace's file whatever `workspaceId` was passed. Always hold the manager and resolve per call. The ratchet test fails on a cached per-workspace DAO field.
- **Repository/DAO methods still take a required `workspaceId`** — that is what selects the file. Never make it optional, nullable-with-a-default, or resolved from a "current"/"active" workspace. An ID-only lookup (`forAgent(agentId)`, `getById(id)`) cannot pick a database, so it must gain one: `forAgent(workspaceId, agentId)`.
- **Crossing workspaces requires `CrossWorkspaceQueries`.** `fanOut` / `fanOutKeyed` / `forEachWorkspace` / `mergeStreams` / `topN`. Its call sites are the complete inventory of what legitimately spans workspaces (all-workspace dashboards, startup reconcilers, retention/GC, event routers) and each keeps a `CROSS-WORKSPACE BY DESIGN:` comment saying why. Anything that enumerates workspaces itself fails the ratchet.
- **Pre-auth lookups route through `workspace_routes`.** A few entry points arrive with nothing but a secret or an opaque id and no workspace: an invite code hash, a webhook token, a deep link naming a run/channel/ticket. Those resolve their workspace from the global `workspace_routes` index (written by the same operation that creates the entity, entity first then route). A miss is a not-found — there is deliberately no scan fallback that could paper over a route that was never written.
- **ID-based access is not a substitute for scoping.** Looking an entity up by its id (`ticketId`, `factId`, `symbol_id`) does not prove it belongs to the caller's workspace. Either scope the query by `workspaceId` so a foreign row is simply not found, or fetch then validate `entity.workspaceId == workspaceId` and reject on mismatch.
- **MCP tools.** Every tool that touches workspace-scoped data declares `workspace_id` in its `required` array, reads it (`if (x is! String) return CallResult.error('Missing or invalid argument: workspace_id')`) and enforces ownership. For repo-scoped tools (code graph) check `WorkspaceRepository.isRepoLinkedToWorkspace`. Tools that genuinely span all workspaces (e.g. `list_workspaces`, `create_workspace`) are the only exemptions.
- **Reject cross-workspace access explicitly.** On a mismatch, deny loudly, never silently no-op (that hides the bug) and never proceed (that leaks). Domain/service code throws `WorkspaceMismatchException` (in `packages/cc_domain/lib/src/errors/app_exceptions.dart`); MCP tools return `CallResult.error('... belongs to a different workspace.')`. The thrown exception's message reaches the agent verbatim via the MCP error path.
- **Validate at a chokepoint.** When a service mutates entities by id, validate once at the single read/write chokepoint rather than per-method. See `TicketWorkflowService._mutate` / `_assertWorkspace`: every mutation threads `workspaceId`, the chokepoint loads the row and asserts `row.workspaceId == workspaceId` before applying.
- **An unregistered workspace id is refused before its database is opened.** Opening a workspace database CREATES the file, so every client-supplied `workspace_id` passes a registry existence check (`workspaceExists`, wired from the global registry and answered by `workspaceRegistryDao.getById`, which excludes soft-deleted rows) at the `repo/call` and `sub/subscribe` chokepoints BEFORE the membership/role lookup or the query handler runs — the role lookup itself opens the named workspace's database. Without the gate, a stale client-held id (e.g. an `active_workspace_id` pref surviving a data-dir reset) sprays an empty ghost `<dataDir>/<id>/workspace.db` per request. Regression coverage: `packages/cc_server_core/test/fresh_boot_first_workspace_test.dart` ("stale workspace id is refused without materialising a ghost database") plus the gate groups in cc_host's dispatcher/subscription-manager tests.
- **Genuinely-global queries are the only exception and must be documented.** A few surfaces legitimately span all workspaces: the dashboard's all-agents/all-channels view, observability aggregation, startup reconcilers (orphan-run reaper, stranded-ticket reconciler, pipeline resume), the embedding backfill and event routers (trigger dispatcher fans out then filters per-event). These keep their unscoped query, but the DAO method MUST carry a `CROSS-WORKSPACE BY DESIGN` doc comment explaining why and pointing to the workspace-scoped alternative. If you add an unscoped query without that comment, assume it is a bug.
- **Membership is enforced at every server chokepoint, not just `repo/call`.** The dispatcher's role gate only covers ops; the other inbound lanes have their own gates, all resolving the caller's role via the `resolveRole` (`WorkspaceRoleResolver`) seam wired from the membership repository: `sub/subscribe` refuses a workspace-scoped watch naming a workspace the user is not a member of (async `sub/error{unauthorized}`; the query handler never runs) and `tools/call` refuses a tool whose arguments name a foreign `workspace_id` (both in `RemoteRpcSession`/`SubscriptionManager` in cc_host). Cross-workspace `watchAll` streams (`workspace`, `agents`, `agent_run_log`, `pipeline_run`, `confirmation.watchPending`) are filtered PER SUBSCRIBER to rows from their workspaces (`_visibleRows` in `remote_rpc_catalog.dart`) and `RemoteEventForwarder` drops notifications whose `workspace_id` the session user does not belong to. Registry ops self-gate: `workspace.upsert` update requires admin, `workspace.delete` is owner-only, `workspace.reorder` filters to the caller's workspaces, `confirmation.respond` requires member. Server-wide settings/MCP/model ops are gated on `serverOwnerUserId` (`requireServerAdmin`) and the `/meeting/audio` + `/workspace-logo` media endpoints verify membership after the device-PSK check. Live revocation: `WorkspaceMemberRemoved` drops the session's subscriptions for that workspace (`dropWorkspaceSubscriptions`) and invalidates the forwarder's cached verdict. Regression coverage: the membership-gate groups in cc_host's `subscription_manager_test.dart` / `remote_rpc_session_test.dart`, `remote_event_forwarder_test.dart` and the non-member e2e in `fresh_boot_first_workspace_test.dart`.
- **Tests.** The structural ratchet is `packages/cc_persistence/test/workspace_isolation_ratchet_test.dart`: every table in exactly one database, the pinned global-table set, no DAO reaching across the boundary, no repository caching a per-workspace DAO, no fan-out outside `CrossWorkspaceQueries` and the workspace-id path-traversal guard. Behavioural denial is covered by `test/features/ticketing/domain/ticket_workflow_service_test.dart` ("workspace isolation" group). Add an analogous isolation test when you introduce a new workspace-scoped surface.

## State management

- **Riverpod** for all state management. Use `Notifier<T>`, `AsyncNotifier<T>`, `FutureProvider<T>` and `Provider<T>`.
- Database-backed state returns `AsyncValue<List<T>>` from Drift `.watch()` streams.
- `core/providers/provider.dart` provides central infrastructure providers (rpc client, server connection, storage, event bus, sync engine, locale) — the thin client has no database/DAO/dio providers.
- `di/providers.dart` is the composition root binding repository interfaces to implementations.
- Feature-level providers live in `features/<name>/providers/`.
- **Never use `ProviderScope.containerOf()`**. Use `ref.read()`/`ref.watch()` in the widget tree.
- MCP tools must NOT receive `Ref`. Use typed constructor parameters.

## Database

- **Drift** (SQLite) with the DAO pattern, owned entirely by the **`cc_persistence`** package (pure Dart over `package:sqlite3`, no Flutter, no `path_provider`). Only `cc_server` opens the DB; every client reaches data over RPC. No code under `lib/` opens a database.

### Two databases: `global.db` + one file per workspace

Persistence is **split by workspace** and this is the single most important thing to know before touching it. There is no `AppDatabase` any more:

- **`GlobalDatabase`** (`lib/database/global/global_database.dart`) → `<dataDir>/global.db`. Holds only genuinely server-wide state: the **workspaces registry**, identity (`users`, `user_preferences`, `paired_devices`), the **per-user newsfeed** (`rss_feeds`/`rss_articles`, scoped by `user_id`), the fleet queue (`workers`/`jobs`/`placement_log`), plus `workspace_routes` and `server_meta`. This is the only database boot opens and it stays small.
- **`WorkspaceDatabase`** (`lib/database/workspace/workspace_database.dart`) → `<dataDir>/<workspaceId>/workspace.db`. Holds _everything else_ — agents, channels, tickets, memory, pipelines, meetings, the code graph, reviews, **repos**. One DIRECTORY per workspace (so anything else belonging only to that workspace lives beside its database and is deleted with it), opened lazily on first touch. There is no flat `workspaces/` directory — see `workspaceDatabasePath` in `cc_persistence/lib/src/server_database.dart`.
- **`WorkspaceDatabaseManager`** (`lib/database/workspace_database_manager.dart`) hands them out: `manager.of(workspaceId)` is **synchronous** (it returns a database over a `LazyDatabase`, so nothing touches disk until the first query — that is what keeps every `Stream`-returning repository signature intact).
- **`CrossWorkspaceQueries`** (`lib/database/cross_workspace_queries.dart`) is the **only** sanctioned way to span workspaces (`fanOut` / `fanOutKeyed` / `forEachWorkspace` / `mergeStreams` / `topN`). Its callers are the complete inventory of everything that legitimately crosses the boundary: all-workspace dashboards, startup reconcilers, retention/GC sweeps, event routers.

**Why it matters:** workspace isolation used to be a _convention_ (every query remembering `WHERE workspace_id = ?`, policed by a regex ratchet). It is now **structural** — a `WorkspaceDatabase` does not declare another workspace's tables, so a cross-workspace read is a compile error. Deleting a workspace is unlinking a file; exporting one is a single `VACUUM INTO`.

**Rules when adding to the schema:**

- A new table goes in exactly one `@DriftDatabase` list. Default to `WorkspaceDatabase` — a table only earns a place in `GlobalDatabase` if it is genuinely server-wide and the routing ratchet test pins that set so the addition has to be argued for.
- A new DAO extends `DatabaseAccessor<WorkspaceDatabase>` or `<GlobalDatabase>` and must not declare a table from the other side.
- **Repositories must never cache a per-workspace DAO in a field.** Hold the manager and resolve `_dbs.of(workspaceId).xDao` per call. A cached DAO pins the first workspace it saw and serves every later caller from that workspace's file — the exact leak the split makes impossible. The ratchet test fails on this.
- The `workspaceId` columns still exist and are still written: they keep the sync-feed triggers and FTS indexes unchanged and make a file self-describing. Inside a file they are redundant, not the isolation mechanism.

- Tables in `packages/cc_persistence/lib/database/tables/`, DAOs in `packages/cc_persistence/lib/database/daos/` (generated `.g.dart` files).
- **Both databases carry a squashed v1 baseline** (`onCreate` builds everything current) plus the appended steps in their `_migrationSteps` list. The live versions are `GlobalDatabase.schemaVersion` and `WorkspaceDatabase.currentSchemaVersion` — read them there rather than here, because a number written down in prose is the part that rots. Each new schema change appends a `MigrationStep(from, to, migrate)` to the `_migrationSteps` list of whichever database owns the table. Partial indexes and FTS/vector virtual tables are (re)built in `beforeOpen` helpers, not `@TableIndex`. An old single-file `control_center.db` from before the split is simply never opened.
- FTS5 external-content tables (`memory_facts_fts`, `code_symbols_fts`, `channel_messages_fts`) and the `sync_changes` change-feed triggers live in `WorkspaceDatabase.beforeOpen` (idempotent, reinstalled on every open); vector embeddings via the `sqlite_vector` extension (FLOAT32, dim 384) with graceful FTS-only degradation. `quick_check` runs per workspace on first touch, not on the boot path.
- ~110 tables. In `global.db`: Workspaces (the registry), Users, UserPreferences, PairedDevices, RssFeeds/RssArticles, Workers/Jobs/PlacementLog, WorkspaceRoutes, ServerMeta. In each workspace file: Repos (which absorbed the old global `repos` + its `workspace_repos` join — see below), Agents, AgentRunLogs, AgentRuntimeState, PullRequests, ReviewDrafts, ReviewChannels, ReviewCohorts/ApiContractSnapshots/VisualDiffSnapshots/ReviewAxisResults, Caches, Channels, ChannelParticipants, ChannelMessages, ChannelNotes, ChannelAutonomy, SyncChanges/SyncSequences (the deterministic change feed), WriteLedger (universal idempotency), Tickets (+ TicketCollaborators/Links and TicketSyncConfigs/SyncLinks/SyncLog), Projects, Playbooks, PlanDocuments + OrchestrationRevisions, Todos, Achievements, AgentDailyStats, Streaks, ActivityLog/UserActivity (audit), WorktreeMergeLog, BudgetPolicy/BudgetIncidents, Approvals/ApprovalComments, Goals, WorkProducts/WorkProductRevisions, RuntimeProfiles, Orchestrations, AgentWorkingMemory, WorkingMemoryItems, MemoryDomains, MemoryFacts, MemoryPolicies, MemoryAccessGrants, MemoryBeliefs/Conflicts/ConsolidationLog, EpisodicEdges, PipelineRuns, PipelineStepRuns, PipelineTemplates, PipelineTriggers, CronExecutions, Teams, TeamActivityLog, CodeSymbols/CodeEdges/CodeFiles/CodeIndexCheckpoints, Meetings (+ TranscriptSegments/Speakers/ActionItems/Decisions/CalendarLinks), CalendarAccounts/Events/Sources, VoiceProfiles, IsolatedRepos, WebhookDeliveries, ProviderPolicies, RememberedDecisions, ActionPolicies, SkillScanResults, SessionRecordings/GoldenSessions/EvalSuites/EvalRuns/AgentConfigVersions, WorkspaceMembers/WorkspaceInvites/WorkspaceMemberRepoGrants, RigSessions/RigActionLog (enclosures + their attributed action log) and WorkspaceMeta (the file's self-identification).
- **Repos are workspace-scoped.** `RepoRepository` takes a required `workspaceId` on every method. The same checkout registered in two workspaces is two rows with two ids — repo identity _across_ workspaces is by path (`findByPath`), never by id. `workspace_repos` is gone; its `position`/`linkedAt` columns moved onto `repos`.
- **Backup is a directory, not a file:** `backups/<ts>/{manifest.json, global.db, <workspaceId>/workspace.db}` (the same shape as the live data dir, so a restore is a copy back), each written with `VACUUM INTO`. `workspace.export` / `workspace.import` hand a single workspace around as one file.

## Routing

- **go_router** with `ShellRoute` wrapping the app shell (`ControlCenterLayout`).
- **Every in-app destination is workspace-prefixed: `/workspaces/:workspaceId/…`.** The workspace id in the URL is the single source of truth for the active workspace (`activeWorkspaceIdProvider` is driven from the route; read it via `context.currentWorkspaceId`). Route builders take the workspace id as their first argument. Only the pre-context surfaces have no prefix: `/splash`, `/onboarding` and `/workspaces` (the picker).
- Splash and onboarding render full-screen outside the shell. The auth guard redirects to `/onboarding` until GitHub auth (PAT or `gh` CLI) + at least one workspace are set.
- Route constants in `router/routes.dart` (builder functions, not string constants). Router config in `router/app_router.dart`; guard logic in `router/guards.dart`; onboarding gate in `features/auth/providers/onboarding_providers.dart`.
- Notable non-obvious routes: `/workspaces/:id/inbox` (the unified inbox) and `/workspaces/:id/plans` + `/workspaces/:id/plans/:kind/:id` (Plan Studio hub + studio; `kind` = `orchestration`|`document`).

## Networking

- **All external network I/O lives in `cc_server`, never in a client.** The dio HTTP clients moved out of `lib/` into **`cc_infra`** (the server-side VM-only adapter package): `GitHubApiClient`, `GitHubPrClient`, `GitHubContentClient`, `GitHubGraphqlClient`, `LinearApiClient`, plus the Google Calendar REST client.
- Auth token injection via dio interceptors; all network errors mapped to typed `AppException` subclasses (in `cc_domain`'s `src/errors`).
- Clients (desktop/web/phone) never dial GitHub/Linear/Google directly — they call server RPC ops and even remote media is fetched through the server's `/proxy/media` endpoint (`MediaProxyConfig`). Non-ranged image fetches are served through a persistent disk cache (`MediaCache` in `cc_server_core`, under `<dataDir>/media_cache/`, keyed by `(url, w)`): TTL honors upstream `max-age` clamped to 1h-7d (24h default), expired entries revalidate with `ETag`/`Last-Modified` conditionals, a failed refresh serves stale and concurrent same-key requests single-flight. Client-side, requested widths are bucketed UP to a shared ladder (`bucketMediaWidth` in `lib/shared/utils/media_width_ladder.dart`) so nearby display sizes share one cache entry.

## UI

- **cc_ui** (`packages/cc_ui/`) is the in-repo design system. The app owns every visual component. Use the `Cc*` widgets (`CcButton`, `CcTextField`, `CcDialog`, `CcSidebar`/`CcSidebarGroup`/`CcSidebarItem`, `CcDivider`, `CcToastScope`, …) for all UI; the Widgetbook gallery in `apps/cc_gallery/` previews every component.
- **cc_ui is purist; it builds on `package:flutter/widgets.dart` only**, never `material.dart`/`cupertino.dart`: no `Material`, `Scaffold`, ink, or Material `Theme`. Design tokens travel through the `CcTheme` `InheritedWidget`. Read semantic tokens with `context.designSystem` and the full config (brightness, reduced-motion, resolved font families) with `context.ccTheme`; both fall back gracefully when there is no `CcTheme` ancestor. Resolve fonts via `CcFonts.ui`/`CcFonts.code`, never by passing a raw family string to `TextStyle.fontFamily`.
- **Overlays do not inherit a Material text theme. Supply your own.** `MaterialApp` only installs a usable `DefaultTextStyle` _inside_ each route's `Material`. Anything presented into the root overlay (dialogs via `showCcDialog` → `showGeneralDialog`, toasts, popovers, sub-windows) sits above that, where the only ambient `DefaultTextStyle` is `WidgetsApp`'s error fallback, 48px text with a double yellow underline. `showCcDialog` wraps its content in a complete design-system `DefaultTextStyle` (concrete size + token color + `decoration: TextDecoration.none`) so this never leaks through; any new off-Material overlay surface MUST do the same.
- **Material 3** remains the _root_ app theme (`MaterialApp`, light/dark) with `ThemeMode` persistence via `shared_preferences` (non-sensitive only); cc_ui renders on top of it without depending on it.
- **Phosphor for iconography, vendored not depended on.** `packages/cc_ui/fonts/Phosphor-Regular.ttf` is the only icon font; glyphs go through the generated `AppIcons`/`CcIcons` codepoint seams owned by `tool/gen_icon_seams.py` (`fontPackage: 'cc_ui'`). Do NOT re-add `phosphoricons_flutter`: its ~1530-member classes stack-overflow the web DDC linker and its pubspec declares all six styles — a dependency's `fonts:` block cannot be opted out of, the icon tree-shaker skips a font with no const `IconData` referencing it and Flutter web downloads every `FontManifest.json` entry at engine boot, so the five unused styles cost 2.46 MB per cold load. `test/tooling/icon_font_bundle_test.dart` pins this.
- **cc_markdown** (`packages/cc_markdown/`) is the in-repo markdown engine — a custom typed-AST parser + widget renderer that replaced `flutter_smooth_markdown` and `flutter_markdown_plus` (both removed). ` ```mermaid ` fences are drawn natively by the package's own diagram engine (`CcMermaidView`) — pure-Dart dialect parsers (flowchart/`graph`, `stateDiagram`, `classDiagram`, `erDiagram`, `sequenceDiagram`, `pie`, `timeline`) → layout (layered Sugiyama-style for the graph family) → `CustomPainter`; no WebView, no JS, no new dependency. Author theming (`%%{init}%%`, `classDef`, `style`) is parsed but NOT applied: diagrams are themed from app tokens via `appMermaidStyle` so light/dark and the contrast floor hold. An unsupported dialect or malformed body degrades to the normal code block (the engine never throws) and an unclosed streaming fence stays code until it closes. Render with `CcMarkdown` (one-shot) or `CcStreamingMarkdown` (first-class LLM streaming: sealed-block memoization, per-delta tail parse, no cache pollution). App-side wiring lives in `lib/shared/widgets/markdown/`: `appMarkdownStyle` (the ONE unified `CcMarkdownStyle` for every surface), `markdown_registries.dart` (chat vs GitHub plugin/builder registers), `markdown_builders.dart` and `buildSharedCodeBlock` (syntax highlighting stays app-side, injected via `codeBuilder`). GitHub surfaces use `GitHubMarkdownBody`; tickets/meetings use `StyledMarkdownBody`. The package is widgets-only except the selection island (`selection_region.dart` + `context_menu.dart`), enforced by the cc_markdown purity group in `architecture_constraints_test.dart`.
- Custom diff viewer with syntax highlighting in `pr_review/presentation/`.
- **Syntax highlighting is shiki_flutter** (TextMate grammars, pure Dart) everywhere: markdown fences, transcript tool bodies and the PR diff. The app-side seam is `lib/shared/syntax/` — the custom `cc-light`/`cc-dark` themes (authored from `syntax_palette.dart`; a drift test pins them together, bump `kCcThemeRevision` on any theme edit), ONE unified language table (`syntax_languages.dart`: fence hints + file paths + well-known filenames → shiki ids, with measured per-grammar weight classes gating sync vs async tokenization) and the grammar registries (native indexes all ~250 grammars; web ships a curated ~50 eagerly + 5 deferred packs regenerated by `tool/gen_grammar_packs.py`). The PR-diff worker compiles `package:shiki_flutter/engine.dart` (the package's Flutter-free entrypoint) straight into `web/diffWorker.js` and tokenizes per hunk. Unmatched tokens carry the `#010203` sentinel foreground which maps to `null` (inherit the surface's base style) — never hardcode that hex elsewhere.
- Global error boundary via `PlatformDispatcher.instance.onError` + `ErrorWidget.builder`.

## Design context

Design is governed by two root files, managed by the `impeccable` skill. Read them before designing or reviewing any UI.

- **PRODUCT.md**, strategic: register, users, product purpose, brand personality, anti-references and the principles below. Answers who/what/why.
- **DESIGN.md**, visual: color tokens, typography, elevation, components, do's and don'ts. Answers how it looks. The design-system tokens live in the `cc_ui` package (`packages/cc_ui/lib/src/tokens/`; the `core/theme/` paths are now re-export shims); read tokens via `context.designSystem`.

Register: **product** (design serves the task). Personality: **alive, warm, confident** (Anthropic-style warmth, never cold), with earned brand moments (onboarding, the dashboard deck, the shader backgrounds). Product framing: a **unified developer ops hub** for a **solo, multi-platform operator** (desktop + web + phone). Agents are one pillar among co-equal ones (messaging, meetings, calendar, newsfeed, PR review). Anti-references (hard): **generic SaaS dashboard** and **default component-kit/template feel**. Accessibility bar: **WCAG 2.1 AAA where feasible, AA as the floor**, never status-by-color-alone, full reduced-motion alternatives, keyboard-first _and_ touch-ergonomic (≥44px targets on phone).

Core design principles:

1. **Presence over decoration.** Motion, color and "life" must report real state (an agent thinking/running/blocked/done/costing, a meeting recording, a sync in flight, a feed updating), or they are cut.
2. **Situational command in one glance.** Across every pillar, surface status, ownership and the next action by default; bury nothing essential a level deep.
3. **Distinctive through behavior, not skins.** Escape the component-kit feel by making the model legible, not by adding decoration.
4. **Warm confidence, earned.** Warmth and expression live in voice and a few thresholds; day-to-day surfaces stay quiet, dense and consistent with one component vocabulary.
5. **Solo-first, multi-platform continuity.** Optimize for one operator now, keep the operation coherent across desktop/web/phone (no surface a degraded afterthought) and keep attribution legible so team use is additive, not a rewrite.

For any design work (new screens, redesigns, reviews, polish), use the `impeccable` skill: `/impeccable <command>`.

## Security

- API tokens stored via `flutter_secure_storage` (macOS keychain, Windows credential store, Linux libsecret).
- `shared_preferences` used only for non-sensitive preferences (theme, font).
- Credentials repository (`SecureCredentialsRepository`) abstracts storage from providers.
- Keychain access group entitlements configured for macOS release + debug.

## Domain Events

- `DomainEventBus` in `packages/cc_domain/lib/core/domain/events/` enables decoupled cross-feature communication.
- Workspace, Agent & Repo: `WorkspaceCreated` (triggers CEO seeding), `AgentRunCompleted`, `RepoAdded` (triggers code indexing)
- PR & Review: `PullRequestPublished`, `PullRequestStatusChanged`, `PrMerged`, `ExternalPrDetected`
- Messaging: `MessageReceived`, `ChannelCreated`, `ChannelDeleted` (drives worktree GC), `ChannelProvisioningChanged` (workspace setup progress: the chat bridge narrates it on its task card)
- Ticketing / task lifecycle (vendor-neutral): `TicketCreated`, `TicketStarted`, `TicketCompleted`, `TicketFailed`, `TicketCancelled`, `TicketStatusChanged`, `TicketAssigned` (the sole event the dispatcher consumes), `TicketReassigned`, `TicketDelegated`, `TicketCollaboratorAdded`, `TicketDetailsUpdated`, `ExternalTicketWebhookReceived`; plus the fine-grained `Task*` run signals (`TaskQueued`/`TaskDispatched`/`TaskRunning`/`TaskProgress`/`TaskMessage`/`TaskCompleted`/`TaskFailed`/`TaskCancelled`/`TaskWaitingLocalDirectory`)
- Orchestration: `OrchestrationProposed`, `OrchestrationApproved`, `OrchestrationRevised`, `OrchestrationExecutionStarted`, `OrchestrationCompleted`, `OrchestrationFailed`, `OrchestrationCancelled`
- Pipeline lifecycle: `PipelineRunStarted`, `PipelineStepStarted`, `PipelineStepCompleted`, `PipelineStepFailed`, `PipelineRunCompleted`, `PipelineRunFailed`, `PipelineRunCancelled`
- Memory: `MemoryFactRecorded`, `MemoryFactUpdated`, `MemoryFactSuperseded`, `MemoryConflictDetected`, `MemoryBeliefHarmonized`, `MemoryConsolidated`
- Calendar & Meetings: `CalendarEventsRefreshed`, `CalendarAuthExpired`, `MeetingStartingSoon`, `MeetingRecordingStopped`
- Identity & membership: `UserCreated`, `WorkspaceMemberAdded`, `WorkspaceMemberRemoved` (live sessions must re-check access immediately), `WorkspaceMemberRoleChanged`, `UserDeviceRevoked` (terminate the session within seconds, not on next reconnect), `WorkspaceInviteRedeemed`
- Observability: `ActivityLogged`, `WorktreeMerged`, `BudgetThresholdCrossed`.
- CEO agent seeding is event-driven (listens to `WorkspaceCreated`) instead of fire-and-forget in `build()`.

## Build and code generation

**Use `fvm` for every Flutter/Dart command.** This repo pins its SDK with [fvm](https://fvm.app), so always prefix invocations: `fvm flutter <…>` / `fvm dart <…>` (e.g. `fvm flutter analyze`, `fvm flutter test`, `fvm flutter gen-l10n`, `fvm dart analyze tool/foo.dart`). A bare `flutter`/`dart` may be missing from PATH or resolve to the wrong SDK version. The user owns running the app (`fvm flutter run`). Do not start it yourself.

**Cap test concurrency: always run tests with `--concurrency=2` (use `--concurrency=1` for the root app suite).** `flutter test` defaults to one `flutter_tester` per CPU core and each one loads the entire app plus a `frontend_server` compiler, so an uncapped run can exhaust machine memory (it has crashed a laptop). Also never run two test suites in parallel. A PreToolUse hook in `.claude/settings.json` denies uncapped `flutter test` / `dart test` invocations.

```bash
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

Because this is a single-lockfile pub workspace, a root `build_runner` run regenerates every member. Required after changes to:

- Database tables/DAOs (drift) — the generated code lives in `packages/cc_persistence`.
- JSON serializable / other codegen models (`*.g.dart`) — mostly in `packages/cc_domain`.

**Rebuild the `cc_server` binary after any server-side change.** The desktop launches a prebuilt `cc_server` binary in preference to source, so a new RPC op or tool won't appear (returns `opUnknown` / "unknown tool") until you rebuild it:

```bash
cd apps/cc_server && dart build cli
```

Tell-tale sign: a change works in tests but not in the running app. The user owns running the app (`fvm flutter run`); do not start it yourself.

**Native libraries are REQUIRED — there is no degraded mode.** Every native
(`rift`, `fff`, `tree-sitter` + its five grammars, `cc_watcher`, `ccpty`,
`aec_ffi`, `lame_ffi`, `cc_inference`) must be built and staged before
`dart build cli`:

```bash
scripts/natives/build_natives.sh      # aborts on the first failure
```

`cc_inference` is the in-repo Rust crate (`packages/cc_natives/native/inference/`)
that owns BOTH on-device ML workloads — speech (sherpa-onnx: ASR, VAD,
diarization, voiceprints) and text embeddings (ONNX Runtime) — statically linked
against ONE ONNX Runtime. On-device inference has NO pub dependency; do not add
one back. A second ONNX Runtime in the process is a Windows loader hazard (it
resolves a DLL dependency from already-loaded modules by base name) and a pub
package that imports `package:flutter` cannot link into the Flutter-free server
binary at all.

A missing dylib is a broken install, never a runtime condition. Loaders throw a
`NativeLibraryUnavailable` (rift signals it via `RiftException.isUnavailable`),
`cc_server`'s boot preflight refuses to start and names the offender, the build
hook fails `dart build cli` (create a repo-root `.cc_natives_allow_missing`
file to downgrade that to a warning for compile-only work — a FILE, not an env
var, because the hooks runner does not forward the caller's environment) and the packaging scripts refuse to produce an artifact. Do
NOT reintroduce a fallback: one hides a broken native behind a slower working
path forever and the only symptom is that things quietly got worse.

The required set lives in ONE matrix, `scripts/lib/natives.sh`, which
`verify_natives.sh` and the packaging scripts read and
`test/tooling/native_matrix_test.dart` pins against the `nativeRequirement` table
in `cc_server_runtime.dart`. `rift` on Windows is the single platform exemption
(no MSVC copy-on-write backend, so `git worktree` is the _backend_ there).

Only two fallbacks remain, both **environment**-driven so neither can mask a
build failure: a filesystem without copy-on-write support
(`RiftException.isCowUnavailable` → `git worktree`) and semantic search staying
FTS-only until the on-device embedding **model** downloads
(`EmbeddingService.isReady`). Models are the only artifacts fetched at runtime.

**Regenerate the Web Workers after changing any worker source.** Heavy CPU work
that must run off the main thread uses [`isolate_manager`](https://pub.dev/packages/isolate_manager)
— real isolates on native, generated `web/<name>.js` Web Workers on the web (so
web reaches desktop parity instead of janking on the main thread). Worker entry
functions are annotated `@isolateManagerCustomWorker` / `@isolateManagerWorker`
and live in **Flutter-free** files (they compile via `dart compile js`, which
cannot see Flutter — e.g. `diff_worker_core.dart`). After editing a worker entry
or any code it pulls in, regenerate and commit the JS (same discipline as
`build_runner` for `*.g.dart`):

```bash
tool/gen_workers.sh   # dart run isolate_manager:generate --input lib --output web --single
```

The generator (`isolate_manager_generator`) is a build-time-only tool run via
`dart pub global` — it is deliberately NOT a dev_dependency because it pins
`analyzer ^10`, which conflicts with mockito's `analyzer ^13`. The committed
`web/*.js` mean `flutter build web` needs no generator. `test/tooling/web_workers_test.dart`
asserts every annotated worker has a committed asset; `tool/check_workers.sh`
(and the scoped `.github/workflows/web-workers.yml`) byte-diff for staleness.

### Internationalization (i18n)

- **All user-facing strings MUST be internationalized** using Flutter's l10n system. NEVER hardcode English text in widgets, screens, or dialogs.
- Access translations via `final l10n = AppLocalizations.of(context)!;` then `l10n.keyName`.
- L10n keys are defined in ARB files under `lib/l10n/`. Source of truth: `app_en.arb`.
- When adding a new key, add it to ALL 7 ARB files: `app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_it.arb`, `app_de.arb`, `app_pt.arb`, `app_nl.arb`. Translate the values you are adding to the other languages.
- Key naming: camelCase, descriptive (e.g. `agentName`, `failedWithError`, `saveChanges`).
- After adding keys, run `flutter gen-l10n` to regenerate the Dart l10n files.
- For strings with parameters: `"keyName": "{param} some text"` with `"@keyName": { "placeholders": { "param": { "type": "String" } } }`.
- MCP tool titles and descriptions are API descriptions for AI agents. Do NOT i18n them.
- Data-layer strings without BuildContext (e.g. default agent names, notification event titles) may remain hardcoded if no context is available. Prefer passing locale through the call chain when practical.
- Example placeholders like `hint: 'e.g. architect'` are acceptable to leave as-is.
- Run `flutter gen-l10n` after any ARB file changes.

### Copy/text conventions

- **All user-facing strings MUST use sentence case** (capitalize only the first word and proper nouns like "GitHub", "Linear", "Riverpod", "Dart").
  - Correct: "Add agent" / "Create new workspace" / "Connect to GitHub"
  - Wrong: "Add Agent" / "Create New Workspace" / "Connect To GitHub"
  - Buttons, labels, tooltips, dialogs, form labels, navigation items, badges, keybinding labels, all sentence case.
  - NEVER use title case in user-facing strings.

## Architecture enforcement

Architecture constraints are validated by `test/core/architecture_constraints_test.dart`.

## Git safety

- **NEVER run `git stash`, `git restore`, `git checkout`, `git reset`, `git clean`, `git stash drop`, or any other destructive git command** that modifies or discards uncommitted working-tree changes.
- If you need a clean tree for verification, create a new branch or worktree instead.
- If you need to inspect the state at HEAD, use `git show HEAD:<path>` or `git diff`, read-only operations only.
- Uncommitted changes are the user's property. Treat them as irreversible.
