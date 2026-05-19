import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-channel count of revert batches the user can still undo this session.
///
/// A conversation revert hides every message after a checkpoint; the host keeps
/// those rows but the wire NEVER carries the `reverted` flag (reverted rows just
/// drop out of the message stream), so a thin client cannot derive "is there
/// something to undo" from the transcript it sees. This notifier holds that
/// signal client-side: a revert pushes (+1), an undo-revert pops (−1). It is
/// session-scoped — undo is a short-lived affordance, so resetting on restart is
/// fine and matches the host (an unrevert only ever restores the latest batch).
class RevertHistoryNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  /// Records that [channelId] gained one undoable revert batch.
  void recordRevert(String channelId) {
    state = {...state, channelId: (state[channelId] ?? 0) + 1};
  }

  /// Records that the latest revert batch in [channelId] was undone.
  void recordUnrevert(String channelId) {
    final current = state[channelId] ?? 0;
    if (current <= 0) {
      return;
    }
    final next = Map<String, int>.from(state);
    if (current - 1 <= 0) {
      next.remove(channelId);
    } else {
      next[channelId] = current - 1;
    }
    state = next;
  }
}

/// Holds the session-scoped per-channel undoable-revert depth.
final revertHistoryProvider =
    NotifierProvider<RevertHistoryNotifier, Map<String, int>>(
      RevertHistoryNotifier.new,
    );

/// Whether the channel has a revert the user can undo (redo) this session.
final channelHasUndoableRevertProvider = Provider.autoDispose
    .family<bool, String>((ref, channelId) {
      return (ref.watch(revertHistoryProvider)[channelId] ?? 0) > 0;
    });

/// Drives conversation undo/redo from the UI: reverts a conversation to a
/// message (and, host-side, rolls the worktree filesystem back to that turn's
/// snapshot) and undoes the most-recent revert. Both run over the messaging
/// repository — `RpcMessagingRepository` on a thin client, executing on the host
/// that owns the DB + checkouts. The reverted/restored rows reappear/disappear
/// in the live `watchMessages` stream, so the feed updates reactively; this
/// controller only tracks the undo depth (see [RevertHistoryNotifier]) and
/// returns the affected count for a toast.
class ConversationCheckpointController {
  /// Creates a [ConversationCheckpointController].
  ConversationCheckpointController(this._ref);

  final Ref _ref;

  /// Reverts [channelId] to just after [messageId] (everything after it is
  /// hidden). Returns the number of messages hidden (0 when already at the end).
  Future<int> revertTo(String channelId, String messageId) async {
    final affected = await _ref
        .read(messagingRepositoryProvider)
        .revertConversationTo(_ref.requireWorkspaceId(), channelId, messageId);
    if (affected.isNotEmpty) {
      _ref.read(revertHistoryProvider.notifier).recordRevert(channelId);
    }
    return affected.length;
  }

  /// Undoes the most-recent revert in [channelId]. Returns the number of
  /// messages restored (0 when nothing was reverted).
  Future<int> unrevert(String channelId) async {
    final restored = await _ref
        .read(messagingRepositoryProvider)
        .unrevertConversation(_ref.requireWorkspaceId(), channelId);
    if (restored.isNotEmpty) {
      _ref.read(revertHistoryProvider.notifier).recordUnrevert(channelId);
    }
    return restored.length;
  }
}

/// Provides the [ConversationCheckpointController].
final conversationCheckpointControllerProvider =
    Provider<ConversationCheckpointController>(
      ConversationCheckpointController.new,
    );
