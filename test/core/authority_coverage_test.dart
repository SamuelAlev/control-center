import 'dart:io';

import 'package:test/test.dart';

/// Ratchets for the two authority declarations `op/list` cannot lie about.
///
/// 1. **Unscoped ops**: `RepoOpDispatcher` evaluates the workspace role gate
///    only for `workspaceScoped` ops, so an unscoped op's ONLY declarative
///    gate is `serverAuthority`. Every unscoped op must either declare it or
///    sit in the curated self-service list below with its reason — otherwise
///    a new install-wide op ships gated by nothing but hope.
/// 2. **Watch queries**: the reactive lane used to be membership-only (the
///    invite roster and the whole audit trail streamed to guests). Every
///    workspace-scoped `WatchQuery` must either declare a `minRole` or be
///    pinned in the guest-visible set; every unscoped watch must declare
///    `serverAuthority` or be pinned with its self-scoping reason.
///
/// Source-level (grep) tests, like `rpc_op_coverage_test.dart` — the catalog
/// takes ~40 dependencies to instantiate. Dynamic (`$`-interpolated) names
/// are skipped, never false-flagged.
void main() {
  Directory repoRoot() {
    var dir = Directory.current;
    while (true) {
      if (File(
        '${dir.path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
      ).existsSync()) {
        return dir;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        return Directory.current;
      }
      dir = parent;
    }
  }

  final root = repoRoot();
  final serverSrcDir = Directory(
    '${root.path}/packages/cc_server_core/lib/src',
  );

  // Strip line comments so prose naming `workspaceScoped: false` (or a field)
  // between two declarations is never attributed to the preceding one.
  String stripped(File f) => f
      .readAsStringSync()
      .replaceAll(RegExp(r'^\s*//.*', multiLine: true), '');

  final nameRe = RegExp(r"name:\s*'([^'$]+)'");

  List<String> bodiesOf(String source, String constructor) {
    // NB `$` (with dotAll, without multiLine) is end-of-input — Dart RegExp
    // has no `\Z`, and using it silently drops the LAST declaration in every
    // file.
    final re = RegExp(
      '$constructor\\((.*?)(?=RepoOp\\(|WatchQuery\\(|\$)',
      dotAll: true,
    );
    return [for (final m in re.allMatches(source)) m.group(1)!];
  }

  final opBodies = <String>[];
  final watchBodies = <String>[];
  for (final entity in serverSrcDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final src = stripped(entity);
    if (src.contains('RepoOp(')) {
      opBodies.addAll(bodiesOf(src, 'RepoOp'));
    }
    if (src.contains('WatchQuery(')) {
      watchBodies.addAll(bodiesOf(src, 'WatchQuery'));
    }
  }

  test('every unscoped RepoOp declares serverAuthority or is self-service', () {
    // The curated self-service set: unscoped ops whose handler scopes to the
    // CALLING USER (or an in-handler gate) by construction, so no server
    // authority applies. Grouped by why. Adding an op here is a review
    // decision — the alternative is declaring `serverAuthority:` on the op.
    const selfService = <String>{
      // Self-scoped to ctx.userId: personal preferences/credentials/identity.
      'prefs.getAll', 'prefs.set',
      'credentials.setGitHubToken', 'credentials.setForgeToken',
      'credentials.clearForgeToken', 'credentials.setTicketingToken',
      'credentials.clearTicketingToken',
      'identity.me', 'users.updateProfile', 'users.markOnboardingFinished',
      'subscriptions.usage',
      // Per-user newsfeed (its own user-scoped pillar).
      'newsfeed.addFeed', 'newsfeed.deleteFeed', 'newsfeed.getArticle',
      'newsfeed.listArticles', 'newsfeed.markAllRead', 'newsfeed.refreshAll',
      'newsfeed.refreshFeed', 'newsfeed.seedDefaultFeedsIfEmpty',
      'newsfeed.setArticleRead', 'newsfeed.setArticleSaved',
      'newsfeed.setFeedEnabled',
      // Per-user provider/oauth flows (the target is always the caller).
      'oauth.begin', 'oauth.providers',
      'providers.addCustom', 'providers.cancelOAuth',
      'providers.completeOAuth', 'providers.list', 'providers.listModels',
      'providers.oauthStatus', 'providers.removeCredential',
      'providers.removeCustom', 'providers.removeModelOverride',
      'providers.saveApiKey', 'providers.saveGenerationDefaults',
      'providers.saveModelOverride', 'providers.startOAuth',
      'forge.capabilities', 'forge.listConnections', 'forge.testConnection',
      'ticketing.listConnections', 'github.currentUser', 'github.userProfile',
      // In-handler gates (owner/admin/membership checks inside the handler,
      // documented at each site).
      'workspace.upsert', 'workspace.delete', 'workspace.reorder',
      'confirmation.respond', 'connectivity.setTunnel',
      'pairing.list', 'pairing.rename', 'pairing.revoke',
      // Non-secret, read-only host/service probes and utility reads.
      'adapter.detectAll', 'adapter.detectOne', 'claude.serviceStatus',
      'claude_accounts.list', 'connection.describe', 'connection.ping',
      'connectivity.status', 'github.serviceStatus', 'kimi.serviceStatus',
      'openai.serviceStatus', 'serviceStatus.getAll', 'sandbox.detect',
      'ide.detectEditors', 'process.detect', 'fonts.list',
      'gif.search', 'gif.trending', 'demo.repoStars',
      'models.voiceCatalog',
      // Cross-workspace reads filtered per subscriber / membership inside.
      'isolated_repo.forSpaceAcrossWorkspaces',
      'isolated_repo.forTicketAcrossWorkspaces',
      'orchestration.approvedNeedingMaterialization',
      'orchestration.forPipelineRunAnyWorkspace',
      'pipeline_trigger.enabledForEvent', 'pipeline_trigger.scheduled',
      'users.list', 'credential_gate.resolve',
      // The worker lane: authenticated by worker credentials at its own
      // chokepoint, not by human workspace roles.
      'fleet.drainWorker', 'fleet.registerWorker', 'fleet.removeWorker',
      'fleet.resumeWorker', 'fleet.revokeWorker', 'fleet.workerComplete',
      'fleet.workerEvents', 'fleet.workerHeartbeat', 'fleet.workerPoll',
      // Local host utilities (fullClient-capability-gated where mutating).
      'fs.browseDirectory', 'process.kill', 'acp.listModels',
    };

    final offenders = <String>[];
    for (final body in opBodies) {
      if (!body.contains('workspaceScoped: false')) {
        continue;
      }
      if (body.contains('serverAuthority:')) {
        continue;
      }
      final name = nameRe.firstMatch(body)?.group(1);
      if (name == null) {
        continue; // dynamic name — checked by review, not this ratchet
      }
      if (!selfService.contains(name)) {
        offenders.add(name);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Unscoped op(s) with no serverAuthority declaration and no '
          'self-service exemption. The workspace role gate never runs for '
          'these, so declare `serverAuthority: ServerAuthority.serverOwner` '
          'or argue the op into the self-service set with its reason:\n'
          '${offenders.map((o) => "  $o").join("\n")}',
    );

    // Stale entries rot the list into noise: every exempted name must still
    // exist as an unscoped op.
    final unscopedNames = <String>{};
    for (final body in opBodies) {
      if (!body.contains('workspaceScoped: false')) {
        continue;
      }
      final name = nameRe.firstMatch(body)?.group(1);
      if (name != null) {
        unscopedNames.add(name);
      }
    }
    final stale = selfService.difference(unscopedNames);
    expect(
      stale,
      isEmpty,
      reason:
          'Self-service exemption(s) name no current unscoped op — remove '
          'them:\n${stale.map((s) => "  $s").join("\n")}',
    );
  });

  test('every WatchQuery declares its authority or is pinned', () {
    // Workspace-scoped watches with NO explicit minRole are guest-visible
    // (membership is still required). This pins that set: a new watch fails
    // here until someone chooses its floor — the invite roster and the audit
    // trail streamed to guests precisely because nothing forced the choice.
    const guestVisible = <String>{
      // Agent/run/goal activity (content guests may read via read ops too).
      'agentGoalRuns.watchForConversation',
      'agent_run_log.watchActiveByConversation',
      'agent_run_log.watchActiveBySpace', 'agent_run_log.watchByAgent',
      'agent_run_log.watchByConversation', 'agent_run_log.watchBySpace',
      'agent_run_log.watchRunTranscript',
      'agent_working_memory.watchByAgent',
      'agent_working_memory.watchByWorkspace',
      'agents.watchForWorkspace',
      // Calendar / meetings.
      'calendar.watchAccounts', 'calendar.watchEventById',
      'calendar.watchEventsInRange', 'calendar.watchSources',
      'meeting.watchActionItemStats', 'meeting.watchActionItems',
      'meeting.watchByWorkspace', 'meeting.watchDecisionCounts',
      'meeting.watchDecisions', 'meeting.watchSegments',
      'meeting.watchSpeakers',
      // Messaging / conversations / notifications.
      'chat.watchUserLinks', 'conversation.watchForSpace',
      'conversation.watchThreadSummaries', 'dictation.watchPartials',
      'messaging.watchConversationTokens', 'messaging.watchMessages',
      'messaging.watchMessagesWindow', 'messaging.watchParticipants',
      'messaging.watchSpaceActivity', 'messaging.watchSpaceMessages',
      'messaging.watchSpaceTurns', 'messaging.watchSpaces',
      'notes.watchForSpace', 'notifications.watch',
      'notifications.watchItemStates', 'notifications.watchReadMark',
      'reactions.watchForSpace', 'space_read.watchUserLastReadAt',
      'presence.watch',
      // Work surfaces (tickets, plans, PRs, reviews, todos, memory, teams).
      'goals.watchForWorkspace', 'isolated_repo.watchForWorkspace',
      'members.watchForWorkspace', 'memory_domain.watchForWorkspace',
      'memory_fact.watchForWorkspace', 'orchestration.watchById',
      'orchestration.watchForWorkspace', 'orchestration.watchRevisions',
      'pipeline_run.watchForWorkspace', 'pipeline_run.watchRun',
      'pipeline_run.watchStepRunsForPipeline',
      'pipeline_template.watchForWorkspace',
      'pipeline_trigger.watchForWorkspace',
      'plan.watchById', 'plan.watchForWorkspace', 'playbook.watchForWorkspace',
      'pr.watchNeedsMyReviewCount', 'pr.watchOpenForWorkspace',
      'pr.watchRepoAccessForWorkspace', 'pr_lifecycle.watchByWorkspace',
      'pr_review.watchCheckRuns', 'pr_review.watchCommitFiles',
      'pr_review.watchCommitStatuses', 'pr_review.watchCommits',
      'pr_review.watchDiff', 'pr_review.watchFileContent',
      'pr_review.watchFiles', 'pr_review.watchIssueComments',
      'pr_review.watchPullRequest', 'pr_review.watchReviewComments',
      'pr_review.watchReviewers', 'pr_review.watchReviews',
      'pr_review.watchTimelineEvents', 'project.watchForWorkspace',
      'repos.watchAll', 'repos.watchScriptRuns',
      'review_space.watchAllBySpace', 'review_space.watchByPr',
      'review_space.watchBySpace', 'review_space.watchByWorkspace',
      'review_studio.watchAxisResults', 'review_studio.watchCohorts',
      'review_studio.watchContractDiffs',
      'review_studio.watchDependencyDiffs', 'review_studio.watchVisualDiffs',
      'team.watchMembersOf', 'team.watchTeamsForWorkspace',
      'ticket_link.watchForTicket', 'tickets.watchCollaborators',
      'tickets.watchForWorkspace', 'todos.watch', 'todos.watchGoal',
      'workProduct.watchById', 'workProduct.watchForSpace',
      'workspace.watchReposForWorkspace',
      // Evals / recordings.
      'evals.watchGoldens', 'evals.watchRecordings',
      'evals.watchRunsForSuite', 'evals.watchSuites',
      // Live surfaces + utilities.
      'codeServer.watchDirtyState', 'codeServer.watchOpenRequests',
      'rig.watchPorts', 'rig.watchSessions', 'terminal.output',
      'terminal.titles', 'soundscape.watchScene', 'weather.watchCurrent',
      'fleet.watchJobs', 'fleet.watchPlacements',
      // The sync change feed: carries rows the guest-readable read surface
      // already exposes; role narrowing happens per-surface, not here.
      'sync.watch',
    };

    // Unscoped watches with no serverAuthority: each must self-scope (to the
    // calling user, or filtered per-subscriber via visibleRows) — reasons at
    // the declaration sites.
    const unscopedSelfScoped = <String>{
      'agent_run_log.watchAll', 'agent_run_log.watchRecent', 'agents.watchAll',
      'confirmation.watchPending', 'credential_gate.watchBlocked',
      'fleet.watchWorkers', 'newsfeed.watchArticles', 'newsfeed.watchFeeds',
      'pairing.watchOwn', 'pipeline_run.watchAll', 'prefs.watchOwn',
      'users.watchAll', 'workspace.watchAll',
    };

    final offenders = <String>[];
    for (final body in watchBodies) {
      final name = nameRe.firstMatch(body)?.group(1);
      if (name == null) {
        continue; // dynamic name (models.watch$capitalized)
      }
      final unscoped = body.contains('workspaceScoped: false');
      if (unscoped) {
        if (!body.contains('serverAuthority:') &&
            !unscopedSelfScoped.contains(name)) {
          offenders.add('$name (unscoped)');
        }
      } else {
        if (!body.contains('minRole:') && !guestVisible.contains(name)) {
          offenders.add('$name (scoped)');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Watch query(ies) with no declared authority. A scoped watch '
          'either declares `minRole:` or is pinned guest-visible here; an '
          'unscoped one either declares `serverAuthority:` or is pinned '
          'self-scoped here. Choose:\n'
          '${offenders.map((o) => "  $o").join("\n")}',
    );

    final allNames = <String>{};
    for (final body in watchBodies) {
      final name = nameRe.firstMatch(body)?.group(1);
      if (name != null) {
        allNames.add(name);
      }
    }
    final stale = {
      ...guestVisible.difference(allNames),
      ...unscopedSelfScoped.difference(allNames),
    };
    expect(
      stale,
      isEmpty,
      reason:
          'Pinned watch name(s) no longer exist — remove them:\n'
          '${stale.map((s) => "  $s").join("\n")}',
    );
  });
}
