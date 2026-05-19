# Control Center Ubiquitous Language Glossary

This document defines the core domain terms used across the Control Center codebase. It serves as the single source of truth for naming conventions and domain concepts.

---

## Core Domain Entities (Shared Kernel)

Entities in `packages/cc_domain/lib/core/domain/` are shared across 3+ features.

### Agent

An AI worker with an identity, skill set, role, persona, capabilities and optional reporting hierarchy. Agents are instantiated from `AGENTS.md` files on disk and are the primary actors in the system. Each agent belongs to exactly one workspace (`workspaceId` is non-null, a hard isolation invariant).

**Key attributes:** `id`, `name`, `title`, `agentMdPath`, `workspaceId`, `reportsTo`, `skills` (AgentSkills), `persona`, `systemPrompt`, `adapterId`, `modelId`, `strictMode`, `effort` (String? — a `ReasoningEffort` wire id), `contextSize`, `capabilities` (AgentCapabilities), `role` (AgentRole), `monthlyBudgetCents`, `silenceTimeoutMinutes`, `maxConcurrentTasks`, `visibility` (AgentVisibility), `lifecycleStatus` (AgentLifecycleStatus), `budgetPolicyId`, `runtimeProfileId`, `createdAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/agent.dart`

### Workspace

A user-named, soft-deletable container that groups agents and repositories, the top-level isolation tenant. Each agent, channel, ticket and memory fact is scoped to a single workspace.

**Key attributes:** `id`, `name`, `logoPath`, `ownerUserId`, `secretExcludeGlobs`, `reviewConcurrency`, `createdAt`, `updatedAt`, `deletedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/workspace.dart`

### Repo

A Git repository registered in the system. Repos are workspace-scoped (each workspace registers its own rows; the former server-global `repos` table and its `workspace_repos` join collapsed into one table). Cross-workspace repo identity is by path (`findByPath`) — the same checkout registered in two workspaces is two rows. A repo may or may not have an associated GitHub remote.

**Key attributes:** `id`, `name`, `path`, `githubOwner`, `githubRepoName`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/repo.dart`

### GitRepoInfo

Immutable metadata about a locally-checked-out Git repository, parsed by inspecting a repo path and its remote origin URL.

**Key attributes:** `path`, `owner`, `repoName`, `branch`

**Location:** `packages/cc_domain/lib/core/domain/entities/git_repo_info.dart`

### IsolatedRepo

A workspace-scoped copy-on-write worktree of a registered repo, provisioned per channel and checked out on its own branch. Backed by the bundled `rift` FFI (with a plain `git worktree` fallback) so agents never mutate the source checkout.

**Key attributes:** `id`, `workspaceId`, `channelId`, `repoId`, `path`, `branch`, `backend` (RepoIsolationBackend), `sourcePath`, `ticketId`, `createdAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/isolated_repo.dart`

### AgentRunLog

An immutable record of a single agent execution. Tracks token cost, liveness classification, error family, retry lineage and process metadata; the pipeline/output-contract fields (`pipelineRunId`, `pipelineStepRunId`, `expectedOutputSchema`, `outputContractMode`, `outputJson`, `outputRejections`) carry what used to live on the ticket. Each run is tied to an agent and workspace and optionally to a conversation, channel, or ticket.

**Key attributes:** `id`, `agentId`, `workspaceId`, `conversationId`, `ticketId`, `channelId`, `startedAt`, `completedAt`, `status` (RunStatus), `summary`, `adapter`, `modelId`, `pid`, `logPath`, `cost` (RunCost), `liveness` (RunLiveness), `errorFamily` (RunErrorFamily), `lastOutputAt`, `continuationSummary`, `contextSnapshotJson`, `pipelineRunId`, `pipelineStepRunId`, `errorCode`, `expectedOutputSchema`, `outputContractMode` (OutputContractMode), `outputJson`, `outputRejections`, `retry` (RetryMeta), `role` (AgentRunRole — parent/sub), `childCostCents`, `parentRunId`, `spawnToolCallId`

**Location:** `packages/cc_domain/lib/core/domain/entities/agent_run_log.dart`

### RunTranscript

The durable per-run activity timeline: ordered `TranscriptSegment`s (reasoning, tool calls, answer text) for one agent run. The only place a subagent run's tool calls and reasoning survive — child events fold here, not into the parent's channel message. Kept out of `agent_run_logs` so watch queries don't re-encode megabytes per emission; live runs stream from an in-memory registry instead.

**Key attributes:** `runId`, `workspaceId`, `segments` (List&lt;TranscriptSegment&gt;), `transcriptChars`, `outcome` (TurnOutcome?), `complete`

**Location:** `packages/cc_domain/lib/core/domain/entities/run_transcript.dart`, table `packages/cc_persistence/lib/database/tables/run_transcripts_table.dart`

### ReviewChannelAssociation

A join entity that decouples PR review from messaging. A review channel is a regular channel. The review context is established by this association record, not by the channel type. This separation lets channels own messages independently of review lifecycle.

**Key attributes:** `id`, `channelId`, `workspaceId`, `prNodeId`, `prNumber`, `repoFullName`, `status` (ReviewChannelStatus), `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/review_channel_association.dart`

---

## Messaging Bounded Context

### Channel

A messaging container scoped to a workspace, with one or more participants. There is no separate DM/group distinction — a one-on-one chat and a multi-participant room are both just channels, differing only in participant count. Each channel carries a `Mode` that gates which tools and sandbox policies apply and a provisioning status. `workspaceId` is nullable: some system/legacy channels carry no workspace.

**Key attributes:** `id`, `name`, `workspaceId` (String?), `mode` (Mode), `provisioningStatus` (ChannelProvisioningStatus), `provisioningStep` (ChannelProvisioningStep?), `origin` (ChannelOrigin), `pipelineRunId`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/messaging/domain/entities/channel.dart`

### Conversation

A message stream inside a channel. Every channel has exactly one `main` conversation (its id == the channel id) — the primary, notification-bearing stream; users open extra `parenthesis` conversations for parallel work against the same worktree, each with its own message history and agent sessions, muted for badges/notifications.

**Key attributes:** `id` (the main conversation's id == channel id), `workspaceId` (String?), `channelId`, `title`, `kind` (ConversationKind), `status` (ConversationStatus), `createdByPrincipalId`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/messaging/domain/entities/conversation.dart`, table `packages/cc_persistence/lib/database/tables/conversations.dart`

### ChannelMessage

A single message within a channel, always belonging to one `Conversation`. Messages carry metadata (mentions, plan status, stream completion flags), support compaction and revert and are typed by `ChannelMessageType` to control rendering.

**Key attributes:** `id`, `channelId`, `conversationId`, `senderId`, `senderType` (ChannelSenderType), `content`, `messageType` (ChannelMessageType), `metadata`, `compacted`, `reverted`, `revertedAt`, `createdAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/channel_message.dart` (shared kernel, consumed by messaging, pr_review, pipelines, mcp)

### ChannelParticipant

A membership record linking a principal — an agent or a human user — to a channel with a role. Each member is identified by `principalId` plus `participantType`; humans are first-class rows (no sentinel), each keeping their own read cursor.

**Key attributes:** `id`, `channelId`, `principalId` (agent or user id), `participantType` (PrincipalType), `role`, `joinedAt`, `lastReadAt`

**Location:** `packages/cc_domain/lib/features/messaging/domain/entities/channel_participant.dart`

### ChannelRepo

A many-to-many join declaring which repos a channel provisions worktrees for. A channel with no rows falls back to every workspace repo (back-compat); PR-workbench channels ignore the table (always the PR's repo). Table-only — no domain entity.

**Location:** `packages/cc_persistence/lib/database/tables/channel_repos.dart`, DAO `packages/cc_persistence/lib/database/daos/channel_repo_dao.dart`

### ChannelMessageType

Rendering type enum for messages: `text`, `system`, `ticketCard`, `agentTurn`, `reviewNode`, `hireProposal`, `reviewSummary`, `plan`, `userQuestion`, `orchestrationProposal`, `artifact`, `compaction`. Controls how the UI renders each message. (`agentTurn` — a complete agent turn persisted under `metadata['segments']` — replaced the old `thinking` type.)

### ChannelSenderType

Enum identifying who sent a message: `user` (human) or `agent` (AI).

### MessageMention

A resolved @mention stored in a message's metadata. Contains the mentioned principal's id (`agentId` field), the raw mention text, how it was resolved and a `principalType` — mentions are no longer agent-only.

**Location:** `packages/cc_domain/lib/core/domain/entities/channel_message.dart`

### MessageReaction

A lightweight emoji reaction on a channel message. The reactor is a principal — human OR agent, co-equal — unique per `(workspaceId, messageId, principalId, emoji)` and rendered from a fixed palette (`kReactionPalette`: 👍 👎 🎉 ❤️ 👀 ✅). Distinct from pr_review's `ReactionGroup`, which mirrors GitHub PR reactions.

**Location:** table `packages/cc_persistence/lib/database/tables/message_reactions_table.dart`; client DTO + palette `lib/features/messaging/providers/channel_reactions_provider.dart`

### ThinkingEvent

One subtype of the `AgentProcessEvent` sealed family carrying thinking (reasoning) content. Grouped into UI rows that pair tool calls with their results. (`MentionContext` and `AgentProcessEvent` itself live in the Dispatch context, see below.)

**Location:** `packages/cc_domain/lib/features/dispatch/domain/entities/agent_process_event.dart`

---

## Dispatch Bounded Context

Extracted from messaging so pipelines, ticketing and sandboxing can depend on agent dispatch without importing the chat feature. Also absorbed the former `agent_modes` prompt library. `MessagingService.sendAndDispatch` (in messaging) is the chat-side caller that drives this feature.

### AgentDispatchService

Launches an agent run: provisions isolated repos, builds the prompt, creates a run log and returns the live process-event stream. Owns run finalization (`completeRun` / `failRun` / `stopRun`).

**Location:** `packages/cc_infra/lib/src/dispatch/agent_dispatch_service.dart`

### AgentProcessEvent

An event emitted by an agent CLI process (thinking, text, tool call/result, error, sandbox violation, debug, done) with a wall-clock timestamp. The unit of the live agent output stream.

**Key attributes:** `type` (AgentProcessEventType), `content`, `metadata`, `timestamp`

**Location:** `packages/cc_domain/lib/features/dispatch/domain/entities/agent_process_event.dart`

### DispatchAgentUseCase / BuildAgentPromptUseCase

`DispatchAgentUseCase` resolves the effective prompt, CLI name and mode for a run. `BuildAgentPromptUseCase` assembles the agent's prompt from the mode prompts plus channel context (`BuildConversationContextUseCase`) and memory context (`BuildMemoryContextUseCase`).

**Location:** `packages/cc_domain/lib/features/dispatch/domain/usecases/`

### PromptBuilder / mode prompts

The channel-mode prompt library (chat / plan / review system-prompt blocks, role personas, protocol docs), formerly the `agent_modes` feature, folded into dispatch.

**Location:** `packages/cc_domain/lib/features/dispatch/domain/prompts/`

### MentionContext / MentionRosterEntry

`MentionContext` describes who summoned an agent plus the full channel roster available for mention resolution. `MentionRosterEntry` is one roster row (agent ID, name, whether top-level).

**Location:** `packages/cc_domain/lib/features/dispatch/domain/value_objects/mention_context.dart`

### AgentGoalRun

A durable supervised objective set via `/goal` or `/loop` (`AgentGoalKind` goal|loop): the supervisor re-dispatches the agent as bounded runs until the agent declares completion, a human stops it, or a budget wall hits. Survives server restarts via a startup reconciler; at most one active goal per agent. Distinct from the governance `Goal` (an org target with progress tracking) and from `ConversationGoal` (a conversation's single working goal).

**Key attributes:** `id`, `workspaceId`, `channelId`, `conversationId`, `agentId`, `userText`, `kind` (AgentGoalKind), `status` (AgentGoalStatus), budget walls (`costCapCents`, `deadlineAt`, `maxRuns`), `costCents`, `runCount`, `activeRunId`, `consecutiveFailures`, `requestedByUserId`, `summary`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/dispatch/domain/entities/agent_goal_run.dart`, table `packages/cc_persistence/lib/database/tables/agent_goal_runs_table.dart`, supervisor `packages/cc_infra/lib/src/dispatch/goal_supervisor.dart`

---

## PR Review Bounded Context

### PullRequest

A GitHub pull request with state, author, diff metrics, requested reviewers/assignees, reactions and rolled-up checks status.

**Key attributes:** `id` (int — the GitHub id, not a UUID), `number`, `title`, `body`, `bodyHtml`, `state` (PrState), `isDraft`, `author` (PrUser), `repoFullName`, `htmlUrl`, `nodeId`, `headSha`, `baseRef`, `baseSha`, `headRef`, `requestedReviewers`, `assignees`, `mergedAt`, `reviewedByMe`, `reactions`, `changedFiles`, `additions`, `deletions`, `commitsCount`, `commentsCount`, `checksStatus` (PrChecksStatus), `mergeableState` (PrMergeableState), `reviewDecision` (PrReviewDecision), `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pull_request.dart`

### EnrichedPullRequest

Sealed supertype pairing a `PullRequest` with its source `Repo` and categorizing it into `PriorityReview`, `StalePr`, or `NormalPr`.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/enriched_pull_request.dart`

### RepoPullRequests

Bundles a `Repo` with the list of pull requests belonging to it.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/enriched_pull_request.dart`

### PrFile

A changed file in a PR with status, line counts, patch text and the viewer's viewed state.

**Key attributes:** `filename`, `status` (PrFileStatus), `additions`, `deletions`, `patch`, `previousFilename`, `viewerViewedState` (PrFileViewedState)

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pr_file.dart`

### FileChange

A lightweight file-change summary (path + addition/deletion counts + new/deleted flags), used where the full patch isn't needed.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/file_change.dart`

### PrCommit

A commit within a pull request: sha, message, author, date.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pr_commit.dart`

### CheckRun

A CI check run on a PR's head commit with status, conclusion, output and parent workflow info.

**Key attributes:** `name`, `status` (CheckRunStatus), `conclusion` (CheckRunConclusion), `htmlUrl`, `completedAt`, `output`, `workflowName`, `checkSuiteId`

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/check_run.dart`

### IssueComment

A top-level (non-inline) PR/issue comment with author and reactions.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/issue_comment.dart`

### PrCodeReviewComment

An inline code review comment anchored to a file path/line/diff hunk, with threading via `inReplyToId` and reactions.

**Key attributes:** `id`, `body`, `user` (PrUser), `path`, `position`, `side`, `inReplyToId`, `startLine`, `line`, `diffHunk`, `reactions`, `createdAt`

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pr_code_review_comment.dart`

### PrInlineThread / PrInlineEntry

`PrInlineThread` is a locally-authored inline comment or suggestion thread anchored to a file line/char range, tracking resolved state and GitHub sync state. `PrInlineEntry` is a single comment within that thread.

**Key attributes (thread):** `id`, `filePath`, `line`, `lineEnd`, `side`, `kind` (PrInlineThreadKind), `originalCode`, `suggestedCode`, `entries`, `resolved`, `syncState` (PrInlineSyncState), `serverId`

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pr_inline_thread.dart`

### PrReviewSubmission

A submitted PR review verdict (`approved` / `changesRequested` / `commented` / `pending`) with author and body.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pr_review_submission.dart`

### PrUser

A minimal GitHub user reference: `login` + `avatarUrl`.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pr_user.dart`

### ReactionGroup

A grouped emoji reaction: content, emoji, count, whether the user reacted and reacting usernames.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/reaction_group.dart`

### GifResult

A GIF search result (e.g. for message reactions) with full + preview URLs and dimensions.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/gif_result.dart`

### PrGeneration

A workspace-scoped generated PR draft (not yet published to GitHub) with a sealed lifecycle status (`Draft` / `Published` / `Created`). Represents work-in-progress that agents prepare before publishing.

**Location:** `packages/cc_domain/lib/features/pr_review/domain/entities/pr_generation.dart`

### Review value objects

- **ReviewNodePayload**, typed view over a `reviewNode` message's metadata (finding kind, P0-P3 priority, lifecycle status, file/line anchor, confidence, confirmations). Rejects malformed payloads. `packages/cc_domain/lib/features/pr_review/domain/value_objects/review_node_payload.dart`
- **ReviewVerdict**, per-PR ship/hold/block aggregate (overall call, confidence, explanation, per-priority counts) computed from review-node findings. `packages/cc_domain/lib/features/pr_review/domain/value_objects/review_verdict.dart`
- **ReviewDisagreement**, a detected disagreement between two reviewer agents on the same file/line finding, plus the detector that finds them. `packages/cc_domain/lib/features/pr_review/domain/value_objects/review_disagreement.dart`
- **DiffOverflowMode**, enum (`wrap`, `scroll`) controlling how the diff viewer renders over-wide lines. `packages/cc_domain/lib/features/pr_review/domain/value_objects/diff_overflow_mode.dart`

---

## Ticketing Bounded Context

Vendor-agnostic work tracking. This feature absorbed the former `tasks` feature. `Ticket` is now the single unit-of-work aggregate.

### Ticket

The unit-of-work aggregate: a mirror of an optional remote provider issue plus a Control-Center orchestration overlay. Carries assignment (agent or team, typed by principal), delegation lineage and collaborators. Supports parent/child hierarchy. Pipeline coupling and the output contract live on `AgentRunLog`, not on the ticket.

**Key attributes:** `id`, `workspaceId`, `provider` (TicketProvider), `externalKey`, `url`, `title`, `description`, `priority` (TicketPriority), `labels`, `status` (TicketStatus), `rawStatus`, `parentTicketId`, `projectId`, `assignedAgentId`, `assigneeType` (PrincipalType), `createdByType` (PrincipalType?), `createdById`, `assignedTeamId`, `delegatedByAgentId`, `delegationDepth`, `delegationRootTicketId`, `channelId`, `errorMessage`, `linkedPrIds`, `metadata`, `originKind` (TicketOriginKind), `version`, `collaborators`, lifecycle timestamps (`createdAt`, `startedAt`, `blockedAt`, `cancelledAt`, `completedAt`, `finishedAt`, `updatedAt`)

**Location:** `packages/cc_domain/lib/features/ticketing/domain/entities/ticket.dart`

### TicketCollaborator

A Control-Center participant — an agent or a human user — invited to collaborate on a ticket with a role. Mirrors `ChannelParticipant`: `principalId` is a real agent or user id per `collaboratorType`, with no sentinel.

**Key attributes:** `id`, `ticketId`, `principalId` (agent or user id), `collaboratorType` (PrincipalType), `role` (TicketCollaboratorRole), `joinedAt`

**Location:** `packages/cc_domain/lib/features/ticketing/domain/entities/ticket_collaborator.dart`

### TicketLink

A directional dependency edge between two tickets (`blocks` / `relatesTo` / `duplicateOf`), with derived per-subject relation kinds.

**Key attributes:** `id`, `workspaceId`, `sourceTicketId`, `targetTicketId`, `type` (TicketLinkType), `createdAt`

**Location:** `packages/cc_domain/lib/features/ticketing/domain/entities/ticket_link.dart`

### Project

A workspace-scoped grouping of tickets toward a shared goal. Control-Center-only, never synced to a remote provider.

**Key attributes:** `id`, `workspaceId`, `name`, `description`, `color` (ProjectColor), `status` (ProjectStatus), `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/ticketing/domain/entities/project.dart`

### Ticketing enums

`TicketStatus` (`backlog`, `open`, `inProgress`, `blocked`, `inReview`, `done`, `failed`, `cancelled`), `TicketPriority`, `TicketProvider` (local, linear; jira/clickup stubbed), `TicketLinkType`, `TicketOriginKind`, `TicketCollaboratorRole`, `ProjectStatus` (active, completed, archived), `ProjectColor`.

---

## Teams Bounded Context

Named, persistent agent teams within a workspace: a roster with a leader plus an operating protocol, so a ticket can be assigned to a team (`Ticket.assignedTeamId`) and an orchestration can materialize one (`Orchestration.teamId`). Team activity is logged per workspace.

### Team / TeamMember / TeamActivity

`Team` is the aggregate (name, description, `leaderId`, instructions); `TeamMember` binds an agent to a team; `TeamActivity` is the append-only log of team-level events. Domain services: `TeamRoutingService` (consumes `TicketAssigned` and routes work to the team), `TeamRoster`, `TeamOperatingProtocol`; the `TeamLeaderDispatchPort` decouples team dispatch from the concrete dispatcher.

**Location:** `packages/cc_domain/lib/features/teams/domain/` (entities `team.dart`, `team_member.dart`, `team_activity.dart`; services; `ports/team_leader_dispatch_port.dart`), tables `packages/cc_persistence/lib/database/tables/teams_table.dart`, `team_activity_log_table.dart`

---

## Pipeline Bounded Context

DAG-based workflow orchestration. Templates live in the DB; step bodies are executable closures resolved from a registry at runtime.

### PipelineDefinition

A workspace-scoped declarative DAG of steps with declared inputs and versioning.

**Key attributes:** `templateId`, `workspaceId`, `name`, `description`, `steps` (List&lt;PipelineStepDefinition&gt;), `inputs` (List&lt;PipelineInput&gt;), `isBuiltIn`, `isEnabled`, `version`

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_definition.dart`

### PipelineStepDefinition

A node in the pipeline graph with a kind, body key, trigger edges, join wait-list, per-node config and canvas coordinates.

**Key attributes:** `id`, `kind` (StepKind), `bodyKey`, `triggers` (List&lt;StepTrigger&gt;), `waitForStepIds`, `config` (PipelineNodeConfig), `x`, `y`

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_step_definition.dart`

### PipelineNodeConfig

Per-node configuration carried inside a step definition: prompt/script/agent/team, input/output keys, output schema, reducer, retry policy, continue-on-fail, timeout, dispatch mode, extras.

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_node_config.dart`

### StepRetryPolicy

Retry behaviour for a failing node body, `maxAttempts`, `backoff` (linear/exponential), `initialDelayMs`, computing per-attempt backoff delays.

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_node_config.dart`

### PipelineInput

A single declared input field of a pipeline definition, rendered as a form control on manual runs.

**Key attributes:** `key`, `label`, `type` (PipelineInputType), `required`, `defaultValue`, `helpText`, `placeholder`, `options`

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_input.dart`

### PipelineRun

A single persisted, resumable execution of a pipeline template with a mutable state bag, trigger info, cost/token totals and parent-run linkage (for sub-pipelines).

**Key attributes:** `id`, `templateId`, `workspaceId`, `status` (PipelineRunStatus), `state` (Map), `triggerEventType`, `triggerPayload`, `dedupKey`, `startedAt`, `finishedAt`, `activeMs`, `lastResumedAt`, `errorMessage`, `errorStackTrace`, `parentPipelineRunId`, `parentStepId`, `templateVersion`, `totalCostCents`, `totalTokens`, `dryRun`

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_run.dart`

### PipelineStepRun

A single persisted, resumable step execution within a run, with branch index, attempt count and I/O JSON.

**Key attributes:** `id`, `pipelineRunId`, `stepId`, `status` (PipelineStepStatus), `inputJson`, `outputJson`, `errorMessage`, `branchIndex`, `attemptCount`, `startedAt`, `finishedAt`

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_step_run.dart`

### PipelineTrigger

A workspace-scoped, default-off declarative trigger that auto-starts a pipeline on a domain event, schedule (cron), or manual run, with a payload match filter.

**Key attributes:** `id`, `eventType`, `templateId`, `workspaceId`, `enabled`, `cronExpression`, `match` (Map), `lastFiredAt`, `createdAt`

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/pipeline_trigger.dart`

### StepResult

What a step body returns to the engine: `ok` / route / suspend-until-event / suspend-until-tasks / terminal / failed, plus state mutations.

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/step_result.dart`

### StepTrigger

Describes when a step fires relative to its source steps, with an optional `routeKey` for conditional (router) edges.

**Location:** `packages/cc_domain/lib/features/pipelines/domain/entities/step_trigger.dart`

### Pipeline enums

`StepKind` (`trigger`, `listen`, `join`, `router`, `forEach`, `terminal`), `PipelineRunStatus`, `PipelineStepStatus`, `PipelineInputType`. The step body keys (`promptAgent`, `bashScript`, `dispatchReviewers`, …) are validated per step kind.

---

## Orchestration Bounded Context

The `orchestration` feature turns one goal into a whole-team plan the user approves once, then a deterministically generated pipeline. An orchestrator (usually the CEO agent) proposes a typed plan; the user approves it; a pure function materializes it into a [pipeline](#pipeline-bounded-context), hires, a team, a project and child [tickets](#ticketing-bounded-context). "The agent plans; a deterministic function executes."

### Orchestration

The aggregate root: one "big ask" the system proposed a whole-team plan for. Always workspace-scoped and opened against a parent ticket with one shared discussion channel. Carries a monotonic `revision` and the `approvedRevision` the user signed off on, so a mid-flight replan can't silently change what was approved.

**Key attributes:** `id`, `workspaceId`, `proposal`, `parentTicketId`, `channelId`, `orchestratorAgentId`, `status`, `revision`, `approvedRevision`, `approvedNodeKeys` (List&lt;String&gt;? — the partial/branched-approval surface), `pipelineTemplateId`, `pipelineRunId`, `teamId`, `projectId`, `estimatedCostCents`, `maxCostCents`, `hiredAgentIds`, `errorMessage`, `createdAt`, `updatedAt`, `completedAt`

**Location:** `packages/cc_domain/lib/features/orchestration/domain/entities/orchestration.dart`

### OrchestrationProposal

The structured plan an orchestrator returns for one upfront approval: `goal`, `roles`, `subTickets` (the work DAG), optional `research` and `discussion` phases, a `synthesis` step that produces the deliverable and a `budget`. Typed and serializable so it can be validated before anything runs. Value identity is its canonical JSON form.

**Location:** `packages/cc_domain/lib/features/orchestration/domain/entities/orchestration_proposal.dart`

### Orchestration status & proposal value objects

- `OrchestrationStatus`, `proposed → approved → executing → synthesizing → completed` (plus `failed`, `cancelled`).
- `ProposedRole`, a role the plan needs, filled by an existing agent or a `ProposedHire` created on approval.
- `ProposedHire`, spec for an agent to hire when materializing.
- `ProposedSubTicket`, a sub-ticket in the work DAG.
- `ResearchSpec` / `DiscussionSpec` / `SynthesisSpec`, optional research phase, bounded discussion round and final deliverable step.
- `BudgetSpec`, hard spending ceiling for the whole orchestration.

**Location:** `packages/cc_domain/lib/features/orchestration/domain/entities/`

### OrchestrationMaterializer

A **pure function** (no LLM, no I/O) that converts an approved `Orchestration` into a `PipelineDefinition` given a resolved role→agent map. Given the same proposal and roles it always produces the same DAG, so the generated pipeline inherits the engine's suspend/resume, crash recovery, cost rollup and run-detail UI for free.

**Location:** `packages/cc_domain/lib/features/orchestration/domain/services/orchestration_materializer.dart`

### OrchestrationProposalValidator / ApproveOrchestrationUseCase / CancelOrchestrationUseCase / OrchestrationRunListener

The validator deterministically checks a proposal (well-formed roles, declared output schemas). The approve use case materializes an approved proposal (hires, team, project, pipeline template + run). The cancel use case tears down in-flight work. The run listener is a kept-alive listener that maps the generated pipeline's terminal state back onto the orchestration and its parent ticket.

**Location:** `packages/cc_domain/lib/features/orchestration/domain/services/`, `packages/cc_domain/lib/features/orchestration/domain/usecases/`

---

## Code Graph Bounded Context

Native code indexing (tree-sitter) into a symbol/edge graph, keyed by `(workspaceId, repoId)` because a repo can be checked out on different branches in different workspaces. Powers `search_code` and the code-relationship MCP tools.

### CodeSymbol

A code symbol (function, class, method, field, …) extracted from source, content-addressed and workspace+repo scoped.

**Key attributes:** `id`, `workspaceId`, `repoId`, `kind` (CodeSymbolKind), `name`, `qualifiedName`, `filePath`, `language`, `startLine`, `endLine`, `signature`, `docstring`, `parentName`

**Location:** `packages/cc_domain/lib/features/code_graph/domain/entities/code_symbol.dart`

### CodeEdge

A directed relationship between code symbols (call/import/extends/…), workspace+repo scoped, with an optional resolved target.

**Key attributes:** `id`, `workspaceId`, `repoId`, `sourceSymbolId`, `sourceFilePath`, `kind` (CodeEdgeKind), `targetSymbolId`, `targetName`, `metadata`

**Location:** `packages/cc_domain/lib/features/code_graph/domain/entities/code_edge.dart`

### CodeSubgraph

The result of an impact-radius BFS traversal: the root, reachable symbols, edges among them and each symbol's depth.

**Key attributes:** `root` (CodeSymbol?), `nodes`, `edges`, `depthById`

**Location:** `packages/cc_domain/lib/features/code_graph/domain/entities/code_subgraph.dart`

### CodeSymbolKind / CodeEdgeKind

Enums of symbol kinds (function, method, class, field, enum, constructor, getter, setter, typedef, extension, mixin, variable) and edge kinds (calls, imports, extends, implements, mixesIn, references). Persisted in `code_symbols.kind` / `code_edges.kind`.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/code_symbol_kind.dart`, `packages/cc_domain/lib/core/domain/value_objects/code_edge_kind.dart`

### CodeIndexCheckpoint

A repo-state fingerprint of the last successful index run, one row per `(workspaceId, repoId, checkoutId)` partition — the indexer's boot-time short-circuit (worktree partitions also compare base generation). The fingerprint comes from `RepoStateProbe` (git HEAD + porcelain status + an mtime/size fold over dirty paths, capped at 5000 entries, living in `cc_natives`); the bundled `cc_watcher` native crate (Rust over `notify`) arms O(1) invalidation. Table-only — no domain entity.

**Location:** `packages/cc_persistence/lib/database/tables/code_index_checkpoints.dart`, probe `packages/cc_natives/lib/src/code_index/repo_state_probe.dart`

---

## Memory Subdomain

### MemoryFact

A semantic memory unit scoped to a workspace. Facts carry content, topic, domain, confidence, provenance, optional embeddings for vector search and FTS integration. Facts can be superseded by newer facts.

**Key attributes:** `id`, `workspaceId`, `domain`, `topic`, `content`, `sourceObservationIds`, `confidence`, `supersededBy`, `authoredByAgentId`, `authoredByRole` (AgentRole), `memoryType` (MemoryType), `veracity` (MemoryVeracity), `validUntil`, `recallCount`, `lastRecalledAt`, `temporalTags`, `mentionCount`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/memory_fact.dart`

### MemoryPolicy

A normative rule derived from facts, optionally gated to a required role, that can be active or inactive. Scoped to workspace + domain.

**Key attributes:** `id`, `workspaceId`, `domain`, `rule`, `sourceFactIds`, `requiredRole` (AgentRole), `active`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/memory_policy.dart`

### MemoryDomain

A workspace-scoped named domain that groups facts and policies (e.g. "security", "conventions", "api-design"), recording who created it.

**Key attributes:** `id`, `workspaceId`, `name`, `label`, `description`, `createdAt`, `createdByRole`

**Location:** `packages/cc_domain/lib/features/memory/domain/entities/memory_domain.dart`

### AgentWorkingMemory

A per-agent free-text working memory scratchpad scoped to a workspace. Holds transient state that persists across runs.

**Key attributes:** `id`, `workspaceId`, `agentId`, `content`, `updatedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/agent_working_memory.dart`

### MemoryAccessGrant

Grants a given agent role a permission level (`MemoryPermission`) over a named memory domain within a workspace.

**Key attributes:** `workspaceId`, `agentRole` (AgentRole), `memoryDomain`, `permission` (MemoryPermission)

**Location:** `packages/cc_domain/lib/core/domain/entities/memory_access_grant.dart`

---

## Newsfeed Bounded Context

A server-wide pillar: the newsfeed tables (`rss_feeds`, `rss_articles`) live in `global.db`, not in any per-workspace file and its RPC ops are `workspaceScoped: false`.

### RssFeed

A registered RSS or Atom feed with fetch state, custom user-agent and last-error tracking.

**Key attributes:** `id`, `name`, `url`, `description`, `iconUrl`, `userAgent`, `enabled`, `lastFetchedAt`, `lastError`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/newsfeed/domain/entities/rss_feed.dart`

### RssArticle

A single article from a feed with read/saved state and an effective publish timestamp.

**Key attributes:** `id`, `feedId`, `guid`, `title`, `link`, `summary`, `imageUrl`, `author`, `publishedAt`, `saved`, `read`, `createdAt`

**Location:** `packages/cc_domain/lib/features/newsfeed/domain/entities/rss_article.dart`

---

## Calendar Bounded Context

Google Calendar integration. Each workspace connects its own Google account(s); the app syncs upcoming events into the local store, renders month/week/day/agenda views, fires "meeting starting soon" alerts, supports RSVP to invitations and can start a local meeting recording seeded from an event and link it back. Beyond the user's own attendance response (RSVP), the feature never creates, edits, or deletes calendar entries. Its other writes are only to the local SQLite store and the platform keychain.

### CalendarEvent

A synced Google Calendar entry scoped to a workspace + account. Distinct from a `Meeting`: an event is a scheduled commitment, a `Meeting` is a recorded session. The `myResponseStatus` getter extracts the signed-in user's RSVP from the attendees; `isUnansweredInvitation` flags an event the user hasn't responded to.

**Key attributes:** `id` (local UUID), `workspaceId`, `accountId`, `externalEventId` (provider id), `calendarId`, `title`, `description`, `location`, `startTime`, `endTime`, `isAllDay`, `meetingUrl`, `attendees` (List&lt;CalendarAttendee&gt;), `status` (CalendarEventStatus), `recurringEventId`, `alertedAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/calendar/domain/entities/calendar_event.dart`

### CalendarAttendee

An attendee on a `CalendarEvent`: email, display name, RSVP response status (`needsAction`/`accepted`/`declined`/`tentative`) and `self`/`organizer` flags.

**Location:** `packages/cc_domain/lib/features/calendar/domain/entities/calendar_event.dart`

### CalendarAccount

A connected external calendar account, per workspace + email (id = `google:<workspaceId>:<email>`). The `needsReauth` getter is true when `authExpiredAt` is set (the OAuth refresh token died); it drives the in-app reconnect banner and is cleared on a successful sync or reconnect. OAuth tokens are **not** stored here. They live in the platform keychain.

**Key attributes:** `id`, `workspaceId`, `providerId` (always `'google'`), `accountEmail`, `displayName`, `lastSyncedAt`, `authExpiredAt`

**Location:** `packages/cc_domain/lib/features/calendar/domain/entities/calendar_event.dart`

### CalendarEventStatus / CalendarViewMode

`CalendarEventStatus` is the event lifecycle enum (`confirmed`, `tentative`, `cancelled`). `CalendarViewMode` is the UI layout enum (`month`, `week`, `day`, `agenda`), persisted in preferences.

**Location:** `packages/cc_domain/lib/features/calendar/domain/entities/calendar_event.dart`, `lib/features/calendar/presentation/calendar_view_mode.dart`

### MeetingCalendarLink

A join row linking one recorded `Meeting` to one `CalendarEvent` (unique on `meetingId`), produced by the record-and-link flow. Kept separate so neither entity depends on the other; workspace-scoped.

**Location:** `packages/cc_persistence/lib/database/tables/meeting_calendar_links.dart`

### GoogleOAuthService / GoogleCredentialsRepository / GoogleOAuthRedirectChannel

`GoogleOAuthService` runs the OAuth 2.0 **PKCE** auth-code flow (public iOS-type client, no client secret) and token refresh. `GoogleCredentialsRepository` stores per-account tokens in the platform keychain, every key suffixed with `__<accountId>` so one workspace's tokens are structurally unreadable from another. `GoogleOAuthRedirectChannel` is a long-lived bus that carries the OS deep-link redirect (reversed-client-id custom scheme) back to the in-flight `authenticate()` call.

**Location:** `lib/features/calendar/data/services/google_oauth_service.dart`, `lib/features/calendar/data/repositories/google_credentials_repository.dart`, `lib/features/calendar/data/services/google_oauth_redirect_channel.dart`

---

## Meetings Bounded Context

Local, Granola-style meeting notes. Records the microphone ("me") and system-output ("them") channels concurrently, transcribes both live with on-device Whisper, diarizes the remote channel into individual speakers and runs a deterministic summarization pipeline that emits structured notes, action items and decisions. Everything is workspace-scoped and stays on the machine.

### Meeting

The root recording artifact: a recorded/transcribed session with a status lifecycle and AI-augmented output. A `Meeting` may optionally link to a `CalendarEvent` (see `MeetingCalendarLink`).

**Key attributes:** `id`, `workspaceId`, `title`, `status` (`recording`/`processing`/`done`/`failed`), `mode` (`remote`/`inPerson`), `sourceApp`, `userNotes`, `enhancedNotes`, `summary`, `summaryInstructions`, `audioPath`, `titleIsCustom`, `startedAt`, `endedAt`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/meetings/domain/entities/meeting.dart`

### MeetingSegment

One transcribed window of audio, speaker-tagged (`me`/`them`) with text and millisecond offsets. A diarization label (e.g. "Person 1") is added post-recording.

**Key attributes:** `id`, `meetingId`, `workspaceId`, `speaker`, `speakerLabel`, `text`, `startMs`, `endMs`

**Location:** `packages/cc_domain/lib/features/meetings/domain/entities/meeting_segment.dart`

### MeetingSpeakerLabel

A diarized speaker identity, one per `(meeting, channel, label)` tuple. Carries the auto-assigned label ("Person 1") and an optional user-supplied `displayName`.

**Location:** `packages/cc_domain/lib/features/meetings/domain/entities/meeting_speaker_label.dart`

### MeetingActionItem / MeetingDecision

`MeetingActionItem` is an extracted to-do (content, owner, `done` flag, optional `ticketId` link, sort order). `MeetingDecision` is an extracted decision (content, sort order). Both are written as discrete rows by the summarization pipeline, never parsed from markdown.

**Location:** `packages/cc_domain/lib/features/meetings/domain/entities/meeting_action_item.dart`, `packages/cc_domain/lib/features/meetings/domain/entities/meeting_decision.dart`

### MeetingOutcome

A domain service that parses the summarization agent's output (Map/JSON, fenced markdown, or plain text) into structured `summary` / `enhancedNotes` / `actionItems` / `decisions`. Its `isStructured` flag gates row persistence: structured output writes rows; degraded plain-text output skips them (with a raw-transcript fallback).

**Location:** `packages/cc_domain/lib/features/meetings/domain/services/meeting_outcome.dart`

### formatMeetingTranscript

A pure function that renders segments into `[mm:ss] SPEAKER: text` lines, respecting diarization labels and user display names. Shared by the recorder, the diarization step and the reconciler.

**Location:** `packages/cc_domain/lib/features/meetings/domain/services/meeting_transcript_formatter.dart`

### VoiceProfile

A reusable speaker voice model used by meeting diarization to recognize a known speaker across recordings. Workspace-scoped and matched against the diarization cluster embeddings (`VoiceProfileMatching`). Backed by a settings UI that downloads/manages on-device voice models.

**Key attributes:** `id`, `workspaceId`, `name`, `modelPath`, `embedding`, `createdAt`

**Location:** `packages/cc_domain/lib/features/meetings/domain/entities/voice_profile.dart` (entity), `packages/cc_domain/lib/features/meetings/domain/services/voice_profile_matching.dart` (matcher), `packages/cc_domain/lib/features/meetings/domain/value_objects/voice_model_paths.dart` (model paths)

---

## Settings Bounded Context

### Adapter

A built-in inference adapter definition (e.g. Pi, Claude Code) with the CLI binary name used for detection.

**Key attributes:** `id`, `name`, `description`, `cliName`

**Location:** `packages/cc_domain/lib/features/settings/domain/entities/adapter.dart`

### DetectedAdapter

Result of probing the local machine for an adapter CLI: detection status, version, path.

**Location:** `packages/cc_domain/lib/features/settings/domain/entities/adapter.dart`

### AcpModel

A model advertised by an ACP-compatible agent runner (a curated list keyed by adapter id until the ACP transport is wired).

**Location:** `packages/cc_domain/lib/features/settings/domain/entities/acp_model.dart`

---

## Agents Bounded Context (Doctor & Live State)

### DiagnosticResult / DoctorReport

`DiagnosticResult` is a single agent-doctor check (name, `status`, message, `canAutoRepair`). `DoctorReport` aggregates results with rolled-up error/warning counts.

**Location:** `packages/cc_domain/lib/features/agents/domain/entities/diagnostic_result.dart`

### AgentLiveState

Enum (`running`, `blocked`, `failed`, `idle`, `neverRun`) deriving an agent's current live state and sort priority from its most recent run logs.

**Location:** `packages/cc_domain/lib/features/agents/domain/value_objects/agent_live_state.dart`

### DiscoveredAgent

The domain-facing shape of an agent definition found on disk (`AGENTS.md`) but not yet registered in the workspace, surfaced for import.

**Location:** `packages/cc_domain/lib/features/agents/domain/value_objects/discovered_agent.dart`

---

## Dashboard Bounded Context

### DashboardStatus

Top-level dashboard status carrying the total workspace count.

**Location:** `packages/cc_domain/lib/features/dashboard/domain/entities/dashboard_status.dart`

### ActiveProcessInfo

Information about a detected active agent OS process matched to an agent and workspace (`agentName`, `workspaceName`, `pid`, `command`, `startTime`).

**Location:** `packages/cc_domain/lib/core/domain/entities/active_process_info.dart` (shared kernel; re-exported from dashboard's `dashboard_status.dart` for legacy call sites)

---

## GitHub Status Bounded Context

### GitHubServiceStatus

Aggregated GitHub service health from the public Statuspage API: overall indicator, components, open incidents, fetch time.

**Location:** `packages/cc_domain/lib/features/service_status/domain/entities/github_service_status.dart`

### GitHubStatusComponent

A single GitHub service component (e.g. "Git Operations", "API Requests") with its current status and sort position.

**Location:** `packages/cc_domain/lib/features/service_status/domain/entities/github_service_status.dart`

### GitHubStatusIncident

An active GitHub incident with headline, status string and short link.

**Location:** `packages/cc_domain/lib/features/service_status/domain/entities/github_service_status.dart`

---

## Auth Bounded Context

### ApiCredentials

The user's external-service API credentials: GitHub token plus ticketing provider key/id.

**Key attributes:** `githubToken`, `ticketingApiKey`, `ticketingProviderId`

**Location:** `packages/cc_domain/lib/features/auth/domain/entities/api_credentials.dart`

### GitHubCliStatus

Status of the local GitHub CLI (`gh`) installation and auth state, including resolved username and token.

**Key attributes:** `isInstalled`, `isAuthenticated`, `username`, `token`

**Location:** `packages/cc_domain/lib/features/auth/domain/entities/github_cli_status.dart`

### Token

A value object wrapping a sensitive API token string with emptiness helpers and a masked `toString` so the value never leaks in logs.

**Location:** `packages/cc_domain/lib/features/auth/domain/value_objects/token.dart`

---

## Identity & Access Bounded Context

Multi-user identity, membership and access control. Humans and agents are co-equal actors unified by a `Principal`. Self-hosted-first: the first user is the workspace admin, others join by invite, OIDC is optional. Membership (not a pairing key) is the access boundary.

### User

A human identity. Global (cross-workspace — one human is one user across every workspace). The first user created becomes the workspace owner/admin (env-driven bootstrap: `CC_OWNER_*`); subsequent users join via invite redemption or OIDC just-in-time provisioning.

**Key attributes:** `id`, `handle` (unique), `displayName`, `email`, `avatarRef`, `gitAuthorName`, `gitAuthorEmail`, `createdAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/user.dart`

### Principal

A sealed value object unifying humans and agents as the single actor abstraction every attribution, message, ticket, review, plan and run log resolves through: `UserPrincipal(userId)` | `AgentPrincipal(agentId)`. Lives in the shared kernel so every feature attributes uniformly.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/principal.dart`

### WorkspaceMember

A membership row binding a `User` to a `Workspace` at a `WorkspaceRole`. This is the access test — **holding a pairing key is no longer the access boundary; being a member is.** Unique on `(workspaceId, userId)`.

**Key attributes:** `id`, `workspaceId`, `userId`, `role` (WorkspaceRole), `invitedBy`, `joinedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/workspace_member.dart`

### WorkspaceRole

Graduated membership role: `owner` / `admin` / `member` / `viewer` / `guest`. The repo-op chokepoint derives a `minRole` floor per op kind (read → guest, mutate → member, destructive → admin) with explicit overrides. Deliberately capped — no arbitrary per-object ACLs.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/workspace_role.dart`

### WorkspaceInvite

A one-time invite code (hash-stored) granting a role on redemption. Drives the invite-by-link flow; expires; records who redeemed it.

**Key attributes:** `workspaceId`, `codeHash`, `role`, `createdBy`, `expiresAt`, `usedAt`, `usedBy`

**Location:** `packages/cc_domain/lib/core/domain/entities/workspace_invite.dart`

### UserDevice

A per-user device credential (a paired client). Revocation is live: a revoked device's sessions terminate within seconds (`UserDeviceRevoked` event), not on next reconnect. Per-principal rate limits aggregate across a user's devices (one budget for N devices).

**Key attributes:** `userId`, `platform`, `credentialRef`, `label`, `lastSeenAt`, `revokedAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/user_device.dart`

### UserActivityEntry

An append-only, workspace-scoped audit-trail entry recording who did what to which target. Powers attribution (PRODUCT.md "keep attribution legible") and the universal-undo `ActionJournal`.

**Key attributes:** `workspaceId`, `userId`, `action`, `targetType`, `targetId`, `createdAt`

**Location:** `packages/cc_domain/lib/core/domain/entities/user_activity_entry.dart`

### WorkspaceMemberRepoGrant

A per-`(workspace, user, repo)` access level (`none` / `read` / `review` / `write`, ranked 0-3) so workspace membership doesn't silently out-privilege the forge (the over-grant trap). Owners and admins implicitly hold `write` on every linked repo; everyone else defaults to `none` until granted. Presence and code surfaces check the grant before rendering repo content.

**Location:** `packages/cc_persistence/lib/database/tables/workspace_member_repo_grants_table.dart`

---

## Governance Bounded Context

Company/org & agent-governance runtime. Provides the org chart, a goal hierarchy, budget hard-stops + incidents, board-style approval gates, versioned work products and runtime health/presence. Its services back the governance MCP tools (`create_goal`/`update_goal_progress`, `create_approval`/`decide_approval`, `create_work_product`/`save_work_product_revision`, `agent_heartbeat`/`list_runtime_health`/`list_agent_presence`, `get_org_chart`, `create_runtime_profile`). The plan-exit gate (`exit_plan_mode`) is a governance approval of kind `plan_exit`.

### Governance entities & services

- **OrgChart / OrgNode** — the reporting tree derived from `Agent.reportsTo` (`OrgChartService`).
- **Goal** — a per-agent/team target with progress tracked via `GoalProgressService` (tables `goals_table`).
- **Approval / ApprovalComment** — a board approval item with a decision workflow (`ApprovalWorkflowService`; tables `approvals_table`, `approval_comments_table`).
- **WorkProduct / WorkProductRevision** — a versioned agent deliverable (`WorkProductService`; tables `work_products_table`, `work_product_revisions_table`).
- **AgentRuntimeState / RuntimeProfile** — liveness/heartbeat + GC and per-agent runtime configuration (`HeartbeatMonitorService`, `AgentPresenceService`; tables `agent_runtime_state_table`, `runtime_profiles_table`).
- **BudgetPolicy / BudgetIncident** — per-scope monthly spend ceilings and the incidents raised when one is crossed.

**Location:** `packages/cc_domain/lib/features/governance/domain/` (entities, value_objects, repositories, services)

## Harness Bounded Context (built-in agent runtime)

Control Center's **built-in agent runtime** (`AdapterTransport.harness`) — an in-process, event-sourced loop that talks to LLM providers directly and runs tools in-process, with no external CLI subprocess. It is one of the agent runtimes alongside the Claude Code, Codex, Pi and ACP adapters. The harness is its own pub-workspace package pair: `packages/cc_harness` is the web-safe kernel and `packages/cc_harness_runtime` is the VM-only batteries (concrete providers, OAuth/PKCE brokering, credential stores, the built-in tool set, the watchdog advisor). CC-coupled adapters that bridge the kernel to server services live in `packages/cc_infra/lib/src/harness/`.

### AgentLoop

The event-sourced turn loop — an abstract interface; `AgentLoopRunner` is the implementation. Emits typed events (text/thinking deltas, tool-call start/result, turn-complete) so the dispatch layer can stream reasoning and render tool-call cards. Supports prompt caching, context compaction (`context/harness_compaction.dart`), reasoning-effort mapping (`provider/effort_mapping.dart`), USD cost accounting, an advisor/steering channel (`loop/advisor.dart`), slash commands (`tools/command_runner.dart`) and subagent spawning. The kernel is consumed through a curated facade (`cc_harness.dart`, held at ~40 symbols by a ratchet test) plus topic entrypoints (`loop.dart`, `provider.dart`, `tools.dart`, `context.dart`, `messages.dart`, `slash_command.dart`, `cancellation.dart`).

**Location:** `packages/cc_harness/lib/src/loop/agent_loop.dart` (interface), `packages/cc_harness/lib/src/loop/agent_loop_runner.dart` (implementation)

### LlmProviderPort / HarnessProviders / Tool / ToolRegistry

`LlmProviderPort` is the provider abstraction (Anthropic/OpenAI/local); `HarnessProviders` + `ProviderCredentialRefresher` resolve provider keys/OAuth from the server-owned credential store with refresh. `Tool` + `ToolRegistry` are the in-process tool contract the loop calls (the built-in Bash/Edit/Read/Write/Find/Search/ApplyPatch/WebFetch/WebSearch/Task/Checkpoint/Rewind tools, plus the shared MCP tools bridged in). `ReasoningEffort` lives here too. The VM-only provider implementations, OAuth/PKCE brokering, credential stores and built-in tool set are in `packages/cc_harness_runtime` (`lib/src/providers/`, `lib/src/oauth/`, `lib/src/tools/`).

**Location:** `packages/cc_harness/lib/src/provider/` (`llm_provider_port.dart`, `harness_providers.dart`, `provider_credential_refresher.dart`, `effort_mapping.dart`, `reasoning_effort.dart`), `packages/cc_harness/lib/src/tools/` (`tool.dart`, `tool_registry.dart`); runtime batteries `packages/cc_harness_runtime/lib/src/`

## Model Routing Bounded Context

A unified model catalog and routing engine. Powers model selection for the harness runtime and the provider-governance policies.

### ModelCatalog

An in-memory provider/model registry parsed from the live `models.dev` catalog, with query/resolve methods (provider lookup, availability, reasoning support, context size, USD pricing). Backs `AgentLoop`'s model resolver.

**Location:** `packages/cc_domain/lib/features/model_routing/domain/services/model_catalog.dart`

### ProviderPolicyEngine / SmallModelRouter / ProviderPolicy

`ProviderPolicyEngine` enforces per-provider allow/deny + context-promotion policy (persisted in `provider_policies`); `SmallModelRouter` routes eligible sub-tasks to cheaper/faster models within quality constraints. Related services cover credential ranking, usage tracking, rate-limit classification and auth-retry.

**Location:** `packages/cc_domain/lib/features/model_routing/domain/` (`services/provider_policy_engine.dart`, `services/small_model_router.dart`, `entities/provider_policy.dart`)

## Skills Bounded Context

Content-addressed skill pinning + distribution + supply-chain scanning. Skills come from three origins (`SkillOrigin`): `manual` (authored in-workspace via `create_skill`), `runtimeLocal` (copied from a runtime-local skills dir) and `github` (fetched and pinned to a commit SHA). Locked skills are tracked in `skills-lock.json` with content hashes (`SkillLockEntry`). Every install/update passes through a [fail-closed scan gate](#skills-supply-chain-security) before reaching disk; `SkillBundleService` invokes it between fetch and write. Backs the `install_skill` / `verify_skills` / `pin_skill` / `list_skills` / `create_skill` / `list_skill_updates` MCP tools.

**Location:** `packages/cc_domain/lib/features/skills/domain/entities/skill_lock.dart`, `packages/cc_domain/lib/features/skills/domain/ports/skill_bundle_port.dart`

## Observability Bounded Context

The workspace observability hub (route `/observability`): a live Agent Hub plus historical cost/usage/quota/behavior/model/goal analytics. Tabs include Agent Hub, Overview, Costs, Models, Behavior, Quota, Goals and Benchmark.

### ObservabilityMetrics / Quota / Benchmark / FrictionAnalyzer / SubagentCostPropagator

Domain types for the hub: rolled-up usage/cost metrics, provider quota + reset windows, task-completion benchmark trials with reward scoring, a friction analyzer over agent decision patterns and a propagator that rolls subagent cost up to the parent run.

**Location:** `packages/cc_domain/lib/features/observability/domain/` (`observability_metrics.dart`, `quota.dart`, `benchmark.dart`, `friction_analyzer.dart`, `subagent_cost_propagator.dart`)

## Todos Bounded Context

Persisted per-channel task checklists shared by agents and the user. Each `Todo` has `content` and a `status` (`pending` / `in_progress` / `completed`), scoped to `(workspaceId, conversationId)` and watched live over RPC. The `todo_write` MCP tool lets any runtime (built-in harness or external adapter) replace the full list in one call; it renders in the General pane.

**Location:** `packages/cc_domain/lib/features/todos/domain/` (entity + `TodoRepository`), table `packages/cc_persistence/lib/database/tables/todos_table.dart`, tool `packages/cc_mcp/lib/src/tools/todo_write_tool.dart`

### ConversationGoal

The single working goal of a conversation, set via `/goal` and keyed by `conversationId` (at most one per conversation). Deliberately separate from the todo list — `todo_write` would clobber it — and from `AgentGoalRun`, the durable supervised objective a `/goal` can also spawn.

**Key attributes:** `conversationId`, `workspaceId`, `title`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/todos/domain/entities/conversation_goal.dart`, table `packages/cc_persistence/lib/database/tables/conversation_goals_table.dart`

## Subscriptions Bounded Context

Live AI-plan usage for configured providers (Claude Code, Codex, z.ai), surfaced as a compact title-bar pill that shows the most-constrained provider at a glance and expands to per-provider progress bars + reset countdowns.

**Location:** `packages/cc_domain/lib/features/subscriptions/domain/` (usage entities + repository), UI `lib/features/subscriptions/presentation/widgets/`

## Soundscape Bounded Context

Generative ambient audio: a `SoundscapeContext` (weather + clock + mood) folds into a synthesized arrangement served as an HLS stream. The domain holds the context entity, arrangement/tune value objects and the synth; the server side builds contexts and segments audio.

**Location:** `packages/cc_domain/lib/features/soundscape/domain/` (`entities/soundscape_context.dart`, `value_objects/soundscape_arrangement.dart`, `value_objects/soundscape_tune.dart`, `synth/`), server `packages/cc_infra/lib/src/soundscape/`

## Weather Bounded Context

A `WeatherSnapshot` for the workspace's location plus its repository, feeding ambient-context surfaces such as the soundscape context builder.

**Location:** `packages/cc_domain/lib/features/weather/domain/` (`entities/weather_snapshot.dart`, `repositories/weather_repository.dart`)

## Dictation Bounded Context

Push-to-talk voice input. The client captures the mic (16 kHz mono PCM16) and streams frames to the host, which runs the same rolling-window transcriber the meeting recorder uses; `DictationControlPort` is the client-side control channel (start/stop/cancel, `DictationPartial` updates).

**Location:** `packages/cc_domain/lib/features/dictation/domain/dictation_control_port.dart`

## Focus Mode Bounded Context

A deep-work mode (`FocusModeState`: active flag, session start/duration, goal, compact mode, notification blocking) that narrows the shell to one thread of work.

**Location:** `packages/cc_domain/lib/features/focus_mode/domain/focus_mode_state.dart`

## IDE (code-server) Bounded Context

An embedded browser IDE: code-server (VS Code in the browser) runs on the server — never on a client — bound loopback only, opening the conversation's isolated worktree as its folder; clients reach it through the authenticated `/proxy/vscode/<sessionId>/` reverse proxy. `CodeServerPort` manages the workspace-scoped sessions (`CodeServerSession`). Distinct from the `IdeEditor` value object, which catalogs locally-installed editors for "open in IDE".

**Location:** `packages/cc_domain/lib/features/ide/domain/` (`code_server_port.dart`, `code_server_session.dart`)

## cc_markdown (markdown & mermaid engine)

The in-repo typed-AST markdown package: pure-Dart parsing and rendering, no WebView/JS. Includes `CcMermaidView`, a native mermaid engine — dialect parsers (flowchart/graph, stateDiagram, classDiagram, erDiagram, sequenceDiagram, pie, timeline) → layout (Sugiyama-style layered for the graph family) → `CustomPainter`. Author theming (`%%{init}%%`, `classDef`, `style`) is parsed but not applied; diagrams are themed from app tokens and unsupported dialects or malformed bodies fall back gracefully.

**Location:** `packages/cc_markdown/` (`lib/src/mermaid/render/mermaid_view.dart`, markdown renderer `lib/src/render/renderer.dart`)

## Session Review & VS Code Theme Bounded Contexts

`session_review` computes and renders the git diff of a run/session's workspace changes, file-by-file, with syntax highlighting. `vscode_theme` imports a VS Code editor theme from disk and collapses it into a lightweight `VsCodeEditorTheme` (only the colors CC's diff/code surfaces use) so those diffs match the user's IDE palette.

**Location:** `lib/features/session_review/` (all session-review code is client-side); `lib/features/vscode_theme/domain/vscode_editor_theme.dart`

---

## Presence & Real-Time Collaboration Bounded Context

Real-time multiplayer for humans and agents. Two lanes that never mix: a **durable lane** (optimistic-mutation + server-rebase + per-field LWW on a monotonic per-workspace `syncSeq`) and an **ephemeral lane** (presence/awareness, never persisted). Authoritative-server + LWW by default — a CRDT is reserved for one possible future co-editing surface (Rust-via-`cc_natives` FFI). Solo-mode zero-regression: with one human the presence lane idles and no roster chrome appears.

### ParticipantPresence

An ephemeral awareness value carried per `Principal`: status (online/idle/offline), current `PresenceLocus`, cursor/selection, typing flag and for agents the live run status + running cost. **Never persisted** (Yjs-awareness model); server-hubbed, never peer-to-peer; repo-grant filtering applies at the server before fan-out so presence never leaks content a viewer can't open.

**Location:** `packages/cc_domain/lib/features/presence/domain/value_objects/participant_presence.dart`

### PresenceLocus

A sealed tagged union of where a participant currently is: `ChannelLocus` / `FileLocus` (repo + path + line) / `PrLocus` / `TicketLocus` / `PlanNodeLocus`. Compact wire keys because cursor-cadence updates ride the ephemeral lane at up to 10 Hz.

**Location:** `packages/cc_domain/lib/features/presence/domain/value_objects/presence_locus.dart`

### Follow-mode / steer / take-over / hand-back

Interaction patterns layered on presence + the sync engine: click an avatar to ride its viewport until you act (follow); reply-in-thread to redirect a running agent (steer); grab an in-flight edit by pausing the agent at a turn boundary, editing its rift worktree, then posting a structured diff-summary it re-reads (take-over + hand-back). Agent paused/resumed state is durable — a server restart mid-take-over comes back paused, never auto-resuming.

### Autonomy dial

A per-channel per-agent control — `propose-only` / `act-with-approval` / `act-freely` — implemented as a named profile over the [Action guardrails](#action-guardrails-bounded-context) store. Risky actions hit a fail-closed gate regardless of dial position.

### syncSeq / sync_changes

The monotonic per-workspace sync counter, allocated inside the same DB transaction that commits the mutation (so a delta's id and its data are atomic). Clients track `lastSyncSeq` per store; a gap triggers a ranged pull, a failed pull drops that store to snapshot mode (the kill-switch path, exercised automatically). Ordering never trusts a client clock — "last writer" = server receipt order. The counter row (`SyncSequencesTable`, one monotonic counter per workspace, bumped by AFTER INSERT/UPDATE/DELETE triggers inside the mutation transaction) and the delta log (`SyncChangesTable`) are defined in the same file; both are per-workspace-DB tables.

**Location:** `packages/cc_persistence/lib/database/tables/sync_changes_table.dart`

---

## Plan Studio Bounded Context

The interactive planning surface: render an orchestration proposal or a single-agent plan as an editable typed DAG, with per-step cost/time/risk estimates, plan-diff versioning and partial/branched approval. "One graph model, two wrappers" — `PlanGraph` is shared by `PlanDocument` and `OrchestrationProposal`. Plan→execution compile stays a **pure function** (`OrchestrationMaterializer`): identical proposal + role map always yields the identical DAG.

### PlanDocument

A single-agent plan-mode artifact, conversation-scoped, wrapping a `PlanGraph`. Distinct lifecycle from an `OrchestrationProposal` (which is orchestration-scoped). Carries a monotonic `revision` for plan-diff/rewind.

**Key attributes:** `id`, `workspaceId`, `conversationId`, `agentId`, `planJson`, `status`, `revision`, `createdAt`, `updatedAt`

**Location:** `packages/cc_domain/lib/features/plan_studio/domain/entities/plan_document.dart`

### OrchestrationRevision

An append-only row capturing one revision of an orchestration's proposal JSON, authored by a principal. Enables plan-diff versioning and rewind; the orchestration carries a monotonic `revision` and the `approvedRevision` the user signed off on, so a mid-flight replan can't silently change what was approved.

**Key attributes:** `id`, `workspaceId`, `orchestrationId`, `revision`, `proposalJson`, `authoredBy`, `createdAt`

**Location:** `packages/cc_domain/lib/features/plan_studio/domain/entities/orchestration_revision.dart`

### Playbook

A named, versioned, parameterized template layering a typed params schema (`string` / `enum` / `repoRef` / `agentRef`) over a stored proposal or pipeline template, with `{{param}}` substitution. Parameters are typed and deliberately dumb — no expression language, no conditionals; "a playbook that needs logic is a pipeline."

**Key attributes:** `id`, `workspaceId`, `name`, `description`, `paramsSchemaJson`, `sourceProposalJson` (or `templateId`), `version`

**Location:** `packages/cc_domain/lib/features/plan_studio/domain/entities/playbook.dart`

### PlanEstimator / ProposalDiff

Pure services: `PlanEstimator` composes the model catalog, per-agent daily stats and the code graph to produce per-step cost/time/blast-radius estimates with confidence ranges (or "no history yet" — never fabricated point values); `ProposalDiff` computes added/removed/reordered nodes, edge changes and budget delta between revisions.

---

## Review Studio Bounded Context

Semantic, multi-modal PR review built on the code graph + Widgetbook: graph-derived file cohorts, a walkthrough with typed diagrams, in-app UI visual diffs, swagger-style API contract diffs, a blast-radius map and multi-axis gates (correctness / security / test-coverage-gap / performance / visual-regression / API-contract). Typed diagrams are schema-validated and cross-checked against code-graph edges; mermaid is export-only. Visual diffs render via a headless `flutter test` golden harness (a supervised child process) because the pure-Dart server has no Flutter engine.

### Cohort / cohort key

A semantic file grouping derived from the code graph (bounded-context/feature). The cohort key is content-derived (dominant symbols/feature, not line ranges) so summaries, findings and review progress survive rebase/force-push. Computed server-side on PR open and every head-SHA change.

**Tables:** `review_cohorts` (workspace-scoped), `review_axis_results` (workspace-scoped). Repo-scoped snapshots keyed by `(workspaceId, repoId)`: `api_contract_snapshots`, `visual_diff_snapshots`.

### ApiContractDiff

A server-side service producing severity-classified OpenAPI/GraphQL contract changes with breaking badges, against per-repo configured spec globs. CC's own stable `changesJson` schema keeps the diff engine swappable.

### Review axis / per-axis gate

A first-class, individually-gateable check (correctness, security, test-coverage-gap, performance, visual-regression, API-contract). Each axis carries a budget; results are cached by `(diff hash, axis)`. A _blocking_ axis that could not run holds the verdict at "hold" — absence of evidence never converts to a green gate.

---

## Fleet Bounded Context

Scaling execution beyond one box. A pure-Dart `cc_worker` binary pairs with a `cc_server`, declares its host capabilities, pulls leased jobs, executes them and streams events back. The ceiling is **leases + heartbeats + reaping**: no consensus, no work-stealing between workers, no autoscaling, no worker-to-worker traffic — one authoritative server, N dumb limbs. Workers hold **no durable state** (no DB, auth, approvals, or budgets); the implicit local worker is an in-process seam so a solo desktop stays byte-identical to today.

### JobSpec / Job

`JobSpec` is the typed serializable spec for everything executable (agent run, pipeline step, code-index, golden-render, benchmark, eval batch): required/preferred capabilities, priority, budget, workspace. A `Job` is one leased row with status `queued` / `leased` / `running` / `done` / `failed` / `reaped`, keyed by `workspaceId` but stored in the server-wide queue in `global.db`.

**Location:** `packages/cc_domain/lib/features/fleet/domain/entities/job.dart`

### Worker

A paired headless executor declaring capabilities (OS, arch, cores, RAM, Flutter SDK, sandbox backends, GPU/ML, always-on). The fleet tables live in the **global** database: `workers` is server-global (CROSS-WORKSPACE BY DESIGN); `jobs` and `placement_log` carry a `workspaceId` as a plain attribute (a job payload carries ids, never workspace content) but also live in `global.db`, since the queue is server-wide. Credentials are minted per lease, never rest on the worker; approvals round-trip through the server (a worker can never self-approve).

**Location:** `packages/cc_domain/lib/features/fleet/domain/entities/worker.dart`; table `packages/cc_persistence/lib/database/tables/fleet_tables.dart`

### Placement policy (pin / prefer / spill)

How the scheduler chooses among eligible workers: `pin` (force a specific worker), `prefer` (favour a capability), `spill` (allow any). Every placement is logged with its reason (`placement_log`).

---

## Evals, Replay & Regression Bounded Context

Regression protection for the fleet — explicitly **not MLOps**: no experiment tracking beyond scorecards, no fine-tuning, no synthetic data. Replay is the primitive; evals are built on it. Two honestly-labeled replay modes: **deterministic** (cassettes stubbed, executes nothing, exact, free, tests the harness) and **live** (real model, sandboxed, tests the agent). Conflating the two is the failure mode the split prevents.

### SessionRecording

An event stream + HTTP/LLM cassettes + tool I/O captured for one run, paired with an `AgentConfigHash`. Cassettes are opt-in per agent/channel (not ambient surveillance); redaction-before-persistence + a retention service apply.

**Location:** `packages/cc_domain/lib/features/evals/domain/entities/evals_entities.dart`

### AgentConfigHash

A content hash (SHA-256 over canonical JSON) of a run's effective config — system prompt, mode prompts, tool registry, model id, memory policies, routing — with a `hashVersion`. Canonicalization is normative. Config is versioned like code; a drift alarm fires when production behavior shifts without a config change.

### EvalSuite / EvalRun / Scorecard

`EvalSuite` is a task prompt + fixture + graders; `EvalRun` is a batch execution (N repetitions) producing a `Scorecard` (pass-rate, cost, latency, variance, per-grader breakdown). Graders are **deterministic first, LLM-rubric last**; LLM judges never grade their own model family unflagged.

### GoldenSession

A blessed `SessionRecording` pinned per agent/playbook, in deterministic or live mode. A prompt/model edit that regresses a golden is blocked with evidence (canary-gated config changes). Goldens default to deterministic mode; live goldens are advisory unless batched.

### Reliability score

Aggregated evidence (from scorecards + replay) cited by the autonomy dial so autonomy is granted on measured reliability, not vibes.

---

## Action Guardrails Bounded Context

The unified allow/prompt/deny engine that generalizes the former bash-only `CommandPolicy` to a closed `ActionClass` taxonomy. One policy surface with provenance, enforced at every chokepoint (the harness `ToolRegistry`, the server-side MCP dispatcher gate and repo-op mutations). Underpins the autonomy dial, delegation guards and skills-scan trust tiers.

### ActionClass

A closed set of ~12 effect classes: `fileDelete`, `fileWriteOutsideWorktree`, `gitCommit`, `gitPush`, `prCreate`, `prPublish`, `vendorSyncWrite`, `networkEgress`, `secretAccess`, `packageInstall`, `processSpawn`, `workspaceMutation`. Every mutating tool declares its ActionClass(es); an undeclared new tool fails the ratchet test. Deliberately small — "taxonomy sprawl is the death of this feature."

**Location:** `packages/cc_domain/lib/features/guardrails/domain/value_objects/action_class.dart`

### ActionPolicyRule

A rule `(scope, ActionClass | commandPrefix) → allow | prompt | deny`. Scope resolution is `channel > agent > workspace > mode preset > built-in default` (most-specific wins; within a scope, longest-prefix then most-restrictive). The flat `allow > deny > prompt` precedence was replaced by specificity-then-restrictiveness.

**Location:** `packages/cc_domain/lib/features/guardrails/domain/entities/action_policy_rule.dart`, table `packages/cc_persistence/lib/database/tables/action_policies_table.dart`

### ActionDecision / PolicyResolver

`PolicyResolver` resolves the decision for an `(actionClass, scope, fingerprint)` and is stable within a turn (denial is terminal for that action in-turn — no re-prompt storm). `prompt` with no approver connected is **denied** (fail-closed). Multi-class actions combine most-restrictive; when several classes prompt, one confirmation lists them all.

**Location:** `packages/cc_domain/lib/features/guardrails/domain/value_objects/action_decision.dart`, `.../services/`

### Adapter honesty matrix

Per adapter, which ActionClasses are enforced at which layer (MCP gate / `--permission-mode` mapping / sandbox floor / not enforceable). External CLIs run some tools natively in-process where CC cannot intercept; the matrix documents this and the settings UI shows it — "claiming coverage that doesn't exist is the one unforgivable failure."

---

## Agent Peer Messaging & Delegation

Agents talk to each other over **channels** (durable, roster-visible) — the old in-memory IRC bus was deleted. Tools: `send_to_agent` (fire-and-forget), `ask_agent` (request/reply, caller suspends until reply or a **mandatory timeout**), `delegate_task` (scoped task that materializes as a child ticket or plan node), `todo_read` (recovers a conversation's todo list), plus the re-implemented `consult_agent`. `ask_agent` chains and `delegate_task` share a single delegation `chain-id` for combined cycle detection; delegation guards (depth cap default 3, cycle detection, budget-envelope inheritance, autonomy ceiling, rate cap) are enforced server-side at a chokepoint — never by prompt instructions. Recipient resolution is exact (by id or unique name; no fuzzy, no cross-workspace). Agent-to-agent channels are muted by default and never bump the human unread badge.

---

## Skills Supply-Chain Security

A **fail-closed scan gate** invoked between fetch and write in `SkillBundleService`: no skill content reaches disk or an agent prompt without a verdict. The scanner is inert by construction (executes nothing from the skill); Layer 1 static rules + Layer 2 capability manifest are the mandatory gate, Layer 3 LLM review is additive. TOCTOU invariant: bytes scanned = bytes written = bytes hash-locked.

### Scan verdict / trust tier

`ScanVerdict` is `pass` / `warn` / `quarantine` (scanner unavailable/errored = quarantine). `TrustTier` is `firstParty` / `workspace` / `verified` / `community` — provenance metadata, **never** a scan substitute or policy shortcut. Results are content-hash-keyed (`skill_scan_results`) so identical bytes are never re-scanned.

**Location:** `packages/cc_persistence/lib/database/tables/skill_scan_results_table.dart`; lock-file fields on `skills-lock.json` (`SkillLockEntry`).

---

## Deterministic UX Bounded Context

The velocity layer: every action reachable, idempotent and undoable. Three guarantees — **Reachability** (⌘K omnibox spans every action), **Determinism** (the same action always does the same thing; idempotent, previewable, reversible-or-confirmed), **Immediacy** (optimistic apply that never lies — every optimistic failure surfaces loudly).

### WriteLedger / idempotency key

Every mutating op carries a client-generated UUIDv7 idempotency key minted per **logical action** (not per attempt). The dispatcher checks the workspace-scoped `WriteLedger` _before_ invoking the handler; a dedup replay returns the byte-identical original result marked `deduplicated: true`. Bounded TTL. Makes reconnect/replay/multi-client safe by construction.

**Location:** `packages/cc_persistence/lib/database/tables/write_ledger_table.dart`

### ActionJournal / universal undo

A workspace-wide journal of reversible actions across pillars (message send/edit, ticket edit, agent file edit via snapshot, plan edit, review action). Each mutating op declares an **undo class**: `reversible` (registered inverse), `compensable` (named compensating action), or `irreversible` (external side effects — get preview/confirm instead, never in the undo stack). The op-coverage ratchet enforces every new mutating op declares a class. Undo is per-principal (⌘Z pops your own most recent reversible action).

### Unified inbox

A cross-pillar queue with a strict inclusion rule: an item enters only if it _blocks_ something (an agent, a merge, a sync) or explicitly requests the operator. Routed per principal. Everything else stays in its pillar surface. The feature lives in `lib/features/inbox/` at route `/inbox`.

### Banner rail

An ambient priority queue of time-critical, actionable-now items at the top of the shell (auto-expiry, reduced-motion variants, AAA icon+label). Inclusion is hard: time-critical AND actionable; one banner at a time, hard-capped at two. A noisy rail is worse than none.

---

## Value Objects (Shared Kernel)

### IdeEditor

A code editor / IDE the app can open a local directory in (e.g. VS Code, Cursor, Zed, the native file manager). The full platform catalog is reported regardless of install state; the `installed` flag marks whether it was actually detected on this machine. Powers the "open in IDE" action on PR files and the worktree directory.

**Key attributes:** `id` (stable platform-independent id, e.g. `vscode`), `displayName`, `installed`

**Location:** `packages/cc_domain/lib/core/domain/entities/ide_editor.dart`

### AgentCapabilities

Per-channel capability flags (push to repo, GitHub API, ticketing, network egress) that the credential broker checks at sandbox launch to gate token/network injection. Serialized as JSON on the agent.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/agent_capabilities.dart`

### AgentSkills

An immutable, case-insensitive collection of skill identifiers associated with an agent. Skills determine which prompts and tool configurations are injected at runtime.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/agent_skills.dart`

### AgentRole

Enumerates the agent's role (CEO, coder, reviewer, QA, designer, security, devops, PM, general), each carrying a display label and description. Also used for memory access and the reporting hierarchy.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/agent_role.dart`

### ReasoningEffort

Enum controlling reasoning effort (`minimal`, `low`, `medium`, `high`, …), mapped per provider by the harness's effort mapping. The `Agent.effort` field is a nullable string naming one of these levels.

**Location:** `packages/cc_harness/lib/src/provider/reasoning_effort.dart`, mapping `packages/cc_harness/lib/src/provider/effort_mapping.dart`

### Mode

An enum (`chat`, `review`, `plan`, `orchestrate`) that gates sandbox writes and the MCP tool allowlist. Each mode maps to a specific system-prompt template and sandbox policy: `chat` is unconstrained; `review` and `plan` are read-only (writes denied, curated tool sets); `orchestrate` is plan-equivalent (read/research) plus the single `propose_orchestration` verb, so hiring and decomposition happen deterministically only after the user approves the proposal.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/mode.dart`

### SandboxBackend

Enum for sandbox execution backends: `native` (OS-native Seatbelt/bubblewrap) and `none` (opt-out), with display labels and legacy-value migration. The previous `docker`/`auto` modes were removed when the in-project native sandbox landed.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/sandbox_backend.dart`

### SandboxSpec / SandboxBindMount

`SandboxSpec` is the full specification used by `SandboxPort.launch` (session, workspace, agent, mounts, network/egress, workdir, mode). `SandboxBindMount` is one host-to-guest bind mount.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/sandbox_spec.dart`

### SandboxHandle / SandboxState

`SandboxHandle` is the opaque handle returned by `SandboxPort.launch` (session id, backend, state, error, adapter details). `SandboxState` is its lifecycle enum (`starting`, `running`, `stopped`, `failed`).

**Location:** `packages/cc_domain/lib/core/domain/value_objects/sandbox_handle.dart`

### SandboxEvent / SandboxEventType / SandboxViolation

A single sandbox lifecycle/stdio event, its kind enum and a structured denial record (`SandboxViolation`: action, target, suggested capability) emitted on a sandbox's event stream.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/sandbox_event.dart`

### RunCost

An aggregable token/cost tally (input tokens, output tokens, estimated cost in cents) for an agent run, supporting addition and a zero identity.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/run_cost.dart`

### RetryMeta

Tracks the retry lineage of an agent run via parent run id and attempt counter, with a helper to advance to the next attempt.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/retry_meta.dart`

### WakeReason / WakeContext

`WakeReason` enumerates why an agent was dispatched; `WakeContext` carries the dispatch context (ticket, run, agent, workspace, channel, reason, message, pipeline run) injected at dispatch and serialized to environment variables.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/wake_context.dart`

### RepoIsolationBackend

Enum identifying which mechanism produced an isolated repo copy: `rift` copy-on-write clone or plain `gitWorktree` fallback.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/repo_isolation_backend.dart`

### MemoryPermission

Enum of memory access levels (`none`, `read`, `write`) used by the memory access policy.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/memory_permission.dart`

### AppLocale

Wraps a language code with display-name lookup and helpers for whether it is English or has localization support.

**Location:** `packages/cc_domain/lib/core/domain/value_objects/app_locale.dart`

---

## Ports (Abstractions)

Domain interfaces implemented by infrastructure adapters. Core ports live in `packages/cc_domain/lib/core/domain/ports/`; feature-specific ports live under their feature's `domain/ports/`.

### SandboxPort

Manages the lifecycle of an isolated execution sandbox (probe, launch, isAlive, events, exec, pause, resume, destroy). One implementation per backend; the executing adapters are VM-only and live server-side under `packages/cc_infra/lib/src/sandboxing/` (e.g. `native_sandbox_adapter.dart`).

**Location:** `packages/cc_domain/lib/core/domain/ports/sandbox_port.dart`

### CredentialBrokerPort

Mints scoped, capability-gated credentials (env map + revoke handle) for one sandbox launch and revokes them on teardown. Ensures secrets never persist in the sandbox filesystem.

**Location:** `packages/cc_domain/lib/core/domain/ports/credential_broker_port.dart`

### ConfirmationPort

Lets sandbox hooks interrupt an in-flight agent and ask the user to approve a privileged/destructive action. Carries `ConfirmationRequest` payloads with severity levels.

**Location:** `packages/cc_domain/lib/core/domain/ports/confirmation_port.dart`

### AgentQuestionPort

Surfaces an agent's question (option choices and/or free text) as an interactive inline form in a channel and blocks until the user answers. Defines the `AgentQuestionOption` / `Request` / `Answer` payloads.

**Location:** `packages/cc_domain/lib/core/domain/ports/agent_question_port.dart`

### GitRepoInspectorPort

Extracts metadata (owner, repo, branch) from a local Git repo path, returning a `GitRepoInfo`.

**Location:** `packages/cc_domain/lib/core/domain/ports/git_repo_inspector_port.dart`

### GitCommandPort

Executes git commands by shelling out to the system git binary, with a completion-returning run and a streaming-progress variant. Defines the `GitResult` value.

**Location:** `packages/cc_domain/lib/core/domain/ports/git_command_port.dart`

### RepoIsolationPort

Provisions and tears down isolated copy-on-write worktrees of a local repo (rift, with `git worktree` fallback) without mutating the source. Defines `RepoIsolationResult`.

**Location:** `packages/cc_domain/lib/core/domain/ports/repo_isolation_port.dart`

### RepoWorkspaceProvisionerPort

Provisions a per-channel working root with isolated CoW worktrees of the workspace's repos and tears them down on unit completion (idempotent, no-op-safe by channel/channel/ticket).

**Location:** `packages/cc_domain/lib/core/domain/ports/repo_workspace_provisioner_port.dart`

### WorkspaceFilesystemPort

Provides filesystem paths and operations for agents, skills, channels, PR clones and logos within a workspace.

**Location:** `packages/cc_domain/lib/core/domain/ports/workspace_filesystem_port.dart`

### RunLogStorePort

Writes, reads and compacts agent run logs by run id, enabling swappable storage backends without changing dispatch logic.

**Location:** `packages/cc_domain/lib/core/domain/ports/run_log_store_port.dart`

### NotificationPort

Shows native desktop notifications (respecting category/route gating) and disposes native resources.

**Location:** `packages/cc_domain/lib/core/domain/ports/notification_port.dart`

### NotificationPreferencesPort

Reads/writes notification preferences (global enable, per-category, batch delivery policy, quiet hours, sound, volume). Defines `BatchDeliveryPolicy`, `TimeOfDay`, `QuietHoursConfig`.

**Location:** `packages/cc_domain/lib/core/domain/ports/notification_preferences_port.dart`

### EmbeddingPort

Produces unit-norm text embedding vectors, exposing readiness and dimensionality so callers can degrade to non-vector paths.

**Location:** `packages/cc_domain/lib/core/domain/ports/embedding_port.dart`

### ProcessControlPort

Kills a process by PID and reports whether a PID is alive. Used to terminate misbehaving agent processes.

**Location:** `packages/cc_domain/lib/core/domain/ports/process_control_port.dart`

### ModeResolver

Resolves the `Mode` for a given channel id, defaulting to `chat` when the id is null or the row is missing.

**Location:** `packages/cc_domain/lib/core/domain/ports/mode_resolver.dart`

### Feature ports

- **AgentBackend**, an agent execution backend keyed by CLI name (pi, claude, codex), streaming `AgentProcessEvent`s and supporting stop. `packages/cc_domain/lib/features/dispatch/domain/ports/agent_backend.dart`
- **AgentDispatchPort**, dispatches agent CLI processes (wake context, mode, env, run-log id), returning a `DispatchHandle`. `packages/cc_domain/lib/features/dispatch/domain/ports/agent_dispatch_port.dart`
- **MessagingPort**, messaging channel operations (send, add agents, create groups, send-and-dispatch, refine plan). `packages/cc_domain/lib/features/messaging/domain/ports/messaging_port.dart`
- **TicketProviderPort**, vendor-agnostic boundary to a ticketing backend (create/get/list/update/transition/assign/watch), exposing provider, capabilities and allowed network domains. `packages/cc_domain/lib/features/ticketing/domain/ports/ticket_provider_port.dart`
- **PipelineEnginePort**, starts a pipeline run from a template, decoupling `SubPipelineLauncher` from the concrete engine. `packages/cc_domain/lib/features/pipelines/domain/ports/pipeline_engine_port.dart`
- **DispatchReviewersPort**, dispatches reviewer agents into a review channel; shared by the MCP tool and pipeline step bodies. `packages/cc_domain/lib/features/pipelines/domain/ports/dispatch_reviewers_port.dart`
- **SchemaValidatorPort**, validates a value against a JSON-Schema subset and returns human-readable violations (never throws). `packages/cc_domain/lib/core/domain/ports/schema_validator_port.dart`
- **SandboxDetectorPort**, detects available sandbox capabilities on the host. `packages/cc_domain/lib/features/sandboxing/domain/ports/sandbox_detector_port.dart`
- **DoctorPort**, runs agent environment diagnostics, returning a `DoctorReport`. `packages/cc_domain/lib/features/agents/domain/ports/doctor_port.dart`
- **GitHubCliPort**, probes the local `gh` CLI and returns its status. `packages/cc_domain/lib/features/auth/domain/ports/github_cli_port.dart`
- **ProcessDetectionPort**, detects running local agent processes and kills by PID. `packages/cc_domain/lib/core/domain/ports/process_detection_port.dart` (shared kernel, used by both dashboard and the agents kill path)
- **McpServerPort / McpTool**, MCP server lifecycle control and the abstract base for an MCP tool (name, description, input schema, run, approval gating). `packages/cc_domain/lib/features/mcp/domain/ports/`
- **TicketWorkflowPort**, consumer-owned (pipelines) port exposing the three ticket-workflow operations the pipeline engine needs (`createTicket`, `completeTicket`, `cancelTicket`); implemented by `TicketWorkflowService` so pipelines depend on a thin contract, not the concrete ticketing service. `packages/cc_domain/lib/features/ticketing/domain/ports/ticket_workflow_port.dart`

---

## Domain Events

### DomainEventBus

An in-process broadcast publish/subscribe bus for cross-feature decoupling. Features `publish(event)`; subscribers consume a typed `on<T>()` stream. Every event implements `DomainEvent` and exposes `occurredAt`.

**Location:** `packages/cc_domain/lib/core/domain/events/domain_event_bus.dart`

**Key events by category:**

**Workspace, Agent & Repo:**

- `WorkspaceCreated`, triggers CEO agent seeding
- `AgentRunCompleted`, triggers notifications, cost rollups, recovery
- `RepoAdded`, triggers background code indexing

**PR & Review:**

- `PullRequestPublished`, PR opened by an agent
- `PullRequestStatusChanged`, merged/closed/opened/reopened; the signal pipeline triggers subscribe to (with optional status filter)
- `PrMerged`, narrow merge-only signal for notifications
- `ExternalPrDetected`, PR by a non-agent author found via polling

**Messaging:**

- `MessageReceived`, triggers desktop notifications
- `ChannelDeleted`, drives worktree GC for per-channel resources

**Ticketing / Task lifecycle** (vendor-neutral; replaced the old task/linear events):

- `TicketCreated`, `TicketStarted`, `TicketCompleted`, `TicketFailed`, `TicketCancelled`, `TicketStatusChanged`
- `TicketAssigned`, the sole event the dispatcher consumes
- `TicketReassigned`, `TicketDelegated`, `TicketCollaboratorAdded`, `TicketDetailsUpdated`

**Pipeline lifecycle:**

- `PipelineRunStarted`, `PipelineStepStarted`, `PipelineStepCompleted`, `PipelineStepFailed`, `PipelineRunCompleted`, `PipelineRunFailed`, `PipelineRunCancelled`

**Orchestration:**

- `OrchestrationProposed`, `OrchestrationApproved`, `OrchestrationRevised`, `OrchestrationExecutionStarted`, `OrchestrationCompleted`, `OrchestrationFailed`, `OrchestrationCancelled` — the one-goal-to-whole-team-plan lifecycle

**Memory:**

- `MemoryFactRecorded`, `MemoryFactUpdated`, `MemoryFactSuperseded`, `MemoryConflictDetected`, `MemoryBeliefHarmonized`, `MemoryConsolidated` — the memory-intelligence lifecycle

**Observability:**

- `ActivityLogged`, audit trail entry created
- `WorktreeMerged`, worktree merge completed
- `BudgetThresholdCrossed`, spend threshold exceeded

**Identity & membership:**

- `UserCreated`, a new user was provisioned (bootstrap, invite redemption, or OIDC JIT)
- `WorkspaceMemberAdded`, a user joined a workspace (invite redemption or admin add)
- `WorkspaceMemberRemoved`, a member was removed — live sessions of that user scoped to the workspace must re-check access immediately
- `WorkspaceMemberRoleChanged`, a member's role changed
- `UserDeviceRevoked`, a device credential was revoked — its session must terminate within seconds, not on next reconnect
- `WorkspaceInviteRedeemed`, an invite was redeemed (user exists, membership recorded, pairing begun)

**Calendar & Meetings:**

- `CalendarEventsRefreshed`, a calendar sync upserted events for a workspace
- `CalendarAuthExpired`, a connected account's OAuth refresh token is permanently invalid; drives the "reconnect calendar" notification (published once per disconnection episode)
- `MeetingStartingSoon`, a calendar event is starting within the configured lead window; drives the "meeting starting soon" notification
- `MeetingRecordingStopped`, a meeting recording finished and is ready to summarize; triggers the built-in `meeting_summary` pipeline

---

## Domain Services

### Shared kernel (`packages/cc_domain/lib/core/domain/services/`)

- **ActivityLogger**, builds and publishes `ActivityLogged` observability events.
- **MemoryAccessPolicy**, resolves and enforces an agent role's memory permission on a domain, throwing on write denial.
- **AgentMentionParser / MentionResolver**, parse/strip @-mention tokens and resolve them to a unique `Agent`.
- **AgentLoopGuard**, suppresses agent→agent dispatch loops (self-trigger + recent-participant guards); gated into `MessagingService.sendAndDispatch`.
- **cosineSimilarity / slugify**, pure helpers for embedding similarity and filesystem-safe slugs.

### Notable feature services

- **AgentDispatchService** (dispatch), launches an agent run: provisions isolated repos, builds the prompt, creates a run log, returns the live process-event stream.
- **AgentStreamProcessor** (messaging), consumes the process-event stream, persisting deltas, embedding content and emitting messaging events.
- **AgentQuestionService** (messaging), `AgentQuestionPort` impl that posts an inline `user_question` message and blocks the asking agent until the user answers.
- **TicketWorkflowService** (ticketing), pure-domain ticket lifecycle engine with optimistic-concurrency mutation chokepoint and workspace-isolation enforcement; never dispatches or opens channels itself.
- **StrandedTicketReconciler / OrphanRunReaper**, startup reconcilers (wired in `main.dart`) that recover tickets stuck in progress and reap dead run-log rows whose process died.
- **PipelineEngine** (pipelines), `PipelineEnginePort` impl orchestrating run execution: starts runs, schedules steps, persists state, handles routers/continue-on-fail and resumes in-flight runs after restart.
- **PipelineTriggerDispatcher** (pipelines), subscribes to domain events and auto-starts runs for each enabled matching trigger.
- **DownstreamPlanner / StateReducer / TemplateRenderer** (pipelines), pure helpers for skip-propagation, concurrent-write reduction and `{{...}}` placeholder substitution.
- **CostTracker** (agents), computes per-run token cost and persists it onto the run log.
- **BudgetEnforcementService** (agents), enforces per-scope monthly spend budgets, blocking invocations when exhausted and publishing `BudgetThresholdCrossed`.
- **DoctorService** (agents), runs environment diagnostics (sandbox backend, database, CLI tools, disk, network).
- **DefaultCodeIndexer** (code_graph), parses changed files with tree-sitter in worker isolates, ingests symbols/edges, prunes deletions, resolves cross-file references; degrades gracefully when natives are missing.
- **RepoWorkspaceProvisioner / WorktreeGcListener** (repos), provision per-channel CoW worktree roots and GC them when a unit ends.
- **DispatchReviewersService** (pr_review), `DispatchReviewersPort` impl that fans out PR review to matched reviewer agents.
- **ReviewerMatchingService** (pr_review), picks the best `Agent` for a desired specialist role label.
- **PrPollingService** (pr_review), polls GitHub for new external PRs and emits `ExternalPrDetected`.
- **TicketSyncService / TicketRemoteSyncHandler** (ticketing), pull remote tickets into the local mirror and mirror local state back, keeping the workflow service free of infrastructure.
- **CalendarSyncService / MeetingAlertScheduler** (calendar), `CalendarSyncService` periodically pulls each connected account's events into the local store (publishing `CalendarEventsRefreshed`) and lazily loads on-demand ranges; `MeetingAlertScheduler` scans per-minute for events inside the lead window and publishes `MeetingStartingSoon`, persisting `alertedAt` so an alert never fires twice.
- **MeetingTranscriptionService / MeetingDiarizationService** (meetings), `MeetingTranscriptionService` decodes rolling Whisper windows off the UI thread (silent-window skip); `MeetingDiarizationService` clusters the recording into individual speakers offline (sherpa-onnx) after the recording stops.
- **MeetingSummaryReconciler** (meetings), listens for the `meeting_summary` pipeline's terminal events and finalizes the meeting `processing → done`, falling back to the raw transcript when the agent produced no structured notes.

---

## Cross-Cutting

### AppNotification

A structured desktop notification payload with category, title, body and navigation route/channel. Mapped from domain events by `NotificationEventMapper`.

**Location:** `packages/cc_domain/lib/core/domain/notifications/notification_category.dart`

### NotificationCategory

Enumerates desktop notification types, each independently toggleable: `agentRunCompleted`, `pullRequestPublished`, `prMerged`, `newMessage`, `prMentioned`, `ticketAssigned`, `ticketStatusChanged`, `meetingStartsSoon`, `calendarAuthExpired`.

**Location:** `packages/cc_domain/lib/core/domain/notifications/notification_category.dart`

### NotificationSound

Built-in notification sounds bundled as MP3 assets under `assets/sounds/`, organized in groups for the settings UI.

**Location:** `packages/cc_domain/lib/core/domain/notifications/notification_sound.dart`

### NotificationEventMapper

Subscribes to `DomainEventBus` and maps domain events to `AppNotification` instances. The single place that decides which events produce user-visible notifications.

**Location:** `lib/core/notifications/notification_event_mapper.dart`

---

## MCP Bounded Context

MCP tools are Ref-free `McpTool` implementations in the **`cc_mcp`** package. They are hosted by the headless `cc_server`, which assembles one shared registry (`buildServerMcpRegistry` in `cc_server_core`) and serves it over JSON-RPC 2.0 (HTTP/SSE; a spawned CLI agent gets a derived `.mcp.json` pointing at the server's loopback MCP endpoint). Every client — desktop, web, external MCP clients (pi, Claude Code) and the built-in harness runtime — reaches the **same** registry through the server; the desktop's former in-process MCP stack was deleted with the thin-client migration. Tools receive their dependencies as typed constructor parameters (no `Ref` injection). The `mcp` feature under `lib/` is now just the settings/status UI.

**102 first-party tools are wired into the live registry today** (62 in `buildServerMcpRegistry`, 40 more registered post-boot as their services come up); the wider `cc_mcp` catalogue holds ~120 tool classes across 81 files. The full registry is advertised in `tools/list` with no discovery gating — external clients refuse to call tools absent from their cached list. External MCP servers are bridged in via `cc_mcp_client`.

### McpTool

The abstract base for an MCP tool: exposes `name`, `description` and `inputSchema` (definition) plus a `call()` handler and approval gating. Also defines `ToolDef`, `CallResult` / `CallResultContent` and `ApprovalPayload`.

**Location:** `packages/cc_domain/lib/features/mcp/domain/ports/mcp_tool_port.dart`

### McpToolRegistry / McpToolDispatcher

The registry keys all tools by name (lookup, definition listing, name enumeration). The dispatcher routes JSON-RPC requests to tools, applying channel-mode gating (`ModeToolGuard`) and destructive-action confirmation prompts.

**Location:** `packages/cc_domain/lib/features/mcp/domain/services/mcp_tool_registry.dart`, `packages/cc_mcp/lib/src/mcp_tool_dispatcher.dart`

### JsonRpcRequest / JsonRpcResponse / JsonRpcError / JsonRpcNotification

The four JSON-RPC 2.0 message shapes used by the MCP server transport.

**Location:** `packages/cc_domain/lib/src/jsonrpc/jsonrpc.dart`

**Tool families currently registered** (`buildServerMcpRegistry` + post-boot registers): newsfeed (`list_feeds`, `list_articles`, `get_article`, `set_article_read`, `set_article_saved`, `refresh_feeds`), tickets (read: `get_ticket`, `list_tickets`; typed writes: `create_ticket`, `update_ticket`, `assign_ticket`, `comment_on_ticket`, `close_ticket`, `link_tickets`, …), messaging (`list_channels`, `get_channel_messages`, `send_channel_message`, `get_channel_notes`, `update_channel_notes`, `todo_write`), workspaces/agents/repos (read: `list_workspaces`, `list_agents`, `list_repos`), memory (`search_memory`, `propose_fact`, `supersede_fact`, `propose_policy`, `list_policies`, `list_memory_domains`, `record_observation`, `get_my_notes`, `update_my_notes` and the memory-intelligence set `remember`, `consolidate_memory`, `harmonize_memory`, `list_memory_conflicts`), pipeline structured output (`submit_output`), governance (`create_goal`, `list_goals`, `update_goal_progress`, `create_approval`, `list_approvals`, `decide_approval`, `comment_approval`, `exit_plan_mode`, `agent_heartbeat`, `list_runtime_health`, `list_agent_presence`, `get_org_chart`, `create_work_product`, `save_work_product_revision`, `list_work_products`, `get_work_product`, `create_runtime_profile`, `list_runtime_profiles`), code graph (`search_code`, `code_symbol`, `code_callers`, `code_callees`, `code_impact`), skills (`install_skill`, `verify_skills`, `pin_skill`, `create_skill`, `list_skills`, `list_skill_updates`), plan tools (`create_playbook`, `run_playbook`), agent peer messaging & delegation (`send_to_agent`, `ask_agent`, `delegate_task`, `todo_read`, `consult_agent`), ticket writes (`create_ticket`, `update_ticket`, `assign_ticket`, `comment_on_ticket`, `close_ticket`, `link_tickets`), review studio (`set_cohort_summary`, `add_review_diagram`) and artifacts (`publish_artifact`, `revise_artifact`, `list_artifacts`, `get_artifact`). The review (`confirm_review_node`, `submit_reviewer_verdict`, `request_peer_review`, `dispatch_reviewers`, `finalize_review`) and orchestration (`propose_orchestration`) tools are registered post-boot once their server-side services exist. The broader `cc_mcp` catalogue additionally defines agent-lifecycle (`hire_agent`/`fire_agent`/`kill_agent`/`update_agent`), `start_ai_review`, `dismiss_review_node`, `propose_hire`, governance checkout (`checkout_task`/`release_task`), project-management and user-interaction (`ask_user_question`, `request_confirmation`) tools that are not wired into the live registry yet. Tools touching workspace-scoped data require `workspace_id`; only genuinely global tools (`list_workspaces`) are exempt. The **calendar** and **meetings** features are UI/desktop-only and are _not_ exposed over MCP.

- `submit_plan` — plan mode's output contract: emits a typed `PlanDocument` that opens in Plan Studio and posts a plan card into the conversation.
- `publish_artifact` / `revise_artifact` / `list_artifacts` / `get_artifact` — typed block documents (markdown / table / chart / mermaid / code / data, never HTML) stored as versioned work products and rendered natively in the client.

---

## Remote Control Bounded Context

The phone companion (`cc_remote`) pairs with a `cc_server` over a **brokered WebSocket relay** that carries end-to-end-sealed JSON-RPC frames, so the fleet can be followed remotely. The phone is a **lower-privilege principal** than a local agent: a default-deny tool policy and a per-session workspace binding keep an approved pairing from becoming full remote control. With the thin-client migration the transport/session/policy logic moved out of `lib/` into the RPC stack (`cc_host` sessions, `cc_server_core` relay + forwarding, `cc_rpc` transport and the `cc_remote` app); the `lib/` side is now just the pairing UI (`lib/features/remote_control/presentation/widgets/server_pairing_panel.dart`). Not exposed over MCP.

### PairingPayload / RemotePairingLifecycle

`PairingPayload` is the compact JSON encoded into the pairing QR's URL **fragment** (so the PWA host never sees it): the server's full `ConnectionDescriptor` (every known connection path plus the identity fingerprint the client TOFU-pins), the minted device id, a PSK (base64url) and a short expiry. The PWA (`cc_remote`) decodes it, persists a pairing record and strips the fragment. `RemotePairingLifecycle` owns pair/unpair/list on the server side. The PSK challenge/response crypto lives in `cc_rpc` (`remote_control_crypto.dart`).

**Location:** `packages/cc_domain/lib/features/remote_control/domain/services/pairing_payload.dart`, `remote_pairing_lifecycle.dart`; `packages/cc_rpc/lib/src/crypto/remote_control_crypto.dart`; `apps/cc_remote/lib/pairing/pairing_store.dart`

### RemoteRpcSession

One live server-side RPC session per connected phone. Pumps inbound JSON-RPC frames through the same server dispatcher every client uses and is **bound to exactly one workspace** — the sole source of `workspace_id` for that session's calls, so a phone bound to workspace A cannot reach workspace B by passing a foreign id (the same [RPC workspace binding](#clientserver-architecture-bounded-context) invariant every client obeys).

**Location:** `packages/cc_host/lib/src/session/remote_rpc_session.dart`

### RemoteToolPolicy

A **default-deny** allow-list governing which tools a paired phone may invoke: `readOnly` (lists/detail reads) and `mutating` (a small set of local-only writes — a message, a ticket update — that spend no LLM budget, spawn no process, touch no external system). Denied by default: agent lifecycle (`hire_agent`/`fire_agent`/`kill_agent`/`consult_agent`), review (`start_ai_review`, `publish_review_to_github`) and `create_workspace`. A per-_principal_ capability gate, orthogonal to the per-call `workspace_id` scoping.

**Location:** `packages/cc_host/lib/src/policy/remote_tool_policy.dart`

### RemoteRateLimiter / RemoteEventForwarder

`RemoteRateLimiter` is a per-session sliding-window limiter (total calls/min and a tighter sub-cap on mutating verbs), a flood/abuse guard for an authenticated-but-untrusted client. `RemoteEventForwarder` pushes live workspace-scoped updates (messages received, ticket assigned/status/reassigned) to one phone as id-less JSON-RPC notifications, filtered to the session's bound workspace so a phone never sees another workspace's events.

**Location:** `packages/cc_host/lib/src/session/remote_rate_limiter.dart`, `packages/cc_server_core/lib/src/remote_event_forwarder.dart`

### The relay: RemoteRelayHost / RelayClientChannel / cc_signaling_server

The live transport is a **broker WebSocket relay**, not a WebRTC data channel (no `RTCPeerConnection`/ICE consumer exists). The signaling broker (`apps/cc_signaling_server`) is a **dumb, stateless `wss://` relay** hosting N-capacity invite-gated rooms: it carries only opaque frames, never app data or the PSK and never interprets them. The server joins one room as its owner (`RemoteRelayHost`); every client — desktop, web, phone — joins with an HMAC admission token via `RelayClientChannel` and frames relay as opaque E2E-sealed payloads (`RelayFrameCrypto` / `ChunkedRelaySession`). `RemoteRpcChannelPort` (in `cc_rpc`) is the transport abstraction a session reads framed JSON from.

**Location:** `apps/cc_signaling_server/lib/cc_signaling_server.dart`, `packages/cc_server_core/lib/src/relay/remote_relay_host.dart` (+ `relay_remote_transport.dart`, `paired_peer_auth.dart`), `packages/cc_rpc/lib/src/channel/relay_client_channel.dart` (+ `crypto/relay_frame_crypto.dart`), `packages/cc_rpc/lib/src/channel/remote_rpc_channel_port.dart`

---

## Client/Server Architecture Bounded Context

Control Center is a **thin-client architecture**. No client opens the database — a `cc_server` process owns the data and serves it over WebSocket RPC. Every client is a renderer over that one RPC connection. The server half is pure-Dart (no Flutter engine); the client half is Flutter.

### ServerConnectionMode

How the desktop reaches its `cc_server`: `local` (spawn and supervise a `cc_server` on this machine that owns the DB) or `remote` (dial a `cc_server` running elsewhere). The web client is always forced to `remote` (a browser cannot spawn a subprocess).

**Location:** `lib/core/server/server_connection_config.dart`

### ServerConnectionConfig / ServerConnectionStore

The desktop's persisted server-connection choice (non-secret fields only: mode, remote URL, device id). The pairing key is intentionally not held here — it lives in the OS keychain, read separately. `ServerConnectionStore` reads/writes the config across `AppPreferences` (non-secret) and `SecureStore` (the PSK), shared by the boot-time resolver and the settings notifier.

**Location:** `lib/core/server/server_connection_config.dart`

### cc_server

A **headless server** — a pure-Dart `dart build cli` binary (no Flutter engine) under `apps/cc_server`. Owns the `cc_persistence` databases (the global `global.db` plus one per-workspace file, handed out by `WorkspaceDatabaseManager`), serves repo-RPC over a WebSocket `LocalRpcServer` and runs the background services (pipeline reconcilers, MCP server, orchestration listener). Subcommands: default (run until SIGINT/SIGTERM), `pair` (provision a device + PSK so a thin client can connect), `calendar connect` (device-code OAuth for a Google account).

**Location:** `apps/cc_server/`

### CcServerProcess / CcServerEndpoint

`CcServerProcess` spawns and supervises the `cc_server` binary as a child process on the desktop (LOCAL mode), exposing the loopback endpoint it bound. A parent-death watchdog (stdin-pipe EOF) ensures the server shuts down instead of orphaning and holding the DB open. `CcServerEndpoint` is the loopback `host:port` the server is listening on, exposing the RPC URI (`ws://host:port/rpc`).

**Location:** `lib/core/server/cc_server_process.dart`

### ServerBackend / ThinClientBackend

`resolveServerBackend` runs before the `ProviderContainer` exists and returns a `ServerBackend` (the connected `RemoteRpcClient` plus, for LOCAL, the supervised `CcServerProcess`). `ThinClientBackend` is the LOCAL-mode handle: a spawned `cc_server` + loopback RPC client + media-proxy config. The resulting client overrides `rpcClientProvider`, so the whole UI reads/writes through the server.

**Location:** `lib/bootstrap/server_backend.dart`, `lib/bootstrap/thin_client_boot.dart`

### RemoteRpcClient

The transport-agnostic JSON-RPC client (`cc_rpc`) that every thin client (desktop local/remote, web, phone) uses to talk to its `cc_server`. Dialed over WSS (remote/web) or loopback (local); on the phone it rides the brokered relay channel (`RelayClientChannel`).

**Location:** `packages/cc_rpc/lib/src/client/remote_rpc_client.dart`

### LocalRpcServer

The server-side RPC entrypoint (`cc_host`): accepts a transport (WSS socket or in-process channel), authenticates the session against a paired-device PSK, binds it to a workspace and dispatches repo-op + subscription frames to the server's repository catalog. Embeds in both the headless `cc_server` binary and (for the in-process path) the desktop.

**Location:** `packages/cc_host/`, composed in `packages/cc_server_core/`

### InProcessRpcChannel

An in-memory back-to-back RPC channel (no serialization, no sockets): the desktop-LOCAL "be your own server" data path and the protocol-conformance test harness that drives the full repo-RPC + subscription surface and asserts parity with direct calls.

**Location:** `packages/cc_rpc/lib/src/channel/in_process_rpc_channel.dart`

### RPC workspace binding

Every server session is bound to exactly one workspace (the sole source of `workspace_id` for that session's calls). A remote client bound to workspace A cannot reach workspace B by passing a foreign id — the same [workspace-isolation](#core-domain-entities-shared-kernel) invariant the rest of the product enforces, enforced at the RPC layer.

### MediaProxyConfig

Routes remote media (avatars, feed images, PR-body images/video) through the connected server's `/proxy/media` endpoint, so a thin client never fetches an upstream host directly. The desktop in LOCAL mode proxies through its loopback server; the web build's per-request CSP is stamped by a Cloudflare Worker from a non-sensitive origin cookie so only the paired server's origin is allowed.

**Location:** `lib/shared/widgets/media_proxy_scope.dart`

### Workspace members (the pub workspace)

The repository is a single-resolved-lockfile Dart workspace of twenty members (5 apps + 15 packages, plus the root app). The **apps** are `cc_server` (headless server binary), `cc_worker` (headless fleet executor binary), `cc_remote` (phone PWA thin client), `cc_signaling_server` (stateless relay broker) and `cc_gallery` (Widgetbook catalogue); the root `control_center` app is the desktop+web thin client. The **packages** are `cc_ui` (design system), `cc_domain` (pure-Dart shared kernel: entities/value-objects/ports/events/services + every feature's `domain/`), `cc_harness` (web-safe built-in agent-loop kernel) + `cc_harness_runtime` (its VM-only batteries: providers, OAuth/PKCE, tool set), `cc_rpc` (client transports), `cc_host` (server kernel + presence hub), `cc_data` (remote repositories), `cc_persistence` (server-side Drift/SQLite), `cc_server_core` (app-server composition: repo-RPC catalog + MCP registry + LocalRpcServer + identity/presence/fleet/evals runtime), `cc_infra` (server-side VM-only adapters + fleet + tunnels), `cc_mcp` (MCP tool surface), `cc_mcp_client` (bridges external MCP servers in), `cc_markdown` (in-repo typed-AST markdown engine + native mermaid), `cc_natives` (FFI leaf: rift/fff/tree-sitter/watcher/pty/audio/ML) and `system_audio_capture` (audio loopback plugin).

## Database Conventions

- Persistence is **split by workspace** and owned entirely by `cc_persistence`; only `cc_server` opens a database — every client reads/writes over RPC. There is no single app database: **`GlobalDatabase`** (`<dataDir>/global.db`, schema v1, 11 tables — the workspaces registry, `users`, `user_preferences`, `paired_devices`, `rss_feeds`/`rss_articles`, the fleet queue `workers`/`jobs`/`placement_log`, `workspace_routes`, `server_meta`) and one **`WorkspaceDatabase`** file per workspace (`<dataDir>/workspaces/<workspaceId>.db`, schema v2 — squashed v1 baseline plus one appended 1→2 step — holding everything else, including `repos`). Table definitions live in `packages/cc_persistence/lib/database/tables/` (Drift); DAOs in `packages/cc_persistence/lib/database/daos/`.
- **`WorkspaceDatabaseManager`** hands out workspace files: `manager.of(workspaceId)` is synchronous over a `LazyDatabase` (nothing touches disk until the first query). Repositories hold the manager and resolve per call — never cache a per-workspace DAO in a field.
- **Isolation is structural, not a WHERE-clause convention.** A `WorkspaceDatabase` does not declare another workspace's tables, so a cross-workspace read is a compile error; deleting a workspace is unlinking a file. `workspaceId` columns remain on workspace tables as defense-in-depth and to keep the sync triggers/FTS indexes unchanged, but they are not the isolation mechanism. The only way to span workspaces is **`CrossWorkspaceQueries`** (`fanOut` / `fanOutKeyed` / `forEachWorkspace` / `mergeStreams` / `topN`), whose call sites are the documented inventory of legitimately global queries. Pre-auth lookups (invite code hash, webhook token, deep link) resolve their workspace from the global **`workspace_routes`** index — a miss is a not-found, with no scan fallback.
- **Backup is a directory, not a file:** `backups/<ts>/{manifest.json, global.db, workspaces/<id>.db}`, each written with `VACUUM INTO` (safe on a live WAL). `workspace.export` / `workspace.import` hand a single workspace around as one file.
- Domain entities are pure Dart, separate from Drift table classes; entity ⇔ table mapping happens in repository adapters via mappers.
- Foreign keys use `CASCADE` or `SET NULL` as appropriate (`PRAGMA foreign_keys=ON`, WAL journal mode, `quick_check` per workspace file on first touch).
- **Full-text search** via FTS5 external-content virtual tables (`memory_facts_fts`, `code_symbols_fts`, `channel_messages_fts`) with triggers reinstalled per workspace file in `beforeOpen`.
- **Vector embeddings** via the `sqlite_vector` extension (FLOAT32, dimension 384) on `memory_facts.embedding` and `code_symbols.embedding`, initialized per workspace file; degrades gracefully to FTS-only when the extension is unavailable. Hybrid search combines BM25 + vector similarity (RRF).
