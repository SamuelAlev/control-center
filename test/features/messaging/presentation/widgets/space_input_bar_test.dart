import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_input_bar.dart';
import 'package:control_center/features/messaging/providers/editing_message_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

class _PlanMode extends ActiveSpaceModeNotifier {
  @override
  Mode build() => Mode.plan;
}

class _ClaudeAdapter extends DefaultChatAdapterNotifier {
  @override
  String? build() => 'claude-code';
}

/// Records what the composer sent, without implementing the other ~30 members
/// of [MessagingPort]. `noSuchMethod` covers the rest: this test is about ONE
/// call, and spelling out the whole port here would make it a test of the
/// interface's shape instead.
class _RecordingMessagingPort implements MessagingPort {
  /// Workspace the composer threaded into the send, or null if it never sent.
  String? sentWorkspaceId;

  /// Body of the last send, or null if it never sent.
  String? sentContent;

  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    Map<String, dynamic>? metadata,
  }) async {
    sentWorkspaceId = workspaceId;
    sentContent = content;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async => const GuidedGoalStepResult();
}

/// Records message edits without standing up the rest of the repository.
class _RecordingEditRepo implements MessagingRepository {
  final List<({String id, String? content})> updates = [];
  final List<String> reverts = [];

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    updates.add((id: messageId, content: content));
  }

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String spaceId,
    String messageId, {
    bool inclusive = false,
  }) async {
    reverts.add(messageId);
    return const ['later'];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

Message _editableMessage({String content = 'original wording'}) => Message(
  id: 'm1',
  spaceId: 'ch-1',
  conversationId: 'conv-1',
  senderId: 'u1',
  senderType: SenderType.user,
  content: content,
  messageType: MessageType.text,
  createdAt: DateTime(2026, 7, 1),
);

String _fieldText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('SpaceInputBar rendering', () {
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
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
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
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
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
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
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

    testWidgets('hovering the degraded badge does not throw', (tester) async {
      tester.view.physicalSize = const Size(420, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            activeSpaceModeProvider.overrideWith(_PlanMode.new),
            defaultChatAdapterProvider.overrideWith(_ClaudeAdapter.new),
            workspaceAgentsProvider(
              'ws-1',
            ).overrideWith((ref) => Stream.value(const [])),
            spaceParticipantsProvider(
              'ch-1',
            ).overrideWith((ref) => Stream.value(const [])),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => Stack(
                children: [
                  Overlay(
                    initialEntries: [
                      OverlayEntry(builder: (_) => child ?? const SizedBox()),
                    ],
                  ),
                ],
              ),
              home: const Scaffold(
                body: IndexedStack(
                  index: 0,
                  sizing: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SpaceInputBar(
                        spaceId: 'ch-1',
                        conversationId: 'conv-1',
                      ),
                    ),
                    SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Degraded'), findsOneWidget);

      await tester.tap(find.byType(CcTextField));
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('Degraded')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('relies on the sandbox only'), findsOneWidget);
    });
  });

  group('SpaceInputBar send', () {
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
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(AppIcons.arrowUp));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SpaceInputBar), findsOneWidget);
    });

    testWidgets('typing text and sending works', (tester) async {
      tester.view.physicalSize = const Size(800, 200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sender = _RecordingMessagingPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            spacesProvider.overrideWithValue(const AsyncData([])),
            // Sending is workspace-scoped: the composer threads the active
            // workspace into the port call, so it has to be seeded.
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            messagingServiceProvider.overrideWithValue(sender),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
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
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
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
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
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

  group('SpaceInputBar edit', () {
    const key = (spaceId: 'ch-1', conversationId: 'conv-1');

    Future<ProviderContainer> pumpBar(
      WidgetTester tester, {
      MessagingRepository? repository,
      _RecordingMessagingPort? sender,
    }) async {
      tester.view.physicalSize = const Size(800, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWithValue(const AsyncData([])),
            spacesProvider.overrideWithValue(const AsyncData([])),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            if (repository != null)
              messagingRepositoryProvider.overrideWithValue(repository),
            if (sender != null)
              messagingServiceProvider.overrideWithValue(sender),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SpaceInputBar(spaceId: 'ch-1', conversationId: 'conv-1'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // The scope owns the container, so the presence heartbeat dies with the
      // tree. A container held past unmount leaves that timer pending.
      return ProviderScope.containerOf(
        tester.element(find.byType(SpaceInputBar)),
      );
    }

    testWidgets(
      'loads the message into the field and cancel restores the draft',
      (tester) async {
        final container = await pumpBar(tester);
        await tester.enterText(find.byType(CcTextField), 'keep this draft');
        await tester.pump();

        container
            .read(editingMessageProvider(key).notifier)
            .begin(_editableMessage());
        await tester.pump();

        expect(_fieldText(tester), 'original wording');
        expect(find.text('Edit message'), findsOneWidget);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(_fieldText(tester), 'keep this draft');
        expect(find.text('Edit message'), findsNothing);

        container
            .read(editingMessageProvider(key).notifier)
            .begin(_editableMessage());
        await tester.pump();
        expect(_fieldText(tester), 'original wording');

        await tester.tap(find.byIcon(AppIcons.x));
        await tester.pump();

        expect(_fieldText(tester), 'keep this draft');
        expect(find.text('Edit message'), findsNothing);
      },
    );

    Future<void> reviseAndSend(WidgetTester tester) async {
      await tester.enterText(find.byType(CcTextField), 'revised wording');
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.arrowUp));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('sending asks, and revert writes the edit without a new send', (
      tester,
    ) async {
      final repo = _RecordingEditRepo();
      final sender = _RecordingMessagingPort();
      final container = await pumpBar(tester, repository: repo, sender: sender);
      await tester.enterText(find.byType(CcTextField), 'keep this draft');
      await tester.pump();

      container
          .read(editingMessageProvider(key).notifier)
          .begin(_editableMessage());
      await tester.pump();
      await reviseAndSend(tester);

      expect(find.text('Revert to there'), findsOneWidget);
      expect(find.text('Send as a new message'), findsOneWidget);
      expect(repo.updates, isEmpty);
      expect(sender.sentWorkspaceId, isNull);

      await tester.tap(find.text('Revert to there'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.updates, hasLength(1));
      expect(repo.updates.single.id, 'm1');
      expect(repo.updates.single.content, 'revised wording');
      expect(repo.reverts, ['m1']);
      expect(sender.sentWorkspaceId, isNull);
      expect(_fieldText(tester), 'keep this draft');
      expect(find.text('Edit message'), findsNothing);
    });

    testWidgets('sending as a new message leaves the original and sends', (
      tester,
    ) async {
      final repo = _RecordingEditRepo();
      final sender = _RecordingMessagingPort();
      final container = await pumpBar(tester, repository: repo, sender: sender);
      await tester.enterText(find.byType(CcTextField), 'keep this draft');
      await tester.pump();

      container
          .read(editingMessageProvider(key).notifier)
          .begin(_editableMessage());
      await tester.pump();
      await reviseAndSend(tester);

      await tester.tap(find.text('Send as a new message'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.updates, isEmpty);
      expect(repo.reverts, isEmpty);
      expect(sender.sentWorkspaceId, 'ws-1');
      expect(sender.sentContent, 'revised wording');
      expect(_fieldText(tester), 'keep this draft');
      expect(find.text('Edit message'), findsNothing);
    });

    testWidgets('dismissing the choice keeps the edit in the composer', (
      tester,
    ) async {
      final container = await pumpBar(tester);
      container
          .read(editingMessageProvider(key).notifier)
          .begin(_editableMessage());
      await tester.pump();
      await reviseAndSend(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_fieldText(tester), 'revised wording');
      expect(find.text('Edit message'), findsOneWidget);
      expect(container.read(editingMessageProvider(key))?.message.id, 'm1');
    });
  });
}
