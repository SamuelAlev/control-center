import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// A human sentence for an audit-trail [entry] — the machine op
/// (`agents.upsert`) stays on the action chip; this is the prose read of it,
/// e.g. `Updated agent · ceo`.
///
/// Resolution order:
/// 1. A full-action special case (`members.setRole` → "Changed a member's
///    role") for compounds whose verb×domain expansion reads wrong.
/// 2. The generic `verb × domain` expansion: the verb is the FIRST camelCase
///    (or snake_case) segment of the action's verb part, mapped to a localized
///    past-tense template; the domain (the segment before the dot) maps to a
///    localized noun ({target}). Both tables cover every auditable op the
///    server records, so known actions always produce a real sentence.
/// 3. A newer server's unknown verb humanizes the raw verb part
///    (`workerHeartbeat` → "Worker heartbeat") — never an empty line, never
///    the dotted machine op (that stays on the chip).
///
/// A present `targetId` (which the server extracts from conventional arg
/// names — ids, paths, names) is appended after a middle dot, so "Added
/// repository" becomes "Added repository · /Users/sam/control-center".
String describeActivity(AppLocalizations l10n, UserActivityDto entry) {
  final action = entry.action;
  final dot = action.indexOf('.');
  if (dot <= 0 || dot == action.length - 1) {
    return action;
  }
  final domain = action.substring(0, dot);
  final verbPart = action.substring(dot + 1);

  final special = _special(l10n, action);
  final targetId = entry.targetId;
  if (special != null) {
    return _withTarget(special, targetId);
  }

  final lemma = _verbLemma(verbPart);
  var template = lemma == null ? null : _verbTemplate(l10n, lemma);
  if (template == null) {
    // `registryInstall`-style compounds lead with a noun modifier — retry
    // with the trailing segment (`install`).
    final trailing = _trailingSegment(verbPart);
    if (trailing != null && trailing != lemma) {
      template = _verbTemplate(l10n, trailing);
    }
  }
  if (template == null) {
    return _withTarget(_humanize(verbPart), targetId);
  }
  final target = _targetNoun(l10n, domain);
  return _withTarget(template(target), targetId);
}

/// Appends ` · targetId` when the audit record carries one.
String _withTarget(String description, String? targetId) {
  if (targetId == null || targetId.isEmpty) {
    return description;
  }
  return '$description · $targetId';
}

/// The first camelCase or snake_case segment of [verbPart], lowercased:
/// `postReviewComment` → `post`, `role_changed` → `role`, `rsvp` → `rsvp`.
String? _verbLemma(String verbPart) {
  if (verbPart.isEmpty) {
    return null;
  }
  final snake = verbPart.indexOf('_');
  if (snake > 0) {
    return verbPart.substring(0, snake).toLowerCase();
  }
  var end = verbPart.length;
  for (var i = 1; i < verbPart.length; i++) {
    final code = verbPart.codeUnitAt(i);
    final isUpper = code >= 0x41 && code <= 0x5A;
    final isDigit = code >= 0x30 && code <= 0x39;
    if (isUpper || isDigit) {
      end = i;
      break;
    }
  }
  return verbPart.substring(0, end).toLowerCase();
}

/// The trailing camelCase or snake_case segment of [verbPart], lowercased
/// (`registryInstall` → `install`, `role_changed` → `changed`), or null when
/// there is only one segment.
String? _trailingSegment(String verbPart) {
  final snake = verbPart.lastIndexOf('_');
  if (snake > 0 && snake < verbPart.length - 1) {
    return verbPart.substring(snake + 1).toLowerCase();
  }
  for (var i = verbPart.length - 1; i > 0; i--) {
    final code = verbPart.codeUnitAt(i);
    if (code >= 0x41 && code <= 0x5A) {
      return verbPart.substring(i).toLowerCase();
    }
  }
  return null;
}

/// `workerHeartbeat` → `Worker heartbeat`; `setRepoGrant` → `Set repo grant`.
String _humanize(String verbPart) {
  final spaced = verbPart
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ')
      .toLowerCase();
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Full-action sentences for compounds whose verb×domain expansion reads
/// wrong, loses the real subject, or deserves richer copy.
String? _special(AppLocalizations l10n, String action) => switch (action) {
  'fs.persistLogo' || 'fs.persistLogoBytes' => l10n.activitySavedWorkspaceLogo,
  'members.setRole' || 'member.role_changed' => l10n.activityChangedMemberRole,
  'members.setRepoGrant' => l10n.activityChangedMemberRepoAccess,
  'credentials.setGitHubToken' => l10n.activityUpdatedGitHubToken,
  'weather.refreshNow' => l10n.activityRefreshedWeather,
  'weather.setManualLocation' => l10n.activitySetWeatherLocation,
  'weather.clearManualLocation' => l10n.activityClearedWeatherLocation,
  'newsfeed.markAllRead' => l10n.activityMarkedAllArticlesRead,
  'newsfeed.setArticleRead' => l10n.activityMarkedArticleRead,
  'newsfeed.setArticleSaved' => l10n.activityUpdatedSavedArticle,
  'takeover.begin' => l10n.activityTookOverSession,
  'takeover.handBack' => l10n.activityHandedBackSession,
  'worktree.commitAndPush' => l10n.activityCommittedAndPushed,
  'server.backupNow' => l10n.activityBackedUpServer,
  'space_read.markSpaceRead' => l10n.activityMarkedSpaceRead,
  'calendar.rsvp' => l10n.activityRespondedToInvitation,
  'calendar.beginConnect' => l10n.activityStartedCalendarConnect,
  'calendar.disconnect' => l10n.activityDisconnectedCalendar,
  'pr_review.markFileAsViewed' => l10n.activityMarkedFileViewed,
  'confirmation.respond' => l10n.activityRespondedToApproval,
  'connectivity.setTunnel' => l10n.activityChangedTunnel,
  'dispatch.sendUserMessage' => l10n.activitySentMessageToAgent,
  'pr.ensureSpace' => l10n.activityOpenedReviewSpace,
  'conversation.ensure' => l10n.activityOpenedStandingConversation,
  'meeting.startRecording' => l10n.activityStartedRecording,
  'meeting.stopRecording' => l10n.activityStoppedRecording,
  'mcp.setEnabled' => l10n.activityToggledMcpServer,
  'mcp.setToken' => l10n.activityUpdatedMcpToken,
  'providers.saveApiKey' => l10n.activitySavedApiKey,
  'providers.removeCredential' => l10n.activityRemovedProviderCredential,
  'workspace.setReposForWorkspace' => l10n.activityUpdatedLinkedRepos,
  'workspace.unlinkRepoFromWorkspace' => l10n.activityUnlinkedRepo,
  'meeting.setActionItemDone' => l10n.activityUpdatedActionItem,
  _ => null,
};

/// The localized past-tense template for a normalized verb lemma, with the
/// domain noun as {target}. Lemmas are first camel segments, so
/// `refreshNow`→`refresh`, `setFeedEnabled`→`set` (→ Changed).
String Function(String target)? _verbTemplate(
  AppLocalizations l10n,
  String lemma,
) => switch (lemma) {
  'add' => l10n.activityVerbAdded,
  'approve' || 'bless' => l10n.activityVerbApproved,
  'archive' => l10n.activityVerbArchived,
  'assign' => l10n.activityVerbAssigned,
  'backup' => l10n.activityVerbBackedUp,
  'begin' || 'start' || 'spawn' => l10n.activityVerbStarted,
  'cancel' => l10n.activityVerbCancelled,
  'change' || 'set' || 'patch' => l10n.activityVerbChanged,
  'clear' => l10n.activityVerbCleared,
  'close' => l10n.activityVerbClosed,
  'commit' => l10n.activityVerbCommitted,
  'compact' => l10n.activityVerbCompacted,
  'complete' => l10n.activityVerbCompleted,
  'connect' => l10n.activityVerbConnected,
  'continue' => l10n.activityVerbContinued,
  'create' || 'insert' || 'mint' => l10n.activityVerbCreated,
  'delete' => l10n.activityVerbDeleted,
  'disconnect' => l10n.activityVerbDisconnected,
  'dispatch' => l10n.activityVerbDispatched,
  'drain' => l10n.activityVerbDrained,
  'enroll' => l10n.activityVerbEnrolled,
  'ensure' => l10n.activityVerbPrepared,
  'estimate' => l10n.activityVerbEstimated,
  'import' => l10n.activityVerbImported,
  'ingest' => l10n.activityVerbProcessed,
  'install' => l10n.activityVerbInstalled,
  'invite' => l10n.activityVerbInvited,
  'kill' => l10n.activityVerbKilled,
  'mark' => l10n.activityVerbMarked,
  'merge' => l10n.activityVerbMerged,
  'open' => l10n.activityVerbOpened,
  'pause' => l10n.activityVerbPaused,
  'poll' => l10n.activityVerbPolled,
  'publish' => l10n.activityVerbPublished,
  'refine' => l10n.activityVerbRefined,
  'refresh' => l10n.activityVerbRefreshed,
  'register' => l10n.activityVerbRegistered,
  'remove' || 'unlink' || 'unenroll' => l10n.activityVerbRemoved,
  'rename' => l10n.activityVerbRenamed,
  'reorder' => l10n.activityVerbReordered,
  'respond' || 'rsvp' => l10n.activityVerbResponded,
  'restore' => l10n.activityVerbRestored,
  'resume' => l10n.activityVerbResumed,
  'retry' => l10n.activityVerbRetried,
  'revert' => l10n.activityVerbReverted,
  'review' => l10n.activityVerbReviewed,
  'run' => l10n.activityVerbRan,
  'save' || 'update' || 'upsert' => l10n.activityVerbUpdated,
  'select' => l10n.activityVerbSelected,
  'send' => l10n.activityVerbSent,
  'stage' => l10n.activityVerbStaged,
  'steer' => l10n.activityVerbSteered,
  'stop' => l10n.activityVerbStopped,
  'submit' => l10n.activityVerbSubmitted,
  'sync' => l10n.activityVerbSynced,
  'toggle' => l10n.activityVerbToggled,
  'uninstall' => l10n.activityVerbUninstalled,
  'unstage' => l10n.activityVerbUnstaged,
  'write' => l10n.activityVerbWrote,
  _ => null,
};

/// The localized noun for the action's domain segment (the part before the
/// dot), used as {target} in the verb templates. Unknown domains keep their
/// raw segment rather than dropping the sentence.
String _targetNoun(AppLocalizations l10n, String domain) => switch (domain) {
  'action_policy' => l10n.activityTargetActionPolicy,
  'agentGoalRuns' => l10n.activityTargetGoalRun,
  'agent_run_log' => l10n.activityTargetRunLog,
  'agent_working_memory' => l10n.activityTargetWorkingMemory,
  'agents' || 'agent' => l10n.activityTargetAgent,
  'approvals' => l10n.activityTargetRoutingPolicy,
  'autonomy' => l10n.activityTargetAutonomy,
  'budget' || 'budgets' => l10n.activityTargetBudget,
  'cache' => l10n.activityTargetCache,
  'calendar' => l10n.activityTargetCalendar,
  'space_read' || 'space' || 'spaces' => l10n.activityTargetSpace,
  'checker' => l10n.activityTargetChecker,
  'codeServer' || 'ide' => l10n.activityTargetEditor,
  'confirmation' => l10n.activityTargetConfirmation,
  'connectivity' => l10n.activityTargetTunnel,
  'conversation' => l10n.activityTargetConversation,
  'credentials' => l10n.activityTargetCredentials,
  'dictation' => l10n.activityTargetDictation,
  'device' || 'devices' || 'pairing' => l10n.activityTargetDevice,
  'dispatch' => l10n.activityTargetAgentRun,
  'evals' => l10n.activityTargetEvalSuite,
  'fleet' => l10n.activityTargetWorker,
  'fs' || 'file' || 'files' => l10n.activityTargetFile,
  'invite' || 'invites' => l10n.activityTargetInvite,
  'isolated_repo' || 'worktree' => l10n.activityTargetWorktree,
  'mcp' => l10n.activityTargetMcpServer,
  'meeting' || 'meetings' => l10n.activityTargetMeeting,
  'member' || 'members' => l10n.activityTargetMember,
  'memory_access_grant' => l10n.activityTargetMemoryAccessGrant,
  'memory_domain' => l10n.activityTargetMemoryDomain,
  'memory_fact' => l10n.activityTargetMemoryFact,
  'memory_policy' => l10n.activityTargetMemoryPolicy,
  'message' || 'messages' || 'messaging' => l10n.activityTargetMessage,
  'model' || 'models' => l10n.activityTargetModel,
  'newsfeed' => l10n.activityTargetFeed,
  'notes' => l10n.activityTargetNote,
  'orchestration' => l10n.activityTargetOrchestration,
  'pipeline' => l10n.activityTargetPipeline,
  'pipeline_run' => l10n.activityTargetPipelineRun,
  'pipeline_template' ||
  'template' ||
  'templates' => l10n.activityTargetTemplate,
  'pipeline_trigger' => l10n.activityTargetPipelineTrigger,
  'plan' => l10n.activityTargetPlan,
  'playbook' => l10n.activityTargetPlaybook,
  'pr' || 'pr_lifecycle' => l10n.activityTargetPullRequest,
  'pr_review' => l10n.activityTargetReview,
  'prefs' || 'preference' || 'preferences' => l10n.activityTargetPreference,
  'process' => l10n.activityTargetProcess,
  'project' || 'projects' => l10n.activityTargetProject,
  'provider' || 'providers' => l10n.activityTargetProvider,
  'provider_policy' => l10n.activityTargetProviderPolicy,
  'reactions' => l10n.activityTargetReaction,
  'repo' ||
  'repos' ||
  'repository' ||
  'repositories' => l10n.activityTargetRepository,
  'review_space' => l10n.activityTargetReviewSpace,
  'review_studio' => l10n.activityTargetReviewStudio,
  'server' => l10n.activityTargetServerData,
  'skill' || 'skills' => l10n.activityTargetSkill,
  'soundscape' => l10n.activityTargetSoundscape,
  'takeover' => l10n.activityTargetSession,
  'team' || 'teams' => l10n.activityTargetTeam,
  'terminal' => l10n.activityTargetTerminal,
  'ticket' || 'tickets' => l10n.activityTargetTicket,
  'ticket_link' => l10n.activityTargetTicketLink,
  'ticket_sync' => l10n.activityTargetTicketSync,
  'todo' || 'todos' => l10n.activityTargetTodo,
  'users' => l10n.activityTargetProfile,
  'voice_profile' => l10n.activityTargetVoiceProfile,
  'weather' => l10n.activityTargetWeather,
  'workProduct' => l10n.activityTargetWorkProduct,
  'workspace' || 'workspaces' => l10n.activityTargetWorkspace,
  _ => domain,
};

/// Whether [ip] is a private or loopback literal (RFC 1918, loopback,
/// link-local, IPv6 loopback/link-local/ULA) — such an address carries no
/// GeoIP signal, so the UI labels it [AppLocalizations.activityNetworkLocal]
/// instead of a country.
bool isPrivateIp(String ip) {
  final v4 = ip.split('.');
  if (v4.length == 4) {
    final a = int.tryParse(v4[0]);
    final b = int.tryParse(v4[1]);
    if (a == null || b == null) {
      return false;
    }
    return a == 127 ||
        a == 10 ||
        (a == 192 && b == 168) ||
        (a == 172 && b >= 16 && b <= 31);
  }
  final lower = ip.toLowerCase();
  return lower == '::1' ||
      lower.startsWith('fe80:') ||
      lower.startsWith('fc') ||
      lower.startsWith('fd');
}

/// The country chip label for [entry]: the resolved ISO country code when the
/// server GeoIP lookup produced one, the local-network label for private /
/// loopback literals, or null when there is nothing meaningful to show (or no
/// IP was captured at all).
String? activityCountryLabel(AppLocalizations l10n, UserActivityDto entry) {
  final ip = entry.ip;
  if (ip == null || ip.isEmpty) {
    return null;
  }
  final code = entry.countryCode;
  if (code != null && code.isNotEmpty) {
    return code;
  }
  return isPrivateIp(ip) ? l10n.activityNetworkLocal : null;
}
