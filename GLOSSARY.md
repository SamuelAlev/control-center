# Control Center Ubiquitous Language Glossary

Names and distinctions used across the domain. This is not a field inventory; entity definitions live under `packages/cc_domain/lib/`, persistence under `packages/cc_persistence/`. See [ARCH.md](ARCH.md) for implementation constraints and [SECURITY.md](SECURITY.md) for trust boundaries.

## Core Domain Entities (Shared Kernel)

- **Agent:** AI worker with a workspace identity, role, skills and optional reporting relationship. Each agent belongs to exactly one workspace. A **DiscoveredAgent** is an on-disk `AGENTS.md` definition not yet registered as an agent.
- **Workspace:** soft-deletable top-level tenant for agents, repositories, spaces, tickets and memory.
- **Repo:** registered Git checkout scoped to one workspace. Registering the same path in another workspace creates a separate repo record; GitHub remote is optional. **GitRepoInfo** is inspected checkout/remote metadata, not a registration.
- **IsolatedRepo:** per-space branch/worktree provisioned from a registered repo, distinct from its source checkout. `rift` supplies copy-on-write isolation where available; Windows uses `git worktree` as its backend. A failed CoW provision does not switch to a source-mutating fallback.
- **AgentRunLog:** one durable execution record, including status, cost, errors, retry/parent lineage and optional pipeline/output contract. **RunTranscript** is its ordered reasoning/tool/answer timeline; a subagent's tool activity belongs to its own transcript, not its parent's message. Live runs stream from an in-memory registry.
- **ReviewSpaceAssociation:** binds a regular space to a PR review. Review identity is the association, not a special message container.

## Messaging Bounded Context

- **Space:** workspace-scoped participant container. A DM and a room differ only by participant count; some legacy/system spaces have no workspace id. A space has a mode and provisioning state.
- **Conversation:** a peer message stream within a space; none is the primary stream. A **thread** is a conversation anchored to one message in a sibling conversation of the same space. Threads do not nest. **ThreadSummary** is a derived reply/participant rollup for its anchor, not independent state.
- **Message:** one conversation entry, typed for rendering by **MessageType** (`text`, `agentTurn`, `reviewNode`, `plan`, etc.); `agentTurn` contains a completed turn's segments. **SenderType** distinguishes human `user` from `agent`.
- **SpaceParticipant:** an agent or human principal in a space, with a role and individual read cursor. **MessageMention** is a resolved @mention referencing either principal type.
- **SpaceRepo:** the space's explicitly selected repos for worktree provisioning. With no rows, older spaces use all workspace repos; PR spaces use their PR repo.
- **MessageReaction:** a principal's emoji reaction on a space message, unique per message/principal/emoji. Do not confuse it with GitHub PR **ReactionGroup**.
- **ThinkingEvent:** reasoning subtype of the live **AgentProcessEvent** stream, grouped with tool calls/results for display.

## Dispatch Bounded Context

- **AgentDispatchService:** provisions repos, assembles a prompt, creates the run record and streams process events; also finalizes/stops runs. **AgentProcessEvent** is a timestamped thinking/text/tool/error/done event, not a persisted message.
- **DispatchAgentUseCase:** resolves effective agent, mode and runtime. **BuildAgentPromptUseCase** combines mode prompts with conversation and memory context. **PromptBuilder** supplies mode/role protocol text.
- **MentionContext / MentionRosterEntry:** who summoned an agent and the eligible space roster for mention resolution.
- **AgentGoalRun:** durable supervised `/goal` or `/loop`, redispatched as bounded runs until completion, stop or budget wall; at most one active per agent, recovered after restart. Not the organization-level **Goal** or the conversation's **ConversationGoal**.

## PR Review Bounded Context

- **PullRequest:** GitHub PR with identity, branches, review/check state and diff metadata. **EnrichedPullRequest** pairs one with a registered Repo and assigns priority/staleness category; **RepoPullRequests** groups them by repo.
- **PrFile / FileChange / PrCommit / CheckRun:** respectively a changed file with patch/viewed state, a patch-free file summary, a PR commit, and a CI check on the PR head. **IssueComment** is top-level; **PrCodeReviewComment** is an inline GitHub comment with diff/thread anchoring.
- **PrInlineThread / PrInlineEntry:** locally authored inline review or suggested-edit thread and its entries, including resolved/GitHub-sync status. **PrReviewSubmission** is a submitted verdict; **PrUser** is a small GitHub user reference.
- **ReactionGroup:** grouped GitHub PR reactions. **GifResult** is a GIF search result; neither is a space-message reaction.
- **PrGeneration:** workspace-scoped generated PR draft not yet published to GitHub.
- **ReviewNodePayload:** validated typed finding attached to a `reviewNode` message. **ReviewVerdict:** ship/hold/block aggregate of findings. **ReviewDisagreement:** conflicting reviewer findings on one file/line. **DiffOverflowMode:** wrapping vs scrolling in the diff viewer.

## Ticketing Bounded Context

- **Ticket:** vendor-neutral unit of work: optional provider issue plus local assignment, delegation, hierarchy and orchestration overlay. Pipeline output contracts belong to **AgentRunLog**, not Ticket.
- **TicketCollaborator:** human/agent participant in ticket work, separate from a **SpaceParticipant**. **TicketLink:** directed `blocks`, `relatesTo` or `duplicateOf` relation. **Project:** local workspace grouping for tickets, not synced to a provider.
- **TicketStatus:** `backlog`, `open`, `inProgress`, `blocked`, `inReview`, `done`, `failed`, `cancelled`. **TicketProvider** distinguishes local and synced sources; status and priority are domain values rather than remote-provider labels.

## Teams Bounded Context

- **Team:** persistent workspace agent roster with a leader and operating protocol, assignable to tickets and orchestrations. **TeamMember** links an agent to that roster; **TeamActivity** is its append-only event log. **TeamRoutingService** dispatches work assigned to a team.

## Pipeline Bounded Context

- **PipelineDefinition:** versioned declarative step DAG (a template), not a running job. **PipelineStepDefinition:** node with kind, triggers, dependencies and configuration. **PipelineNodeConfig:** body inputs/outputs, reducer, retry/timeout, agent/script choices; **StepRetryPolicy:** bounded attempts and backoff. **PipelineInput:** declared manual-run form field.
- **PipelineRun:** persisted, resumable execution of one template with mutable state and cost totals. **PipelineStepRun:** one node execution and attempt/output history within that run.
- **PipelineTrigger:** default-off workspace rule starting a pipeline on a domain event, cron schedule or manual run. **StepTrigger:** edge rule determining when a downstream node fires. **StepResult:** node result, including route, suspend, terminal and failure outcomes.
- **StepKind:** `trigger`, `listen`, `join`, `router`, `forEach`, `terminal`; step body keys are validated against kind.

## Orchestration Bounded Context

- **Orchestration:** a workspace-scoped, parent-ticket-backed large request. An agent proposes a plan; a person approves it; deterministic materialization creates a pipeline, team/project and child tickets. Its `revision` and `approvedRevision` keep replans from changing an approved plan silently.
- **OrchestrationProposal:** typed goal, roles, sub-ticket DAG, optional research/discussion/synthesis and budget, validated before execution. **ProposedRole / ProposedHire / ProposedSubTicket / BudgetSpec:** the plan's staffing, work and spending inputs.
- **OrchestrationMaterializer:** pure plan-to-pipeline translation for an approved proposal and role map; same inputs produce the same DAG. **OrchestrationProposalValidator** validates input; approval/cancel use cases govern transition; **OrchestrationRunListener** maps terminal pipeline state to orchestration and parent ticket.

## Code Graph Bounded Context

- **CodeSymbol:** indexed source symbol, workspace+repo scoped. **CodeEdge:** directed relationship between symbols, possibly unresolved. **CodeSubgraph:** root plus reachable symbols/edges/depth for impact traversal. **CodeSymbolKind / CodeEdgeKind:** stored symbol/relationship classifications.
- **CodeIndexCheckpoint:** per-workspace/repo/checkout fingerprint of the last successful index, not a domain entity. See [ARCH.md](ARCH.md) for probe, watcher and index invalidation rules.

## Memory Subdomain

- **MemoryFact:** workspace-scoped knowledge with provenance/confidence and optional embedding; a newer fact can supersede it. **MemoryPolicy:** active/inactive normative rule derived from facts and optionally gated by agent role.
- **MemoryDomain:** named workspace grouping of facts and policies. **MemoryAccessGrant:** role-specific permission to a domain. **AgentWorkingMemory:** per-agent scratchpad persisting across runs, distinct from shared facts and policies.

## Newsfeed Bounded Context

- **RssFeed / RssArticle:** registered RSS/Atom source and its fetched article with read/saved state. Newsfeed is server-global, not a workspace data set.

## Calendar Bounded Context

- **CalendarAccount:** connected Google account per workspace/email; reauthorization is indicated by expired auth state. Tokens are not fields on this entity. **CalendarEvent:** synced scheduled event, distinct from a recorded **Meeting**. **CalendarAttendee:** RSVP participant; the app only writes the signed-in user's attendance response, never creates/edits/deletes events.
- **MeetingCalendarLink:** optional unique link from a recorded meeting to its source calendar event. **CalendarEventStatus** is the provider event lifecycle; **CalendarViewMode** is a UI preference, not an event state.
- **GoogleOAuthService / GoogleCredentialsRepository / GoogleOAuthRedirectChannel:** OAuth PKCE flow, per-account server-side credential store and OS redirect bridge, respectively. See [SECURITY.md](SECURITY.md) for credential ownership.

## Meetings Bounded Context

- **Meeting:** workspace-scoped recording/transcription session, with status and optional calendar link. **MeetingSegment:** time-offset transcript window marked `me` or `them`, with optional diarized identity. **MeetingSpeakerLabel:** inferred speaker label with optional user-chosen name.
- **MeetingActionItem / MeetingDecision:** structured rows extracted from summarization, not markdown parsing. **MeetingOutcome:** parser for agent output; only structured output writes those rows; degraded text retains raw transcript. **formatMeetingTranscript:** renders timestamped speaker lines for processing.
- **VoiceProfile:** workspace-specific voice model used to recognize speakers across recordings. Mic/system audio, transcription and diarization run on device.

## Settings Bounded Context

- **Adapter:** agent runtime definition, including executable identity where applicable. **DetectedAdapter:** status/version/path found on the host. **AcpModel:** model advertised for an ACP-compatible runner.

## Agents Bounded Context (Doctor & Live State)

- **DiagnosticResult / DoctorReport:** one environment check and its aggregate report. **AgentLiveState:** `running`, `blocked`, `failed`, `idle`, `neverRun`, derived from recent runs rather than independently persisted.

## Dashboard Bounded Context

- **DashboardStatus:** summary of workspace counts. **ActiveProcessInfo:** matched live agent OS process and workspace.

## GitHub Status Bounded Context

- **GitHubServiceStatus:** aggregate public GitHub service health. **GitHubStatusComponent / GitHubStatusIncident:** individual service and active incident within that status.

## Auth Bounded Context

- **ApiCredentials:** external-service API credentials for a user. **GitHubCliStatus:** local `gh` installation/auth state. **Token:** sensitive value object whose string rendering masks the secret.

## Identity & Access Bounded Context

- **User:** human identity spanning workspaces. **Principal:** tagged union `UserPrincipal` or `AgentPrincipal`, used for attribution and ownership; never use a sentinel user id for an agent.
- **WorkspaceMember:** user-to-workspace role assignment. Membership is the access boundary; a paired device alone is not membership. **WorkspaceRole:** `owner`, `admin`, `member`, `viewer`, `guest`.
- **WorkspaceInvite:** expiring one-use, hash-stored invite for a role. **UserDevice:** user's paired-client credential; revocation closes active sessions. **UserActivityEntry:** append-only attribution/audit record.
- **WorkspaceMemberRepoGrant:** per-workspace/user/repo `none`, `read`, `review`, `write` grant. Owners/admins have implicit write; other members default to none, preventing workspace membership from over-granting forge access.

## Governance Bounded Context

- **OrgChart / OrgNode:** hierarchy derived from agent reporting lines. **Goal:** tracked organizational agent/team target, distinct from **AgentGoalRun** and **ConversationGoal**.
- **Approval / ApprovalComment:** board decision gate and discussion; plan-mode exit is a `plan_exit` approval. **WorkProduct / WorkProductRevision:** versioned deliverable. **AgentRuntimeState / RuntimeProfile:** heartbeat/liveness and runtime settings. **BudgetPolicy / BudgetIncident:** spending ceiling and its breach record.

## Harness Bounded Context (built-in agent runtime)

- **Harness:** in-process agent loop calling model providers and tools directly, not an external CLI subprocess. `cc_harness` is the portable kernel, `cc_harness_runtime` hosts VM-only providers/tools; server adapters live in `cc_infra`. A model *provider* (including Cursor) is not an adapter process.
- **AgentLoop / AgentLoopRunner:** event-sourced turn interface and implementation, emitting text/reasoning/tool/turn events. **LlmProviderPort / HarnessProviders:** provider contract and credential resolution. **Tool / ToolRegistry:** in-process tools available to the loop; external MCP tools are bridged in. **ReasoningEffort:** provider-mapped reasoning setting.

## Model Routing Bounded Context

- **ModelCatalog:** provider/model metadata including context limits, reasoning support and prices. **ProviderPolicyEngine / ProviderPolicy:** per-provider availability and context-promotion policy. **SmallModelRouter:** routes eligible subtasks to cheaper/faster models within quality constraints.

## Skills Bounded Context

- **Skill:** reusable instruction bundle. Workspace skills may be `manual`, `runtimeLocal` or commit-pinned `github` origins, locked by content hash in `skills-lock.json`. A **repo-scoped skill** instead comes from the active worktree (`.agents/skills`, `.claude/skills`, `.opencode/skills`) and is not installed workspace-wide. Invocation may name the repo to disambiguate a collision (`/skill:<repo>:<name>`).
- **SkillLockEntry / SkillBundleService:** pinned content/provenance and scan-gated install/update boundary. See [Skills Supply-Chain Security](#skills-supply-chain-security).

## Observability Bounded Context

- **ObservabilityMetrics / Quota / Benchmark / FrictionAnalyzer / SubagentCostPropagator:** workspace usage/cost, provider quota windows, repeatable scored trials, agent-decision friction and child-to-parent run cost aggregation.

## Todos Bounded Context

- **Todo:** shared per-conversation task checklist; `todo_write` replaces its full list. **ConversationGoal:** one working goal per conversation, kept separate so todo replacement cannot erase it. Unlike **AgentGoalRun**, it is not a durable run supervisor.

## Subscriptions Bounded Context

- **Subscription usage:** configured providers' live plan limits and reset windows, distinct from per-run dollar costs.

## Soundscape Bounded Context

- **SoundscapeContext:** weather, clock and mood input to an ambient arrangement served as HLS audio; arrangement and tune describe its synthesized output.

## Weather Bounded Context

- **WeatherSnapshot:** workspace-location conditions used by ambient features such as soundscape.

## Dictation Bounded Context

- **DictationControlPort / DictationPartial:** client push-to-talk controls and partial transcript updates; the server uses the meeting recorder's rolling on-device transcriber.

## Focus Mode Bounded Context

- **FocusModeState:** current deep-work session, goal and notification/compact-mode choices.

## IDE (code-server) Bounded Context

- **CodeServerSession / CodeServerPort:** server-hosted, loopback-bound code-server IDE session opening an isolated worktree, reached through authenticated `/proxy/vscode/<sessionId>/`. Not the local installed-editor catalog **IdeEditor**.

## cc_markdown (markdown & mermaid engine)

- **cc_markdown / CcMermaidView:** typed-AST Dart markdown and native-painted Mermaid subset; not a WebView/JavaScript renderer. Unsupported diagrams or malformed input fall back; parsed author styling is not applied.

## Session Review & VS Code Theme Bounded Contexts

- **session_review:** file-by-file diff of a run's worktree changes. **vscode_theme / VsCodeEditorTheme:** imported subset of an editor's colors used on code/diff surfaces.

## Presence & Real-Time Collaboration Bounded Context

- **ParticipantPresence:** ephemeral, never-persisted human/agent awareness; repo-grant filtered before fan-out. **PresenceLocus:** tagged position in a space, file, PR, ticket or plan node.
- **Follow / steer / take-over / hand-back:** follow another viewport; redirect a running agent via conversation; pause at a turn boundary to edit its worktree; send the change summary before resuming. Paused state survives restart.
- **Autonomy dial:** per-space/agent `propose-only`, `act-with-approval` or `act-freely` profile over action guardrails; risky actions still require the policy gate.

## Plan Studio Bounded Context

- **PlanGraph:** shared typed DAG shape for a single-agent **PlanDocument** (conversation-scoped) and an **OrchestrationProposal** (orchestration-scoped). Both can be edited before approval; only approved revisions execute.
- **OrchestrationRevision:** append-only authored proposal snapshot for diff and rewind. **Playbook:** versioned typed-parameter template over a stored proposal or pipeline; substitution is not an expression language.
- **PlanEstimator / ProposalDiff:** evidence-based cost/time/risk estimates with uncertainty and structural changes between revisions, respectively.

## Review Studio Bounded Context

- **Cohort / cohort key:** semantic PR-file grouping keyed by content/feature rather than line range so review progress survives a rebase. **ApiContractDiff:** classified OpenAPI/GraphQL changes against configured specs.
- **Review axis / per-axis gate:** individually budgeted correctness, security, coverage, performance, visual or API-contract check. A blocking axis unable to run holds the review verdict at `hold`, not `ship`.

## Fleet Bounded Context

- **JobSpec:** typed executable work and capability/budget requirements. **Job:** leased execution row in the server-global queue, with workspace ownership. **Worker:** paired stateless executor; no DB, approval authority or lasting credentials. One server schedules and reaps jobs; workers do not coordinate with each other.
- **Placement policy:** `pin` a worker, `prefer` a capability or `spill` to any eligible worker, with logged placement reasons.

## Evals, Replay & Regression Bounded Context

- **SessionRecording:** opt-in redacted run event stream and model/HTTP/tool cassettes with retention policy. **AgentConfigHash:** versioned canonical hash of effective prompt, tools, model and policy inputs.
- **Deterministic replay:** stubbed cassettes, no execution, testing the harness. **Live replay:** real model and sandbox, testing agent behavior. Never label one as evidence for the other.
- **EvalSuite / EvalRun / Scorecard:** fixture and graders, repeated run, and pass/cost/latency/variance results. Prefer deterministic grading; flag a model judging its own family. **GoldenSession:** blessed recording pinned per agent/playbook; live goldens are advisory without batching. **Reliability score:** evidence from replay/evals informing autonomy.

## Action Guardrails Bounded Context

- **ActionClass:** closed taxonomy of effects (file mutation, git/PR mutation, network, secret access, package/process/workspace/enclosure actions). Tools declare effect classes; unknown classes do not gain implicit permission.
- **ActionPolicyRule:** scoped `allow`, `prompt` or `deny`; resolution order is space > agent > workspace > mode preset > built-in default, then longest command prefix and most restrictive rule. **ActionDecision / PolicyResolver:** stable within a turn; an unanswerable prompt is denied and multi-class actions take the most restrictive decision.
- **Adapter honesty matrix:** records what each runtime can actually enforce at MCP, native CLI and sandbox layers; CC cannot intercept every external CLI action.
- **Agent run gateway:** loopback `/agent/` endpoint through which the action policy reaches code inside an agent's sandbox. Hard half: every GitHub push is rewritten to it, checked against `gitPush` (refs included) and forwarded on a server-held write token. Soft half: `ShellActionClassifier` maps shell command lines (harness `bash`, Claude Code's PreToolUse hook) to action classes; a hidden command evades it, a push cannot.
- **ForgeTokenScope:** `read` (contents read + pull requests, what an agent's environment holds) or `write` (push; held only by the gateway or a human-opened terminal rig). There is no "none": permission is the policy's call, not token withholding.

## Agent Peer Messaging & Delegation

- **send_to_agent:** asynchronous space message. **ask_agent:** request/reply with mandatory timeout. **delegate_task:** bounded child ticket or plan node. **consult_agent / todo_read:** consult another agent or recover a conversation's checklist. Delegation/ask chains share a cycle-detection id. Exact recipient resolution is workspace-local; depth, budget, autonomy and rate limits are server-enforced, not prompt promises. Agent-to-agent spaces do not increment the human unread badge.

## Skills Supply-Chain Security

- **Scan verdict:** `pass`, `warn` or `quarantine`; scanner failure quarantines. Mandatory inert static/capability scanning precedes writing skill bytes, and scanned, written and hash-locked bytes must match. LLM review is additive. **Trust tier:** `firstParty`, `workspace`, `verified`, `community` provenance; it never bypasses scanning or policy. See [SECURITY.md](SECURITY.md) for the boundary.

## Deterministic UX Bounded Context

- **WriteLedger / idempotency key:** one client UUIDv7 per logical mutation, reused on retries; server deduplicates before handling and returns the original result. **ActionJournal / universal undo:** reversible, compensable and irreversible action classes; irreversible side effects use preview/confirmation instead of an undo promise.
- **Unified inbox:** items that block work or explicitly need an operator, rather than all activity. **Banner rail:** at most two time-critical actionable items, displayed one at a time.

## Value Objects (Shared Kernel)

- **IdeEditor:** installed/local-editor catalog entry, not a code-server session. **AgentSkills / AgentRole:** case-insensitive skill identifiers and role used in prompts/governance/memory. Agents carry no permission flags; what they may do is action policy.
- **Mode:** `chat`, `review`, `plan`, `orchestrate`; constrains prompt, writes and tool access per conversation. Plan/review are read-only; orchestrate may propose work but execution waits for approval. **SandboxBackend / SandboxSpec / SandboxBindMount / SandboxHandle / SandboxState / SandboxEvent / SandboxViolation:** host isolation selection, launch contract, mounted path, running handle/lifecycle and event/denial record.
- **RunCost / RetryMeta / WakeReason / WakeContext:** token/cost aggregate, attempt lineage and reason/context for dispatch. **RepoIsolationBackend:** `rift` or Windows `gitWorktree` (also possible on legacy persisted rows). **MemoryPermission:** `none`, `read`, `write`. **AppLocale:** locale/display metadata.

## Ports (Abstractions)

Ports are domain contracts implemented by infrastructure; `packages/cc_domain/lib/core/domain/ports/` holds shared ports and each feature's `domain/ports/` its own. Key boundaries:

- **SandboxPort / CredentialBrokerPort / ConfirmationPort / AgentQuestionPort:** sandbox lifecycle, per-launch `ForgeTokenScope`d credentials with revocation, privileged-action approval and inline agent questions.
- **GitRepoInspectorPort / GitCommandPort / RepoIsolationPort / RepoWorkspaceProvisionerPort / WorkspaceFilesystemPort:** checkout inspection, Git execution, isolated worktree creation and per-space filesystem management. Provision failure must not mutate the source checkout.
- **RunLogStorePort / EmbeddingPort / NotificationPort / NotificationPreferencesPort / ProcessControlPort / ModeResolver:** run storage, optional vectorization, desktop notifications/preferences, process control and mode lookup.
- **AgentBackend / AgentDispatchPort / MessagingPort / TicketProviderPort / PipelineEnginePort / DispatchReviewersPort / SchemaValidatorPort / SandboxDetectorPort / DoctorPort / GitHubCliPort / ProcessDetectionPort / McpServerPort / McpTool / TicketWorkflowPort:** feature-specific seams, named by the feature that consumes them; inspect the corresponding `domain/ports/` for signatures.

## Domain Events

- **DomainEventBus:** in-process typed publish/subscribe for cross-feature reactions; each event carries `occurredAt`. Events notify after state transitions; they are not commands or a persisted queue.
- Representative triggers: `WorkspaceCreated` seeds defaults; `RepoAdded` indexes code; `AgentRunCompleted` unblocks pipeline/goal/cost consumers; `SpaceCreated` provisions worktrees; `SpaceDeleted` triggers GC; `MeetingRecordingStopped` starts summarization; `CalendarAuthExpired` prompts reconnection; `TicketAssigned` routes team work.
- Distinct PR signals matter: `PullRequestStatusChanged` is a general transition, `PrMerged` is merge-specific, `PrHeadChanged` invalidates stale review and `ExternalPrDetected` concerns non-agent PRs. Pipeline lifecycle events are terminal (`PipelineRunCompleted`, `PipelineRunFailed`, `PipelineRunCancelled`). Device revocation is observed directly from its table, not a `UserDeviceRevoked` event.

## Domain Services

- **ActivityLogger / MemoryAccessPolicy / AgentMentionParser:** audit publishing, role-scoped memory access and mention parsing in the shared kernel.
- **TicketWorkflowService:** optimistic, workspace-checked ticket lifecycle without dispatching agents. **PipelineEngine / PipelineTriggerDispatcher:** resumable DAG execution and event-triggered starts. **StrandedTicketReconciler / OrphanRunReaper:** startup repair of stranded tickets/dead runs.
- **DefaultCodeIndexer / RepoWorkspaceProvisioner / WorktreeGcListener:** indexed source updates and lifecycle of isolated repos. **BudgetEnforcementService:** hard-stop on exhausted budgets. **MeetingSummaryReconciler:** completes processing or falls back to raw transcript. Other feature services live under their respective `domain/services/` directories; see [ARCH.md](ARCH.md) for runtime constraints.

## Cross-Cutting

- **AppNotification / NotificationCategory / NotificationSound:** payload, per-category settings and bundled sound. Live notifications come from `notifications/*` RPC frames via `mapNotificationFrame`; legacy `NotificationEventMapper` is test-only, not a live server-event subscriber.

## MCP Bounded Context

- **McpTool:** schema, handler and approval metadata for one tool. **McpToolRegistry / McpToolDispatcher:** lookup/listing and mode/confirmation-gated call routing. **JsonRpcRequest / JsonRpcResponse / JsonRpcError / JsonRpcNotification:** wire message shapes.
- `cc_server` assembles a common registry in `cc_server_core`; desktop/web/external clients and the built-in harness reach it over server RPC/MCP. Registry entries are advertised through `tools/list`, not hidden behind discovery; additional external servers are bridged by `cc_mcp_client`. `cc_mcp` owns server tools; the client `mcp` feature is settings/status UI. Tool families include messaging, tickets, review, memory, code, agents, workspace, pipelines and governance. `submit_plan` produces a typed plan document; artifact tools publish versioned typed blocks, not HTML. Avoid fixed tool-count inventories.

## Remote Control Bounded Context

- **PairingPayload / RemotePairingLifecycle:** URL-fragment QR data (connection paths/fingerprint, device id, PSK, expiry) and pair/unpair ownership. The fragment is stripped after pairing, so the PWA host does not receive the PSK.
- **RemoteRpcSession:** server RPC session bound to one workspace. **RemoteToolPolicy:** default-deny phone tool allowlist for reads and a narrow set of local writes, not full agent/forge control. **RemoteRateLimiter / RemoteEventForwarder:** per-session call caps and workspace-filtered updates.
- **RemoteRelayHost / RelayClientChannel / cc_signaling_server:** server, client and stateless WebSocket relay roles. Brokered frames are end-to-end sealed; the broker cannot read application data or PSK. This is not a WebRTC data channel. See [SECURITY.md](SECURITY.md) for pairing and trust boundaries.

## Client/Server Architecture Bounded Context

- **cc_server:** headless pure-Dart owner of persistence, background jobs, MCP and RPC. **ServerConnectionMode:** desktop `local` (supervised child) or `remote`; browser always remote. **ServerConnectionConfig / ServerConnectionStore:** non-secret server choice and separate secure pairing credential.
- **CcServerProcess / CcServerEndpoint:** supervised local child and its loopback RPC address, with parent-death shutdown. **ServerBackend / ThinClientBackend:** boot-time resolved server client and local-child handle. **RemoteRpcClient / LocalRpcServer / InProcessRpcChannel:** client RPC contract, authenticated server endpoint and in-memory local/test transport.
- **RPC workspace binding:** one workspace is bound to each session; clients cannot supply another workspace id to gain access. **MediaProxyConfig:** client media fetches through the paired server, not directly from upstream hosts. No client opens a database. For server/client package layout and storage, see [ARCH.md](ARCH.md).

## Database Conventions

- **GlobalDatabase / WorkspaceDatabase:** server-wide registry/identity/newsfeed/fleet data versus one database file per workspace. **WorkspaceDatabaseManager:** resolves the workspace database per operation; repositories do not cache a workspace DAO. **CrossWorkspaceQueries:** explicit path for legitimate cross-workspace reads. **workspace_routes:** global index for pre-auth workspace resolution without scanning all workspace files.
- **Workspace isolation:** separate files provide the boundary, with `workspaceId` columns as defense in depth. Backups are directories containing a manifest, global DB and per-workspace DB snapshots made via `VACUUM INTO`; a workspace export/import is one workspace file. FTS indexes and optional vector embeddings are scoped to workspace files. See [ARCH.md](ARCH.md) for schema/indexing and recovery constraints.
