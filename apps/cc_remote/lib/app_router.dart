import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/connect_screen.dart';
import 'package:cc_remote/screens/messaging_screen.dart';
import 'package:cc_remote/screens/newsfeed_screen.dart';
import 'package:cc_remote/screens/tickets_screen.dart';
import 'package:cc_remote/screens/settings_screen.dart';
import 'package:cc_remote/screens/workspace_switcher.dart';
import 'package:cc_remote/widgets/app_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's [GoRouter].
///
/// The bottom-tab shell owns the three feature roots (`/tickets`, `/messaging`,
/// `/newsfeed`). Detail routes (`/ticket/:id`, `/thread/:channelId`,
/// `/article/:articleId`) and `/workspaces` are top-level full-screen routes so
/// they cover the tab bar. `/connect` is shown while unpaired; the redirect
/// flips to it (and back) on [RemoteSession] state changes via
/// [RouterRefresh].
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(remoteSessionProvider);
  final refresh = RouterRefresh(session);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/tickets',
    refreshListenable: refresh,
    redirect: (context, state) {
      final ui = session.currentUiState;
      final loc = state.matchedLocation;
      // Unpaired (fresh, or after an explicit "disconnect" / a desktop revoke)
      // always returns to the connect/scan screen — even if we connected earlier
      // this session — so a forgotten pairing can't keep showing stale tabs.
      if (ui.isNotPaired) {
        return loc == '/connect' ? null : '/connect';
      }
      // Keep the full-screen status flow (scan → connecting → awaiting approval
      // → failed/retry) until the FIRST successful connection. After that,
      // transient drops stay in-app (the shell shows a reconnect banner) instead
      // of bouncing back to /connect and losing the user's place.
      final showStatus = !ui.isConnected && !session.hasEverConnected;
      if (showStatus && loc != '/connect') {
        return '/connect';
      }
      if (!showStatus && loc == '/connect') {
        return '/tickets';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: '/workspaces',
        builder: (context, state) => const WorkspaceSwitcherScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (context, state) =>
            TicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/thread/:channelId',
        builder: (context, state) => MessagingThreadScreen(
          channelId: state.pathParameters['channelId']!,
        ),
      ),
      GoRoute(
        path: '/article/:articleId',
        builder: (context, state) =>
            ArticleReaderScreen(articleId: state.pathParameters['articleId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tickets',
                builder: (context, state) => const TicketsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messaging',
                builder: (context, state) => const MessagingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/newsfeed',
                builder: (context, state) => const NewsfeedScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
