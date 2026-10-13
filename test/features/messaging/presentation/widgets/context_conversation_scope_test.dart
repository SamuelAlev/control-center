import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_summaries_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_header.dart';
import 'package:control_center/features/messaging/providers/context_inspection_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _workspaceId = 'ws-context-tabs';
const _spaceId = 'space-context-tabs';
const _agentId = 'agent-context-tabs';

class _Workspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _workspaceId;
}

class _Summaries implements MessagingSummariesPort {
  final updates = StreamController<ConversationTokenTotals>.broadcast();

  Future<void> dispose() => updates.close();

  @override
  Stream<ConversationTokenTotals> watchConversationTokens(
    String workspaceId,
    String spaceId,
    String conversationId,
  ) async* {
    if (workspaceId != _workspaceId || spaceId != _spaceId) {
      throw StateError('Unexpected conversation scope');
    }
    final tokens = switch (conversationId) {
      'conversation-1' => 21000,
      'conversation-2' => 78000,
      'conversation-3' => 142000,
      _ => throw StateError('Unknown conversation'),
    };
    yield ConversationTokenTotals(
      tokens: tokens,
      chars: tokens * 4,
      reportedContextTokens: tokens,
      reportedWindowTokens: 200000,
    );
    if (conversationId == 'conversation-2') {
      yield* updates.stream;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('each conversation tab keeps its own live context reading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.utc(2026);
    final space = Space(
      id: _spaceId,
      workspaceId: _workspaceId,
      name: 'Shared space',
      createdAt: now,
      updatedAt: now,
    );
    final conversations = [
      for (var index = 1; index <= 3; index++)
        Conversation(
          id: 'conversation-$index',
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          title: 'Conversation $index',
          createdAt: now,
          updatedAt: now,
        ),
    ];
    final selected = ValueNotifier(conversations.first);
    final summaries = _Summaries();
    addTearDown(selected.dispose);
    addTearDown(summaries.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_Workspace.new),
          messagingSummariesPortProvider.overrideWithValue(summaries),
          standingConversationIdProvider(
            _spaceId,
          ).overrideWith((ref) async => conversations.first.id),
          spaceParticipantsProvider(_spaceId).overrideWith(
            (ref) => Stream.value([
              SpaceParticipant(
                id: 'participant-context-tabs',
                spaceId: _spaceId,
                principalId: _agentId,
                participantType: PrincipalType.agent,
                role: 'member',
                joinedAt: now,
              ),
            ]),
          ),
          agentDetailProvider(_agentId).overrideWith(
            (ref) async => Agent(
              id: _agentId,
              name: 'Agent',
              title: 'Engineer',
              agentMdPath: '/tmp/agent.md',
              workspaceId: _workspaceId,
              skills: AgentSkills([]),
              contextSize: 200000,
              createdAt: now,
            ),
          ),
          contextInspectionProvider.overrideWith(
            (ref, args) async => const ContextInspection(
              workspaceId: _workspaceId,
              spaceId: _spaceId,
              agentId: _agentId,
              agentName: 'Agent',
              mode: 'chat',
              windowTokens: 200000,
              segments: [],
            ),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  Row(
                    children: [
                      for (var index = 0; index < conversations.length; index++)
                        CcButton(
                          onPressed: () =>
                              selected.value = conversations[index],
                          child: Text('Tab ${index + 1}'),
                        ),
                    ],
                  ),
                  ValueListenableBuilder<Conversation>(
                    valueListenable: selected,
                    builder: (context, conversation, child) => SpaceHeader(
                      space: space,
                      conversation: conversation,
                      onManage: () {},
                      onArchive: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('21k / 200k'), findsOneWidget);

    await tester.tap(find.text('Tab 2'));
    await tester.pumpAndSettle();
    expect(find.text('78k / 200k'), findsOneWidget);
    expect(find.text('21k / 200k'), findsNothing);

    summaries.updates.add(
      const ConversationTokenTotals(
        tokens: 83000,
        chars: 332000,
        reportedContextTokens: 83000,
        reportedWindowTokens: 200000,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('83k / 200k'), findsOneWidget);

    await tester.tap(find.text('Tab 3'));
    await tester.pumpAndSettle();
    expect(find.text('142k / 200k'), findsOneWidget);
    expect(find.text('83k / 200k'), findsNothing);

    await tester.tap(find.text('Tab 1'));
    await tester.pumpAndSettle();
    expect(find.text('21k / 200k'), findsOneWidget);
    await tester.tap(find.text('21k / 200k'));
    await tester.pumpAndSettle();
    expect(find.text('21K / 200K tokens'), findsOneWidget);
  });
}
