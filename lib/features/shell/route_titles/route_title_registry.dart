import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The app's product name, used as the shared suffix in browser-tab titles
/// (e.g. `Inbox · Control Center`). Mirrors `MaterialApp.title`.
const String kAppTitle = 'Control Center';

/// The page/suffix separator for browser-tab titles: a double backslash
/// (e.g. `Inbox \\ Control Center`).
const String kTitleSeparator = r'\\';

/// Resolves a single route to the *page label* shown in the browser tab title
/// (before the ` · Control Center` suffix). Runs inside the title widget's
/// build, so it may watch async providers (e.g. to fetch the PR title). Returning
/// `null` means "use the bare app name" (used for the splash/loading surface,
/// where no page identity exists yet).
///
/// The richer, widget-bearing labels live in the breadcrumb registry; this is
/// the tab-title mirror of that map, returning plain strings.
typedef RouteTitleBuilder =
    String? Function(WidgetRef ref, GoRouterState state, AppLocalizations l10n);

/// Route `fullPath` pattern → page label. Patterns mirror go_router's
/// `GoRouterState.fullPath` (with `:param` placeholders), keyed identically to
/// the breadcrumb registry. A missing entry falls back to the bare app name.
///
/// Keep this in sync with the breadcrumb registry — a test asserts the two share
/// the same set of keys (minus the pre-context routes added only here).
final Map<String, RouteTitleBuilder> routeTitleRegistry = {
  // ─── Pre-context routes (no workspace prefix) ──────────────────────────────
  splashRoute: (_, _, _) => null,
  onboardingRoute: (_, _, _) => null,
  workspaceListRoute: (_, _, l10n) => l10n.workspaces,

  // ─── Workspace shell ────────────────────────────────────────────────────────
  inboxRoute(workspaceIdParam): (_, _, l10n) => l10n.inboxTitle,
  pullRequestsRoute(workspaceIdParam): (_, _, l10n) => l10n.pullRequests,
  '${pullRequestsRoute(workspaceIdParam)}/:owner/:repo/:prNumber':
      _pullRequestDetailTitle,
  channelsRoute(workspaceIdParam): (_, _, l10n) => l10n.navConversations,
  '${channelsRoute(workspaceIdParam)}/:channelId': (_, _, l10n) =>
      l10n.navConversations,
  ticketsRoute(workspaceIdParam): (_, _, l10n) => l10n.navTickets,
  '${ticketsRoute(workspaceIdParam)}/:ticketId': (_, _, l10n) =>
      l10n.navTickets,
  projectOverviewRoute(workspaceIdParam, ':projectId'): (_, _, l10n) =>
      l10n.navTickets,
  pipelinesRoute(workspaceIdParam): (_, _, l10n) => l10n.pipelinesScreenTitle,
  runPipelineRoute(workspaceIdParam): (_, _, l10n) => l10n.pipelinesRunPipeline,
  '${pipelinesRoute(workspaceIdParam)}/:runId': (_, _, l10n) =>
      l10n.pipelinesScreenTitle,
  plansRoute(workspaceIdParam): (_, _, l10n) => l10n.plansTitle,
  '${plansRoute(workspaceIdParam)}/:kind/:id': (_, _, l10n) =>
      l10n.planStudioTitle,
  newsfeedRoute(workspaceIdParam): (_, _, l10n) => l10n.newsfeedLabel,
  newsfeedSettingsRoute(workspaceIdParam): (_, _, l10n) => l10n.settingsLabel,
  '${newsfeedRoute(workspaceIdParam)}/article/:articleId': (_, _, l10n) =>
      l10n.newsfeedLabel,
  meetingsRoute(workspaceIdParam): (_, _, l10n) => l10n.navMeetings,
  '${meetingsRoute(workspaceIdParam)}/record': (_, _, l10n) =>
      l10n.meetingsRecordingCrumb,
  '${meetingsRoute(workspaceIdParam)}/:meetingId': (_, _, l10n) =>
      l10n.navMeetings,
  calendarRoute(workspaceIdParam): (_, _, l10n) => l10n.navCalendar,
  '${calendarRoute(workspaceIdParam)}/:eventId': (_, _, l10n) =>
      l10n.navCalendar,
  memoryRoute(workspaceIdParam): (_, _, l10n) => l10n.navMemory,
  apiKeysRoute(workspaceIdParam): (_, _, l10n) => l10n.apiKeys,
  // Settings page titles are DERIVED from `kSettingsNav`, the single source of
  // truth for the settings IA, so a renamed or moved page cannot leave a stale
  // tab title behind. Pipelines/teams/memory keep their own entries below
  // because they are foreign features that merely live under `/settings`.
  for (final entry in kSettingsNavItems)
    entry.route(workspaceIdParam): (_, _, l10n) => entry.label(l10n),
  settingsPipelinesRoute(workspaceIdParam): (_, _, l10n) =>
      l10n.pipelineTemplatesTitle,
  '${settingsPipelinesRoute(workspaceIdParam)}/:templateId': (_, _, l10n) =>
      l10n.pipelineTemplatesTitle,
  teamsRoute(workspaceIdParam): (_, _, l10n) => l10n.teamsTitle,
  userProfileRoute(workspaceIdParam, ':login'): _userProfileTitle,
};

String? _pullRequestDetailTitle(
  WidgetRef ref,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final raw = state.pathParameters['prNumber'] ?? '';
  final prNumber = int.tryParse(raw);
  if (prNumber == null) {
    return '#$raw';
  }
  final pr = ref.watch(prDetailProvider(prNumber)).value;
  final title = pr?.title;
  // Format: `<pr title> (<pr id>)`. Falls back to the bare number while the
  // PR is loading or has no title. The `\` separator + app suffix is applied in
  // routeTitleFor.
  return (title == null || title.isEmpty)
      ? '#$prNumber'
      : '$title (#$prNumber)';
}

String? _userProfileTitle(
  WidgetRef ref,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final login = state.pathParameters['login'] ?? '';
  return login.isEmpty ? l10n.usersLabel : login;
}

/// Resolves the full browser-tab title for [state]: the page label followed by
/// the app-name suffix, or just the app name when the route has no page
/// identity (splash, unknown route).
///
/// The separator between page label and app name is the double backslash
/// (see [kTitleSeparator]).
String routeTitleFor(
  WidgetRef ref,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final fullPath = state.fullPath;
  final builder = fullPath == null ? null : routeTitleRegistry[fullPath];
  final page = builder?.call(ref, state, l10n);
  if (page == null || page.isEmpty) {
    return kAppTitle;
  }
  return '$page $kTitleSeparator $kAppTitle';
}
