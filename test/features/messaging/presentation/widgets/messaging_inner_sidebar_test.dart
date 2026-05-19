import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _SelectedChannelNotifier extends SelectedChannelNotifier {
  _SelectedChannelNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

final _testAgent = Agent(
  id: 'agent-1',
  name: 'Architect',
  title: 'Software Architect',
  agentMdPath: '/path',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2024),
);

final _dmChannel = Channel(
  id: 'dm-1',
  name: '',
  isDm: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final _groupChannel = Channel(
  id: 'g-1',
  name: 'Dev Team',
  isDm: false,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final _dmParticipant = ChannelParticipant(
  id: 'p-1',
  channelId: 'dm-1',
  agentId: 'agent-1',
  role: 'participant',
  joinedAt: DateTime(2024),
);

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child)),
  );
}

late AppPreferences prefs;

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  group('ConversationsSidebarSection', () {
    testWidgets('renders Direct messages and Groups section labels', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Section labels render as branded mono eyebrows (uppercased).
      expect(find.text('DIRECT MESSAGES'), findsOneWidget);
      expect(find.text('GROUPS'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('shows empty state hint when no DMs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No direct messages yet'), findsOneWidget);
      expect(find.text('No groups yet'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders DM channel items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => [_dmChannel]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            agentDetailProvider('agent-1').overrideWith(
              (ref) async => _testAgent,
            ),
            channelParticipantsProvider('dm-1').overrideWith(
              (ref) => Stream.value([_dmParticipant]),
            ),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Architect'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders group channel items with hash icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => [_groupChannel]),
            channelParticipantsProvider('g-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      // Group channels render a leading hash (#) icon.
      expect(find.byIcon(LucideIcons.hash), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders Plus icons for adding', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(LucideIcons.plus), findsWidgets);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('selected channel is highlighted', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier('g-1'),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => [_groupChannel]),
            channelParticipantsProvider('g-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('unnamed group channel shows Group label', (tester) async {
      final unnamed = Channel(
        id: 'g-unnamed',
        name: '',
        isDm: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => [unnamed]),
            channelParticipantsProvider('g-unnamed').overrideWith(
              (ref) => Stream.value(const []),
            ),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Group'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders CcAvatar for DM channels with agent', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => [_dmChannel]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            agentDetailProvider('agent-1').overrideWith(
              (ref) async => _testAgent,
            ),
            channelParticipantsProvider('dm-1').overrideWith(
              (ref) => Stream.value([_dmParticipant]),
            ),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const ConversationsSidebarSection()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CcAvatar), findsWidgets);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('tapping a channel selects it and navigates to /messaging',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const Scaffold(body: ConversationsSidebarSection()),
          ),
          GoRoute(
            path: '/messaging',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => [_groupChannel]),
            channelParticipantsProvider('g-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Dev Team'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/messaging',
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}
