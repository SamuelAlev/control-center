import 'package:control_center/features/analytics/presentation/screens/agent_detail_screen.dart';
import 'package:control_center/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:control_center/features/auth/presentation/screens/api_keys_screen.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_detail_screen.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_record_screen.dart';
import 'package:control_center/features/meetings/presentation/screens/meetings_screen.dart';
import 'package:control_center/features/memory/presentation/screens/memory_screen.dart';
import 'package:control_center/features/messaging/presentation/screens/messaging_screen.dart';
import 'package:control_center/features/newsfeed/presentation/screens/article_webview_screen.dart'
    if (dart.library.js_interop) 'package:control_center/features/newsfeed/presentation/screens/article_webview_screen_web.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_screen.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_settings_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_run_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_template_editor_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_templates_settings_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipelines_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/compose_pull_request_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_list_screen.dart';
import 'package:control_center/features/sandboxing/presentation/sandboxing_settings_page.dart';
import 'package:control_center/features/settings/presentation/screens/keybindings_settings_screen.dart';
import 'package:control_center/features/settings/presentation/screens/settings_screen.dart';
import 'package:control_center/features/shell/presentation/layout/control_center_layout.dart';
import 'package:control_center/features/teams/presentation/screens/teams_settings_screen.dart';
import 'package:control_center/features/ticketing/presentation/screens/project_overview_screen.dart';
import 'package:control_center/features/ticketing/presentation/screens/tickets_screen.dart';
import 'package:control_center/features/user_profiles/presentation/screens/user_profile_screen.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/guards.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/router/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Wraps a route's child with an opaque [GestureDetector] so taps in
/// transparent areas don't fall through to the route's underlying
/// [ModalBarrier], which plays the macOS alert sound on every tap (Flutter's
/// MaterialPageRoute defaults to barrierDismissible: false). The wrapper must
/// live inside the inner navigator's modal scope to win the gesture arena
/// against the barrier; wrapping at the shell level isn't sufficient because
/// ShellRoute creates an inner Navigator whose barrier sits below this layer.
/// Also drops focus from any active TextField, matching macOS click-outside
/// behavior.
Widget _absorb(Widget child) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
  child: child,
);

/// Provides the configured [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  final gateNotifier = ValueNotifier<OnboardingGate>(
    ref.read(onboardingGateProvider),
  );

  ref.listen(onboardingGateProvider, (_, next) {
    gateNotifier.value = next;
  });

  // Stable page keys for the master–detail screens (tickets, calendar) that
  // share one screen instance across list/detail locations. They include the
  // `:workspaceId` literal because the pattern is constant per shell.
  const ticketsPageKey = ValueKey('tickets_screen');
  const calendarPageKey = ValueKey('calendar_screen');

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splashRoute,
    refreshListenable: gateNotifier,
    redirect: (context, state) => onboardingGuard(
      context,
      state,
      gateNotifier,
      () => ref.read(activeWorkspaceIdProvider),
    ),
    routes: [
      GoRoute(
        path: splashRoute,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: _absorb(const SplashScreen()),
        ),
      ),
      GoRoute(
        path: onboardingRoute,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: _absorb(const OnboardingScreen()),
        ),
      ),
      // The workspace picker is full-screen (outside the workspace shell): it
      // has no single-workspace context. Selecting one enters its dashboard.
      GoRoute(
        path: workspaceListRoute,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: _absorb(const WorkspaceListScreen()),
        ),
      ),
      // A bare `/workspaces/:workspaceId` enters the workspace at its dashboard.
      GoRoute(
        path: workspaceRoot(workspaceIdParam),
        redirect: (context, state) =>
            dashboardRoute(state.pathParameters['workspaceId']!),
      ),
      // Everything else lives inside the workspace shell, scoped by the
      // `:workspaceId` path parameter (the app's active-workspace source of
      // truth). ShellRoute children use absolute, prefixed paths.
      ShellRoute(
        builder: (context, state, child) => ControlCenterLayout(child: child),
        routes: [
          GoRoute(
            path: dashboardRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const DashboardScreen()),
            ),
          ),
          GoRoute(
            path: pullRequestsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const PullRequestListScreen()),
            ),
            routes: [
              // Static `compose` segment, declared before `:prNumber` so it is
              // matched as the compose screen rather than parsed as a PR number.
              GoRoute(
                path: 'compose',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: _absorb(const ComposePullRequestScreen()),
                ),
              ),
              // `:owner/:repo/:prNumber` — PR numbers are per-repo, so the repo
              // owner/name are part of the path. Three segments, so this never
              // collides with the single-segment `compose` route above.
              GoRoute(
                path: ':owner/:repo/:prNumber',
                redirect: (context, state) {
                  final raw = state.pathParameters['prNumber'] ?? '';
                  final parsed = int.tryParse(raw);
                  if (parsed == null) {
                    return pullRequestsRoute(
                      state.pathParameters['workspaceId']!,
                    );
                  }

                  return null;
                },
                pageBuilder: (context, state) {
                  final prNumber = int.parse(state.pathParameters['prNumber']!);
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: _absorb(
                      PullRequestDetailScreen(
                        owner: state.pathParameters['owner']!,
                        repo: state.pathParameters['repo']!,
                        prNumber: prNumber,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: messagingRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const MessagingScreen()),
            ),
          ),
          GoRoute(
            path: ticketsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: ticketsPageKey,
              child: _absorb(const TicketsScreen()),
            ),
          ),
          // SIBLING (not nested) so the detail location reuses the one
          // TicketsScreen instance in place — shared page key → state preserved,
          // no transition. Nesting stacked a second TicketsScreen under the same
          // key, which both defeated that intent and tripped the Navigator's
          // duplicate-page-key assertion on web debug (see the calendar routes).
          GoRoute(
            path: '${ticketsRoute(workspaceIdParam)}/:ticketId',
            pageBuilder: (context, state) => NoTransitionPage(
              key: ticketsPageKey,
              child: _absorb(
                TicketsScreen(
                  selectedTicketId: state.pathParameters['ticketId'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: projectOverviewRoute(workspaceIdParam, ':projectId'),
            pageBuilder: (context, state) {
              final id = state.pathParameters['projectId'] ?? '';
              return NoTransitionPage(
                key: const ValueKey('project_overview'),
                child: _absorb(ProjectOverviewScreen(projectId: id)),
              );
            },
          ),
          GoRoute(
            path: newsfeedRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const NewsfeedScreen()),
            ),
            routes: [
              GoRoute(
                path: 'settings',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: _absorb(const NewsfeedSettingsScreen()),
                ),
              ),
              GoRoute(
                path: 'article/:articleId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['articleId'] ?? '';
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: _absorb(ArticleWebviewScreen(articleId: id)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: apiKeysRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const ApiKeysScreen()),
            ),
          ),
          GoRoute(
            path: settingsRoute(workspaceIdParam),
            redirect: (_, state) =>
                settingsAppearanceRoute(state.pathParameters['workspaceId']!),
          ),
          GoRoute(
            path: settingsAppearanceRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AppearanceSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsNotificationsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const NotificationsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsIntegrationsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const IntegrationsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsDevicesRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const DevicesSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsAdvancedRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AdvancedSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsAdaptersRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AdaptersSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsAgentsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AgentsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsReposRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const ReposSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsSkillsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const SkillsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsKeybindingsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const KeybindingsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsSandboxingRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const SandboxingSettingsScreen()),
            ),
          ),
          GoRoute(
            path: analyticsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AnalyticsScreen()),
            ),
            routes: [
              GoRoute(
                path: 'agents/:agentId',
                pageBuilder: (context, state) {
                  final agentId = state.pathParameters['agentId'] ?? '';
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: _absorb(AgentDetailScreen(agentId: agentId)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: userProfileRoute(workspaceIdParam, ':login'),
            pageBuilder: (context, state) {
              final login = state.pathParameters['login'] ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: _absorb(UserProfileScreen(login: login)),
              );
            },
          ),
          GoRoute(
            path: pipelinesRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const PipelinesScreen()),
            ),
            routes: [
              // Static `run` must precede the `:runId` param route so
              // /pipelines/run resolves to the launcher, not a run detail.
              GoRoute(
                path: 'run',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: _absorb(
                    PipelineRunScreen(
                      initialTemplateId:
                          state.uri.queryParameters['templateId'],
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: ':runId',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: _absorb(
                    PipelinesScreen(
                      initialRunId: state.pathParameters['runId'],
                    ),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: settingsPipelinesRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const PipelineTemplatesSettingsScreen()),
            ),
            routes: [
              GoRoute(
                path: ':templateId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['templateId'] ?? '';
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: _absorb(
                      PipelineTemplateEditorScreen(templateId: id),
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: teamsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const TeamsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: memoryRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const MemoryScreen()),
            ),
          ),
          GoRoute(
            path: meetingsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const MeetingsScreen()),
            ),
            routes: [
              GoRoute(
                path: 'record',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: _absorb(const MeetingRecordScreen()),
                ),
              ),
              GoRoute(
                path: ':meetingId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['meetingId'] ?? '';
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: _absorb(MeetingDetailScreen(meetingId: id)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: calendarRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: calendarPageKey,
              child: _absorb(const CalendarScreen()),
            ),
          ),
          // The event-detail location is a SIBLING (not a nested child) so that
          // exactly one page ever carries `calendarPageKey`: a sole sibling
          // matches at a time, and the shared key makes the Navigator reuse the
          // one CalendarScreen instance across list↔detail — state preserved,
          // no transition (the master–detail pane lives inside the screen).
          // Nesting kept the parent /calendar page mounted AND stacked the child
          // /calendar/:eventId page under the SAME key, which both defeats the
          // single-instance intent and trips the Navigator's
          // `_debugCheckDuplicatedPageKeys` assertion (debug-only — it surfaced
          // on the web/DDC build, stripped in desktop release).
          GoRoute(
            path: '${calendarRoute(workspaceIdParam)}/:eventId',
            pageBuilder: (context, state) => NoTransitionPage(
              key: calendarPageKey,
              child: _absorb(
                CalendarScreen(
                  selectedEventId: state.pathParameters['eventId'],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    gateNotifier.dispose();
  });

  return router;
});
