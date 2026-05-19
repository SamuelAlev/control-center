import 'dart:async';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_header.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';


final testChannel = Channel(
  id: 'ch-1',
  name: 'General',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final unnamedChannel = Channel(
  id: 'ch-unnamed',
  name: '',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

final agentParticipant = ChannelParticipant(
  id: 'p-1',
  channelId: 'ch-1',
  principalId: 'agent-1',
  participantType: PrincipalType.agent,
  role: 'member',
  joinedAt: DateTime(2024),
);

final agentParticipant2 = ChannelParticipant(
  id: 'p-2',
  channelId: 'ch-1',
  principalId: 'agent-2',
  participantType: PrincipalType.agent,
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

  group('ChannelHeader channel', () {
    testWidgets('renders channel name', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
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
                  onDelete: () {},
                ),
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

    testWidgets('renders channel with plural agents', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider('ch-1').overrideWith(
              (ref) => Stream.value([agentParticipant, agentParticipant2]),
            ),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            agentDetailProvider('agent-2').overrideWith((ref) async => agent2),
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
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('2 agents'), findsOneWidget);
    });

    testWidgets('renders channel with no agents', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(const [])),
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
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No agents'), findsOneWidget);
    });

    testWidgets('renders unnamed channel as Channel', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider(
              'ch-unnamed',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(
                  channel: unnamedChannel,
                  onManage: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Channel'), findsOneWidget);
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
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
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The header carries a manage (users) and a delete (trash) action, plus
      // other context actions depending on participants.
      expect(find.widgetWithIcon(CcIconButton, AppIcons.users), findsWidgets);
      expect(
        find.widgetWithIcon(CcIconButton, AppIcons.trash2),
        findsOneWidget,
      );
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(const [])),
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
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // present-toggle + take-over + search + manage + delete (no undoable
      // revert in this fixture; the who's-here strip renders nothing with no
      // active workspace).
      expect(find.byType(CcIconButton), findsNWidgets(5));
    });
  });

  group('ChannelHeader long title', () {
    // The header is a fixed 56px band. A long channel name used to wrap to two
    // lines, pushing the "1 agent" subtitle 2px past the bottom edge (a
    // RenderFlex overflow with debug stripes over the subtitle).
    const longName =
        'AI-Generated PR Summaries — Automated summaries from diff + conversation';

    final longChannel = Channel(
      id: 'ch-1',
      name: longName,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    Future<void> pumpLongHeader(WidgetTester tester) async {
      // Narrow enough that the name cannot fit on one line.
      tester.view.physicalSize = const Size(520, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChannelHeader(
                  channel: longChannel,
                  onManage: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('truncates to one line instead of overflowing the 56px band', (
      tester,
    ) async {
      await pumpLongHeader(tester);

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ChannelHeader)).height, 56);
      // One line of titleSmall — not two. The subtitle still has room below it.
      expect(tester.getSize(find.text(longName)).height, lessThan(28));
      expect(find.text('1 agent'), findsOneWidget);
    });

    testWidgets('discloses the full name on hover', (tester) async {
      await pumpLongHeader(tester);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text(longName)));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Twice: the ellipsized header label and the tooltip panel.
      expect(find.text(longName), findsNWidgets(2));
    });

    testWidgets('a short name gets no tooltip machinery', (tester) async {
      tester.view.physicalSize = const Size(800, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(const [])),
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
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // "General" fits, so the title is a plain Text — no hover affordance
      // promising information the operator can already read.
      expect(
        find.descendant(
          of: find.byType(CcTruncatedText),
          matching: find.byType(CcTooltip),
        ),
        findsNothing,
      );
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
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

      await tester.tap(find.widgetWithIcon(CcIconButton, AppIcons.users));
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
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

      await tester.tap(find.byIcon(AppIcons.trash2));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });

  group('ManageChannelDialog', () {
    testWidgets('renders manage dialog for channel', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith(
              (ref) => Stream.value([agent, agent2, agent3]),
            ),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith(
              (ref) => Stream.value([agent, agent2, agent3]),
            ),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('All agents are already in this channel.'),
        findsOneWidget,
      );
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

      final manyAgents = List.generate(
        10,
        (i) => Agent(
          id: 'agent-$i',
          name: 'Agent $i',
          title: 'Title $i',
          agentMdPath: '/path$i',
          workspaceId: 'ws-1',
          skills: AgentSkills([]),
          createdAt: DateTime(2024),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(const [])),
            agentsProvider.overrideWith((ref) => Stream.value(manyAgents)),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(AppIcons.x), findsOneWidget);
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value([agentParticipant])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            agentDetailProvider('agent-1').overrideWith((ref) async => agent),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(const [])),
            agentsProvider.overrideWith((ref) => Stream.value([agent])),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
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
            channelParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(const [])),
            agentsProvider.overrideWith((ref) => Stream.value([agent, agent2])),
            workspacesProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ManageChannelDialog(channelId: 'ch-1')),
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
