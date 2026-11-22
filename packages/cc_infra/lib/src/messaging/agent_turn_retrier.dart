import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/agent_turn_retry_policy.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Starts the run that replaces a failed turn (`MessagingService.dispatchAgent`).
/// Returns the new turn's message id, or null when the dispatch was refused.
typedef RetryDispatch =
    Future<String?> Function({
      required String workspaceId,
      required String spaceId,
      required String agentId,
      required String prompt,
      required WakeContext wakeContext,
      String? requestedByUserId,
      String? conversationId,
      String? modelOverride,
    });

/// Retries failed agent turns.
///
/// [AgentTurnRetryPolicy] says which turn can be retried. This makes it hold
/// however often Retry is pressed, from however many clients: one failed turn
/// starts at most one run, and a turn that cannot be retried starts none.
///
/// Three things carry that, in the order a press meets them:
///
///  1. [_starting] turns a press that arrives while the same turn's retry is
///     still being started into nothing.
///  2. The turn is judged against the conversation as stored now, not as the
///     pressing client last drew it.
///  3. The run it starts is itself a newer turn from the same agent, so the
///     failed turn stops being retryable the moment its retry exists. The
///     `retried` mark written afterwards is what the clients show; nothing
///     here depends on that write landing.
class AgentTurnRetrier {
  /// Creates the retrier over [_repo], starting runs through [_dispatch].
  AgentTurnRetrier(this._repo, this._dispatch);

  final MessagingRepository _repo;
  final RetryDispatch _dispatch;

  /// Turns whose retry is being started, as `(workspaceId, messageId)`. One
  /// server process owns a workspace's database, so this set sees every press.
  final _starting = <(String, String)>{};

  /// Retries [failedMessageId] in [spaceId] for [requestedByUserId].
  ///
  /// Does nothing when the turn is gone or cannot be retried: a repeated press
  /// is expected, and the clients' own view catches up with the stored one.
  /// Throws [WorkspaceMismatchException] when the message is not in [spaceId].
  Future<void> retry({
    required String workspaceId,
    required String spaceId,
    required String failedMessageId,
    String? modelOverride,
    String? requestedByUserId,
  }) async {
    final key = (workspaceId, failedMessageId);
    if (!_starting.add(key)) {
      return _ignored(failedMessageId, 'its retry is already starting');
    }
    try {
      final failed = await _repo.getMessageById(workspaceId, failedMessageId);
      if (failed == null) {
        return _ignored(failedMessageId, 'no such message');
      }
      // The caller was cleared for [spaceId], not for wherever this id lives.
      if (failed.spaceId != spaceId) {
        throw const WorkspaceMismatchException(
          'Message belongs to a different space.',
        );
      }
      if (!await _canRetry(workspaceId, failed)) {
        return _ignored(
          failedMessageId,
          "it is not its agent's newest turn, did not fail, or was retried",
        );
      }
      // Dispatched with the SAME context as the turn it replaces, or it is a
      // second-class run. A wrong or absent `workspaceId` hides it from every
      // workspace-scoped surface (composer stop, shimmer, roster, run tree),
      // fails the ownership check on stop/pause/steer (an unstoppable run) and
      // loses the conversation's isolated worktree. No `conversationId` lands
      // it in the standing conversation, not the failed turn's. No
      // `requestedByUserId` makes it nobody's run: bot commits, and nobody's
      // sign-in to push with. It is told what failed, to try something else.
      final failure = (failed.metadata?['errorMessage'] as String?)?.trim();
      final retryId = await _dispatch(
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentId: failed.senderId,
        prompt:
            'Your previous attempt in this space failed before finishing'
            '${failure == null || failure.isEmpty ? '' : ': $failure'}. '
            'Review the conversation above and re-attempt the task. If the '
            'previous approach is what failed, try a different one rather than '
            'repeating it.',
        // A person pressed Retry: the new run is their message's.
        wakeContext: const WakeContext.userMessage(),
        requestedByUserId: requestedByUserId,
        conversationId: failed.conversationId,
        modelOverride: modelOverride,
      );
      if (retryId == null) {
        // Refused (a person holds the worktree) and said so in the space.
        // Nothing replaced the turn, so it stays retryable.
        return _ignored(failedMessageId, 'the dispatch was refused');
      }
      // Merged into the row as it is now, not as it was before the dispatch.
      final current = await _repo.getMessageById(workspaceId, failedMessageId);
      await _repo.updateMessage(
        workspaceId,
        failedMessageId,
        metadata: {...?current?.metadata, 'retried': true},
      );
      CcInfraLog.info('Turn $failedMessageId retried as $retryId');
    } finally {
      _starting.remove(key);
    }
  }

  /// Whether [turn] passes [AgentTurnRetryPolicy] in its conversation as
  /// stored now.
  ///
  /// Reads newest first and stops at the first page holding a turn from the
  /// same agent: that is either [turn] or the one that replaced it. One page,
  /// unless the conversation moved on without this agent.
  Future<bool> _canRetry(String workspaceId, Message turn) async {
    final tail = <Message>[];
    String? cursor;
    do {
      final page = await _repo.getMessagePage(
        workspaceId,
        turn.spaceId,
        turn.conversationId,
        cursor: cursor,
      );
      tail.insertAll(0, page.messages);
      final reached = page.messages.any(
        (m) => m.isAgentTurn && m.senderId == turn.senderId,
      );
      cursor = reached ? null : page.nextCursor;
    } while (cursor != null);
    return const AgentTurnRetryPolicy().retryableIn(tail).contains(turn.id);
  }

  void _ignored(String messageId, String why) =>
      CcInfraLog.info('Retry of turn $messageId ignored: $why');
}
