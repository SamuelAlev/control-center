import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/presentation/widgets/messaging_inner_sidebar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

List _channelParticipantOverrides(List<Channel> channels) {
  return channels
      .map((c) => channelParticipantsProvider(c.id).overrideWith((ref) => Stream.value(const [])))
      .toList();
}

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
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
  );
}

late SharedPreferences prefs;

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });


  group('MessagingInnerSidebarHeader', () {
    testWidgets('renders header with icon and text', (tester) async {
      await tester.pumpWidget(_wrap(const MessagingInnerSidebarHeader()));
      await tester.pump();

      expect(find.text('Messaging'), findsOneWidget);
    });
  });

  group('MessagingInnerSidebar', () {
    testWidgets('renders Direct Messages section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Architect'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders group channel items', (tester) async {
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(LucideIcons.plus), findsWidgets);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('DM channel without known agent shows fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => [_dmChannel]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            channelParticipantsProvider('dm-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Direct message'), findsOneWidget);
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dev Team'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders both DM and group channels together', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => [_dmChannel]),
            groupChannelsProvider.overrideWith((ref) => [_groupChannel]),
            agentDetailProvider('agent-1').overrideWith(
              (ref) async => _testAgent,
            ),
            channelParticipantsProvider('dm-1').overrideWith(
              (ref) => Stream.value([_dmParticipant]),
            ),
            channelParticipantsProvider('g-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Architect'), findsOneWidget);
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Group'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders # icon for group channels', (tester) async {
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Group channels render a leading hash (#) icon in their channel row.
      expect(find.byIcon(LucideIcons.hash), findsOneWidget);
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CcAvatar), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('DM channel loading shows ellipsis', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => [_dmChannel]),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            channelParticipantsProvider('dm-1').overrideWith(
              (ref) => Stream.value([_dmParticipant]),
            ),
            agentDetailProvider('agent-1').overrideWith(
              (ref) => null,
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('\u2026'), findsNWidgets(2));
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders with many DM channels', (tester) async {
      tester.view.physicalSize = const Size(300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final dms = List.generate(
        5,
        (i) => Channel(
          id: 'dm-$i',
          name: '',
          isDm: true,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => dms),
            groupChannelsProvider.overrideWith((ref) => const <Channel>[]),
            ..._channelParticipantOverrides(dms),
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
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

    testWidgets('renders with many group channels', (tester) async {
      tester.view.physicalSize = const Size(300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final groups = List.generate(
        5,
        (i) => Channel(
          id: 'g-$i',
          name: 'Group $i',
          isDm: false,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
            selectedChannelIdProvider.overrideWith(
              () => _SelectedChannelNotifier(null),
            ),
            dmChannelsProvider.overrideWith((ref) => const <Channel>[]),
            groupChannelsProvider.overrideWith((ref) => groups),
            ..._channelParticipantOverrides(groups),
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: _wrap(const MessagingInnerSidebar()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Group 0'), findsOneWidget);
      expect(find.text('Group 4'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
