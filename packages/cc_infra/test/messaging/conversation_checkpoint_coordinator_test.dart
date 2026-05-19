import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/ports/git_snapshot_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/messaging/conversation_checkpoint_coordinator.dart';
import 'package:test/test.dart';

ChannelMessage _msg(
  String id, {
  ChannelSenderType who = ChannelSenderType.user,
  Map<String, dynamic>? metadata,
}) => ChannelMessage(
  id: id,
  channelId: 'c1',
  conversationId: 'c1',
  senderId: who == ChannelSenderType.user ? 'user' : 'a1',
  senderType: who,
  content: id,
  messageType: who == ChannelSenderType.user
      ? ChannelMessageType.text
      : ChannelMessageType.agentTurn,
  metadata: metadata,
  createdAt: DateTime.utc(2026),
);

ChannelParticipant _part(
  String id,
  String principalId, {
  PrincipalType participantType = PrincipalType.agent,
}) => ChannelParticipant(
  id: id,
  channelId: 'c1',
  principalId: principalId,
  participantType: participantType,
  role: 'member',
  joinedAt: DateTime.utc(2026),
);

Agent _agent(String id, String agentMdPath) => Agent(
  id: id,
  name: 'Architect',
  title: 'Architect',
  agentMdPath: agentMdPath,
  workspaceId: 'ws1',
  skills: AgentSkills(const []),
  createdAt: DateTime.utc(2026),
);

class _FakeMessaging implements MessagingRepository {
  _FakeMessaging(this.messages, this.participants);

  final List<ChannelMessage> messages;
  final List<ChannelParticipant> participants;
  final List<
    ({String workspaceId, String channelId, String messageId, bool inclusive})
  >
  reverts = [];
  int unreverts = 0;

  /// Workspace the unrevert was scoped to.
  String? unrevertWorkspaceId;

  @override
  Future<List<ChannelMessage>> getMessages(
    String workspaceId,
    String channelId, {
    String? conversationId,
  }) async => List.of(messages);

  @override
  Future<List<ChannelParticipant>> getParticipants(
    String workspaceId,
    String channelId,
  ) async => participants;

  @override
  Future<List<String>> revertConversationTo(
    String workspaceId,
    String channelId,
    String messageId, {
    bool inclusive = false,
  }) async {
    reverts.add((
      workspaceId: workspaceId,
      channelId: channelId,
      messageId: messageId,
      inclusive: inclusive,
    ));
    return ['b', 'c'];
  }

  @override
  Future<List<String>> unrevertConversation(
    String workspaceId,
    String channelId,
  ) async {
    unrevertWorkspaceId = workspaceId;
    unreverts++;
    return ['b', 'c'];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeAgents implements AgentRepository {
  _FakeAgents(this._byId);

  final Map<String, Agent> _byId;

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    final agent = _byId[id];
    return agent != null && agent.workspaceId == workspaceId ? agent : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeGit implements GitSnapshotPort {
  final List<({String path, String ref})> restored = [];

  @override
  Future<String?> capture(String worktreePath) async => 'cap';

  @override
  Future<void> restore(String worktreePath, String ref) async =>
      restored.add((path: worktreePath, ref: ref));
}

void main() {
  const ws = 'ws1';

  group('ConversationCheckpointCoordinator', () {
    test(
      'resolves the worktree from the channel agent and restores it',
      () async {
        final messaging = _FakeMessaging(
          [
            _msg('a'),
            _msg(
              'b',
              who: ChannelSenderType.agent,
              metadata: {
                'snapshot': {'start': 'before-b', 'end': 'after-b'},
              },
            ),
            _msg('c'),
          ],
          [_part('p1', 'user'), _part('p2', 'a1')],
        );
        final git = _FakeGit();
        final coordinator = ConversationCheckpointCoordinator(
          messaging: messaging,
          agents: _FakeAgents({'a1': _agent('a1', '/repos/conv-1/agent.md')}),
          git: git,
        );

        final outcome = await coordinator.revertTo(
          workspaceId: ws,
          channelId: 'c1',
          messageId: 'b',
        );

        expect(outcome.affectedMessageIds, ['b', 'c']);
        expect(outcome.filesystemRestored, isTrue);
        expect(messaging.reverts.single.workspaceId, ws);
        expect(messaging.reverts.single.messageId, 'b');
        // Worktree resolved from the agent's .md dir; kept turn → restore to "end".
        expect(git.restored.single.path, '/repos/conv-1');
        expect(git.restored.single.ref, 'after-b');
      },
    );

    test('skips the user participant when resolving the worktree', () async {
      final messaging = _FakeMessaging(
        [
          _msg(
            'b',
            who: ChannelSenderType.agent,
            metadata: {
              'snapshot': {'start': 'before-b', 'end': 'after-b'},
            },
          ),
        ],
        // User listed first — must be skipped in favour of the agent.
        [_part('p1', 'user'), _part('p2', 'a1')],
      );
      final git = _FakeGit();
      final coordinator = ConversationCheckpointCoordinator(
        messaging: messaging,
        agents: _FakeAgents({'a1': _agent('a1', '/repos/conv-2/agent.md')}),
        git: git,
      );

      await coordinator.revertTo(
        workspaceId: ws,
        channelId: 'c1',
        messageId: 'b',
        inclusive: true,
      );
      // inclusive → restore to the pre-state ("start") in the agent's worktree.
      expect(git.restored.single.path, '/repos/conv-2');
      expect(git.restored.single.ref, 'before-b');
    });

    test(
      'falls back to transcript-only revert when no worktree resolves',
      () async {
        final messaging = _FakeMessaging(
          [_msg('a'), _msg('b', who: ChannelSenderType.agent)],
          [_part('p1', 'user')], // no agent participant
        );
        final git = _FakeGit();
        final coordinator = ConversationCheckpointCoordinator(
          messaging: messaging,
          agents: _FakeAgents(const {}),
          git: git,
        );

        final outcome = await coordinator.revertTo(
          workspaceId: ws,
          channelId: 'c1',
          messageId: 'a',
        );

        expect(outcome.affectedMessageIds, ['b', 'c']);
        expect(outcome.filesystemRestored, isFalse);
        expect(messaging.reverts.single.messageId, 'a');
        expect(git.restored, isEmpty);
      },
    );

    test(
      'unrevert restores the transcript only (no filesystem re-apply)',
      () async {
        final messaging = _FakeMessaging(const [], const []);
        final git = _FakeGit();
        final coordinator = ConversationCheckpointCoordinator(
          messaging: messaging,
          agents: _FakeAgents(const {}),
          git: git,
        );

        final outcome = await coordinator.unrevert(
          workspaceId: ws,
          channelId: 'c1',
        );

        expect(outcome.affectedMessageIds, ['b', 'c']);
        expect(outcome.filesystemRestored, isFalse);
        expect(messaging.unreverts, 1);
        expect(messaging.unrevertWorkspaceId, ws);
        expect(git.restored, isEmpty);
      },
    );
  });
}
