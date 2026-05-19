import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/usecases/send_channel_message_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

class _MockSendChannelMessageUseCase implements SendChannelMessageUseCase {
  /// Workspace the composer threaded into the send, or null if it never sent.
  String? sentWorkspaceId;

  @override
  Future<void> execute({
    required String content,
    required String channelId,
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? conversationId,
  }) async {
    sentWorkspaceId = workspaceId;
  }
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('ChannelInputBar rendering', () {
    testWidgets('renders text field and send button', (tester) async {
      tester.view.physicalSize = const Size(800, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
            speechTranscriberProvider.overrideWithValue(null),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChannelInputBar(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CcTextField), findsOneWidget);
      expect(find.byIcon(AppIcons.arrowUp), findsOneWidget);
    });

    testWidgets('shows hint text', (tester) async {
      tester.view.physicalSize = const Size(800, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
            speechTranscriberProvider.overrideWithValue(null),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChannelInputBar(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Message… (@ to mention, / for commands)'),
        findsOneWidget,
      );
    });

    testWidgets('typing @ shows mention suggestions', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final a = Agent(
        id: 'a1',
        name: 'Architect',
        title: 'Software Architect',
        agentMdPath: '/path',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(AsyncData([a])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
            speechTranscriberProvider.overrideWithValue(null),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChannelInputBar(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(CcTextField), '@Arch');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Architect'), findsOneWidget);
    });
  });

  group('ChannelInputBar send', () {
    testWidgets('send button exists and is tappable', (tester) async {
      tester.view.physicalSize = const Size(800, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
            speechTranscriberProvider.overrideWithValue(null),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChannelInputBar(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(AppIcons.arrowUp));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ChannelInputBar), findsOneWidget);
    });

    testWidgets('typing text and sending works', (tester) async {
      tester.view.physicalSize = const Size(800, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sender = _MockSendChannelMessageUseCase();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            // Sending is workspace-scoped: the composer threads the active
            // workspace into the use case, so it has to be seeded.
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            speechTranscriberProvider.overrideWithValue(null),
            sendChannelMessageUseCaseProvider.overrideWithValue(sender),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChannelInputBar(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(CcTextField), 'Hello');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(AppIcons.arrowUp));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(sender.sentWorkspaceId, 'ws-1');
    });

    testWidgets('does not show mentions when no @ in text', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final a = Agent(
        id: 'a1',
        name: 'Architect',
        title: 'Software Architect',
        agentMdPath: '/path',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(AsyncData([a])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
            speechTranscriberProvider.overrideWithValue(null),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChannelInputBar(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(CcTextField), 'Hello');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Architect'), findsNothing);
    });

    testWidgets('mention partial filter works', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final a = Agent(
        id: 'a1',
        name: 'Builder',
        title: 'Build Engineer',
        agentMdPath: '/path',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        createdAt: DateTime(2024),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(AsyncData([a])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
            speechTranscriberProvider.overrideWithValue(null),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: ChannelInputBar(channelId: 'ch-1')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(CcTextField), '@B');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Builder'), findsOneWidget);
    });
  });
}
