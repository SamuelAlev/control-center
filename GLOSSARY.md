# Control Center — Ubiquitous Language Glossary

This document defines the core domain terms used across the Control Center codebase. It serves as the single source of truth for naming conventions and domain concepts.

---

## Core Domain Entities (Shared Kernel)

Entities in `lib/core/domain/` are shared across 3+ features.

### Agent
An AI worker with an identity, skill set, role, persona, capabilities, and optional reporting hierarchy. Agents are instantiated from `AGENTS.md` files on disk and are the primary actors in the system. Each agent belongs to exactly one workspace (`workspaceId` is non-null — a hard isolation invariant).

**Key attributes:** `id`, `name`, `title`, `agentMdPath`, `workspaceId`, `reportsTo`, `skills` (AgentSkills), `persona`, `systemPrompt`, `adapterId`, `modelId`, `strictMode`, `effort` (AgentEffort), `contextSize`, `capabilities` (AgentCapabilities), `role` (AgentRole), `monthlyBudgetCents`, `createdAt`

**Location:** `lib/core/domain/entities/agent.dart`

### Workspace
A user-named, soft-deletable container that groups agents and repositories — the top-level isolation tenant. Each agent, channel, ticket, and memory fact is scoped to a single workspace.

**Key attributes:** `id`, `name`, `logoPath`, `reviewConcurrency`, `createdAt`, `updatedAt`, `deletedAt`

**Location:** `lib/core/domain/entities/workspace.dart`

### Repo
A Git repository registered in the system. Repos are global (managed in Settings, not workspace-specific) but can be linked to workspaces through the `WorkspaceRepo` join table. A repo may or may not have an associated GitHub remote.

**Key attributes:** `id`, `name`, `path`, `githubOwner`, `githubRepoName`, `createdAt`, `updatedAt`

**Location:** `lib/core/domain/entities/repo.dart`

### GitRepoInfo
Immutable metadata about a locally-checked-out Git repository, parsed by inspecting a repo path and its remote origin URL.

**Key attributes:** `path`, `owner`, `repoName`, `branch`

**Location:** `lib/core/domain/entities/git_repo_info.dart`

### IsolatedRepo
A workspace-scoped copy-on-write worktree of a registered repo, provisioned per conversation and checked out on its own branch. Backed by the bundled `rift` FFI (with a plain `git worktree` fallback) so agents never mutate the source checkout.

**Key attributes:** `id`, `workspaceId`, `channelId`, `repoId`, `path`, `branch`, `backend` (RepoIsolationBackend), `sourcePath`, `ticketId`, `createdAt`

**Location:** `lib/core/domain/entities/isolated_repo.dart`

### AgentRunLog
An immutable record of a single agent execution. Tracks token cost, liveness classification, error family, retry lineage, and process metadata. Each run is tied to an agent and workspace, and optionally to a conversation/channel/ticket.

**Key attributes:** `id`, `agentId`, `workspaceId`, `conversationId`, `ticketId`, `channelId`, `startedAt`, `completedAt`, `status` (RunStatus), `summary`, `adapter`, `pid`, `logPath`, `cost` (RunCost), `liveness` (RunLiveness), `errorFamily` (RunErrorFamily), `lastOutputAt`, `continuationSummary`, `contextSnapshotJson`, `retry` (RetryMeta)

**Location:** `lib/core/domain/entities/agent_run_log.dart`

### ReviewChannelAssociation
A join entity that decouples PR review from messaging. A review channel is a regular `group` channel — the review context is established by this association record, not by the channel type. This separation lets channels own messages independently of review lifecycle.

**Key attributes:** `id`, `channelId`, `workspaceId`, `prNodeId`, `prNumber`, `repoFullName`, `status` (ReviewChannelStatus), `createdAt`, `updatedAt`

**Location:** `lib/core/domain/entities/review_channel_association.dart`

---

## Messaging Bounded Context

### Channel
A messaging container scoped to a workspace. A channel is either a direct message (`isDm`, two participants) or a group. Each channel carries a `ConversationMode` that gates which tools and sandbox policies apply.

**Key attributes:** `id`, `name`, `isDm`, `workspaceId`, `mode` (ConversationMode), `createdAt`, `updatedAt`

**Location:** `lib/features/messaging/domain/entities/channel.dart`

### ChannelMessage
A single message within a channel. Messages carry metadata (mentions, plan status, stream completion flags), support threading and compaction, and are typed by `ChannelMessageType` to control rendering.

**Key attributes:** `id`, `channelId`, `senderId`, `senderType` (ChannelSenderType), `content`, `messageType` (ChannelMessageType), `metadata`, `parentMessageId`, `compacted`, `createdAt`

**Location:** `lib/core/domain/entities/channel_message.dart` (shared kernel — consumed by messaging, pr_review, pipelines, mcp)

### ChannelParticipant
A membership record linking an agent (or the human user, via the sentinel `'user'`) to a channel with a role.

**Key attributes:** `id`, `channelId`, `agentId` (or `'user'`), `role`, `joinedAt`

**Location:** `lib/features/messaging/domain/entities/channel_participant.dart`

### ChannelMessageType
Rendering type enum for messages: `text`, `system`, `ticketCard`, `thinking`, `reviewNode`, `hireProposal`, `reviewSummary`, `plan`, `userQuestion`. Controls how the UI renders each message.

### ChannelSenderType
Enum identifying who sent a message: `user` (human) or `agent` (AI).

### MessageMention
A resolved @mention stored in a message's metadata. Contains the mentioned agent's ID, the raw mention text, and how it was resolved.

**Location:** `lib/core/domain/entities/channel_message.dart`

### ThinkingEvent
A value object for a single structured entry (reasoning, tool call/result, error, sandbox violation) in an agent's thinking transcript. Grouped into UI rows that pair tool calls with their results. (`MentionContext` and `AgentProcessEvent` moved to the Dispatch context — see below.)

**Location:** `lib/core/domain/value_objects/thinking_event.dart` (shared kernel)

---

## Dispatch Bounded Context

Extracted from messaging so pipelines, ticketing, and sandboxing can depend on agent dispatch without importing the chat feature. Also absorbed the former `agent_modes` prompt library. `MessagingService.sendAndDispatch` (in messaging) is the chat-side caller that drives this feature.

### AgentDispatchService
Launches an agent run: provisions isolated repos, builds the prompt, creates a run log, and returns the live process-event stream. Owns run finalization (`completeRun` / `failRun` / `stopRun`).

**Location:** `lib/features/dispatch/data/services/agent_dispatch_service.dart`

### AgentProcessEvent
An event emitted by an agent CLI process (thinking, text, tool call/result, error, sandbox violation, debug, done) with a wall-clock timestamp. The unit of the live agent output stream.

**Key attributes:** `type` (AgentProcessEventType), `content`, `metadata`, `timestamp`

**Location:** `lib/features/dispatch/domain/entities/agent_process_event.dart`

### DispatchAgentUseCase / BuildAgentPromptUseCase
`DispatchAgentUseCase` resolves the effective prompt, CLI name, and mode for a run. `BuildAgentPromptUseCase` assembles the agent's prompt from the mode prompts plus conversation context (`BuildConversationContextUseCase`) and memory context (`BuildMemoryContextUseCase`).

**Location:** `lib/features/dispatch/domain/usecases/`

### PromptBuilder / mode prompts
The conversation-mode prompt library (chat / plan / review system-prompt blocks, role personas, protocol docs) — formerly the `agent_modes` feature, folded into dispatch.

**Location:** `lib/features/dispatch/domain/prompts/`

### MentionContext / MentionRosterEntry
`MentionContext` describes who summoned an agent plus the full channel roster available for mention resolution. `MentionRosterEntry` is one roster row (agent ID, name, whether top-level).

**Location:** `lib/features/dispatch/domain/value_objects/mention_context.dart`

---

## PR Review Bounded Context

### PullRequest
A GitHub pull request with state, author, diff metrics, requested reviewers/assignees, reactions, and rolled-up checks status.

**Key attributes:** `id`, `number`, `title`, `body`, `state` (PrState), `isDraft`, `author` (PrUser), `repoFullName`, `htmlUrl`, `nodeId`, `headSha`, `baseRef`, `headRef`, `requestedReviewers`, `assignees`, `mergedAt`, `changedFiles`, `additions`, `deletions`, `commitsCount`, `checksStatus` (PrChecksStatus), `createdAt`, `updatedAt`

**Location:** `lib/features/pr_review/domain/entities/pull_request.dart`

### EnrichedPullRequest
Sealed supertype pairing a `PullRequest` with its source `Repo` and categorizing it into `PriorityReview`, `StalePr`, or `NormalPr`.

**Location:** `lib/features/pr_review/domain/entities/enriched_pull_request.dart`

### RepoPullRequests
Bundles a `Repo` with the list of pull requests belonging to it.

**Location:** `lib/features/pr_review/domain/entities/enriched_pull_request.dart`

### PrFile
A changed file in a PR with status, line counts, patch text, and the viewer's viewed state.

**Key attributes:** `filename`, `status` (PrFileStatus), `additions`, `deletions`, `patch`, `previousFilename`, `viewerViewedState` (PrFileViewedState)

**Location:** `lib/features/pr_review/domain/entities/pr_file.dart`

### FileChange
A lightweight file-change summary (path + addition/deletion counts + new/deleted flags), used where the full patch isn't needed.

**Location:** `lib/features/pr_review/domain/entities/file_change.dart`

### PrCommit
A commit within a pull request: sha, message, author, date.

**Location:** `lib/features/pr_review/domain/entities/pr_commit.dart`

### CheckRun
A CI check run on a PR's head commit with status, conclusion, output, and parent workflow info.

**Key attributes:** `name`, `status` (CheckRunStatus), `conclusion` (CheckRunConclusion), `htmlUrl`, `completedAt`, `output`, `workflowName`, `checkSuiteId`

**Location:** `lib/features/pr_review/domain/entities/check_run.dart`

### IssueComment
A top-level (non-inline) PR/issue comment with author and reactions.

**Location:** `lib/features/pr_review/domain/entities/issue_comment.dart`

### PrCodeReviewComment
An inline code review comment anchored to a file path/line/diff hunk, with threading via `inReplyToId` and reactions.

**Key attributes:** `id`, `body`, `user` (PrUser), `path`, `position`, `side`, `inReplyToId`, `startLine`, `line`, `diffHunk`, `reactions`, `createdAt`

**Location:** `lib/features/pr_review/domain/entities/pr_code_review_comment.dart`

### PrInlineThread / PrInlineEntry
`PrInlineThread` is a locally-authored inline comment or suggestion thread anchored to a file line/char range, tracking resolved state and GitHub sync state. `PrInlineEntry` is a single comment within that thread.

**Key attributes (thread):** `id`, `filePath`, `line`, `lineEnd`, `side`, `kind` (PrInlineThreadKind), `originalCode`, `suggestedCode`, `entries`, `resolved`, `syncState` (PrInlineSyncState), `serverId`

**Location:** `lib/features/pr_review/domain/entities/pr_inline_thread.dart`

### PrReviewSubmission
A submitted PR review verdict (`approved` / `changesRequested` / `commented` / `pending`) with author and body.

**Location:** `lib/features/pr_review/domain/entities/pr_review_submission.dart`

### PrUser
A minimal GitHub user reference: `login` + `avatarUrl`.

**Location:** `lib/features/pr_review/domain/entities/pr_user.dart`

### ReactionGroup
A grouped emoji reaction: content, emoji, count, whether the user reacted, and reacting usernames.

**Location:** `lib/features/pr_review/domain/entities/reaction_group.dart`

### GifResult
A GIF search result (e.g. for message reactions) with full + preview URLs and dimensions.

**Location:** `lib/features/pr_review/domain/entities/gif_result.dart`

### PrGeneration
A workspace-scoped generated PR draft (not yet published to GitHub) with a sealed lifecycle status (`Draft` / `Published` / `Created`). Represents work-in-progress that agents prepare before publishing.

**Location:** `lib/features/pr_review/domain/entities/pr_generation.dart`

### Review value objects
- **ReviewNodePayload** — typed view over a `reviewNode` message's metadata (finding kind, P0–P3 priority, lifecycle status, file/line anchor, confidence, confirmations). Rejects malformed payloads. `lib/features/pr_review/domain/value_objects/review_node_payload.dart`
- **ReviewVerdict** — per-PR ship/hold/block aggregate (overall call, confidence, explanation, per-priority counts) computed from review-node findings. `lib/features/pr_review/domain/value_objects/review_verdict.dart`
- **ReviewDisagreement** — a detected disagreement between two reviewer agents on the same file/line finding, plus the detector that finds them. `lib/features/pr_review/domain/value_objects/review_disagreement.dart`
- **DiffOverflowMode** — enum (`wrap`, `scroll`) controlling how the diff viewer renders over-wide lines. `lib/features/pr_review/domain/value_objects/diff_overflow_mode.dart`

---

## Ticketing Bounded Context

Vendor-agnostic work tracking. This feature absorbed the former `tasks` feature — `Ticket` is now the single unit-of-work aggregate.

### Ticket
The unit-of-work aggregate: a mirror of an optional remote provider issue plus a Control-Center orchestration overlay. Carries assignment, pipeline coupling, an execution lock, and collaborators. Supports parent/child hierarchy.

**Key attributes:** `id`, `workspaceId`, `provider` (TicketProvider), `externalKey`, `url`, `title`, `description`, `priority` (TicketPriority), `labels`, `status` (TicketStatus), `rawStatus`, `parentTicketId`, `projectId`, `assignedAgentId`, `assignedTeamId`, `delegatedByAgentId`, `channelId`, `mode` (ConversationMode), `pipelineRunId`, `pipelineStepId`, `expectedOutputSchema`, `outputJson`, `errorMessage`, `linkedPrIds`, `metadata`, `originKind` (TicketOriginKind), `checkoutRunId`, `executionLockedAt`, `checkoutAgentId`, `version`, `collaborators`, lifecycle timestamps

**Location:** `lib/features/ticketing/domain/entities/ticket.dart`

### TicketCollaborator
A Control-Center participant (agent or the `'user'` sentinel) invited to collaborate on a ticket with a role.

**Key attributes:** `id`, `ticketId`, `agentId` (or user sentinel), `role` (TicketCollaboratorRole), `joinedAt`

**Location:** `lib/features/ticketing/domain/entities/ticket_collaborator.dart`

### TicketLink
A directional dependency edge between two tickets (`blocks` / `relatesTo` / `duplicateOf`), with derived per-subject relation kinds.

**Key attributes:** `id`, `workspaceId`, `sourceTicketId`, `targetTicketId`, `type` (TicketLinkType), `createdAt`

**Location:** `lib/features/ticketing/domain/entities/ticket_link.dart`

### Project
A workspace-scoped grouping of tickets toward a shared goal. Control-Center-only — never synced to a remote provider.

**Key attributes:** `id`, `workspaceId`, `name`, `description`, `color` (ProjectColor), `status` (ProjectStatus), `createdAt`, `updatedAt`

**Location:** `lib/features/ticketing/domain/entities/project.dart`

### Ticketing enums
`TicketStatus` (open, in_progress, blocked, done, cancelled, failed …), `TicketPriority`, `TicketProvider` (local, linear; jira/clickup stubbed), `TicketLinkType`, `TicketOriginKind`, `TicketCollaboratorRole`, `ProjectStatus` (active, completed, archived), `ProjectColor`.

---

## Pipeline Bounded Context

DAG-based workflow orchestration. Templates live in the DB; step bodies are executable closures resolved from a registry at runtime.

### PipelineDefinition
A workspace-scoped declarative DAG of steps with declared inputs and versioning.

**Key attributes:** `templateId`, `workspaceId`, `name`, `description`, `steps` (List&lt;PipelineStepDefinition&gt;), `inputs` (List&lt;PipelineInput&gt;), `isBuiltIn`, `isEnabled`, `version`

**Location:** `lib/features/pipelines/domain/entities/pipeline_definition.dart`

### PipelineStepDefinition
A node in the pipeline graph with a kind, body key, trigger edges, join wait-list, per-node config, and canvas coordinates.

**Key attributes:** `id`, `kind` (StepKind), `bodyKey`, `triggers` (List&lt;StepTrigger&gt;), `waitForStepIds`, `config` (PipelineNodeConfig), `x`, `y`

**Location:** `lib/features/pipelines/domain/entities/pipeline_step_definition.dart`

### PipelineNodeConfig
Per-node configuration carried inside a step definition: prompt/script/agent/team, input/output keys, output schema, reducer, retry policy, continue-on-fail, timeout, dispatch mode, extras.

**Location:** `lib/features/pipelines/domain/entities/pipeline_node_config.dart`

### StepRetryPolicy
Retry behaviour for a failing node body — `maxAttempts`, `backoff` (linear/exponential), `initialDelayMs` — computing per-attempt backoff delays.

**Location:** `lib/features/pipelines/domain/entities/pipeline_node_config.dart`

### PipelineInput
A single declared input field of a pipeline definition, rendered as a form control on manual runs.

**Key attributes:** `key`, `label`, `type` (PipelineInputType), `required`, `defaultValue`, `helpText`, `placeholder`, `options`

**Location:** `lib/features/pipelines/domain/entities/pipeline_input.dart`

### PipelineRun
A single persisted, resumable execution of a pipeline template with a mutable state bag, trigger info, cost/token totals, and parent-run linkage (for sub-pipelines).

**Key attributes:** `id`, `templateId`, `workspaceId`, `status` (PipelineRunStatus), `state` (Map), `triggerEventType`, `triggerPayload`, `dedupKey`, `startedAt`, `finishedAt`, `errorMessage`, `parentPipelineRunId`, `parentStepId`, `templateVersion`, `totalCostCents`, `totalTokens`, `dryRun`

**Location:** `lib/features/pipelines/domain/entities/pipeline_run.dart`

### PipelineStepRun
A single persisted, resumable step execution within a run, with branch index, attempt count, and I/O JSON.

**Key attributes:** `id`, `pipelineRunId`, `stepId`, `status` (PipelineStepStatus), `inputJson`, `outputJson`, `errorMessage`, `branchIndex`, `attemptCount`, `startedAt`, `finishedAt`

**Location:** `lib/features/pipelines/domain/entities/pipeline_step_run.dart`

### PipelineTrigger
A workspace-scoped, default-off declarative trigger that auto-starts a pipeline on a domain event, schedule (cron), or manual run, with a payload match filter.

**Key attributes:** `id`, `eventType`, `templateId`, `workspaceId`, `enabled`, `cronExpression`, `match` (Map), `lastFiredAt`, `createdAt`

**Location:** `lib/features/pipelines/domain/entities/pipeline_trigger.dart`

### StepResult
What a step body returns to the engine: `ok` / route / suspend-until-event / suspend-until-tasks / terminal / failed, plus state mutations.

**Location:** `lib/features/pipelines/domain/entities/step_result.dart`

### StepTrigger
Describes when a step fires relative to its source steps, with an optional `routeKey` for conditional (router) edges.

**Location:** `lib/features/pipelines/domain/entities/step_trigger.dart`

### Pipeline enums
`StepKind` (`trigger`, `promptAgent`, `bashScript`, `dispatchReviewers`, router/conditional, join, …), `PipelineRunStatus`, `PipelineStepStatus`, `PipelineInputType`.

---

## Code Graph Bounded Context

Native code indexing (tree-sitter) into a symbol/edge graph, keyed by `(workspaceId, repoId)` because a repo can be checked out on different branches in different workspaces. Powers `search_code` and the code-relationship MCP tools.

### CodeSymbol
A code symbol (function, class, method, field, …) extracted from source, content-addressed and workspace+repo scoped.

**Key attributes:** `id`, `workspaceId`, `repoId`, `kind` (CodeSymbolKind), `name`, `qualifiedName`, `filePath`, `language`, `startLine`, `endLine`, `signature`, `docstring`, `parentName`

**Location:** `lib/features/code_graph/domain/entities/code_symbol.dart`

### CodeEdge
A directed relationship between code symbols (call/import/extends/…), workspace+repo scoped, with an optional resolved target.

**Key attributes:** `id`, `workspaceId`, `repoId`, `sourceSymbolId`, `sourceFilePath`, `kind` (CodeEdgeKind), `targetSymbolId`, `targetName`, `metadata`

**Location:** `lib/features/code_graph/domain/entities/code_edge.dart`

### CodeSubgraph
The result of an impact-radius BFS traversal: the root, reachable symbols, edges among them, and each symbol's depth.

**Key attributes:** `root` (CodeSymbol?), `nodes`, `edges`, `depthById`

**Location:** `lib/features/code_graph/domain/entities/code_subgraph.dart`

### CodeSymbolKind / CodeEdgeKind
Enums of symbol kinds (function, method, class, field, enum, constructor, getter, setter, typedef, extension, mixin, variable) and edge kinds (calls, imports, extends, implements, mixesIn, references). Persisted in `code_symbols.kind` / `code_edges.kind`.

**Location:** `lib/core/domain/value_objects/code_symbol_kind.dart`, `lib/core/domain/value_objects/code_edge_kind.dart`

---

## Memory Subdomain

### MemoryFact
A semantic memory unit scoped to a workspace. Facts carry content, topic, domain, confidence, provenance, optional embeddings for vector search, and FTS integration. Facts can be superseded by newer facts.

**Key attributes:** `id`, `workspaceId`, `domain`, `topic`, `content`, `sourceObservationIds`, `confidence`, `supersededBy`, `authoredByAgentId`, `authoredByRole` (AgentRole), `createdAt`, `updatedAt`

**Location:** `lib/core/domain/entities/memory_fact.dart`

### MemoryPolicy
A normative rule derived from facts, optionally gated to a required role, that can be active or inactive. Scoped to workspace + domain.

**Key attributes:** `id`, `workspaceId`, `domain`, `rule`, `sourceFactIds`, `requiredRole` (AgentRole), `active`, `createdAt`, `updatedAt`

**Location:** `lib/core/domain/entities/memory_policy.dart`

### MemoryDomain
A workspace-scoped named domain that groups facts and policies (e.g. "security", "conventions", "api-design"), recording who created it.

**Key attributes:** `id`, `workspaceId`, `name`, `label`, `description`, `createdAt`, `createdByRole`

**Location:** `lib/features/memory/domain/entities/memory_domain.dart`

### AgentWorkingMemory
A per-agent free-text working memory scratchpad scoped to a workspace. Holds transient state that persists across runs.

**Key attributes:** `id`, `workspaceId`, `agentId`, `content`, `updatedAt`

**Location:** `lib/core/domain/entities/agent_working_memory.dart`

### MemoryAccessGrant
Grants a given agent role a permission level (`MemoryPermission`) over a named memory domain within a workspace.

**Key attributes:** `workspaceId`, `agentRole` (AgentRole), `memoryDomain`, `permission` (MemoryPermission)

**Location:** `lib/core/domain/entities/memory_access_grant.dart`

---

## Analytics Bounded Context

### AgentDailyStats
Per-day per-agent metrics: runs completed/errored, run duration, PRs created/merged, reviews, blocking comments, lines added/deleted, XP.

**Location:** `lib/features/analytics/domain/entities/agent_daily_stats.dart`

### AgentScorecard
Aggregated lifetime scorecard for an agent: level, XP progress, success rate, totals, current streaks, achievements.

**Location:** `lib/features/analytics/domain/entities/agent_scorecard.dart`

### Achievement
A badge earned by an agent for reaching a milestone (`badgeKey`, `unlockedAt`, `metadata`).

**Location:** `lib/features/analytics/domain/entities/achievement.dart`

### Streak
Consecutive activity of a given type for an agent, with current and best counts.

**Location:** `lib/features/analytics/domain/entities/streak.dart`

### UserBadge / UserBadgeCategory
`UserBadge` is the user's tiered progress within a badge category (derives current `BadgeTier` and progress-to-next from a count). `UserBadgeCategory` defines one category (icon, unit, action copy, tier thresholds).

**Location:** `lib/features/analytics/domain/entities/user_badge.dart`

### LeaderboardEntry
A single ranked entry in the agent leaderboard (`agentId`, `agentName`, `score`, `rank`).

**Location:** `lib/features/analytics/domain/entities/leaderboard_entry.dart`

### WorkspaceHealth
Composite health metrics for a workspace: overall score plus activity/throughput/review/success sub-scores and supporting counts.

**Location:** `lib/features/analytics/domain/entities/workspace_health.dart`

---

## Newsfeed Bounded Context

### RssFeed
A registered RSS or Atom feed with fetch state, custom user-agent, and last-error tracking.

**Key attributes:** `id`, `name`, `url`, `description`, `iconUrl`, `userAgent`, `enabled`, `lastFetchedAt`, `lastError`, `createdAt`, `updatedAt`

**Location:** `lib/features/newsfeed/domain/entities/rss_feed.dart`

### RssArticle
A single article from a feed with read/saved state and an effective publish timestamp.

**Key attributes:** `id`, `feedId`, `guid`, `title`, `link`, `summary`, `imageUrl`, `author`, `publishedAt`, `saved`, `read`, `createdAt`

**Location:** `lib/features/newsfeed/domain/entities/rss_article.dart`

---

## Calendar Bounded Context

Google Calendar integration. Each workspace connects its own Google account(s); the app syncs upcoming events into the local store, renders month/week/day/agenda views, fires "meeting starting soon" alerts, supports RSVP to invitations, and can start a local meeting recording seeded from an event and link it back. Beyond the user's own attendance response (RSVP), the feature never creates, edits, or deletes calendar entries — its other writes are only to the local SQLite store and the platform keychain.

### CalendarEvent
A synced Google Calendar entry scoped to a workspace + account. Distinct from a `Meeting`: an event is a scheduled commitment, a `Meeting` is a recorded session. The `myResponseStatus` getter extracts the signed-in user's RSVP from the attendees; `isUnansweredInvitation` flags an event the user hasn't responded to.

**Key attributes:** `id` (local UUID), `workspaceId`, `accountId`, `externalEventId` (provider id), `calendarId`, `title`, `description`, `location`, `startTime`, `endTime`, `isAllDay`, `meetingUrl`, `attendees` (List&lt;CalendarAttendee&gt;), `status` (CalendarEventStatus), `recurringEventId`, `alertedAt`, `updatedAt`

**Location:** `lib/features/calendar/domain/entities/calendar_event.dart`

### CalendarAttendee
An attendee on a `CalendarEvent`: email, display name, RSVP response status (`needsAction`/`accepted`/`declined`/`tentative`), and `self`/`organizer` flags.

**Location:** `lib/features/calendar/domain/entities/calendar_event.dart`

### CalendarAccount
A connected external calendar account, per workspace + email (id = `google:<workspaceId>:<email>`). The `needsReauth` getter is true when `authExpiredAt` is set (the OAuth refresh token died); it drives the in-app reconnect banner and is cleared on a successful sync or reconnect. OAuth tokens are **not** stored here — they live in the platform keychain.

**Key attributes:** `id`, `workspaceId`, `providerId` (always `'google'`), `accountEmail`, `displayName`, `lastSyncedAt`, `authExpiredAt`

**Location:** `lib/features/calendar/domain/entities/calendar_event.dart`

### CalendarEventStatus / CalendarViewMode
`CalendarEventStatus` is the event lifecycle enum (`confirmed`, `tentative`, `cancelled`). `CalendarViewMode` is the UI layout enum (`month`, `week`, `day`, `agenda`), persisted in preferences.

**Location:** `lib/features/calendar/domain/entities/calendar_event.dart`, `lib/features/calendar/presentation/calendar_view_mode.dart`

### MeetingCalendarLink
A join row linking one recorded `Meeting` to one `CalendarEvent` (unique on `meetingId`), produced by the record-and-link flow. Kept separate so neither entity depends on the other; workspace-scoped.

**Location:** `lib/core/database/tables/meeting_calendar_links.dart`

### GoogleOAuthService / GoogleCredentialsRepository / GoogleOAuthRedirectChannel
`GoogleOAuthService` runs the OAuth 2.0 **PKCE** auth-code flow (public iOS-type client, no client secret) and token refresh. `GoogleCredentialsRepository` stores per-account tokens in the platform keychain, every key suffixed with `__<accountId>` so one workspace's tokens are structurally unreadable from another. `GoogleOAuthRedirectChannel` is a long-lived bus that carries the OS deep-link redirect (reversed-client-id custom scheme) back to the in-flight `authenticate()` call.

**Location:** `lib/features/calendar/data/services/google_oauth_service.dart`, `lib/features/calendar/data/repositories/google_credentials_repository.dart`, `lib/features/calendar/data/services/google_oauth_redirect_channel.dart`

---

## Meetings Bounded Context

Local, Granola-style meeting notes. Records the microphone ("me") and system-output ("them") channels concurrently, transcribes both live with on-device Whisper, diarizes the remote channel into individual speakers, and runs a deterministic summarization pipeline that emits structured notes, action items, and decisions. Everything is workspace-scoped and stays on the machine.

### Meeting
The root recording artifact: a recorded/transcribed session with a status lifecycle and AI-augmented output. A `Meeting` may optionally link to a `CalendarEvent` (see `MeetingCalendarLink`).

**Key attributes:** `id`, `workspaceId`, `title`, `status` (`recording`/`processing`/`done`/`failed`), `mode` (`remote`/`inPerson`), `userNotes`, `enhancedNotes`, `summary`, `audioPath`, `startedAt`, `endedAt`

**Location:** `lib/features/meetings/domain/entities/meeting.dart`

### MeetingSegment
One transcribed window of audio, speaker-tagged (`me`/`them`) with text and millisecond offsets. A diarization label (e.g. "Person 1") is added post-recording.

**Key attributes:** `id`, `meetingId`, `workspaceId`, `speaker`, `speakerLabel`, `text`, `startMs`, `endMs`

**Location:** `lib/features/meetings/domain/entities/meeting_segment.dart`

### MeetingSpeakerLabel
A diarized speaker identity, one per `(meeting, channel, label)` tuple. Carries the auto-assigned label ("Person 1") and an optional user-supplied `displayName`.

**Location:** `lib/features/meetings/domain/entities/meeting_speaker_label.dart`

### MeetingActionItem / MeetingDecision
`MeetingActionItem` is an extracted to-do (content, owner, `done` flag, optional `ticketId` link, sort order). `MeetingDecision` is an extracted decision (content, sort order). Both are written as discrete rows by the summarization pipeline — never parsed from markdown.

**Location:** `lib/features/meetings/domain/entities/meeting_action_item.dart`, `lib/features/meetings/domain/entities/meeting_decision.dart`

### MeetingOutcome
A domain service that parses the summarization agent's output (Map/JSON, fenced markdown, or plain text) into structured `summary` / `enhancedNotes` / `actionItems` / `decisions`. Its `isStructured` flag gates row persistence: structured output writes rows; degraded plain-text output skips them (with a raw-transcript fallback).

**Location:** `lib/features/meetings/domain/services/meeting_outcome.dart`

### formatMeetingTranscript
A pure function that renders segments into `[mm:ss] SPEAKER: text` lines, respecting diarization labels and user display names. Shared by the recorder, the diarization step, and the reconciler.

**Location:** `lib/features/meetings/domain/services/meeting_transcript_formatter.dart`

---

## Settings Bounded Context

### Adapter
A built-in inference adapter definition (e.g. Pi, Claude Code) with the CLI binary name used for detection.

**Key attributes:** `id`, `name`, `description`, `cliName`

**Location:** `lib/features/settings/domain/entities/adapter.dart`

### DetectedAdapter
Result of probing the local machine for an adapter CLI: detection status, version, path.

**Location:** `lib/features/settings/domain/entities/adapter.dart`

### AcpModel
A model advertised by an ACP-compatible agent runner (a curated list keyed by adapter id until the ACP transport is wired).

**Location:** `lib/features/settings/domain/entities/acp_model.dart`

---

## Agents Bounded Context (Doctor & Live State)

### DiagnosticResult / DoctorReport
`DiagnosticResult` is a single agent-doctor check (name, `status`, message, `canAutoRepair`). `DoctorReport` aggregates results with rolled-up error/warning counts.

**Location:** `lib/features/agents/domain/entities/diagnostic_result.dart`

### AgentLiveState
Enum (`running`, `blocked`, `failed`, `idle`, `neverRun`) deriving an agent's current live state and sort priority from its most recent run logs.

**Location:** `lib/features/agents/domain/value_objects/agent_live_state.dart`

### DiscoveredAgent
The domain-facing shape of an agent definition found on disk (`AGENTS.md`) but not yet registered in the workspace, surfaced for import.

**Location:** `lib/features/agents/domain/value_objects/discovered_agent.dart`

---

## Dashboard Bounded Context

### DashboardStatus
Top-level dashboard status carrying the total workspace count.

**Location:** `lib/features/dashboard/domain/entities/dashboard_status.dart`

### ActiveProcessInfo
Information about a detected active agent OS process matched to an agent and workspace (`agentName`, `workspaceName`, `pid`, `command`, `startTime`).

**Location:** `lib/core/domain/entities/active_process_info.dart` (shared kernel; re-exported from dashboard's `dashboard_status.dart` for legacy call sites)

---

## GitHub Status Bounded Context

### GitHubServiceStatus
Aggregated GitHub service health from the public Statuspage API: overall indicator, components, open incidents, fetch time.

**Location:** `lib/features/github_status/domain/entities/github_service_status.dart`

### GitHubStatusComponent
A single GitHub service component (e.g. "Git Operations", "API Requests") with its current status and sort position.

**Location:** `lib/features/github_status/domain/entities/github_service_status.dart`

### GitHubStatusIncident
An active GitHub incident with headline, status string, and short link.

**Location:** `lib/features/github_status/domain/entities/github_service_status.dart`

---

## Auth Bounded Context

### ApiCredentials
The user's external-service API credentials: GitHub token plus ticketing provider key/id.

**Key attributes:** `githubToken`, `ticketingApiKey`, `ticketingProviderId`

**Location:** `lib/features/auth/domain/entities/api_credentials.dart`

### GitHubCliStatus
Status of the local GitHub CLI (`gh`) installation and auth state, including resolved username and token.

**Key attributes:** `isInstalled`, `isAuthenticated`, `username`, `token`

**Location:** `lib/features/auth/domain/entities/github_cli_status.dart`

### Token
A value object wrapping a sensitive API token string with emptiness helpers and a masked `toString` so the value never leaks in logs.

**Location:** `lib/features/auth/domain/value_objects/token.dart`

---

## Value Objects (Shared Kernel)

### AgentCapabilities
Per-conversation capability flags (push to repo, GitHub API, ticketing, network egress) that the credential broker checks at sandbox launch to gate token/network injection. Serialized as JSON on the agent.

**Location:** `lib/core/domain/value_objects/agent_capabilities.dart`

### AgentSkills
An immutable, case-insensitive collection of skill identifiers associated with an agent. Skills determine which prompts and tool configurations are injected at runtime.

**Location:** `lib/core/domain/value_objects/agent_skills.dart`

### AgentRole
Enumerates the agent's role (CEO, coder, reviewer, QA, designer, security, devops, PM, general), each carrying a display label and description. Also used for memory access and the reporting hierarchy.

**Location:** `lib/core/domain/value_objects/agent_role.dart`

### AgentEffort
Enum controlling reasoning effort: `low`, `medium`, `high`.

**Location:** `lib/core/domain/entities/agent.dart`

### ConversationMode
An enum (`chat`, `review`, `plan`) that gates sandbox writes and the MCP tool allowlist. Each mode maps to a specific system-prompt template and sandbox policy.

**Location:** `lib/core/domain/value_objects/conversation_mode.dart`

### SandboxBackend
Enum for sandbox execution backends: `native` (OS-native Seatbelt/bubblewrap) and `none` (opt-out), with display labels and legacy-value migration. The previous `docker`/`auto` modes were removed when the in-project native sandbox landed.

**Location:** `lib/core/domain/value_objects/sandbox_backend.dart`

### SandboxSpec / SandboxBindMount
`SandboxSpec` is the full specification used by `SandboxPort.launch` (session, workspace, agent, mounts, network/egress, workdir, mode). `SandboxBindMount` is one host-to-guest bind mount.

**Location:** `lib/core/domain/value_objects/sandbox_spec.dart`

### SandboxHandle / SandboxState
`SandboxHandle` is the opaque handle returned by `SandboxPort.launch` (session id, backend, state, error, adapter details). `SandboxState` is its lifecycle enum (`starting`, `running`, `stopped`, `failed`).

**Location:** `lib/core/domain/value_objects/sandbox_handle.dart`

### SandboxEvent / SandboxEventType / SandboxViolation
A single sandbox lifecycle/stdio event, its kind enum, and a structured denial record (`SandboxViolation`: action, target, suggested capability) emitted on a sandbox's event stream.

**Location:** `lib/core/domain/value_objects/sandbox_event.dart`

### RunCost
An aggregable token/cost tally (input tokens, output tokens, estimated cost in cents) for an agent run, supporting addition and a zero identity.

**Location:** `lib/core/domain/value_objects/run_cost.dart`

### RetryMeta
Tracks the retry lineage of an agent run via parent run id and attempt counter, with a helper to advance to the next attempt.

**Location:** `lib/core/domain/value_objects/retry_meta.dart`

### WakeReason / WakeContext
`WakeReason` enumerates why an agent was dispatched; `WakeContext` carries the dispatch context (ticket, run, agent, workspace, channel, reason, message, pipeline run) injected at dispatch and serialized to environment variables.

**Location:** `lib/core/domain/value_objects/wake_context.dart`

### RepoIsolationBackend
Enum identifying which mechanism produced an isolated repo copy: `rift` copy-on-write clone or plain `gitWorktree` fallback.

**Location:** `lib/core/domain/value_objects/repo_isolation_backend.dart`

### MemoryPermission
Enum of memory access levels (`none`, `read`, `write`) used by the memory access policy.

**Location:** `lib/core/domain/value_objects/memory_permission.dart`

### AppLocale
Wraps a language code with display-name lookup and helpers for whether it is English or has localization support.

**Location:** `lib/core/domain/value_objects/app_locale.dart`

---

## Ports (Abstractions)

Domain interfaces implemented by infrastructure adapters. Core ports live in `lib/core/domain/ports/`; feature-specific ports live under their feature's `domain/ports/`.

### SandboxPort
Manages the lifecycle of an isolated execution sandbox (probe, launch, isAlive, events, exec, pause, resume, destroy). One implementation per backend; adapters live under `lib/features/sandboxing/data/adapters/`.

**Location:** `lib/core/domain/ports/sandbox_port.dart`

### CredentialBrokerPort
Mints scoped, capability-gated credentials (env map + revoke handle) for one sandbox launch and revokes them on teardown. Ensures secrets never persist in the sandbox filesystem.

**Location:** `lib/core/domain/ports/credential_broker_port.dart`

### ConfirmationPort
Lets sandbox hooks interrupt an in-flight agent and ask the user to approve a privileged/destructive action. Carries `ConfirmationRequest` payloads with severity levels.

**Location:** `lib/core/domain/ports/confirmation_port.dart`

### AgentQuestionPort
Surfaces an agent's question (option choices and/or free text) as an interactive inline form in a conversation and blocks until the user answers. Defines the `AgentQuestionOption` / `Request` / `Answer` payloads.

**Location:** `lib/core/domain/ports/agent_question_port.dart`

### GitRepoInspectorPort
Extracts metadata (owner, repo, branch) from a local Git repo path, returning a `GitRepoInfo`.

**Location:** `lib/core/domain/ports/git_repo_inspector_port.dart`

### GitCommandPort
Executes git commands by shelling out to the system git binary, with a completion-returning run and a streaming-progress variant. Defines the `GitResult` value.

**Location:** `lib/core/domain/ports/git_command_port.dart`

### RepoIsolationPort
Provisions and tears down isolated copy-on-write worktrees of a local repo (rift, with `git worktree` fallback) without mutating the source. Defines `RepoIsolationResult`.

**Location:** `lib/core/domain/ports/repo_isolation_port.dart`

### RepoWorkspaceProvisionerPort
Provisions a per-conversation working root with isolated CoW worktrees of the workspace's repos, and tears them down on unit completion (idempotent, no-op-safe by conversation/channel/ticket).

**Location:** `lib/core/domain/ports/repo_workspace_provisioner_port.dart`

### WorkspaceFilesystemPort
Provides filesystem paths and operations for agents, skills, conversations, PR clones, and logos within a workspace.

**Location:** `lib/core/domain/ports/workspace_filesystem_port.dart`

### RunLogStorePort
Writes, reads, and compacts agent run logs by run id, enabling swappable storage backends without changing dispatch logic.

**Location:** `lib/core/domain/ports/run_log_store_port.dart`

### NotificationPort
Shows native desktop notifications (respecting category/route gating) and disposes native resources.

**Location:** `lib/core/domain/ports/notification_port.dart`

### NotificationPreferencesPort
Reads/writes notification preferences (global enable, per-category, batch delivery policy, quiet hours, sound, volume). Defines `BatchDeliveryPolicy`, `TimeOfDay`, `QuietHoursConfig`.

**Location:** `lib/core/domain/ports/notification_preferences_port.dart`

### EmbeddingPort
Produces unit-norm text embedding vectors, exposing readiness and dimensionality so callers can degrade to non-vector paths.

**Location:** `lib/core/domain/ports/embedding_port.dart`

### ProcessControlPort
Kills a process by PID and reports whether a PID is alive. Used to terminate misbehaving agent processes.

**Location:** `lib/core/domain/ports/process_control_port.dart`

### ConversationModeResolver
Resolves the `ConversationMode` for a given conversation id, defaulting to `chat` when the id is null or the row is missing.

**Location:** `lib/core/domain/ports/conversation_mode_resolver.dart`

### Feature ports

- **AgentBackend** — an agent execution backend keyed by CLI name (pi, claude, codex), streaming `AgentProcessEvent`s and supporting stop. `lib/features/dispatch/domain/ports/agent_backend.dart`
- **AgentDispatchPort** — dispatches agent CLI processes (wake context, mode, env, run-log id), returning a `DispatchHandle`. `lib/features/dispatch/domain/ports/agent_dispatch_port.dart`
- **MessagingPort** — messaging channel operations (send, add agents, create groups, send-and-dispatch, refine plan). `lib/features/messaging/domain/ports/messaging_port.dart`
- **TicketProviderPort** — vendor-agnostic boundary to a ticketing backend (create/get/list/update/transition/assign/watch), exposing provider, capabilities, and allowed network domains. `lib/features/ticketing/domain/ports/ticket_provider_port.dart`
- **PipelineEnginePort** — starts a pipeline run from a template, decoupling `SubPipelineLauncher` from the concrete engine. `lib/features/pipelines/domain/ports/pipeline_engine_port.dart`
- **DispatchReviewersPort** — dispatches reviewer agents into a review channel; shared by the MCP tool and pipeline step bodies. `lib/features/pipelines/domain/ports/dispatch_reviewers_port.dart`
- **SchemaValidatorPort** — validates a value against a JSON-Schema subset and returns human-readable violations (never throws). `lib/features/pipelines/domain/ports/schema_validator_port.dart`
- **SandboxDetectorPort** — detects available sandbox capabilities on the host. `lib/features/sandboxing/domain/ports/sandbox_detector_port.dart`
- **DoctorPort** — runs agent environment diagnostics, returning a `DoctorReport`. `lib/features/agents/domain/ports/doctor_port.dart`
- **GitHubCliPort** — probes the local `gh` CLI and returns its status. `lib/features/auth/domain/ports/github_cli_port.dart`
- **ProcessDetectionPort** — detects running local agent processes and kills by PID. `lib/core/domain/ports/process_detection_port.dart` (shared kernel — used by both dashboard and the agents kill path)
- **McpServerPort / McpTool** — MCP server lifecycle control, and the abstract base for an MCP tool (name, description, input schema, run, approval gating). `lib/features/mcp/domain/ports/`
- **TicketWorkflowPort** — consumer-owned (pipelines) port exposing the three ticket-workflow operations the pipeline engine needs (`createTicket`, `completeTicket`, `cancelTicket`); implemented by `TicketWorkflowService` so pipelines depend on a thin contract, not the concrete ticketing service. `lib/features/pipelines/domain/ports/ticket_workflow_port.dart`

---

## Domain Events

### DomainEventBus
An in-process broadcast publish/subscribe bus for cross-feature decoupling. Features `publish(event)`; subscribers consume a typed `on<T>()` stream. Every event implements `DomainEvent` and exposes `occurredAt`.

**Location:** `lib/core/domain/events/domain_event_bus.dart`

**Key events by category:**

**Workspace, Agent & Repo:**
- `WorkspaceCreated` — triggers CEO agent seeding
- `AgentRunCompleted` — triggers notifications, analytics, cost rollups, recovery
- `RepoAdded` — triggers background code indexing

**PR & Review:**
- `PullRequestPublished` — PR opened by an agent
- `PullRequestStatusChanged` — merged/closed/opened/reopened; the signal pipeline triggers subscribe to (with optional status filter)
- `PrMerged` — narrow merge-only signal for analytics/notifications
- `ExternalPrDetected` — PR by a non-agent author found via polling

**Messaging:**
- `MessageReceived` — triggers desktop notifications
- `ConversationDeleted` — drives worktree GC for per-conversation resources

**Ticketing / Task lifecycle** (vendor-neutral; replaced the old task/linear events):
- `TicketCreated`, `TicketStarted`, `TicketCompleted`, `TicketFailed`, `TicketCancelled`, `TicketStatusChanged`
- `TicketAssigned` — the sole event the dispatcher consumes
- `TicketReassigned`, `TicketDelegated`, `TicketCollaboratorAdded`, `TicketDetailsUpdated`

**Pipeline lifecycle:**
- `PipelineRunStarted`, `PipelineStepStarted`, `PipelineStepCompleted`, `PipelineStepFailed`, `PipelineRunCompleted`, `PipelineRunFailed`

**Observability:**
- `ActivityLogged` — audit trail entry created
- `WorktreeMerged` — worktree merge completed
- `BudgetThresholdCrossed` — spend threshold exceeded

**Analytics:**
- `AchievementUnlocked` — agent earned a badge

**Calendar & Meetings:**
- `CalendarEventsRefreshed` — a calendar sync upserted events for a workspace
- `CalendarAuthExpired` — a connected account's OAuth refresh token is permanently invalid; drives the "reconnect calendar" notification (published once per disconnection episode)
- `MeetingStartingSoon` — a calendar event is starting within the configured lead window; drives the "meeting starting soon" notification
- `MeetingRecordingStopped` — a meeting recording finished and is ready to summarize; triggers the built-in `meeting_summary` pipeline

---

## Domain Services

### Shared kernel (`lib/core/domain/services/`)

- **ActivityLogger** — builds and publishes `ActivityLogged` observability events.
- **MemoryAccessPolicy** — resolves and enforces an agent role's memory permission on a domain, throwing on write denial.
- **AgentMentionParser / MentionResolver** — parse/strip @-mention tokens and resolve them to a unique `Agent`.
- **AgentLoopGuard** — suppresses agent→agent dispatch loops (self-trigger + recent-participant guards); gated into `MessagingService.sendAndDispatch`.
- **cosineSimilarity / slugify** — pure helpers for embedding similarity and filesystem-safe slugs.

### Notable feature services

- **AgentDispatchService** (dispatch) — launches an agent run: provisions isolated repos, builds the prompt, creates a run log, returns the live process-event stream.
- **AgentStreamProcessor** (messaging) — consumes the process-event stream, persisting deltas, embedding content, and emitting messaging events.
- **AgentQuestionService** (messaging) — `AgentQuestionPort` impl that posts an inline `user_question` message and blocks the asking agent until the user answers.
- **TicketWorkflowService** (ticketing) — pure-domain ticket lifecycle engine with optimistic-concurrency mutation chokepoint and workspace-isolation enforcement; never dispatches or opens channels itself.
- **TicketDispatcher** (ticketing) — sole owner of assigned-ticket→agent dispatch: on `TicketAssigned`, runs readiness check, ensures a channel, transitions open→in_progress, dispatches once.
- **StrandedTicketReconciler / OrphanRunReaper** — startup reconcilers (wired in `main.dart`) that recover tickets stuck in progress and reap dead run-log rows whose process died.
- **PipelineEngine** (pipelines) — `PipelineEnginePort` impl orchestrating run execution: starts runs, schedules steps, persists state, handles routers/continue-on-fail, and resumes in-flight runs after restart.
- **PipelineTriggerDispatcher** (pipelines) — subscribes to domain events and auto-starts runs for each enabled matching trigger.
- **DownstreamPlanner / StateReducer / TemplateRenderer** (pipelines) — pure helpers for skip-propagation, concurrent-write reduction, and `{{...}}` placeholder substitution.
- **CostTracker** (agents) — computes per-run token cost and persists it onto the run log.
- **BudgetEnforcementService** (agents) — enforces per-scope monthly spend budgets, blocking invocations when exhausted and publishing `BudgetThresholdCrossed`.
- **DoctorService** (agents) — runs environment diagnostics (sandbox backend, database, CLI tools, disk, network).
- **DefaultCodeIndexer** (code_graph) — parses changed files with tree-sitter in worker isolates, ingests symbols/edges, prunes deletions, resolves cross-file references; degrades gracefully when natives are missing.
- **RepoWorkspaceProvisioner / WorktreeGcListener** (repos) — provision per-conversation CoW worktree roots and GC them when a unit ends.
- **DispatchReviewersService** (pr_review) — `DispatchReviewersPort` impl that fans out PR review to matched reviewer agents.
- **ReviewerMatchingService** (pr_review) — picks the best `Agent` for a desired specialist role label.
- **PrPollingService** (pr_review) — polls GitHub for new external PRs and emits `ExternalPrDetected`.
- **TicketSyncService / TicketRemoteSyncHandler** (ticketing) — pull remote tickets into the local mirror and mirror local state back, keeping the workflow service free of infrastructure.
- **SnapshotAggregator** (analytics) — hourly timer rebuilding the daily-stats snapshot.
- **CalendarSyncService / MeetingAlertScheduler** (calendar) — `CalendarSyncService` periodically pulls each connected account's events into the local store (publishing `CalendarEventsRefreshed`) and lazily loads on-demand ranges; `MeetingAlertScheduler` scans per-minute for events inside the lead window and publishes `MeetingStartingSoon`, persisting `alertedAt` so an alert never fires twice.
- **MeetingTranscriptionService / MeetingDiarizationService** (meetings) — `MeetingTranscriptionService` decodes rolling Whisper windows off the UI thread (silent-window skip); `MeetingDiarizationService` clusters the recording into individual speakers offline (sherpa-onnx) after the recording stops.
- **MeetingSummaryReconciler** (meetings) — listens for the `meeting_summary` pipeline's terminal events and finalizes the meeting `processing → done`, falling back to the raw transcript when the agent produced no structured notes.

---

## Cross-Cutting

### AppNotification
A structured desktop notification payload with category, title, body, and navigation route/channel. Mapped from domain events by `NotificationEventMapper`.

**Location:** `lib/core/domain/notifications/notification_category.dart`

### NotificationCategory
Enumerates desktop notification types, each independently toggleable: `agentRunCompleted`, `pullRequestPublished`, `prMerged`, `newMessage`, `externalPr`, `ticketAssigned`, `ticketStatusChanged`, `meetingStartsSoon`, `calendarAuthExpired`.

**Location:** `lib/core/domain/notifications/notification_category.dart`

### NotificationSound
Built-in notification sounds bundled as MP3 assets under `assets/sounds/`, organized in groups for the settings UI.

**Location:** `lib/core/domain/notifications/notification_sound.dart`

### NotificationEventMapper
Subscribes to `DomainEventBus` and maps domain events to `AppNotification` instances. The single place that decides which events produce user-visible notifications.

**Location:** `lib/core/notifications/notification_event_mapper.dart`

---

## MCP Bounded Context

The `mcp` feature hosts a JSON-RPC 2.0 MCP server exposing **71 typed tools** to external MCP clients. It uses `application/` instead of `presentation/` because tools are use-case logic, not UI. Tools receive their dependencies as typed constructor parameters (no `Ref` injection); the wiring happens once in `mcpToolRegistryProvider`.

### McpTool
The abstract base for an MCP tool: exposes `name`, `description`, and `inputSchema` (definition) plus a `call()` handler and approval gating. Also defines `ToolDef`, `CallResult` / `CallResultContent`, and `ApprovalPayload`.

**Location:** `lib/features/mcp/domain/ports/mcp_tool_port.dart`

### McpToolRegistry / McpToolDispatcher
The registry keys all tools by name (lookup, definition listing, name enumeration). The dispatcher routes JSON-RPC requests to tools, applying conversation-mode gating (`ConversationModeToolGuard`) and destructive-action confirmation prompts.

**Location:** `lib/features/mcp/domain/services/mcp_tool_registry.dart`, `lib/features/mcp/data/services/mcp_tool_dispatcher.dart`

### JsonRpcRequest / JsonRpcResponse / JsonRpcError / JsonRpcNotification
The four JSON-RPC 2.0 message shapes used by the MCP server transport.

**Location:** `lib/features/mcp/domain/value_objects/jsonrpc_message.dart`

**Tool families** (registered into one shared registry): agents (`list_agents`, `hire_agent`, `update_agent`, `fire_agent`, `kill_agent`, `get_agent_run_logs`), agent collaboration (`consult_agent`, `propose_hire`, `request_peer_review`), skills (`list_skills`, `create_skill`), workspaces (`list_workspaces`, `create_workspace`), repos (`list_repos`), messaging (`list_channels`, `list_private_messages`, `get_channel_messages`, `send_channel_message`, `send_thread_reply`), pull requests & review (`list_pull_requests`, `start_ai_review`, `add_review_node`, `confirm_review_node`, `dismiss_review_node`, `dispatch_reviewers`, `submit_reviewer_verdict`, `finalize_review`, `publish_review_to_github`), memory (`search_memory`, `propose_fact`, `supersede_fact`, `propose_policy`, `list_policies`, `list_memory_domains`, `record_observation`, `update_my_notes`, `get_my_notes`), code graph (`search_code`, `code_symbol`, `code_callers`, `code_callees`, `code_impact`), the universal `read` resource tool, user interaction (`ask_user_question`, `request_confirmation`, `suggest_tasks`), `doctor`, and ticketing/projects (CRUD, lifecycle, assignment, links, approval gates). Tools touching workspace-scoped data require `workspace_id`; only genuinely global tools (`list_workspaces`, `create_workspace`) are exempt. The **calendar** and **meetings** features are UI/desktop-only — they are *not* exposed over MCP.

---

## Database Conventions

- Table definitions live in `lib/core/database/tables/` (Drift); DAOs in `lib/core/database/daos/`.
- Domain entities are pure Dart, separate from Drift table classes; entity ⇔ table mapping happens in feature data layers via mappers.
- Workspace-scoped tables carry a `workspaceId` column and MUST be filtered by it on every read (see the workspace-isolation invariant). This now includes the calendar tables (`calendar_accounts`, `calendar_events`, `meeting_calendar_links`) and the meeting tables (`meetings`, `meeting_transcript_segments`, `meeting_speakers`, `meeting_action_items`, `meeting_decisions`). Code-graph tables are keyed by `(workspaceId, repoId)`.
- Foreign keys use `CASCADE` or `SET NULL` as appropriate (`PRAGMA foreign_keys=ON`, WAL journal mode, integrity check on open).
- **Full-text search** via FTS5 external-content virtual tables (`memory_facts_fts`, `code_symbols_fts`) kept in sync by AFTER INSERT/DELETE/UPDATE triggers.
- **Vector embeddings** via the `sqlite_vector` extension (FLOAT32, dimension 384) on `memory_facts.embedding` and `code_symbols.embedding`; degrades gracefully to FTS-only when the extension is unavailable. Hybrid search combines BM25 + vector similarity (RRF).
