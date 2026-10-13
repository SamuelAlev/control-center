import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_window_usage.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_pane.dart';
import 'package:control_center/features/messaging/providers/context_inspection_provider.dart';
import 'package:control_center/features/messaging/providers/context_usage_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart' show Override;

const _workspaceId = 'ws-1';
const _spaceId = 'sp-1';
const _agentId = 'ag-1';

class _ActiveWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;
}

class _RecordingMessages implements MessagingRepository {
  final requestedConversations = <String>[];

  @override
  Stream<List<Message>> watchMessages(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) {
    expect(workspaceId, _workspaceId);
    expect(spaceId, _spaceId);
    requestedConversations.add(conversationId);
    return Stream.value([
      Message(
        id: 'message-$conversationId',
        spaceId: spaceId,
        conversationId: conversationId,
        senderId: 'user-1',
        senderType: SenderType.user,
        content: 'Only in $conversationId',
        messageType: MessageType.text,
        createdAt: DateTime.utc(2026),
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ContextInspection _inspection() => const ContextInspection(
  workspaceId: _workspaceId,
  spaceId: _spaceId,
  agentId: _agentId,
  agentName: 'Aria',
  mode: 'chat',
  workingDirectory: '/overlay',
  windowTokens: 256000,
  hasContent: true,
  segments: [],
);

List<Override> _overrides(_RecordingMessages repository) => [
  activeWorkspaceIdProvider.overrideWith(_ActiveWorkspace.new),
  messagingRepositoryProvider.overrideWithValue(repository),
  for (final conversationId in ['cv-1', 'cv-2']) ...[
    contextInspectionProvider((
      spaceId: _spaceId,
      conversationId: conversationId,
      agentId: _agentId,
      includeContent: true,
    )).overrideWith((ref) async => _inspection()),
    conversationContextUsageProvider((
      spaceId: _spaceId,
      conversationId: conversationId,
      agentId: _agentId,
    )).overrideWith(
      (ref) => const ContextWindowUsage(usedTokens: 0, windowTokens: 256000),
    ),
    conversationTokenTotalsProvider((
      spaceId: _spaceId,
      conversationId: conversationId,
    )).overrideWith((ref) => Stream.value(ConversationTokenTotals.empty)),
  ],
];

void main() {
  testWidgets(
    'switching explorers reads and renders only their conversations',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = _RecordingMessages();
      final selectedConversation = ValueNotifier('cv-1');
      addTearDown(selectedConversation.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(repository),
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ValueListenableBuilder<String>(
                  valueListenable: selectedConversation,
                  builder: (context, conversationId, child) =>
                      ContextExplorerPane(
                        workspaceId: _workspaceId,
                        spaceId: _spaceId,
                        conversationId: conversationId,
                        agentId: _agentId,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Everything'));
      await tester.pump();
      expect(find.textContaining('Only in cv-1'), findsOneWidget);
      expect(repository.requestedConversations, ['cv-1']);

      selectedConversation.value = 'cv-2';
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Only in cv-2'), findsOneWidget);
      expect(find.textContaining('Only in cv-1'), findsNothing);
      expect(repository.requestedConversations, ['cv-1', 'cv-2']);
    },
  );
}
