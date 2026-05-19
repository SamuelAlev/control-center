import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/dispatch/domain/snapshot/turn_snapshot.dart';
import 'package:cc_domain/features/messaging/domain/ports/worktree_fork_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// The result of forking a conversation.
class ForkOutcome {
  /// Creates a [ForkOutcome].
  const ForkOutcome({
    required this.newChannelId,
    required this.copiedMessageCount,
    this.worktreePath,
  });

  /// Id of the newly-created channel.
  final String newChannelId;

  /// Number of messages copied from the source.
  final int copiedMessageCount;

  /// Path of the new worktree, when the fork branched the filesystem too.
  final String? worktreePath;
}

/// Forks a conversation at a chosen message into a brand-new channel — and,
/// optionally, a brand-new worktree — so an alternative approach can be
/// explored without disturbing the original. The copied history is retained
/// intentionally; a synthetic `<system-reminder>` tells the agent so.
class ConversationForkService {
  /// Creates a [ConversationForkService].
  ConversationForkService({
    required MessagingRepository repo,
    WorktreeForkPort? worktree,
  })  : _repo = repo,
        _worktree = worktree;

  final MessagingRepository _repo;
  final WorktreeForkPort? _worktree;

  /// Forks [sourceChannelId] at [atMessageId] into a new channel named [name].
  /// Copies messages up to (and including, when [includeTarget]) the fork
  /// point. When [intoNewWorktree] and a [WorktreeForkPort] + [sourceRepoPath]
  /// are available, also creates a fresh worktree and notes it in the handoff.
  Future<ForkOutcome> fork({
    required String sourceChannelId,
    required String atMessageId,
    required String name,
    String? workspaceId,
    bool includeTarget = true,
    bool intoNewWorktree = false,
    String? sourceRepoPath,
  }) async {
    final source = await _repo.getMessages(sourceChannelId);
    final cut = source.indexWhere((m) => m.id == atMessageId);
    if (cut < 0) {
      throw ArgumentError('Fork point $atMessageId not found in $sourceChannelId');
    }
    final end = includeTarget ? cut + 1 : cut;
    final copied = source.sublist(0, end);

    // Mirror the source's agent participants into the fork.
    final participants = await _repo.getParticipants(sourceChannelId);
    final agentIds = participants
        .map((p) => p.agentId)
        .where((id) => id != 'user')
        .toList();

    final channel = await _repo.createGroup(
      name,
      agentIds,
      workspaceId: workspaceId,
    );

    String? worktreePath;
    if (intoNewWorktree && _worktree != null && sourceRepoPath != null) {
      worktreePath = await _worktree.createForkWorktree(
        sourceRepoPath: sourceRepoPath,
        forkName: name,
      );
    }

    var count = 0;
    for (final m in copied) {
      await _repo.sendMessage(
        channelId: channel.id,
        content: m.content,
        senderId: m.senderId,
        senderType: m.senderType == ChannelSenderType.user ? 'user' : 'agent',
        messageType: _typeToWire(m.messageType),
        metadata: m.metadata,
      );
      count++;
    }

    // Synthetic reminder so the forked agent understands the retained context
    // and (when applicable) the new working directory.
    await _repo.sendMessage(
      channelId: channel.id,
      content: buildForkHandoffReminder(directory: worktreePath),
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );

    return ForkOutcome(
      newChannelId: channel.id,
      copiedMessageCount: count,
      worktreePath: worktreePath,
    );
  }

  String _typeToWire(ChannelMessageType type) => switch (type) {
        ChannelMessageType.text => 'text',
        ChannelMessageType.system => 'system',
        ChannelMessageType.ticketCard => 'ticket_card',
        ChannelMessageType.agentTurn => 'agent_turn',
        ChannelMessageType.reviewNode => 'review_node',
        ChannelMessageType.hireProposal => 'hire_proposal',
        ChannelMessageType.reviewSummary => 'review_summary',
        ChannelMessageType.plan => 'plan',
        ChannelMessageType.userQuestion => 'user_question',
        ChannelMessageType.orchestrationProposal => 'orchestration_proposal',
        ChannelMessageType.compaction => 'compaction',
      };
}
