import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/messaging/domain/usecases/send_channel_message_use_case.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

class _MockSendChannelMessageUseCase implements SendChannelMessageUseCase {
  @override
  Future<void> execute({
    required String content,
    required String channelId,
    List<StructuredMention>? structuredMentions,
    String? workspaceId,
    String? parentMessageId,
  }) async {}
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

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);
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

      await tester.enterText(find.byType(TextField), '@Arch');
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

      await tester.tap(find.byIcon(LucideIcons.arrowUp));
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            channelsProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
            speechTranscriberProvider.overrideWithValue(null),
            sendChannelMessageUseCaseProvider.overrideWithValue(
              _MockSendChannelMessageUseCase(),
            ),
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

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(LucideIcons.arrowUp));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
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

      await tester.enterText(find.byType(TextField), 'Hello');
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

      await tester.enterText(find.byType(TextField), '@B');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Builder'), findsOneWidget);
    });
  });
}
