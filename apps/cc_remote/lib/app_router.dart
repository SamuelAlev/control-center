import 'package:cc_data/cc_data.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/activity_screen.dart';
import 'package:cc_remote/screens/article_reader_screen.dart';
import 'package:cc_remote/screens/calendar_screen.dart';
import 'package:cc_remote/screens/connect_screen.dart';
import 'package:cc_remote/screens/conversation_directory_screen.dart';
import 'package:cc_remote/screens/conversation_history_screen.dart';
import 'package:cc_remote/screens/conversation_progress_screen.dart';
import 'package:cc_remote/screens/credentials_screen.dart';
import 'package:cc_remote/screens/event_detail_screen.dart';
import 'package:cc_remote/screens/inbox_screen.dart';
import 'package:cc_remote/screens/messaging_screen.dart';
import 'package:cc_remote/screens/newsfeed_screen.dart';
import 'package:cc_remote/screens/permissions_screen.dart';
import 'package:cc_remote/screens/plan_detail_screen.dart';
import 'package:cc_remote/screens/plans_screen.dart';
import 'package:cc_remote/screens/pr_detail_screen.dart';
import 'package:cc_remote/screens/pr_screen.dart';
import 'package:cc_remote/screens/settings_screen.dart';
import 'package:cc_remote/screens/space_management_screen.dart';
import 'package:cc_remote/screens/space_screen.dart';
import 'package:cc_remote/screens/supervised_goals_screen.dart';
import 'package:cc_remote/screens/ticket_detail_screen.dart';
import 'package:cc_remote/screens/ticket_editor_screen.dart';
import 'package:cc_remote/screens/tickets_screen.dart';
import 'package:cc_remote/screens/workspace_switcher.dart';
import 'package:cc_remote/widgets/app_shell.dart';
import 'package:cc_remote/widgets/remote_route_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pairing/reconnect retains the complete intended route, never a PSK in a URL.
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(remoteSessionProvider);
  final refresh = RouterRefresh(session);
  ref.onDispose(refresh.dispose);
  var redirectGeneration = 0;
  final router = GoRouter(
    initialLocation: '/inbox',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final generation = ++redirectGeneration;
      final ui = session.currentUiState;
      final connecting =
          ui.isNotPaired || (!ui.isConnected && !session.hasEverConnected);
      if (connecting) {
        if (state.matchedLocation == '/connect') return null;
        return Uri(
          path: '/connect',
          queryParameters: {'return_to': state.uri.toString()},
        ).toString();
      }
      if (state.matchedLocation == '/connect') {
        return safeRemoteReturn(state.uri.queryParameters['return_to']) ??
            '/inbox';
      }
      final requested = state.uri.queryParameters['workspace_id'];
      if (requested != null && requested != session.activeWorkspaceId) {
        final client = session.client;
        if (client == null) return null;
        try {
          final workspaces = await RemoteWorkspaceRepository(client).list();
          if (generation != redirectGeneration) return null;
          if (!workspaces.any((workspace) => workspace.id == requested)) {
            return '/unavailable';
          }
          await session.setActiveWorkspace(requested);
        } on Object {
          // Never open the target entity in whichever workspace was selected.
          if (generation == redirectGeneration) return '/unavailable';
        }
      }
      return null;
    },
    errorBuilder: (context, state) => const RemoteUnavailablePage(),
    routes: [
      GoRoute(path: '/connect', builder: (_, _) => const ConnectScreen()),
      GoRoute(
        path: '/unavailable',
        builder: (_, _) => const RemoteUnavailablePage(),
      ),
      GoRoute(
        path: '/workspaces',
        builder: (_, _) => const WorkspaceSwitcherScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, state) => _scoped(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/activity',
        builder: (_, state) => _scoped(state, const ActivityScreen()),
      ),
      GoRoute(
        path: '/permissions',
        builder: (_, state) => _scoped(state, const PermissionsScreen()),
      ),
      GoRoute(
        path: '/credentials',
        builder: (_, state) => _scoped(state, const CredentialsScreen()),
      ),
      GoRoute(
        path: '/plans',
        builder: (context, state) => _scoped(
          state,
          RemoteDetailPage(
            title: AppLocalizations.of(context).mobilePlans,
            child: const PlansScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/plans/:planId',
        builder: (_, state) => _scoped(
          state,
          PlanDetailScreen(planId: state.pathParameters['planId']!),
        ),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => _scoped(
          state,
          RemoteDetailPage(
            title: AppLocalizations.of(context).mobileGoals,
            child: SupervisedGoalsScreen(
              conversationId: state.uri.queryParameters['conversation_id'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/goals/:goalId',
        builder: (_, state) => _scoped(
          state,
          SupervisedGoalsScreen(goalId: state.pathParameters['goalId']!),
        ),
      ),
      GoRoute(
        path: '/ticket/new',
        builder: (_, state) => _scoped(state, const TicketEditorScreen()),
      ),
      GoRoute(
        path: '/ticket/:id/edit',
        builder: (_, state) => _scoped(
          state,
          TicketEditorScreen(ticketId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (_, state) => _scoped(
          state,
          TicketDetailScreen(ticketId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/spaces/new',
        builder: (_, state) => _scoped(state, const SpaceManagementScreen()),
      ),
      GoRoute(
        path: '/spaces/:spaceId/manage',
        builder: (_, state) => _scoped(
          state,
          SpaceManagementScreen(spaceId: state.pathParameters['spaceId']!),
        ),
      ),
      GoRoute(
        path: '/spaces/:spaceId/conversations',
        builder: (_, state) => _scoped(
          state,
          ConversationDirectoryScreen(
            spaceId: state.pathParameters['spaceId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/spaces/:spaceId/progress',
        builder: (_, state) => _scoped(
          state,
          state.uri.queryParameters['conversation_id'] == null
              ? const RemoteUnavailablePage()
              : ConversationProgressScreen(
                  spaceId: state.pathParameters['spaceId']!,
                  conversationId: state.uri.queryParameters['conversation_id']!,
                ),
        ),
      ),
      GoRoute(
        path: '/spaces/:spaceId/history',
        builder: (_, state) => _scoped(
          state,
          state.uri.queryParameters['conversation_id'] == null
              ? const RemoteUnavailablePage()
              : ConversationHistoryScreen(
                  spaceId: state.pathParameters['spaceId']!,
                  conversationId: state.uri.queryParameters['conversation_id']!,
                ),
        ),
      ),
      GoRoute(
        path: '/spaces/:spaceId',
        builder: (_, state) => _scoped(
          state,
          SpaceScreen(
            spaceId: state.pathParameters['spaceId']!,
            conversationId: state.uri.queryParameters['conversation_id'],
            messageId: state.uri.queryParameters['message_id'],
          ),
        ),
      ),
      GoRoute(
        path: '/article/:articleId',
        builder: (_, state) =>
            ArticleReaderScreen(articleId: state.pathParameters['articleId']!),
      ),
      GoRoute(
        path: '/pr/:repoId/:number',
        builder: (_, state) => _scoped(
          state,
          PrDetailScreen(
            repoId: state.pathParameters['repoId']!,
            number: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/event/:eventId',
        builder: (_, state) => _scoped(
          state,
          EventDetailScreen(eventId: state.pathParameters['eventId']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (_, state) => _scoped(state, const InboxScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tickets',
                builder: (_, state) => _scoped(state, const TicketsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/spaces',
                builder: (_, state) => _scoped(state, const MessagingScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/prs',
                builder: (_, state) => _scoped(state, const PrScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, state) => _scoped(state, const CalendarScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/newsfeed',
                builder: (_, _) => const NewsfeedScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Widget _scoped(GoRouterState state, Widget child) => WorkspaceRouteGate(
  key: ValueKey(state.uri.queryParameters['workspace_id']),
  workspaceId: state.uri.queryParameters['workspace_id'],
  child: child,
);

/// No external or recursive pairing redirect is admitted from query input.
String? safeRemoteReturn(String? location) {
  if (location == null) return null;
  final uri = Uri.tryParse(location);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/') ||
      uri.path.startsWith('//') ||
      uri.path == '/connect') {
    return null;
  }
  return uri.toString();
}
