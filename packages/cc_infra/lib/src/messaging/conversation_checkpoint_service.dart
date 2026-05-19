import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/ports/git_snapshot_port.dart';
import 'package:cc_domain/features/dispatch/domain/snapshot/turn_snapshot.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// The result of a revert/unrevert operation.
class RevertOutcome {
  /// Creates a [RevertOutcome].
  const RevertOutcome({
    required this.affectedMessageIds,
    required this.filesystemRestored,
  });

  /// Ids reverted (or restored, for unrevert).
  final List<String> affectedMessageIds;

  /// Whether the worktree filesystem was rolled back to a turn snapshot.
  final bool filesystemRestored;

  /// Whether anything changed.
  bool get didSomething => affectedMessageIds.isNotEmpty;
}

/// Reverts a conversation to a checkpoint — rolling back BOTH the transcript
/// (reverted messages are hidden but kept for unrevert) AND, when a worktree
/// and per-turn snapshots are available, the filesystem to that turn's state.
class ConversationCheckpointService {
  /// Creates a [ConversationCheckpointService].
  ConversationCheckpointService({
    required MessagingRepository repo,
    GitSnapshotPort? git,
  })  : _repo = repo,
        _git = git;

  final MessagingRepository _repo;
  final GitSnapshotPort? _git;

  /// Reverts the conversation to [messageId]. When [inclusive] the target
  /// message is reverted too. When [worktreePath] is provided and the relevant
  /// turn carries a git snapshot, the filesystem is rolled back as well:
  /// keeping the target → restore to its post-state; reverting it → its
  /// pre-state.
  Future<RevertOutcome> revertTo({
    required String channelId,
    required String messageId,
    String? worktreePath,
    bool inclusive = false,
  }) async {
    final messages = await _repo.getMessages(channelId);
    final ref = _restoreRef(messages, messageId, inclusive: inclusive);

    final reverted = await _repo.revertConversationTo(
      channelId,
      messageId,
      inclusive: inclusive,
    );

    var restored = false;
    if (worktreePath != null && _git != null && ref != null) {
      try {
        await _git.restore(worktreePath, ref);
        restored = true;
      } catch (_) {
        // Filesystem restore is best-effort; the conversation revert still holds.
      }
    }

    return RevertOutcome(
      affectedMessageIds: reverted,
      filesystemRestored: restored,
    );
  }

  /// Undoes the most-recent revert (redo). Conversation-only; the filesystem is
  /// not re-applied (the user can re-run the agent to regenerate changes).
  Future<RevertOutcome> unrevert({required String channelId}) async {
    final restored = await _repo.unrevertConversation(channelId);
    return RevertOutcome(
      affectedMessageIds: restored,
      filesystemRestored: false,
    );
  }

  /// Picks the git ref to restore to: the kept boundary's snapshot. When the
  /// target turn itself is reverted ([inclusive]) we want the state BEFORE it
  /// (`start`); otherwise the state AFTER it (`end`). Falls back to the nearest
  /// preceding turn that carries a snapshot.
  String? _restoreRef(
    List<ChannelMessage> messages,
    String messageId, {
    required bool inclusive,
  }) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index < 0) {
      return null;
    }
    if (!inclusive) {
      final snap = TurnSnapshot.fromMetadata(messages[index].metadata);
      if (snap?.end != null) {
        return snap!.end;
      }
    }
    // Walk back from the target for the nearest pre-state snapshot.
    for (var i = index; i >= 0; i--) {
      final snap = TurnSnapshot.fromMetadata(messages[i].metadata);
      if (snap?.start != null) {
        return snap!.start;
      }
    }
    return null;
  }
}
