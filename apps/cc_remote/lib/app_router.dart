import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/calendar_screen.dart';
import 'package:cc_remote/screens/connect_screen.dart';
import 'package:cc_remote/screens/inbox_screen.dart';
import 'package:cc_remote/screens/messaging_screen.dart';
import 'package:cc_remote/screens/newsfeed_screen.dart';
import 'package:cc_remote/screens/pr_detail_screen.dart';
import 'package:cc_remote/screens/pr_screen.dart';
import 'package:cc_remote/screens/settings_screen.dart';
import 'package:cc_remote/screens/tickets_screen.dart';
import 'package:cc_remote/screens/workspace_switcher.dart';
import 'package:cc_remote/widgets/app_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's [GoRouter].
///
/// The bottom-tab shell owns the six feature roots (`/inbox`, `/tickets`,
/// `/spaces`, `/prs`, `/calendar`, `/newsfeed`). Detail routes (`/ticket/:id`,
/// `/spaces/:spaceId`, `/article/:articleId`, `/pr/:repoId/:number`,
/// `/event/:eventId`) and `/workspaces` are top-level full-screen routes so
/// they cover the tab bar. `/connect` is shown while unpaired; the redirect
/// flips to it (and back) on [RemoteSession] state changes via [RouterRefresh].
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(remoteSessionProvider);
  final refresh = RouterRefresh(session);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    // The inbox lands first because it is the only tab that answers "is
    // anything waiting on me" — the question a phone gets opened for.
    initialLocation: '/inbox',
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
        return '/inbox';
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
        path: '/spaces/:spaceId',
        builder: (context, state) =>
            SpaceScreen(spaceId: state.pathParameters['spaceId']!),
      ),
      GoRoute(
        path: '/article/:articleId',
        builder: (context, state) =>
            ArticleReaderScreen(articleId: state.pathParameters['articleId']!),
      ),
      // A PR number is unique only WITHIN a repo, so the repo travels in the
      // path too — `/pr/42` would name a different PR in every repo the
      // workspace has linked.
      GoRoute(
        path: '/pr/:repoId/:number',
        builder: (context, state) => PrDetailScreen(
          repoId: state.pathParameters['repoId']!,
          number: int.tryParse(state.pathParameters['number'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/event/:eventId',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
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
                path: '/spaces',
                builder: (context, state) => const MessagingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/prs',
                builder: (context, state) => const PrScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
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
