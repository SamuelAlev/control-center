import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/src/framework.dart' show Override;

const _workspaceId = 'ws-1';

class _ActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;
}

final _channel = Channel(
  id: 'g-1',
  name: 'Dev Team',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

/// Common provider overrides so the sidebar's per-row providers resolve to
/// cheap defaults instead of reaching for DB/RPC infrastructure.
List<Override> _commonOverrides({required List<Channel> channels}) => [
  activeWorkspaceIdProvider.overrideWith(_ActiveWorkspaceIdNotifier.new),
  workspaceVisibleChannelsProvider(_workspaceId).overrideWithValue(channels),
  appPreferencesProvider.overrideWithValue(prefs),
  workspacesProvider.overrideWith((ref) => Stream.value(const [])),
  for (final c in channels) ...[
    channelStatusProvider(c.id).overrideWithValue(ChannelStatus.idle),
    channelUnreadProvider(c.id).overrideWithValue(false),
    channelPrsProvider(c.id).overrideWithValue(const []),
  ],
];

/// Hosts [ConversationsSidebarSection] at a channels location so the widget's
/// `GoRouterState`/`currentWorkspaceId` reads resolve. The URL is the source of
/// truth for the selected channel, so [location] sets the active highlight.
GoRouter _router(String location) => GoRouter(
  initialLocation: location,
  routes: [
    GoRoute(
      path: '/workspaces/:workspaceId/channels',
      builder: (_, _) => const Scaffold(body: ConversationsSidebarSection()),
      routes: [
        GoRoute(
          path: ':channelId',
          builder: (_, _) =>
              const Scaffold(body: ConversationsSidebarSection()),
        ),
      ],
    ),
  ],
);

Widget _wrap(GoRouter router) => CcTheme(
  data: CcThemeData.light(),
  child: MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

late AppPreferences prefs;

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  group('ConversationsSidebarSection', () {
    testWidgets('renders the Channels section label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(channels: const []),
          child: _wrap(_router(channelsRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The section label renders as a branded mono eyebrow (uppercased).
      expect(find.text('CHANNELS'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('shows empty state hint when no channels', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(channels: const []),
          child: _wrap(_router(channelsRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No channels yet'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders channel items by name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(channels: [_channel]),
          child: _wrap(_router(channelsRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders a Plus icon for adding a channel', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(channels: const []),
          child: _wrap(_router(channelsRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(AppIcons.plus), findsWidgets);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('selected channel (from URL) still renders', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(channels: [_channel]),
          child: _wrap(_router(channelRoute(_workspaceId, 'g-1'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('unnamed channel shows Channel label', (tester) async {
      final unnamed = Channel(
        id: 'g-unnamed',
        name: '',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(channels: [unnamed]),
          child: _wrap(_router(channelsRoute(_workspaceId))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Channel'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('tapping a channel navigates to its channel route', (
      tester,
    ) async {
      final router = _router(channelsRoute(_workspaceId));

      await tester.pumpWidget(
        ProviderScope(
          overrides: _commonOverrides(channels: [_channel]),
          child: _wrap(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Dev Team'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        channelRoute(_workspaceId, 'g-1'),
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}
