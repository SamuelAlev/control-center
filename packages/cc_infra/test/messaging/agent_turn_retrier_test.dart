import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
import 'package:cc_infra/src/messaging/agent_turn_retrier.dart';
import 'package:test/test.dart';

const _ws = 'ws-1';
const _space = 'space-1';
const _conv = 'conv-1';

/// One workspace's messages, oldest first, paged the way the stored
/// conversation is: newest page first, older pages behind a cursor.
class _Repo implements MessagingRepository {
  final List<Message> messages = [];

  /// Every `(spaceId, conversationId)` a page was read for.
  final List<(String, String)> pageReads = [];

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      workspaceId != _ws
      ? null
      : messages.where((m) => m.id == messageId).firstOrNull;

  @override
  Future<MessagePage> getMessagePage(
    String workspaceId,
    String spaceId,
    String conversationId, {
    int limit = defaultMessagePageSize,
    String? cursor,
  }) async {
    pageReads.add((spaceId, conversationId));
    final all = [
      for (final m in messages)
        if (m.spaceId == spaceId && m.conversationId == conversationId) m,
    ];
    final end = cursor == null ? all.length : int.parse(cursor);
    final start = end - limit < 0 ? 0 : end - limit;
    return MessagePage(
      messages: all.sublist(start, end),
      hasMore: start > 0,
      nextCursor: start > 0 ? '$start' : null,
    );
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    String? idempotencyKey,
  }) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    messages[index] = messages[index].copyWith(
      content: content,
      metadata: metadata,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Message _turn(
  String id, {
  String agentId = 'agent-1',
  String spaceId = _space,
  String conversationId = _conv,
  Map<String, dynamic>? metadata = const {'error': true},
}) => Message(
  id: id,
  spaceId: spaceId,
  conversationId: conversationId,
  senderId: agentId,
  senderType: SenderType.agent,
  content: '',
  messageType: MessageType.agentTurn,
  metadata: metadata,
  createdAt: DateTime(2026),
);

Message _said(String id) => Message(
  id: id,
  spaceId: _space,
  conversationId: _conv,
  senderId: 'user-1',
  senderType: SenderType.user,
  content: 'hello',
  messageType: MessageType.text,
  createdAt: DateTime(2026),
);

void main() {
  late _Repo repo;
  late List<Map<String, Object?>> dispatched;
  late AgentTurnRetrier retrier;

  /// What the next dispatch does before answering. Null answers at once.
  Future<void> Function()? beforeDispatch;

  /// Whether the dispatch is refused (answers null and starts nothing).
  var refuse = false;

  setUp(() {
    repo = _Repo();
    dispatched = [];
    beforeDispatch = null;
    refuse = false;
    retrier = AgentTurnRetrier(repo, ({
      required workspaceId,
      required spaceId,
      required agentId,
      required prompt,
      requestedByUserId,
      conversationId,
      modelOverride,
    }) async {
      dispatched.add({
        'workspaceId': workspaceId,
        'spaceId': spaceId,
        'agentId': agentId,
        'prompt': prompt,
        'requestedByUserId': requestedByUserId,
        'conversationId': conversationId,
        'modelOverride': modelOverride,
      });
      await beforeDispatch?.call();
      if (refuse) {
        return null;
      }
      // As the real dispatch does: the new run's turn is in the conversation
      // before the dispatch answers.
      final id = 'retry-${dispatched.length}';
      repo.messages.add(
        _turn(
          id,
          agentId: agentId,
          spaceId: spaceId,
          conversationId: conversationId!,
          metadata: const {'streamComplete': false},
        ),
      );
      return id;
    });
  });

  Future<void> press(
    String id, {
    String spaceId = _space,
    String? by = 'member-7',
    String? model,
  }) => retrier.retry(
    workspaceId: _ws,
    spaceId: spaceId,
    failedMessageId: id,
    requestedByUserId: by,
    modelOverride: model,
  );

  bool retried(String id) =>
      repo.messages.firstWhere((m) => m.id == id).metadata?['retried'] == true;

  test(
    'retries the failed turn where it failed, for whoever pressed',
    () async {
      repo.messages.add(
        _turn(
          'failed',
          metadata: const {'error': true, 'errorMessage': ' rate limited '},
        ),
      );

      await press('failed', model: 'another-model');

      expect(dispatched, hasLength(1));
      expect(dispatched.single, {
        'workspaceId': _ws,
        'spaceId': _space,
        'agentId': 'agent-1',
        'prompt': contains('failed before finishing: rate limited.'),
        'requestedByUserId': 'member-7',
        'conversationId': _conv,
        'modelOverride': 'another-model',
      });
      expect(retried('failed'), isTrue);
    },
  );

  test('the retried mark keeps what the turn already recorded', () async {
    repo.messages.add(
      _turn(
        'failed',
        metadata: const {'error': true, 'errorFamily': 'rate_limit'},
      ),
    );

    await press('failed');

    expect(repo.messages.first.metadata, {
      'error': true,
      'errorFamily': 'rate_limit',
      'retried': true,
    });
  });

  test('pressing again while the retry is starting starts nothing', () async {
    repo.messages.add(_turn('failed'));
    final gate = Completer<void>();
    beforeDispatch = () => gate.future;

    final first = press('failed');
    await pumpEventQueue();
    // The same turn, pressed twice more before the first run exists.
    await press('failed');
    await press('failed', by: 'member-9');
    expect(dispatched, hasLength(1));

    gate.complete();
    await first;
    expect(dispatched, hasLength(1));
    expect(retried('failed'), isTrue);
  });

  test('pressing again once the retry exists starts nothing', () async {
    repo.messages.add(_turn('failed'));

    await press('failed');
    await press('failed');
    await press('failed');

    expect(dispatched, hasLength(1));
  });

  test('a turn retried once stays retried even without its retry', () async {
    // The mark alone is enough: the run that retried it was reverted.
    repo.messages.add(
      _turn('failed', metadata: const {'error': true, 'retried': true}),
    );

    await press('failed');

    expect(dispatched, isEmpty);
  });

  test('an older failure cannot be retried once the agent moved on', () async {
    repo.messages
      ..add(_turn('older'))
      ..add(_said('reply'))
      ..add(_turn('working', metadata: const {'streamComplete': false}));

    await press('older');

    expect(dispatched, isEmpty);
    expect(retried('older'), isFalse);
  });

  test(
    'of several failures in a row, only the newest can be retried',
    () async {
      repo.messages
        ..add(_turn('first'))
        ..add(_turn('second'))
        ..add(_turn('third'));

      await press('first');
      await press('second');
      expect(dispatched, isEmpty);

      await press('third');
      expect(dispatched, hasLength(1));
      expect(retried('third'), isTrue);
      expect(retried('first'), isFalse);
      expect(retried('second'), isFalse);
    },
  );

  test("another agent's turns do not stand in the way", () async {
    repo.messages
      ..add(_turn('failed'))
      ..add(_turn('other', agentId: 'agent-2', metadata: const {}));

    await press('failed');

    expect(dispatched.single['agentId'], 'agent-1');
  });

  test('a turn that did not fail is not retried', () async {
    repo.messages.add(_turn('fine', metadata: const {'streamComplete': true}));

    await press('fine');

    expect(dispatched, isEmpty);
    expect(retried('fine'), isFalse);
  });

  test('a message that is not an agent turn is not retried', () async {
    repo.messages.add(_said('words').copyWith(metadata: const {'error': true}));

    await press('words');

    expect(dispatched, isEmpty);
  });

  test('a message that is gone is not retried', () async {
    await press('never-existed');

    expect(dispatched, isEmpty);
  });

  test('a turn from another space is refused and left untouched', () async {
    repo.messages.add(_turn('theirs', spaceId: 'space-2'));

    // The caller was cleared for `space-1`; the turn lives in `space-2`.
    await expectLater(
      press('theirs'),
      throwsA(isA<WorkspaceMismatchException>()),
    );

    expect(dispatched, isEmpty);
    expect(repo.pageReads, isEmpty);
    expect(retried('theirs'), isFalse);
    // The refusal does not leave the turn stuck: its own space can retry it.
    await press('theirs', spaceId: 'space-2');
    expect(dispatched.single['spaceId'], 'space-2');
  });

  test('a turn in another workspace is not found', () async {
    repo.messages.add(_turn('failed'));

    await retrier.retry(
      workspaceId: 'ws-2',
      spaceId: _space,
      failedMessageId: 'failed',
    );

    expect(dispatched, isEmpty);
  });

  test('a refused dispatch leaves the turn retryable', () async {
    repo.messages.add(_turn('failed'));
    refuse = true;

    await press('failed');
    expect(dispatched, hasLength(1));
    expect(retried('failed'), isFalse);

    // The person handed the worktree back.
    refuse = false;
    await press('failed');
    expect(dispatched, hasLength(2));
    expect(retried('failed'), isTrue);
  });

  test('a dispatch that throws leaves the turn retryable', () async {
    repo.messages.add(_turn('failed'));
    beforeDispatch = () async => throw StateError('adapter down');

    await expectLater(press('failed'), throwsStateError);
    expect(retried('failed'), isFalse);

    beforeDispatch = null;
    await press('failed');
    expect(dispatched, hasLength(2));
    expect(retried('failed'), isTrue);
  });

  test('a failure many messages back is still its agent\'s newest', () async {
    repo.messages.add(_turn('failed'));
    // More than two pages of conversation without this agent.
    for (var i = 0; i < defaultMessagePageSize * 2 + 5; i++) {
      repo.messages.add(_said('said-$i'));
    }

    await press('failed');

    expect(dispatched, hasLength(1));
    expect(repo.pageReads, hasLength(3));
  });

  test('stops reading at the turn that replaced the failure', () async {
    repo.messages.add(_turn('failed'));
    for (var i = 0; i < defaultMessagePageSize * 2; i++) {
      repo.messages.add(_said('said-$i'));
    }
    repo.messages.add(_turn('newer', metadata: const {'streamComplete': true}));

    await press('failed');

    expect(dispatched, isEmpty);
    expect(repo.pageReads, hasLength(1));
  });

  test('judges the turn in its own conversation', () async {
    repo.messages
      ..add(_turn('failed', conversationId: 'conv-side'))
      // The agent's newer turn is in the standing conversation, not this one.
      ..add(_turn('elsewhere', metadata: const {'streamComplete': true}));

    await press('failed');

    expect(repo.pageReads.single, (_space, 'conv-side'));
    expect(dispatched.single['conversationId'], 'conv-side');
  });
}
