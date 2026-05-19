import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_header.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final testChannel = Channel(
  id: 'ch-1',
  name: 'General',
  isDm: false,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final unnamedGroup = Channel(
  id: 'ch-unnamed',
  name: '',
  isDm: false,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final dmChannel = Channel(
  id: 'ch-dm',
  name: '',
  isDm: true,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final agentParticipant = ChannelParticipant(
  id: 'p-1',
  channelId: 'ch-1',
  agentId: 'agent-1',
  role: 'member',
  joinedAt: DateTime(2024),
);

final agentParticipant2 = ChannelParticipant(
  id: 'p-2',
  channelId: 'ch-1',
  agentId: 'agent-2',
  role: 'member',
  joinedAt: DateTime(2024),
);

final agent = Agent(
  id: 'agent-1',
  name: 'Architect',
  title: 'Software Architect',
  agentMdPath: '/path',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2024),
);

final agent2 = Agent(
  id: 'agent-2',
  name: 'Reviewer',
  title: 'Code Reviewer',
  agentMdPath: '/path2',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2024),
);

final agent3 = Agent(
  id: 'agent-3',
  name: 'Builder',
  title: 'Build Engineer',
  agentMdPath: '/path3',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2024),
);

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('ChannelHeader group channel', () {
    testWidgets('renders group channel name', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: testChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('General'), findsOneWidget);
      expect(find.text('1 agent'), findsOneWidget);
    });

    testWidgets('renders group with plural agents', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant, agentParticipant2])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            agentDetailProvider('agent-2').overrideWith((ref) async => agent2),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: testChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('2 agents'), findsOneWidget);
    });

    testWidgets('renders group with no agents', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: testChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No agents'), findsOneWidget);
    });

    testWidgets('renders unnamed group as Group', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-unnamed')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: unnamedGroup, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Group'), findsOneWidget);
    });

    testWidgets('has manage and delete IconButtons', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: testChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CcIconButton), findsNWidgets(2));
    });

    testWidgets('has manage participants tooltip', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: testChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CcIconButton), findsNWidgets(2));
    });
  });

  group('ChannelHeader DM channel', () {
    testWidgets('renders DM channel with agent name', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-dm')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: dmChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Architect'), findsOneWidget);
      expect(find.text('Software Architect'), findsOneWidget);
    });

    testWidgets('renders DM channel without agent shows loading', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-dm')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => null),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: dmChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('...'), findsOneWidget);
      expect(find.text('Direct message'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('renders DM channel with avatar', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-dm')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: dmChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AgentAvatar), findsNWidgets(2));
    });

    testWidgets('renders DM channel without agent participant shows default', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final userParticipant = ChannelParticipant(
        id: 'p-user',
        channelId: 'ch-dm',
        agentId: 'user',
        role: 'member',
        joinedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-dm')
                .overrideWith((ref) => Stream.value([userParticipant])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(channel: dmChannel, onManage: () {}, onDelete: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Group'), findsOneWidget);
      expect(find.text('No agents'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });

  group('ChannelHeader callbacks', () {
    testWidgets('calls onManage when manage button tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var managed = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(
                  channel: testChannel,
                  onManage: () => managed = true,
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithIcon(CcIconButton, LucideIcons.users));
      await tester.pumpAndSettle();
      expect(managed, isTrue);
    });

    testWidgets('calls onDelete when delete button tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var deleted = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(
                  channel: testChannel,
                  onManage: () {},
                  onDelete: () => deleted = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });

  group('ManageChannelDialog', () {
    testWidgets('renders manage dialog for group channel', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent, agent2, agent3])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Manage participants'), findsOneWidget);
      expect(find.text('Current participants'), findsOneWidget);
      expect(find.text('Invite agent'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('renders manage dialog for DM channel', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-dm')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent, agent2])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-dm', isDm: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Manage participants'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('renders participant row with agent name', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Architect'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('shows invite list with available agents', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent, agent2, agent3])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reviewer'), findsOneWidget);
      expect(find.text('Builder'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('shows message when all agents are in channel', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('All agents are already in this channel.'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('shows dropdown for many available agents', (tester) async {
      tester.view.physicalSize = const Size(800, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final manyAgents = List.generate(10, (i) => Agent(
        id: 'agent-$i',
        name: 'Agent $i',
        title: 'Title $i',
        agentMdPath: '/path$i',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        createdAt: DateTime(2024),
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value(const [])),
            agentsProvider.overrideWith((ref) => Stream.value(manyAgents)),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Select an agent'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('remove button shown on participant rows', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('participant row shows agent title', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Software Architect'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('close button present', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value(const [])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Close'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('no current participants section when empty', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1')
                .overrideWith((ref) => Stream.value(const [])),
            agentsProvider.overrideWith((ref) => Stream.value([agent, agent2])),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ManageChannelDialog(channelId: 'ch-1', isDm: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Current participants'), findsNothing);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}
