import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/catalog/conversation_scope.dart';
import 'package:cc_server_core/src/catalog/person_goal_dispatch.dart';
import 'package:test/test.dart';

/// Two conversations: one in the caller's space, one in another space.
class _Conversations implements ConversationRepository {
  final rows = {
    'conv-own': Conversation(
      id: 'conv-own',
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      title: 'Own',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
    'conv-other': Conversation(
      id: 'conv-other',
      workspaceId: 'ws-1',
      spaceId: 'space-2',
      title: 'Other',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
  };

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => rows[conversationId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final started = <String?>[];

  setUp(started.clear);

  Future<String?> command({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String prompt,
    required String requestedByUserId,
    String? conversationId,
  }) async {
    started.add(conversationId);
    return 'run-1';
  }

  Future<Map<String, dynamic>?> dispatch(Map<String, dynamic> args) =>
      startPersonGoalIfAsked(
        RepoOpContext(
          args: {'space_id': 'space-1', 'agent_id': 'agent-1', ...args},
          workspaceId: 'ws-1',
          deviceId: 'device-1',
          userId: 'olga',
        ),
        command: command,
        spaceId: 'space-1',
        resolveConversation: (supplied) => resolveSpaceConversation(
          _Conversations(),
          workspaceId: 'ws-1',
          spaceId: 'space-1',
          supplied: supplied,
        ),
      );

  test(
    "a person's /goal starts the goal in the conversation they named",
    () async {
      final result = await dispatch({
        'prompt': '/goal ship it',
        'conversation_id': 'conv-own',
      });

      expect(result, {'run_id': 'run-1'});
      expect(started, ['conv-own']);
    },
  );

  test(
    'a conversation of another space is refused, and no goal starts',
    () async {
      await expectLater(
        dispatch({'prompt': '/goal ship it', 'conversation_id': 'conv-other'}),
        throwsA(isA<NotFoundException>()),
      );
      expect(started, isEmpty);
    },
  );

  test('routed work and ordinary prompts are ordinary dispatches', () async {
    expect(
      await dispatch({'prompt': '/goal ship it', 'ticket_id': 't-1'}),
      isNull,
    );
    expect(await dispatch({'prompt': 'ship it'}), isNull);
    expect(started, isEmpty);
  });
}
