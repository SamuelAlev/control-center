import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_server_core/src/pr_review/pr_merge_conflict_service.dart';
import 'package:test/test.dart';

class _Messaging implements MessagingPort {
  final sent = <({String content, String? conversationId, String? user})>[];
  final dispatched = <({String agentId, String? conversationId})>[];
  final added = <String>[];

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async => sent.add((
    content: content,
    conversationId: conversationId,
    user: senderUserId,
  ));

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    dispatched.add((agentId: agentId, conversationId: conversationId));
    return 'run-1';
  }

  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) async => added.add(agentId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessagingRepo implements MessagingRepository {
  _MessagingRepo({this.messages = const []});

  final List<Message> messages;

  @override
  Future<List<Message>> getSpaceMessages(String workspaceId, String spaceId) =>
      Future.value(messages);

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations implements ConversationRepository {
  final titles = <String>[];

  @override
  Future<Conversation> create({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? anchorMessageId,
    String? createdByPrincipalId,
  }) async {
    titles.add(title);
    final now = DateTime.utc(2026);
    return Conversation(
      id: 'conv-1',
      workspaceId: workspaceId,
      spaceId: spaceId,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Message _agentSaid(String agentId) => Message(
  id: 'm1',
  spaceId: 'space-1',
  conversationId: 'main',
  senderId: agentId,
  senderType: SenderType.agent,
  content: 'hi',
  messageType: MessageType.text,
  createdAt: DateTime.utc(2026),
);

void main() {
  late _Messaging messaging;
  late _Conversations conversations;

  PrMergeConflictService build({
    List<Message> messages = const [],
    Future<List<String>> Function()? files,
    PrMergeRefs? refs = (title: 'T', baseRef: 'main', headRef: 'feat'),
  }) => PrMergeConflictService(
    refs: (_, _, _) async => refs,
    conflictFiles:
        ({
          required workspaceId,
          required owner,
          required repo,
          required prNumber,
          required baseRef,
          required userId,
        }) => files?.call() ?? Future.value(const ['a.dart', 'b.dart']),
    ensureSpace:
        ({
          required workspaceId,
          required repoFullName,
          required prNumber,
          required title,
        }) async => 'space-1',
    defaultAgent: (_) async => 'ceo',
    conversations: conversations,
    messaging: messaging,
    messagingRepository: _MessagingRepo(messages: messages),
  );

  setUp(() {
    messaging = _Messaging();
    conversations = _Conversations();
  });

  test('conflicts reports the files against the PR base', () async {
    final result = await build().conflicts(
      workspaceId: 'ws',
      owner: 'o',
      repo: 'r',
      prNumber: 7,
    );
    expect(result.toWire(), {
      'files': ['a.dart', 'b.dart'],
      'base_ref': 'main',
      'head_ref': 'feat',
    });
  });

  test('a missing pull request is a not-found, not an internal error', () {
    expect(
      build(refs: null).conflicts(
        workspaceId: 'ws',
        owner: 'o',
        repo: 'r',
        prNumber: 7,
      ),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('fix posts the request as the caller and dispatches into a new '
      'conversation, to the agent that already spoke', () async {
    final result = await build(messages: [_agentSaid('reviewer')])
        .fixConflicts(
          workspaceId: 'ws',
          owner: 'o',
          repo: 'r',
          prNumber: 7,
          userId: 'u1',
        );

    expect(result['space_id'], 'space-1');
    expect(result['conversation_id'], 'conv-1');
    expect(result['agent_id'], 'reviewer');
    expect(conversations.titles, ['Resolve merge conflicts']);
    expect(messaging.sent.single.user, 'u1');
    expect(messaging.sent.single.conversationId, 'conv-1');
    expect(messaging.sent.single.content, contains('- `a.dart`'));
    expect(messaging.dispatched.single, (
      agentId: 'reviewer',
      conversationId: 'conv-1',
    ));
    expect(messaging.added, isEmpty);
  });

  test('an empty space gets the default agent, added to the roster', () async {
    await build().fixConflicts(
      workspaceId: 'ws',
      owner: 'o',
      repo: 'r',
      prNumber: 7,
    );
    expect(messaging.added, ['ceo']);
    expect(messaging.dispatched.single.agentId, 'ceo');
  });

  test('a failed conflict probe still starts the fix', () async {
    await build(files: () async => throw StateError('fetch failed'))
        .fixConflicts(workspaceId: 'ws', owner: 'o', repo: 'r', prNumber: 7);
    expect(messaging.dispatched, hasLength(1));
    expect(
      messaging.sent.single.content,
      contains('GitHub did not say which files conflict'),
    );
  });

  test('the prompt merges the base in and never rebases', () {
    final prompt = buildMergeConflictPrompt(
      prNumber: 7,
      baseRef: 'main',
      headRef: 'feat',
      files: const ['x.dart'],
    );
    expect(prompt, contains('merge it into this branch'));
    expect(prompt, contains('Do NOT rebase'));
    expect(prompt, contains('push it to `feat`'));
  });
}
