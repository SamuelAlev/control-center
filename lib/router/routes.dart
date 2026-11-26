/// Application route paths.
///
/// Every in-app destination lives under a `/workspaces/:workspaceId/…` prefix:
/// the workspace id in the URL is the single source of truth for the app's
/// active-workspace context (see `activeWorkspaceIdProvider`, which is driven
/// from the route). Route builders therefore take the workspace id as their
/// first argument and return a concrete path. Pass [workspaceIdParam] instead
/// of a real id to produce the go_router *pattern* (e.g. for `GoRoute.path` or
/// breadcrumb-registry keys).
///
/// The only routes WITHOUT a workspace prefix are the pre-context surfaces:
/// [splashRoute], [onboardingRoute] and [workspaceListRoute] (the picker).
library;

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Root navigator key used by the app router.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The go_router path-parameter name carrying the active workspace id. Pass this to any route builder to obtain its `:workspaceId` *pattern* form.
const String workspaceIdParam = ':workspaceId';

/// Loading screen shown while we figure out whether onboarding is complete.
const String splashRoute = '/splash';

/// First-run onboarding (API keys + first workspace).
const String onboardingRoute = '/onboarding';

/// Whether a route is still showing startup or first-run setup. App settings
/// and the command palette stay unavailable on these surfaces.
bool isAuthenticationRoute(String path) =>
    isAtRoute(path, splashRoute) || isAtRoute(path, onboardingRoute);

/// Whether [path] is [route] itself or one of its sub-routes.
///
/// The one way the app asks "is the user on this route": a bare `==` misses a
/// sub-route, and a bare `startsWith` also matches an unrelated sibling
/// (`/onboarding` vs `/onboardingx`).
bool isAtRoute(String path, String route) =>
    path == route || path.startsWith('$route/');

/// Workspaces list / picker. Full-screen (outside the workspace shell) — it is where the user chooses or creates the workspace whose context everything else runs in.
const String workspaceListRoute = '/workspaces';

/// The bare workspace root. Redirects to that workspace's inbox.
String workspaceRoot(String workspaceId) => '/workspaces/$workspaceId';

/// API keys configuration screen.
String apiKeysRoute(String workspaceId) => '/workspaces/$workspaceId/api-keys';

/// Pull requests list screen.
///
/// Pass [repo] (`owner/name`) to select that repository in the left rail.
/// The query is the source of truth for the rail selection, so a breadcrumb
/// or reload lands on the same repo. Omit it for the implicit first-repo
/// selection used by the sidebar.
String pullRequestsRoute(String workspaceId, {String? repo}) {
  final base = '/workspaces/$workspaceId/pull-requests';
  if (repo == null || repo.isEmpty) {
    return base;
  }
  return '$base?repo=${Uri.encodeQueryComponent(repo)}';
}

/// Compose-a-new-pull-request screen. Static segment, matched before the
/// `:prNumber` detail route so "compose" isn't parsed as a PR number.
///
/// [spaceId] carries the conversation the compose was launched from (the
/// Source Control panel's "Create pull request"). It is the only way the compose
/// screen can find the conversation's isolated worktree — and therefore the
/// branch the user actually means to open a PR from. Dropping it was why that
/// entry point led to two empty branch pickers: the screen fell back to the
/// GitHub remote's ref list, which by construction cannot contain a
/// never-pushed `space/<id>` worktree branch.
String pullRequestsComposeRoute(String workspaceId, {String? spaceId}) {
  final base = '/workspaces/$workspaceId/pull-requests/compose';
  return (spaceId == null || spaceId.isEmpty)
      ? base
      : '$base?space=${Uri.encodeQueryComponent(spaceId)}';
}

/// Pull request detail screen for PR [number] in [repoFullName] (`owner/repo`).
///
/// PR numbers are unique only *within* a repo and the queue spans every repo
/// linked to the workspace, so the repo is part of the path:
/// `…/pull-requests/<owner>/<repo>/<number>`. The repo in the URL — not the
/// active repo — is what the detail screen resolves the PR against, so a
/// deep-link or reload always shows the right PR.
/// Pass [tab] to open a specific workbench tab (`?tab=<key>`), and [commentId]
/// to deep-link to one comment (`?comment=<id>`, the numeric REST id).
///
/// Pass [commits] to scope the diff to those SHAs (`?commits=sha,sha`). An
/// empty set is the whole pull request and adds no param — the unscoped diff
/// is a URL with no commit search param.
///
/// There is deliberately no `thread` parameter: the detail screen already
/// reassembles threads from their comments, so a thread id in the URL would be
/// a second source of truth for the same fact — and the two could disagree
/// once a thread is split or a comment deleted.
///
/// [forge] rides as `?forge=` for anything but GitHub, so a workspace linking
/// the same `owner/name` on two forges opens the right one; absent reads as
/// "unstated" ([prForgeFromQuery]).
String pullRequestDetailRoute(
  String workspaceId,
  String repoFullName,
  int number, {
  String? tab,
  int? commentId,
  Set<String> commits = const {},
  ForgeHost? forge,
}) {
  final base = '/workspaces/$workspaceId/pull-requests/$repoFullName/$number';
  final query = <String>[
    if (forge != null && forge != ForgeHost.github)
      '$kPrForgeQueryParam=${forge.wire}',
    if (tab != null && tab.isNotEmpty) 'tab=${Uri.encodeComponent(tab)}',
    if (commentId != null) 'comment=$commentId',
    if (commits.isNotEmpty) 'commits=${_encodeCommitShas(commits)}',
  ];
  return query.isEmpty ? base : '$base?${query.join('&')}';
}

/// Query param naming the forge of a PR-detail route (non-GitHub only).
const String kPrForgeQueryParam = 'forge';

/// The forge a PR-detail route states, or null when it states none (GitHub
/// links, and every link built before the param existed).
ForgeHost? prForgeFromQuery(Map<String, String> query) {
  final raw = query[kPrForgeQueryParam];
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final forge = ForgeHost.fromWire(raw);
  return forge.isSupported ? forge : null;
}

/// Query param naming the commits the diff is scoped to.
///
/// Absent, blank, or empty means the whole pull request.
const String prCommitsQueryParam = 'commits';

/// SHAs named by [prCommitsQueryParam] on [params]. Empty when the diff should
/// show every commit.
Set<String> prCommitsFromQuery(Map<String, String> params) {
  final raw = params[prCommitsQueryParam];
  if (raw == null || raw.trim().isEmpty) {
    return const {};
  }
  return {
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  };
}

/// [current] with [prCommitsQueryParam] set to [shas], sorted, or removed when
/// [shas] is empty. Other query params stay. An empty query is stripped so
/// the unscoped diff has no search params. SHAs stay comma-separated rather
/// than percent-encoded, so the param reads as a list.
String locationWithPrCommits(Uri current, Set<String> shas) {
  final params = Map<String, String>.of(current.queryParameters)
    ..remove(prCommitsQueryParam);
  if (shas.isNotEmpty) {
    params[prCommitsQueryParam] = (shas.toList()..sort()).join(',');
  }
  if (params.isEmpty) {
    final raw = current.toString();
    final q = raw.indexOf('?');
    return q < 0 ? raw : raw.substring(0, q);
  }
  final query = params.entries
      .map((entry) {
        if (entry.key == prCommitsQueryParam) {
          final list = entry.value
              .split(',')
              .map(Uri.encodeQueryComponent)
              .join(',');
          return '${entry.key}=$list';
        }
        return '${Uri.encodeQueryComponent(entry.key)}='
            '${Uri.encodeQueryComponent(entry.value)}';
      })
      .join('&');
  return current.replace(query: query).toString();
}

String _encodeCommitShas(Set<String> shas) => (shas.toList()..sort()).join(',');

/// Spaces list / conversation surface (no space selected).
String spacesRoute(String workspaceId) => '/workspaces/$workspaceId/spaces';

/// A specific space (conversation) by [spaceId]. The id in the URL is the
/// source of truth for the selected conversation, so a deep-link or reload
/// always reopens the right space.
///
/// Pass [messageId] to deep-link to a specific message (a permalink target):
/// it rides as a `?m=<id>` query param, which drops out of the path-based
/// space-selection parser and is consumed once on open.
///
/// Pass [tab] to deep-link to a specific editor tab (`?tab=<key>`, an editor
/// tab URL key such as a conversation's [conversationTabKey]) — how the
/// sidebar's conversation rows focus one conversation's tab.
String spaceRoute(
  String workspaceId,
  String spaceId, {
  String? messageId,
  String? tab,
}) {
  final base = '/workspaces/$workspaceId/spaces/$spaceId';
  final query = [
    if (messageId != null && messageId.isNotEmpty) 'm=$messageId',
    if (tab != null && tab.isNotEmpty) 'tab=${Uri.encodeQueryComponent(tab)}',
  ].join('&');
  return query.isEmpty ? base : '$base?$query';
}

/// The `?tab=` key of the chat tab showing [conversationId] in its space.
///
/// Lives here rather than with the messaging tab kinds so layers that may not
/// import a feature (notification deep links in `core/`) can still target one
/// conversation of a space instead of whichever one is standing.
String conversationTabKey(String conversationId) => 'chat:$conversationId';

/// The `?tab=` key of the goal tab showing [goalId] in its space.
String goalTabKey(String goalId) => 'goal:$goalId';

/// Ticketing board (work items the agents read from and act on).
String ticketsRoute(String workspaceId) => '/workspaces/$workspaceId/tickets';

/// Ticket detail screen for [id].
String ticketDetailRoute(String workspaceId, String id) =>
    '/workspaces/$workspaceId/tickets/$id';

/// Project overview screen for [projectId] (grouped tickets + progress).
String projectOverviewRoute(String workspaceId, String projectId) =>
    '/workspaces/$workspaceId/projects/$projectId';

/// Newsfeed (RSS reader) home — all articles, with All/Unread/Saved views.
String newsfeedRoute(String workspaceId) => '/workspaces/$workspaceId/newsfeed';

/// Article reader (in-app webview) for a given article id.
String newsfeedArticleRoute(String workspaceId, String articleId) =>
    '/workspaces/$workspaceId/newsfeed/article/$articleId';

//
// Settings paths are namespaced by SCOPE — `you/`, `workspace/`, `server/` —
// because the question an operator asks of a setting is "who does changing this
// affect: just me, just this laptop, everyone in this workspace, or the whole
// server?". The segment answers it in the URL, the route registry and the
// breadcrumb, not just in the sidebar grouping.
//
// The `/workspaces/:workspaceId` prefix stays on every settings path, including
// the user- and server-scoped ones. There the workspace id is CONTEXT — which
// workspace you were in when you opened settings — so the shell, the auth
// guard and "return to where you were" keep their existing contract. The scope
// segment, not the prefix, is what states the blast radius.

/// Settings root (redirects to [settingsLandingRoute]).
String settingsRoute(String workspaceId) => '/workspaces/$workspaceId/settings';

/// Where Settings opens: You → Profile, the first page in its sidebar.
String settingsLandingRoute(String workspaceId) =>
    settingsAccountProfileRoute(workspaceId);

/// Settings → Workspace → Profile & identity.
String settingsProfileRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/profile';

/// Settings → You → Profile: who the person is on this server (username,
/// name, picture, single sign-on identity), then the accounts they connect
/// for themself (code hosting, ticketing, calendar and chat sign-ins).
String settingsAccountProfileRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/profile';

/// [settingsAccountProfileRoute] opened at its connected accounts, for a link
/// that is about one of them. Read back with [opensAtConnectedAccounts].
String settingsAccountsRoute(String workspaceId) =>
    '${settingsAccountProfileRoute(workspaceId)}?section=accounts';

/// Whether [uri] asks for the profile page at its connected accounts: what
/// [settingsAccountsRoute] writes.
bool opensAtConnectedAccounts(Uri uri) =>
    uri.queryParameters['section'] == 'accounts';

/// Settings → You → Appearance (theme, language, typography, editor theme).
String settingsAppearanceRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/appearance';

/// Settings → You → Notifications (per-event toggles, quiet hours).
String settingsNotificationsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/notifications';

/// Settings → You → Commits (authorship, co-author credit, signing key).
String settingsCommitsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/commits';

/// Settings → You → Audio (microphone, dictation, meeting detection,
/// soundscape output).
String settingsAudioRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/audio';

/// Settings → You → Desktop app (tray icon, closing the window, opening at
/// login). Desktop-only: the page configures the native process.
String settingsDesktopAppRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/desktop';

/// Settings → You → Your devices (paired phones + remote control).
String settingsRemoteControlRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/devices';

/// Settings → You → Newsfeed (the user's feed registry + reader prefs — the
/// feed list is per-user, so it lives in the You scope).
String settingsNewsfeedRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/newsfeed';

/// Settings → You → Links (the workspace a repository's external links open
/// in, when several workspaces link it).
String settingsLinksRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/links';

/// Settings → Workspace → General (secret globs, review concurrency, commit
/// attribution, branch naming).
String settingsWorkspaceGeneralRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/general';

/// Settings → Workspace → Integrations (the workspace's Connect choice and
/// its side of code hosting, tickets and sync health, calendar, chat bridges
/// and GIFs; a person's own sign-ins live on [settingsAccountsRoute]).
String settingsWorkspaceIntegrationsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/integrations';

/// Settings → Workspace → Meetings (note templates and saved voice profiles).
String settingsMeetingsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/meetings';

/// Settings → Workspace → Members & roles (roster, invites, audit trail).
String settingsMembersRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/members';

/// Replaces or clears the `cursor` query param on [current] (the audit
/// trail's page token). An empty/null cursor strips the param so the
/// newest page is a clean members URL.
String uriWithCursor(Uri current, String? cursor) {
  final params = Map<String, String>.of(current.queryParameters)
    ..remove('cursor');
  if (cursor != null && cursor.isNotEmpty) {
    params['cursor'] = cursor;
  }
  if (params.isEmpty) {
    final raw = current.toString();
    final q = raw.indexOf('?');
    return q < 0 ? raw : raw.substring(0, q);
  }
  return current.replace(queryParameters: params).toString();
}

/// Settings → Workspace → Agents (registered agent identities).
String settingsAgentsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/agents';

/// Settings → Workspace → Repositories.
String settingsReposRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/repositories';

/// Settings → Workspace → Environments.
String settingsEnvironmentsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/environments';

/// Stands in for the id of a definition that has not been saved yet. Stored
/// definitions have UUIDs, so it cannot name one.
const settingsNewEnvironmentId = 'new';

/// One definition, open on Settings → Workspace → Environments.
String settingsEnvironmentRoute(String workspaceId, String definitionId) =>
    '${settingsEnvironmentsRoute(workspaceId)}/$definitionId';

/// Settings → Workspace → Skills.
String settingsSkillsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/skills';

/// Settings → Workspace → Agent permissions (guardrail matrix, what-if probe).
String settingsGuardrailsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/permissions';

/// Settings → Workspace → Code mode: whether runs get the script tool, and
/// the limits a script runs under.
String settingsCodeModeRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/code-mode';

/// Settings → Workspace → Schedules: the workspace's schedules and watches
/// (wake rules), its limits on them, and what happens to requests nobody
/// answers.
String settingsSchedulesRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/schedules';

/// One schedule or watch's page, open on Settings → Workspace → Schedules.
String scheduleRoute(String workspaceId, String ruleId) =>
    '${settingsSchedulesRoute(workspaceId)}/$ruleId';

/// Settings → Server → Connection & status: which server this client talks to,
/// plus how this server is shared (mDNS, tunnel opt-in, relay usage).
String settingsServerConnectionRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/connection';

/// Settings → Server → Single sign-on (SAML + OIDC + SCIM provisioning).
String settingsSsoRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/sso';

/// Query on [settingsAdaptersRoute] that opens one runner's detail pane.
const settingsAdapterQueryParam = 'adapter';

/// Settings → Server → Model providers & adapters.
///
/// [adapterId] selects that runner on arrival (`claude-code`, for example)
/// so a caller that is sending someone there to sign in does not land on
/// whichever runner the page would have opened by itself.
String settingsAdaptersRoute(String workspaceId, {String? adapterId}) {
  final path = '/workspaces/$workspaceId/settings/server/providers';
  if (adapterId == null || adapterId.isEmpty) {
    return path;
  }
  return '$path?$settingsAdapterQueryParam=${Uri.encodeQueryComponent(adapterId)}';
}

/// Settings → Server → MCP servers (built-in + external).
String settingsMcpRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/mcp';

/// Settings → Server → Voice & meeting models (ASR, diarization).
String settingsVoiceMeetingsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/voice';

/// Settings → Server → Diagnostics & privacy (sandboxing, embedding, sync
/// engine, logging, crash reporting).
String settingsDiagnosticsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/diagnostics';

/// Settings → Server → Audit log: who changed what, across the server trail
/// (server owner) and every workspace the person administers.
String settingsServerAuditRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/audit';

/// Settings → Server → People: every account on the server and whether its
/// email is confirmed. Server owner only.
String settingsServerPeopleRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/people';

/// Settings → Server → Enclosures (rigs): what this host can boot, the base
/// images, and the machines running right now.
///
/// A server-capability page rather than a workspace destination: whether a rig
/// can boot at all is a property of the machine running `cc_server`, and the
/// live view of a running one belongs beside the work it is doing (a space
/// or PR tab), not in a separate place you have to go and find.
String settingsRigsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/rigs';

/// Settings → Server → Sandbox: which worktrees the operator has allowed
/// agents to run programs from.
///
/// A server-capability page for the same reason Enclosures is one: the exec
/// block being re-opened is a property of the sandbox on the host running
/// `cc_server`, not of a workspace destination.
String settingsSandboxRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/sandbox';

/// Settings → Server → Backup & restore: whole-install snapshots, plus the
/// export, import and delete operations for one workspace.
///
/// Server-scoped for the same reason Enclosures and Sandbox are: a snapshot
/// covers every database this install holds, not the workspace in the URL.
String settingsBackupRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/backup';

/// Settings → Server → About & updates.
String settingsAboutRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/about';

/// The unified inbox (PRD 19 §7): PRs classified by review lifecycle plus
/// everything non-PR that blocks the operator.
String inboxRoute(String workspaceId) => '/workspaces/$workspaceId/inbox';

/// Observability hub: live Agent Hub + cost/usage/quota/behavior analytics
/// Defaults to the Agent Hub tab.
String observabilityRoute(String workspaceId) =>
    '/workspaces/$workspaceId/observability';

/// Observability → Code executions: the scripts a workspace's runs ran,
/// newest first.
///
/// [runId], [conversationId] and [agentId] scope the list to one run,
/// conversation or agent; [statuses] (wire names) narrows it by outcome. They
/// ride as query parameters so a scoped list is a URL like any other.
String codeExecutionsRoute(
  String workspaceId, {
  String? runId,
  String? conversationId,
  String? agentId,
  Iterable<String> statuses = const [],
}) {
  final base = '/workspaces/$workspaceId/observability/code-executions';
  final query = <String, String>{
    if (runId != null && runId.isNotEmpty) codeExecutionsRunParam: runId,
    if (conversationId != null && conversationId.isNotEmpty)
      codeExecutionsConversationParam: conversationId,
    if (agentId != null && agentId.isNotEmpty)
      codeExecutionsAgentParam: agentId,
    if (statuses.isNotEmpty) codeExecutionsStatusParam: statuses.join(','),
  };
  return query.isEmpty
      ? base
      : Uri(path: base, queryParameters: query).toString();
}

/// The query parameter scoping [codeExecutionsRoute] to one run.
const String codeExecutionsRunParam = 'run';

/// The query parameter scoping [codeExecutionsRoute] to one conversation.
const String codeExecutionsConversationParam = 'conversation';

/// The query parameter scoping [codeExecutionsRoute] to one agent.
const String codeExecutionsAgentParam = 'agent';

/// The query parameter narrowing [codeExecutionsRoute] to some outcomes, as
/// comma-separated wire names.
const String codeExecutionsStatusParam = 'status';

/// One code execution's record.
///
/// An execution id is opaque and can hold `/` and `#` (`run-1/call_3#2`), so
/// it is encoded as ONE path segment here and read back whole from the
/// route's path parameter; nothing may split it.
String codeExecutionRoute(String workspaceId, String executionId) =>
    '/workspaces/$workspaceId/observability/code-executions/'
    '${executionId == codeExecutionIdParam ? executionId : Uri.encodeComponent(executionId)}';

/// The go_router parameter of [codeExecutionRoute]'s pattern.
const String codeExecutionIdParam = ':executionId';

/// GitHub user profile screen.
String userProfileRoute(String workspaceId, String login) =>
    '/workspaces/$workspaceId/users/$login';

/// GitHub organization team profile screen.
String teamProfileRoute(String workspaceId, String organization, String slug) =>
    '/workspaces/$workspaceId/teams/$organization/$slug';

/// Pipeline runs list screen.
String pipelinesRoute(String workspaceId) =>
    '/workspaces/$workspaceId/pipelines';

/// Manual run launcher — pick a manually-runnable pipeline, fill its input
/// form and start a run.
String runPipelineRoute(String workspaceId) =>
    '/workspaces/$workspaceId/pipelines/run';

/// Pipeline run detail screen — shows step timeline for a specific run.
String pipelineRunRoute(String workspaceId, String runId) =>
    '/workspaces/$workspaceId/pipelines/$runId';

/// Pipeline templates settings screen — list and edit pipeline templates.
String settingsPipelinesRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/pipelines';

/// Pipeline template editor (drag-and-drop canvas) for a specific template.
String pipelineTemplateEditorRoute(String workspaceId, String templateId) =>
    '/workspaces/$workspaceId/settings/pipelines/$templateId';

/// Plan Studio hub — active plans, plan documents and playbooks.
String plansRoute(String workspaceId) => '/workspaces/$workspaceId/plans';

/// Plan Studio for one plan. [kind] is `orchestration` or `document`; [id] is the orchestration or plan-document id.
String planStudioRoute(String workspaceId, String kind, String id) =>
    '/workspaces/$workspaceId/plans/$kind/$id';

/// Memory (knowledge) screen: facts, policies and the knowledge graph. Lives
/// under `/settings` so the settings sub-sidebar stays mounted.
String memoryRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/memory';

/// One fact, open on the Memory screen.
String memoryFactRoute(String workspaceId, String factId) =>
    '${memoryRoute(workspaceId)}/facts/$factId';

/// One policy, open on the Memory screen.
String memoryPolicyRoute(String workspaceId, String policyId) =>
    '${memoryRoute(workspaceId)}/policies/$policyId';

/// Query parameter selecting an initial tab on [memoryRoute].
const String memoryTabQueryParam = 'tab';

/// Tab key opening [memoryRoute] on its Improvements tab.
const String memoryImprovementsTabKey = 'improvements';

/// Memory screen opened directly at its Improvements tab.
String memoryImprovementsRoute(String workspaceId) =>
    '${memoryRoute(workspaceId)}?$memoryTabQueryParam=$memoryImprovementsTabKey';

/// One improvement proposal, open on the Memory screen.
String memoryImprovementRoute(String workspaceId, String proposalId) =>
    '${memoryRoute(workspaceId)}/improvements/$proposalId';

/// Meetings list screen (local meeting notes).
String meetingsRoute(String workspaceId) => '/workspaces/$workspaceId/meetings';

/// Live meeting recording screen (rec bar + notes + streaming transcript).
/// Static segment, matched before the `:meetingId` detail route so "record" isn't parsed as a meeting id.
String meetingsRecordRoute(String workspaceId) =>
    '/workspaces/$workspaceId/meetings/record';

/// Meeting detail screen (notes + transcript) for [id].
String meetingDetailRoute(String workspaceId, String id) =>
    '/workspaces/$workspaceId/meetings/$id';

/// Calendar screen (month / week / agenda views of synced events).
String calendarRoute(String workspaceId) => '/workspaces/$workspaceId/calendar';

/// Calendar event detail screen for [id].
String calendarDetailRoute(String workspaceId, String id) =>
    '/workspaces/$workspaceId/calendar/$id';

/// Maps a concrete in-shell location to the *logical* route that keybinding `when` clauses and `scope`s are written against (workspace-independent, so without the `/workspaces/:id` prefix).
/// For example `/workspaces/ws-1/tickets/42` → `/tickets/42`. Non-workspace locations (`/onboarding`, the `/workspaces` picker) pass through unchanged.
String workspaceShellLogicalRoute(String location) {
  final scoped = RegExp(r'^/workspaces/[^/]+(/.*)$').firstMatch(location);
  if (scoped != null) {
    return scoped.group(1)!;
  }
  // A bare `/workspaces/<id>` redirects to the inbox; treat it as such.
  if (location != workspaceListRoute &&
      RegExp(r'^/workspaces/[^/]+/?$').hasMatch(location)) {
    return '/inbox';
  }
  return location;
}

/// Reads the active workspace id straight from the current route.
extension WorkspaceRouteContext on BuildContext {
  /// The `:workspaceId` of the current route, or `null` outside the workspace shell (splash, onboarding, the picker).
  /// Inside any shell screen this is always present, so call sites use `context.currentWorkspaceId!`.
  String? get currentWorkspaceId =>
      GoRouterState.of(this).pathParameters['workspaceId'];
}
