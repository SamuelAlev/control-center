import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/ports/git_snapshot_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/worktree_fork_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/messaging/conversation_checkpoint_service.dart';
import 'package:cc_infra/src/messaging/conversation_fork_service.dart';
import 'package:test/test.dart';

class _FakeRepo implements MessagingRepository {
  _FakeRepo(this.messages, {this.participants = const []});

  final List<ChannelMessage> messages;
  final List<ChannelParticipant> participants;
  final List<({String channelId, String content, String type})> sent = [];
  final List<({String channelId, String messageId, bool inclusive})> reverts =
      [];
  String? createdChannelName;

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async =>
      List.of(messages);

  @override
  Future<List<ChannelParticipant>> getParticipants(String channelId) async =>
      participants;

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    dynamic mode,
    String? workspaceId,
    String? pipelineRunId,
  }) async {
    createdChannelName = name;
    return Channel(
      id: 'fork-1',
      name: name,
      isDm: false,
      workspaceId: workspaceId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<String> sendMessage({
    required String channelId,
    required String content,
    required String senderId,
    required String senderType,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
    String? parentMessageId,
  }) async {
    sent.add((channelId: channelId, content: content, type: messageType));
    return 'msg${sent.length}';
  }

  @override
  Future<List<String>> revertConversationTo(
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async {
    reverts.add((channelId: channelId, messageId: messageId, inclusive: inclusive));
    return ['x'];
  }

  @override
  Future<List<String>> unrevertConversation(String channelId) async => ['y'];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeWorktree implements WorktreeForkPort {
  String? lastName;
  @override
  Future<String> createForkWorktree({
    required String sourceRepoPath,
    required String forkName,
  }) async {
    lastName = forkName;
    return '/tmp/worktrees/$forkName';
  }
}

class _FakeGit implements GitSnapshotPort {
  final List<({String path, String ref})> restored = [];
  @override
  Future<String?> capture(String worktreePath) async => 'cap';
  @override
  Future<void> restore(String worktreePath, String ref) async =>
      restored.add((path: worktreePath, ref: ref));
}

ChannelMessage _msg(String id, String content, {ChannelSenderType who = ChannelSenderType.user, Map<String, dynamic>? metadata}) =>
    ChannelMessage(
      id: id,
      channelId: 'src',
      senderId: who == ChannelSenderType.user ? 'user' : 'agent',
      senderType: who,
      content: content,
      messageType: who == ChannelSenderType.user
          ? ChannelMessageType.text
          : ChannelMessageType.agentTurn,
      metadata: metadata,
      createdAt: DateTime.utc(2026),
    );

void main() {
  group('ConversationForkService', () {
    test('copies messages up to the fork point + injects handoff', () async {
      final repo = _FakeRepo(
        [
          _msg('a', 'first'),
          _msg('b', 'second', who: ChannelSenderType.agent),
          _msg('c', 'third'),
          _msg('d', 'fourth'),
        ],
        participants: [
          ChannelParticipant(
            id: 'p1',
            channelId: 'src',
            agentId: 'architect',
            role: 'member',
            joinedAt: DateTime.utc(2026),
          ),
          ChannelParticipant(
            id: 'p2',
            channelId: 'src',
            agentId: 'user',
            role: 'member',
            joinedAt: DateTime.utc(2026),
          ),
        ],
      );
      final service = ConversationForkService(repo: repo);
      final outcome = await service.fork(
        sourceChannelId: 'src',
        atMessageId: 'b',
        name: 'explore-alt',
      );

      expect(outcome.newChannelId, 'fork-1');
      // Copied a + b (inclusive), then a system handoff reminder.
      expect(outcome.copiedMessageCount, 2);
      expect(repo.sent.length, 3);
      expect(repo.sent.last.type, 'system');
      expect(repo.sent.last.content, contains('<system-reminder>'));
      expect(repo.sent.last.content, isNot(contains('working directory')));
    });

    test('creates a worktree and notes it in the handoff', () async {
      final repo = _FakeRepo([_msg('a', 'first')]);
      final worktree = _FakeWorktree();
      final service = ConversationForkService(repo: repo, worktree: worktree);
      final outcome = await service.fork(
        sourceChannelId: 'src',
        atMessageId: 'a',
        name: 'wt-fork',
        intoNewWorktree: true,
        sourceRepoPath: '/repo',
      );
      expect(worktree.lastName, 'wt-fork');
      expect(outcome.worktreePath, '/tmp/worktrees/wt-fork');
      expect(repo.sent.last.content, contains('/tmp/worktrees/wt-fork'));
    });
  });

  group('ConversationCheckpointService', () {
    test('reverts conversation and restores filesystem to turn end snapshot',
        () async {
      final repo = _FakeRepo([
        _msg('a', 'first'),
        _msg(
          'b',
          'turn',
          who: ChannelSenderType.agent,
          metadata: {
            'snapshot': {'start': 'before-b', 'end': 'after-b'},
          },
        ),
        _msg('c', 'later'),
      ]);
      final git = _FakeGit();
      final service = ConversationCheckpointService(repo: repo, git: git);
      final outcome = await service.revertTo(
        channelId: 'src',
        messageId: 'b',
        worktreePath: '/wt',
      );
      expect(outcome.didSomething, isTrue);
      expect(repo.reverts.single.messageId, 'b');
      // Kept b → restore to its post-state ("end").
      expect(git.restored.single.ref, 'after-b');
    });

    test('inclusive revert restores to the pre-state snapshot', () async {
      final repo = _FakeRepo([
        _msg(
          'b',
          'turn',
          who: ChannelSenderType.agent,
          metadata: {
            'snapshot': {'start': 'before-b', 'end': 'after-b'},
          },
        ),
      ]);
      final git = _FakeGit();
      final service = ConversationCheckpointService(repo: repo, git: git);
      await service.revertTo(
        channelId: 'src',
        messageId: 'b',
        worktreePath: '/wt',
        inclusive: true,
      );
      expect(git.restored.single.ref, 'before-b');
    });

    test('no git restore when no worktree provided', () async {
      final repo = _FakeRepo([_msg('a', 'x')]);
      final git = _FakeGit();
      final service = ConversationCheckpointService(repo: repo, git: git);
      await service.revertTo(channelId: 'src', messageId: 'a');
      expect(git.restored, isEmpty);
    });
  });
}
