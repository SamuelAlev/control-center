import 'package:cc_domain/cc_domain.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart'
    show RepoOp, RepoOpRegistry, WatchQueryRegistry;

/// The demo's op-level lockdown: which RPC operations a public visitor may
/// reach at all.
///
/// This is the SECOND of three layers. The first and primary one is structural
/// absence — the demo runtime passes `null` for every execution port, so
/// `terminal.*`, `rig.*`, `fs.*`, `codeServer.*`, `mcp.*` and the rest are never
/// built into the registry and `RepoOpDispatcher` answers `opUnknown`. This
/// profile is the belt over that brace, and the third layer is the ratchet test
/// that forces a human to classify every op that is ever added.
///
/// **Why a name allowlist rather than an `ActionClass` denylist.** The catalog
/// declares 548 ops, 326 of them mutating, and only 29 declare `actionClasses:`
/// — `terminal.spawn` among the silent ones. A denylist keyed on `processSpawn`
/// would therefore have admitted the terminal. ActionClass is kept as a second
/// net below, never as the boundary.
///
/// The default is DENY: an op that is not explicitly allowed and is not a plain
/// read cannot be called. Adding an op to the catalog tomorrow makes it
/// unreachable in the demo until someone classifies it, which is the safe
/// direction for a public endpoint.
///
/// The same discipline covers the SUBSCRIPTION lane: `sub/subscribe` answers
/// from a separate watch-query registry the op allowlist never sees, so
/// [reviewedWatchQueries] pins every watch name a demo visitor may stream and
/// the ratchet fails when the catalog grows one nobody reviewed.
class DemoProfile {
  /// Creates a profile. The default lists are the shipped demo policy.
  const DemoProfile({
    this.allowedMutations = defaultAllowedMutations,
    this.deniedMutations = defaultDeniedMutations,
    this.deniedPrefixes = defaultDeniedPrefixes,
    this.prefixExceptions = defaultPrefixExceptions,
    this.deniedReads = defaultDeniedReads,
    this.reviewedWatchQueries = defaultReviewedWatchQueries,
    this.deniedWatchQueries = defaultDeniedWatchQueries,
  });

  /// Watch queries reviewed and REFUSED, as opposed to never examined.
  ///
  /// [lockdownWatch] admits only [reviewedWatchQueries], so a name here is
  /// absent either way — the set exists so the ratchet can prove the decision
  /// was made. Without it, "we decided no" and "nobody looked" were the same
  /// state, which is exactly what let `fleet.*` sit unclassified.
  final Set<String> deniedWatchQueries;

  /// Mutating ops a visitor may call in their own sandbox workspace.
  final Set<String> allowedMutations;

  /// Mutating ops explicitly refused by name (those a [deniedPrefixes] entry
  /// does not already cover). Kept explicit so the ratchet can prove every
  /// mutating op in the catalog was consciously classified.
  final Set<String> deniedMutations;

  /// Op-name prefixes refused wholesale, reads included.
  final Set<String> deniedPrefixes;

  /// Op names admitted DESPITE a [deniedPrefixes] match.
  ///
  /// A prefix is a family-level verdict, but a few families contain one or two
  /// members a demo genuinely needs (the newsfeed's per-user article state
  /// under the otherwise-denied `newsfeed.` management lane; the model list a
  /// demo answers from static data under the otherwise-denied `providers.`
  /// credential lane). Lifting a NAME leaves the family denied and the kind
  /// rules in force: an exception that mutates must still be in
  /// [allowedMutations], and one that reads must still dodge [deniedReads].
  final Set<String> prefixExceptions;

  /// Reads that would dial an external service. A demo container makes no
  /// outbound request, so these are refused rather than left to fail slowly.
  final Set<String> deniedReads;

  /// Every watch query a demo visitor may subscribe to, by name.
  ///
  /// The subscription lane is read-only streams, but it is a LANE — the op
  /// allowlist above never sees it. This set is the reviewed snapshot: every
  /// name in it was checked to be workspace-scoped (or individually gated,
  /// like `server_settings.watch` and the per-user `newsfeed.watch*`), and the
  /// ratchet test fails when a watch query appears in the catalog that nobody
  /// has added here. Unreviewed names are filtered out of the registry the
  /// same way refused ops are: `lookup` returns null and the subscribe fails.
  final Set<String> reviewedWatchQueries;

  /// Every [ActionClass] except [ActionClass.workspaceMutation].
  ///
  /// A visitor's workspace is theirs to mutate; nothing else is on the table.
  /// This is the second net only — see the class doc for why it cannot be the
  /// boundary.
  static const Set<ActionClass> forbiddenClasses = {
    ActionClass.fileDelete,
    ActionClass.fileWriteOutsideWorktree,
    ActionClass.gitCommit,
    ActionClass.gitPush,
    ActionClass.prCreate,
    ActionClass.prPublish,
    ActionClass.vendorSyncWrite,
    ActionClass.networkEgress,
    ActionClass.secretAccess,
    ActionClass.packageInstall,
    ActionClass.processSpawn,
    ActionClass.enclosureControl,
  };

  /// Prefixes refused wholesale: execution, credentials, identity, the forge,
  /// device pairing and server administration.
  static const Set<String> defaultDeniedPrefixes = {
    'account_pools.',
    'acp.',
    'action_policy.',
    'adapter.',
    'agent_run_log.',
    'claude_accounts.',
    'codeServer.',
    'connectivity.',
    'credentials.',
    'dictation.',
    // Chat transports (Slack/Discord): every verb dials a third party.
    'chat.',
    // Evals: `runSuite` executes agents against golden recordings, and the
    // rest edit suites. The evals WATCHES are separately reviewed, so the
    // screen still renders (empty) rather than erroring.
    'evals.',
    // The fleet lease protocol. This is the sharpest one the widened ratchet
    // caught: `fleet.registerWorker` and `fleet.submitJob` let a caller enrol
    // a worker and push jobs, and workers/jobs live in the GLOBAL database —
    // shared by every visitor. Nothing about that belongs on a public demo.
    'fleet.',
    'forge.',
    // Weather: `refreshNow` fetches a public API. The dashboard widget reads
    // through `weather.watchCurrent`, which is reviewed below.
    'weather.',
    'fs.',
    'gif.',
    'github.',
    'ide.',
    'invites.',
    'isolated_repo.',
    'mcp.',
    'members.',
    'models.',
    'oauth.',
    'pairing.',
    'pr_lifecycle.',
    'process.',
    'provider_policy.',
    'providerApps.',
    'rig.',
    'sandbox.',
    'scim.',
    'server.',
    'server_settings.',
    'service_status.',
    'skills.',
    'sso.',
    'subscriptions.',
    'terminal.',
    'ticket_sync.',
    'users.',
    'voice_profile.',
    'workspace_settings.',
    'worktree.',
  };

  /// Name-level exceptions under otherwise-denied prefixes.
  ///
  /// The newsfeed lane: a demo fetches REAL feeds server-side and a visitor
  /// reads them, marks articles read/saved and clears the list — the feed
  /// MANAGEMENT verbs (add/delete/toggle/refresh/seed) stay denied, which is
  /// what "read-only feeds" means here. The providers lane: the model list a
  /// demo answers from static data (see `DemoInertProvider.listModels`); every
  /// credential-touching verb in that family stays refused.
  static const Set<String> defaultPrefixExceptions = {
    'newsfeed.listArticles',
    'newsfeed.getArticle',
    'newsfeed.setArticleRead',
    'newsfeed.setArticleSaved',
    'newsfeed.markAllRead',
    'providers.list',
    'providers.listModels',
    // One-shot reads of data the demo SEEDS. Their watch variants were already
    // reviewed and admitted, but a screen that opens a detail view calls the
    // one-shot — so denying it turned a furnished run transcript or PR page
    // into red "Unknown op" text on exactly the surfaces the screenshots
    // needed. All are `RepoOpKind.read` against the visitor's own workspace
    // database; none reaches a network.
    'agent_run_log.get',
    'agent_run_log.getTranscript',
    'agent_run_log.readEvents',
    'pr_lifecycle.getById',
    'workspace_settings.getAll',
    'action_policy.list',
    'provider_policy.listForWorkspace',
    'members.getRepoGrants',
    // Not workspace-scoped, but scoped by CO-MEMBERSHIP: it returns the caller
    // plus everyone sharing a workspace with them, which for a demo visitor is
    // themselves and their own seeded teammates. Never another visitor — the
    // e2e test asserts exactly that, on both this lane and `users.watchAll`.
    'users.list',
  };

  /// Reads that reach the network. Refused so a demo container is provably
  /// egress-free rather than merely slow.
  static const Set<String> defaultDeniedReads = {
    // EXFILTRATION, not egress: `workspace.export` VACUUMs the visitor's whole
    // workspace database into a file and hands it back. Harmless for their own
    // fixtures, but it is a whole-database read on a public endpoint and there
    // is no reason a demo needs one.
    'workspace.export',
    // The only calendar READ that is about reaching a provider rather than
    // reading the seeded calendar.
    'calendar.connectInfo',
    'pr.closedByAuthorForWorkspace',
    'pr.listOpenForWorkspace',
    'pr.openPageForRepo',
    'pr.refreshOpenForWorkspace',
    'pr.searchForWorkspace',
    'pr.searchReviewRequestedForWorkspace',
    'pr.searchReviewedByForWorkspace',
  };

  /// The mutating surface a visitor actually needs to drive every demo screen:
  /// chat and dispatch, tickets and todos, PR review write-back, plans and
  /// orchestrations, memory, notifications and their own preferences.
  static const Set<String> defaultAllowedMutations = {
    // Chat + spaces.
    'messaging.sendMessage',
    'messaging.updateMessage',
    'messaging.createSpace',
    'messaging.deleteSpace',
    'messaging.archiveSpace',
    'messaging.unarchiveSpace',
    'messaging.updateSpaceName',
    'messaging.setSpaceMode',
    'messaging.addParticipant',
    'messaging.removeParticipant',
    'messaging.clearSpaceMessages',
    'messaging.branchConversationAt',
    'messaging.forkConversation',
    'messaging.revertConversationTo',
    'messaging.unrevertConversation',
    'messaging.retrySpaceProvisioning',
    'messaging.cancelSpaceProvisioning',
    'conversation.create',
    'conversation.ensure',
    'conversation.rename',
    'conversation.archive',
    'space_read.markSpaceRead',
    'notes.update',
    'reactions.toggle',
    'blob.put',
    // Agents + the scripted run lane.
    'agents.upsert',
    'agents.delete',
    'dispatch.sendAndDispatch',
    'dispatch.sendUserMessage',
    'dispatch.dispatchAgent',
    'dispatch.addAgentToSpace',
    'dispatch.stopRun',
    'dispatch.pauseRun',
    'dispatch.resumeRun',
    'dispatch.steer',
    'dispatch.retryAgentTurn',
    'dispatch.compact',
    'dispatch.shake',
    'dispatch.refinePlan',
    'dispatch.reviewFeedbackAgent',
    'steering.enqueue',
    'steering.update',
    'steering.delete',
    'steering.reorder',
    'steering.deliver',
    'autonomy.setForSpace',
    'checker.setForSpace',
    'takeover.begin',
    'takeover.handBack',
    'confirmation.respond',
    // Answering a run parked on a credential. A demo runs no real dispatch, so
    // nothing can ever be parked and the dialog that calls this never renders —
    // but the op itself is safe to admit rather than special-case: it resolves
    // an in-memory registry entry, writes nothing, and is membership-gated
    // against the blocked run's own workspace.
    'credential_gate.resolve',
    'agentGoalRuns.cancel',
    'agentGoalRuns.pause',
    'agentGoalRuns.resume',
    // Tickets, projects, todos.
    'tickets.insert',
    'tickets.update',
    'tickets.patch',
    'tickets.assign',
    'tickets.delete',
    'tickets.addCollaborator',
    'tickets.removeCollaborator',
    'ticket_link.insert',
    'ticket_link.deleteById',
    'ticket_link.deleteByEndpoints',
    'project.insert',
    'project.update',
    'project.delete',
    'todos.append',
    'todos.remove',
    'todos.clear',
    'todos.reorder',
    'todos.replaceAll',
    'todos.setStatus',
    'todos.setGoal',
    'todos.clearGoal',
    // PR review. Only the lane `DemoPrReviewRepository` writes back into the
    // `caches` table — merge/close/upload/stack are absent on purpose, so a
    // visitor never presses a button whose write-back does not exist.
    'pr_review.postReviewComment',
    'pr_review.replyToReviewComment',
    'pr_review.submitReview',
    'pr_review.upsertDraft',
    'pr_review.clearDraft',
    'pr_review.markFileAsViewed',
    'pr_review.setReviewThreadResolved',
    'pr_review.toggleIssueCommentReaction',
    'pr_review.togglePullRequestReaction',
    'pr_review.toggleReviewCommentReaction',
    'pr_review.toggleReviewReaction',
    'pr_review.invalidateDiff',
    'pr_review.invalidatePullRequest',
    'review_space.create',
    'review_space.updateStatus',
    'review_studio.compute',
    'review_studio.approveVisual',
    'review_studio.setContractDecision',
    'review_hub.start',
    // Plans, orchestrations, pipelines, playbooks.
    'plan.approve',
    'plan.updateStatus',
    'plan.estimate',
    'plan.delete',
    'orchestration.insert',
    'orchestration.update',
    'orchestration.approve',
    'orchestration.approveNodes',
    'orchestration.cancel',
    'orchestration.continueNode',
    'orchestration.saveRevision',
    'playbook.save',
    'playbook.delete',
    'playbook.run',
    'pipeline.start',
    'pipeline.cancel',
    'pipeline.retry',
    'pipeline.killStep',
    'pipeline_run.insertRun',
    'pipeline_run.updateRun',
    'pipeline_run.updateRunState',
    'pipeline_run.deleteRun',
    'pipeline_run.insertStepRun',
    'pipeline_run.updateStepRun',
    'pipeline_run.restartStepRun',
    'pipeline_run.deleteStepRun',
    'pipeline_run.incrementCost',
    'pipeline_template.upsert',
    'pipeline_template.deleteById',
    'pipeline_trigger.insert',
    'pipeline_trigger.update',
    'pipeline_trigger.deleteById',
    'pipeline_trigger.markFired',
    'workProduct.restoreRevision',
    // Meetings. The demo seeds finished meetings with transcripts, speakers,
    // decisions and action items; these are the edits a visitor can make to
    // them, and every one is a local database write.
    'meeting.updateTitle',
    'meeting.updateNotes',
    'meeting.addActionItem',
    'meeting.updateActionItem',
    'meeting.deleteActionItem',
    'meeting.setActionItemDone',
    'meeting.addDecision',
    'meeting.updateDecision',
    'meeting.deleteDecision',
    'meeting.renameSpeakerByLabel',
    'meeting.setSegmentSpeakerName',
    'meeting.clearSpeakerNameOverridesForLabel',
    'meeting.delete',
    // The generic workspace cache. The client persists its EDITOR LAYOUT
    // through it (`editor_layout_cache_provider`), which is per-visitor UI
    // state in the visitor's own workspace file — denying it made every tab
    // arrangement fail to save with red text.
    'cache.write',
    // Month navigation on the calendar. The demo's only calendar account is
    // `providerId: 'local'`, so there is no sync adapter to dial — this
    // resolves against the seeded rows and returns.
    'calendar.ensureRangeLoaded',
    // Review-finding triage state: a local row on `review_axis_results`, and
    // the surface the seeded AI review renders into. Posting those findings
    // to a forge (`pr_review.commentFindings`) stays denied.
    'pr_review.setFindingStatus',
    // Soundscape tunes are generated server-side from local state.
    'soundscape.setTune',
    // Memory.
    'memory_fact.upsert',
    'memory_fact.delete',
    'memory_domain.upsert',
    'memory_policy.upsert',
    'memory_policy.delete',
    'memory_access_grant.upsert',
    'memory_access_grant.upsertAll',
    'agent_working_memory.upsert',
    // Newsfeed article state — personal, per-user rows in global.db. The
    // FEED-management verbs (add/delete/toggle/refresh) stay denied; these
    // are the read/saved toggles the reading surface needs.
    'newsfeed.setArticleRead',
    'newsfeed.setArticleSaved',
    'newsfeed.markAllRead',
    // Teams, notifications, preferences.
    'team.insertTeam',
    'team.updateTeam',
    'team.deleteTeam',
    'team.addMember',
    'team.removeMember',
    'notifications.setItemRead',
    'notifications.markAllRead',
    'notifications.dismissItem',
    'notifications.clear',
    'approval_routing.setPolicy',
    'prefs.set',
  };

  /// Mutating ops refused by name rather than by prefix.
  ///
  /// Each is a deliberate call, not an oversight: they either reach a forge, a
  /// process, the host filesystem or server-wide configuration, or they are
  /// internal lanes a visitor has no reason to drive.
  static const Set<String> defaultDeniedMutations = {
    // Forge writes. `DemoPrReviewRepository` is structurally offline, but these
    // verbs have no cache write-back, so allowing them would render a button
    // that silently does nothing.
    'pr_review.mergePullRequest',
    'pr_review.closePullRequest',
    'pr_review.updatePullRequest',
    'pr_review.setPullRequestDraft',
    'pr_review.publishReview',
    'pr_review.commentFindings',
    'pr_review.uploadContent',
    'pr_review.addAssignees',
    'pr_review.removeAssignees',
    'pr_review.requestReviewers',
    'pr_review.removeRequestedReviewers',
    'pr_review.createStack',
    'pr_review.addToStack',
    'pr_review.unstack',
    // Provisions a PR review space, which on a real host means a worktree. The
    // demo seeds its review spaces directly, so the verb is unnecessary here
    // and provisioning is a path a public visitor should not be able to start.
    'pr.ensureSpace',
    // Process control on the host.
    'agents.killProcesses',
    // Repo wiring: the demo has no repos row at all.
    'messaging.setSpaceRepos',
    // ── Families whose READS the demo needs, so they cannot be denied by
    // prefix: the newsfeed shows real articles, the PR surface resolves a repo
    // row, the workspace serves its logo. Every MUTATION in them is named here
    // instead.
    //
    // Repos: adding or deleting a checkout, reordering, staging, and running
    // or saving a lifecycle script. `getScripts` stays readable so the script
    // dialog can still SHOW what a repo would run.
    'repos.addFromPath',
    'repos.upsert',
    'repos.delete',
    'repos.reorder',
    'repos.setScripts',
    'repos.testScript',
    'repos.stage',
    'repos.unstage',
    // Newsfeed: the feed LIST is fixed for a visitor. Per-article read/saved
    // state stays allowed (it is their own session), and the refresh happens
    // server-side at claim time rather than on demand.
    'newsfeed.addFeed',
    'newsfeed.deleteFeed',
    'newsfeed.setFeedEnabled',
    'newsfeed.refreshAll',
    'newsfeed.refreshFeed',
    'newsfeed.seedDefaultFeedsIfEmpty',
    // Providers: every one of these writes or spends a credential.
    'providers.addCustom',
    'providers.removeCustom',
    'providers.saveApiKey',
    'providers.removeCredential',
    'providers.startOAuth',
    'providers.completeOAuth',
    'providers.cancelOAuth',
    'providers.saveGenerationDefaults',
    'providers.saveModelOverride',
    'providers.removeModelOverride',
    // Workspace registry: a visitor owns ONE workspace and cannot create,
    // delete, reorder or re-point it. `workspace.import` would also write an
    // operator-supplied database file onto the host.
    'workspace.upsert',
    'workspace.delete',
    'workspace.import',
    'workspace.reorder',
    'workspace.setReposForWorkspace',
    'workspace.unlinkRepoFromWorkspace',
    // Ownership handover needs a second member to hand it TO, and a demo
    // visitor's workspace has exactly one — the visitor, who would only be
    // able to demote themselves out of their own sandbox.
    'workspace.transferOwnership',
    // Governance surfaces. A demo workspace has one member, so custom roles
    // govern nobody; the managed tier is INSTALL-wide, so a visitor editing
    // it would be editing every other visitor's policy — and the demo's own
    // lockdown is exactly the posture that must not be adjustable from
    // inside it.
    'roles.upsert',
    'roles.delete',
    'roles.assign',
    'managed_policy.upsert',
    'managed_policy.delete',

    // Recording needs audio capture and a speech model; the demo ships
    // neither, and `meeting.setActionItemTicket`/`setSpeakerEnrolledProfile`
    // reach subsystems (ticket sync, voice profiles) the demo does not run.
    'meeting.startRecording',
    'meeting.stopRecording',
    'meeting.ingestAudio',
    'meeting.setActionItemTicket',
    'meeting.setSpeakerEnrolledProfile',
    // Every calendar mutation either reaches Google (connect, RSVP, refresh)
    // or manages an account the demo's single local one stands in for. The
    // seeded week is read-only, which is what a demo calendar should be.
    'calendar.beginConnect',
    'calendar.pollConnect',
    'calendar.disconnect',
    'calendar.refreshNow',
    'calendar.rsvp',
    'calendar.linkMeetingToEvent',
    'calendar.unlinkMeeting',
  };

  /// The reviewed watch-query snapshot. See [reviewedWatchQueries].
  ///
  /// Every name here is either workspace-scoped (the membership gate is the
  /// boundary) or individually gated/caller-scoped: `server_settings.watch`
  /// refuses everyone but the operator inside its handler, `newsfeed.watch*`
  /// streams only the caller's own feeds, `pairing.watchOwn` only the caller's
  /// invites, and the cross-workspace `*.watchAll` streams are filtered
  /// per-subscriber to the caller's workspaces.
  /// Watch queries deliberately refused.
  static const Set<String> defaultDeniedWatchQueries = {
    // The fleet lease lane. `workers`, `jobs` and `placement_log` live in the
    // GLOBAL database, shared by every visitor — one visitor watching another
    // deployment's workers is a cross-tenant read, and the demo runs no fleet
    // at all.
    'fleet.watchWorkers',
    'fleet.watchJobs',
    'fleet.watchPlacements',
    // Chat transports are never connected on a demo, so this streams a link
    // set that cannot exist.
    'chat.watchUserLinks',
  };

  /// The reviewed snapshot of every watch query a demo visitor may subscribe
  /// to. See [reviewedWatchQueries]; the ratchet fails on an unlisted name.
  static const Set<String> defaultReviewedWatchQueries = {
    // Surfaces whose OPS are denied but whose read-only stream still has to
    // render, so the screen shows an honest empty state instead of red text.
    // Each is workspace-scoped and database-only.
    'evals.watchSuites',
    'evals.watchRunsForSuite',
    'evals.watchGoldens',
    'evals.watchRecordings',
    // Local, generated server-side from workspace state.
    'soundscape.watchScene',
    // The dashboard's weather widget. Fetching is disabled in demo mode, so
    // this streams whatever state exists — which is nothing, rendered as the
    // widget's own empty state.
    'weather.watchCurrent',
    'action_policy.watchForWorkspace',
    'activity.watchForEntity',
    'activity.watchForWorkspace',
    'agentGoalRuns.watchForConversation',
    'agent_run_log.watchActiveByConversation',
    'agent_run_log.watchActiveBySpace',
    'agent_run_log.watchAll',
    'agent_run_log.watchByAgent',
    'agent_run_log.watchByConversation',
    'agent_run_log.watchBySpace',
    'agent_run_log.watchRecent',
    'agent_run_log.watchRunTranscript',
    'agent_working_memory.watchByAgent',
    'agent_working_memory.watchByWorkspace',
    'agents.watchAll',
    'agents.watchForWorkspace',
    'approvals.watchForWorkspace',
    'autonomy.watchForSpace',
    'calendar.watchAccounts',
    'calendar.watchEventById',
    'calendar.watchEventsInRange',
    'calendar.watchSources',
    'codeServer.watchDirtyState',
    'codeServer.watchOpenRequests',
    'confirmation.watchPending',
    // Runs parked on a credential — always empty on a demo (no real dispatch),
    // and filtered per subscriber to the caller's own workspaces like the
    // approvals stream beside it. Reviewed so the always-mounted overlay
    // subscribes to an empty stream instead of erroring.
    'credential_gate.watchBlocked',
    'conversation.watchForSpace',
    'conversation.watchThreadSummaries',
    'dictation.watchPartials',
    'goals.watchForWorkspace',
    'invites.watchForWorkspace',
    'isolated_repo.watchForWorkspace',
    'meeting.watchActionItemStats',
    'meeting.watchActionItems',
    'meeting.watchByWorkspace',
    'meeting.watchDecisionCounts',
    'meeting.watchDecisions',
    'meeting.watchSegments',
    'meeting.watchSpeakers',
    'members.watchForWorkspace',
    // Both workspace-scoped and role-gated (member / admin floors), reading
    // only rows from the visitor's own workspace database.
    'roles.watchForWorkspace',
    'audit.watchRecent',
    // `terminal.output`/`terminal.titles` are built only under
    // `if (terminals != null)` — a demo wires no terminal port, so they are
    // never in its registry at all. Listed so the ratchet knows they were
    // LOOKED at, not because a visitor can reach them.
    'terminal.output',
    'terminal.titles',
    'memory_access_grant.watchByWorkspace',
    'memory_domain.watchForWorkspace',
    'memory_fact.watchForWorkspace',
    'memory_policy.watchForWorkspace',
    'messaging.watchConversationTokens',
    'messaging.watchMessages',
    'messaging.watchMessagesWindow',
    'messaging.watchParticipants',
    'messaging.watchSpaceActivity',
    'messaging.watchSpaceMessages',
    'messaging.watchSpaces',
    'messaging.watchSpaceTurns',
    'newsfeed.watchArticles',
    'newsfeed.watchFeeds',
    'notes.watchForSpace',
    'notifications.watch',
    'notifications.watchItemStates',
    'notifications.watchReadMark',
    'orchestration.watchById',
    'orchestration.watchForWorkspace',
    'orchestration.watchRevisions',
    'pairing.watchOwn',
    'pipeline_run.watchAll',
    'pipeline_run.watchForWorkspace',
    'pipeline_run.watchRun',
    'pipeline_run.watchStepRunsForPipeline',
    'pipeline_template.watchForWorkspace',
    'pipeline_trigger.watchForWorkspace',
    'plan.watchById',
    'plan.watchForWorkspace',
    'playbook.watchForWorkspace',
    'pr.watchNeedsMyReviewCount',
    'pr.watchOpenForWorkspace',
    'pr.watchRepoAccessForWorkspace',
    'pr_lifecycle.watchByWorkspace',
    'pr_review.watchCheckRuns',
    'pr_review.watchCommitFiles',
    'pr_review.watchCommitStatuses',
    'pr_review.watchCommits',
    'pr_review.watchDiff',
    'pr_review.watchFileContent',
    'pr_review.watchFiles',
    'pr_review.watchIssueComments',
    'pr_review.watchPullRequest',
    'pr_review.watchReviewComments',
    'pr_review.watchReviewers',
    'pr_review.watchReviews',
    'pr_review.watchTimelineEvents',
    'presence.watch',
    'prefs.watchOwn',
    'project.watchForWorkspace',
    'provider_policy.watchForWorkspace',
    'reactions.watchForSpace',
    'repos.watchAll',
    'repos.watchScriptRuns',
    'review_space.watchAllBySpace',
    'review_space.watchByPr',
    'review_space.watchBySpace',
    'review_space.watchByWorkspace',
    'review_studio.watchAxisResults',
    'review_studio.watchCohorts',
    'review_studio.watchContractDiffs',
    'review_studio.watchDependencyDiffs',
    'review_studio.watchVisualDiffs',
    'rig.watchPorts',
    'rig.watchSessions',
    'server_settings.watch',
    'space_read.watchUserLastReadAt',
    'sync.watch',
    'team.watchMembersOf',
    'team.watchTeamsForWorkspace',
    'ticket_link.watchForTicket',
    'ticket_sync_config.watchForWorkspace',
    'ticket_sync_log.watchForWorkspace',
    'tickets.watchCollaborators',
    'tickets.watchForWorkspace',
    'todos.watch',
    'todos.watchGoal',
    'users.watchAll',
    'voice_profile.watchForWorkspace',
    'workProduct.watchById',
    'workProduct.watchForSpace',
    'workspace.watchAll',
    'workspace.watchReposForWorkspace',
    'workspace_settings.watchForWorkspace',
  };

  /// Whether [op] may be reached by a demo visitor.
  bool admits(RepoOp op) {
    if (deniedMutations.contains(op.name)) {
      return false;
    }
    if (!prefixExceptions.contains(op.name) &&
        deniedPrefixes.any(op.name.startsWith)) {
      return false;
    }
    if (op.actionClasses.any(forbiddenClasses.contains)) {
      return false;
    }
    if (op.kind == RepoOpKind.read) {
      return !deniedReads.contains(op.name);
    }
    // Default-deny for everything that mutates.
    return allowedMutations.contains(op.name);
  }

  /// Returns [registry] narrowed to the ops this profile admits.
  ///
  /// Rebuilding the registry (rather than filtering at dispatch time) means a
  /// refused op is genuinely absent: `lookup` returns null and the dispatcher
  /// answers `opUnknown`, exactly as it does for an op that was never built.
  RepoOpRegistry lockdown(RepoOpRegistry registry) => RepoOpRegistry([
    for (final op in registry.ops)
      if (admits(op)) op,
  ], catalogVersion: registry.catalogVersion);

  /// Returns [registry] narrowed to the watch queries this profile reviewed.
  ///
  /// The subscription lane's counterpart of [lockdown]: an unreviewed watch is
  /// absent, so `sub/subscribe` answers for it exactly as it does for a watch
  /// that was never built.
  WatchQueryRegistry lockdownWatch(WatchQueryRegistry registry) =>
      WatchQueryRegistry([
        for (final query in registry.queries)
          if (reviewedWatchQueries.contains(query.name)) query,
      ]);
}
