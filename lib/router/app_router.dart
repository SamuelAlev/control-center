import 'package:control_center/features/agents/presentation/screens/agents_registry_screen.dart';
import 'package:control_center/features/analytics/presentation/screens/agent_detail_screen.dart';
import 'package:control_center/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:control_center/features/auth/presentation/screens/api_keys_screen.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:control_center/features/memory/presentation/screens/memory_screen.dart';
import 'package:control_center/features/messaging/presentation/screens/messaging_screen.dart';
import 'package:control_center/features/newsfeed/presentation/screens/article_webview_screen.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_screen.dart';
import 'package:control_center/features/newsfeed/presentation/screens/newsfeed_settings_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_run_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_template_editor_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_templates_settings_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipelines_screen.dart';
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
import 'package:control_center/features/workspaces/presentation/screens/workspace_detail_screen.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
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

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splashRoute,
    refreshListenable: gateNotifier,
    redirect: (context, state) => onboardingGuard(context, state, gateNotifier),
    routes: [
      GoRoute(
        path: splashRoute,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: _absorb(const SplashScreen())),
      ),
      GoRoute(
        path: onboardingRoute,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: _absorb(const OnboardingScreen()),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ControlCenterLayout(child: child),
        routes: [
          GoRoute(
            path: dashboardRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const DashboardScreen()),
            ),
          ),
          GoRoute(
            path: pullRequestsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const PullRequestListScreen()),
            ),
            routes: [
              GoRoute(
                path: ':prNumber',
                redirect: (context, state) {
                  final raw = state.pathParameters['prNumber'] ?? '';
                  final parsed = int.tryParse(raw);
                  if (parsed == null) {
                    return pullRequestsRoute;
                  }

                  return null;
                },
                pageBuilder: (context, state) {
                  final prNumber = int.parse(state.pathParameters['prNumber']!);
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: _absorb(PullRequestDetailScreen(prNumber: prNumber)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: agentsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AgentsRegistryScreen()),
            ),
          ),
          GoRoute(
            path: messagingRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const MessagingScreen()),
            ),
          ),
          GoRoute(
            path: ticketsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: const ValueKey(ticketsRoute),
              child: _absorb(const TicketsScreen()),
            ),
          ),
          // Sibling (not nested) so the detail location replaces the list page
          // rather than stacking a second TicketsScreen on top of it. Both
          // share one page key, so selecting a ticket reuses the same
          // master–detail screen in place — state preserved, no transition.
          GoRoute(
            path: '$ticketsRoute/:ticketId',
            pageBuilder: (context, state) => NoTransitionPage(
              key: const ValueKey(ticketsRoute),
              child: _absorb(
                TicketsScreen(
                  selectedTicketId: state.pathParameters['ticketId'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/projects/:projectId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['projectId'] ?? '';
              return NoTransitionPage(
                key: const ValueKey('project_overview'),
                child: _absorb(ProjectOverviewScreen(projectId: id)),
              );
            },
          ),
          GoRoute(
            path: newsfeedRoute,
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
            path: apiKeysRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const ApiKeysScreen()),
            ),
          ),
          GoRoute(
            path: settingsRoute,
            redirect: (_, _) => settingsAppearanceRoute,
          ),
          GoRoute(
            path: settingsAppearanceRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AppearanceSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsNotificationsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const NotificationsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsIntegrationsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const IntegrationsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsAdvancedRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AdvancedSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsAdaptersRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AdaptersSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsAgentsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const AgentsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsReposRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const ReposSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsSkillsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const SkillsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsKeybindingsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const KeybindingsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: settingsSandboxingRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const SandboxingSettingsScreen()),
            ),
          ),
          GoRoute(
            path: workspaceListRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const WorkspaceListScreen()),
            ),
            routes: [
              GoRoute(
                path: ':workspaceId',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['workspaceId'];
                  if (id == null || id.isEmpty) {
                    return NoTransitionPage(
                      key: state.pageKey,
                      child: _absorb(const WorkspaceListScreen()),
                    );
                  }
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: _absorb(WorkspaceDetailScreen(workspaceId: id)),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: analyticsRoute,
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
            path: '/users/:login',
            pageBuilder: (context, state) {
              final login = state.pathParameters['login'] ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: _absorb(UserProfileScreen(login: login)),
              );
            },
          ),
          GoRoute(
            path: pipelinesRoute,
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
                  child: _absorb(PipelineRunScreen(
                    initialTemplateId: state.uri.queryParameters['templateId'],
                  )),
                ),
              ),
              GoRoute(
                path: ':runId',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: _absorb(PipelinesScreen(
                    initialRunId: state.pathParameters['runId'],
                  )),
                ),
              ),
            ],
          ),
          GoRoute(
            path: settingsPipelinesRoute,
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
            path: teamsRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const TeamsSettingsScreen()),
            ),
          ),
          GoRoute(
            path: memoryRoute,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: _absorb(const MemoryScreen()),
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
