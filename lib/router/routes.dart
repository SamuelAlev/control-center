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
/// [splashRoute], [onboardingRoute], and [workspaceListRoute] (the picker).
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Root navigator key used by the app router.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The go_router path-parameter name carrying the active workspace id. Pass
/// this to any route builder to obtain its `:workspaceId` *pattern* form.
const String workspaceIdParam = ':workspaceId';

// ─── Pre-context routes (no workspace prefix) ─────────────────────────────────

/// Loading screen shown while we figure out whether onboarding is complete.
const String splashRoute = '/splash';

/// First-run onboarding (API keys + first workspace).
const String onboardingRoute = '/onboarding';

/// Workspaces list / picker. Full-screen (outside the workspace shell) — it is
/// where the user chooses or creates the workspace whose context everything
/// else runs in.
const String workspaceListRoute = '/workspaces';

// ─── Workspace shell ──────────────────────────────────────────────────────────

/// The bare workspace root. Redirects to that workspace's dashboard.
String workspaceRoot(String workspaceId) => '/workspaces/$workspaceId';

/// API keys configuration screen.
String apiKeysRoute(String workspaceId) => '/workspaces/$workspaceId/api-keys';

/// Main dashboard screen.
String dashboardRoute(String workspaceId) =>
    '/workspaces/$workspaceId/dashboard';

/// Pull requests list screen.
String pullRequestsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/pull-requests';

/// Compose-a-new-pull-request screen. Static segment, matched before the
/// `:prNumber` detail route so "compose" isn't parsed as a PR number.
String pullRequestsComposeRoute(String workspaceId) =>
    '/workspaces/$workspaceId/pull-requests/compose';

/// Pull request detail screen for PR [number] in [repoFullName] (`owner/repo`).
///
/// PR numbers are unique only *within* a repo, and the queue spans every repo
/// linked to the workspace, so the repo is part of the path:
/// `…/pull-requests/<owner>/<repo>/<number>`. The repo in the URL — not the
/// active repo — is what the detail screen resolves the PR against, so a
/// deep-link or reload always shows the right PR.
String pullRequestDetailRoute(
  String workspaceId,
  String repoFullName,
  int number,
) => '/workspaces/$workspaceId/pull-requests/$repoFullName/$number';

/// Messaging screen (Slack-style DMs and group channels).
String messagingRoute(String workspaceId) =>
    '/workspaces/$workspaceId/messaging';

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

/// Newsfeed → Settings (manage feeds + open behavior).
String newsfeedSettingsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/newsfeed/settings';

/// Article reader (in-app webview) for a given article id.
String newsfeedArticleRoute(String workspaceId, String articleId) =>
    '/workspaces/$workspaceId/newsfeed/article/$articleId';

/// Settings screen (defaults to the appearance subroute — the first item in
/// the "General" sidebar group).
String settingsRoute(String workspaceId) => '/workspaces/$workspaceId/settings';

/// Settings → Appearance (theme, language, typography). The settings landing.
String settingsAppearanceRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/appearance';

/// Settings → Notifications (per-event notification toggles).
String settingsNotificationsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/notifications';

/// Settings → Advanced (voice, semantic search, branch template, privacy,
/// logging). The rarely-touched system configuration.
String settingsAdvancedRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/advanced';

/// Settings → Integrations (GitHub, ticketing, MCP server).
String settingsIntegrationsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/integrations';

/// Settings → Devices (paired remote-control phones).
String settingsDevicesRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/devices';

/// Settings → Adapters (auto-detected agent runners).
String settingsAdaptersRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/adapters';

/// Settings → Agents (registered agent identities).
String settingsAgentsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/agents';

/// Settings → Repositories (manage repos that workspaces can target).
String settingsReposRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/repositories';

/// Settings → Skills.
String settingsSkillsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/skills';

/// Settings → Keybindings.
String settingsKeybindingsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/keybindings';

/// Settings → Security → Sandboxing.
String settingsSandboxingRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/sandboxing';

/// Analytics dashboard screen.
String analyticsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/analytics';

/// Agent detail screen within analytics.
String analyticsAgentRoute(String workspaceId, String agentId) =>
    '/workspaces/$workspaceId/analytics/agents/$agentId';

/// GitHub user profile screen.
String userProfileRoute(String workspaceId, String login) =>
    '/workspaces/$workspaceId/users/$login';

/// Pipeline runs list screen.
String pipelinesRoute(String workspaceId) =>
    '/workspaces/$workspaceId/pipelines';

/// Manual run launcher — pick a manually-runnable pipeline, fill its input
/// form, and start a run.
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

/// Teams management screen.
String teamsRoute(String workspaceId) =>
    '/workspaces/$workspaceId/settings/teams';

/// Memory (knowledge) screen: facts, policies, and the knowledge graph.
String memoryRoute(String workspaceId) => '/workspaces/$workspaceId/memory';

/// Meetings list screen (local meeting notes).
String meetingsRoute(String workspaceId) => '/workspaces/$workspaceId/meetings';

/// Live meeting recording screen (rec bar + notes + streaming transcript).
/// Static segment, matched before the `:meetingId` detail route so "record"
/// isn't parsed as a meeting id.
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

/// Maps a concrete in-shell location to the *logical* route that keybinding
/// `when` clauses and `scope`s are written against (they predate the
/// `/workspaces/:id` prefix). For example `/workspaces/ws-1/tickets/42` →
/// `/tickets/42`. Non-workspace locations (`/onboarding`, the `/workspaces`
/// picker) pass through unchanged.
String workspaceShellLogicalRoute(String location) {
  final scoped = RegExp(r'^/workspaces/[^/]+(/.*)$').firstMatch(location);
  if (scoped != null) {
    return scoped.group(1)!;
  }
  // A bare `/workspaces/<id>` redirects to the dashboard; treat it as such.
  if (location != workspaceListRoute &&
      RegExp(r'^/workspaces/[^/]+/?$').hasMatch(location)) {
    return '/dashboard';
  }
  return location;
}

/// Reads the active workspace id straight from the current route.
extension WorkspaceRouteContext on BuildContext {
  /// The `:workspaceId` of the current route, or `null` outside the workspace
  /// shell (splash, onboarding, the picker). Inside any shell screen this is
  /// always present, so call sites use `context.currentWorkspaceId!`.
  String? get currentWorkspaceId =>
      GoRouterState.of(this).pathParameters['workspaceId'];
}
