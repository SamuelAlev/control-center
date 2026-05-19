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

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Root navigator key used by the app router.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The go_router path-parameter name carrying the active workspace id. Pass this to any route builder to obtain its `:workspaceId` *pattern* form.
const String workspaceIdParam = ':workspaceId';

// ─── Pre-context routes (no workspace prefix) ─────────────────────────────────

/// Loading screen shown while we figure out whether onboarding is complete.
const String splashRoute = '/splash';

/// First-run onboarding (API keys + first workspace).
const String onboardingRoute = '/onboarding';

/// Workspaces list / picker. Full-screen (outside the workspace shell) — it is where the user chooses or creates the workspace whose context everything else runs in.
const String workspaceListRoute = '/workspaces';

// ─── Workspace shell ──────────────────────────────────────────────────────────

/// The bare workspace root. Redirects to that workspace's inbox.
String workspaceRoot(String workspaceId) => '/workspaces/$workspaceId';

/// API keys configuration screen.
String apiKeysRoute(String workspaceId) => '/workspaces/$workspaceId/api-keys';

/// Pull requests list screen.
String pullRequestsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/pull-requests';

/// Compose-a-new-pull-request screen. Static segment, matched before the
/// `:prNumber` detail route so "compose" isn't parsed as a PR number.
///
/// [channelId] carries the conversation the compose was launched from (the
/// Source Control panel's "Create pull request"). It is the only way the compose
/// screen can find the conversation's isolated worktree — and therefore the
/// branch the user actually means to open a PR from. Dropping it was why that
/// entry point led to two empty branch pickers: the screen fell back to the
/// GitHub remote's ref list, which by construction cannot contain a
/// never-pushed `conv/<id>` worktree branch.
String pullRequestsComposeRoute(String workspaceId, {String? channelId}) {
  final base = '/workspaces/$workspaceId/pull-requests/compose';
  return (channelId == null || channelId.isEmpty)
      ? base
      : '$base?channel=${Uri.encodeQueryComponent(channelId)}';
}

/// Pull request detail screen for PR [number] in [repoFullName] (`owner/repo`).
///
/// PR numbers are unique only *within* a repo and the queue spans every repo
/// linked to the workspace, so the repo is part of the path:
/// `…/pull-requests/<owner>/<repo>/<number>`. The repo in the URL — not the
/// active repo — is what the detail screen resolves the PR against, so a
/// deep-link or reload always shows the right PR.
String pullRequestDetailRoute(
  String workspaceId,
  String repoFullName,
  int number,
) => '/workspaces/$workspaceId/pull-requests/$repoFullName/$number';

/// Channels list / conversation surface (no channel selected).
String channelsRoute(String workspaceId) => '/workspaces/$workspaceId/channels';

/// A specific channel (conversation) by [channelId]. The id in the URL is the
/// source of truth for the selected conversation, so a deep-link or reload
/// always reopens the right channel.
///
/// Pass [messageId] to deep-link to a specific message (a permalink target):
/// it rides as a `?m=<id>` query param, which drops out of the path-based
/// channel-selection parser and is consumed once on open.
String channelRoute(String workspaceId, String channelId, {String? messageId}) {
  final base = '/workspaces/$workspaceId/channels/$channelId';
  if (messageId == null || messageId.isEmpty) {
    return base;
  }
  return '$base?m=$messageId';
}

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

// ── Settings ────────────────────────────────────────────────────────────────
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

/// Settings root (redirects to the You → profile landing).
String settingsRoute(String workspaceId) => '/workspaces/$workspaceId/settings';

/// Settings → You → Profile & identity. The settings landing.
String settingsProfileRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/profile';

/// Settings → You → Appearance (theme, language, typography, editor theme).
String settingsAppearanceRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/appearance';

/// Settings → You → Notifications (per-event toggles, quiet hours).
String settingsNotificationsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/notifications';

/// Settings → You → Keybindings (a read-only reference over the const registry).
String settingsKeybindingsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/keybindings';

/// Settings → You → Audio (microphone, dictation, meeting detection,
/// soundscape output).
String settingsAudioRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/audio';

/// Settings → You → Your devices (paired phones + remote control).
String settingsRemoteControlRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/devices';

/// Settings → You → Newsfeed (the user's feed registry + reader prefs — the
/// feed list is per-user, so it lives in the You scope).
String settingsNewsfeedRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/you/newsfeed';

/// Settings → Workspace → General (name, logo, secret globs, review
/// concurrency, branch naming, sync health, chat bridges, danger zone).
String settingsWorkspaceGeneralRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/general';

/// Settings → Workspace → Members & roles (roster, invites, audit trail).
String settingsMembersRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/members';

/// Settings → Workspace → Agents (registered agent identities).
String settingsAgentsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/agents';

/// Settings → Workspace → Repositories.
String settingsReposRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/repositories';

/// Settings → Workspace → Skills.
String settingsSkillsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/skills';

/// Settings → Workspace → Agent permissions (guardrail matrix, what-if probe).
String settingsGuardrailsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/workspace/permissions';

/// Settings → Server → Connection & status: which server this client talks to,
/// plus how this server is shared (mDNS, tunnel opt-in, relay usage).
String settingsServerConnectionRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/connection';

/// Settings → Server → Single sign-on (SAML + OIDC + SCIM provisioning).
String settingsSsoRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/sso';

/// Settings → Server → Model providers & adapters.
String settingsAdaptersRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/providers';

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

/// Settings → Server → Enclosures (rigs): what this host can boot, the base
/// images, and the machines running right now.
///
/// A server-capability page rather than a workspace destination: whether a rig
/// can boot at all is a property of the machine running `cc_server`, and the
/// live view of a running one belongs beside the work it is doing (a channel
/// or PR tab), not in a separate place you have to go and find.
String settingsRigsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/server/rigs';

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

/// GitHub user profile screen.
String userProfileRoute(String workspaceId, String login) =>
    '/workspaces/$workspaceId/users/$login';

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

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Maps a concrete in-shell location to the *logical* route that keybinding `when` clauses and `scope`s are written against (they predate the/ `/workspaces/:id` prefix).
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
