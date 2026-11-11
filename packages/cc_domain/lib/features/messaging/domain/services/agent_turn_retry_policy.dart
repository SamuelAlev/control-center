import 'package:cc_domain/core/domain/entities/message.dart';

/// One agent turn as the retry rule sees it: who took it and how it ended.
typedef RetryTurn = ({String id, String agentId, Object? metadata});

/// Which failed agent turns can be retried.
///
/// A turn can be retried when it ended in an error, has not been retried yet
/// and is still its agent's newest turn in the conversation. Any newer turn
/// from that agent replaces it: the retry itself, a reply to a later message,
/// a run that is still working. The retry tells the agent its previous attempt
/// failed, which is only true of the newest one, so an older failure is
/// history and has nothing left to retry.
///
/// The server enforces the rule (`AgentTurnRetrier`). The clients apply the
/// same one to the messages they show, so Retry is offered only where the
/// server would accept it.
class AgentTurnRetryPolicy {
  /// Creates the policy.
  const AgentTurnRetryPolicy();

  /// Whether a turn with this [metadata] failed and has not been retried.
  bool awaitsRetry(Object? metadata) =>
      metadata is Map &&
      metadata['error'] == true &&
      metadata['retried'] != true;

  /// Ids of the turns that can be retried, given the agent [turns] of ONE
  /// conversation, oldest first.
  ///
  /// The newest messages of a conversation are enough: a turn is judged
  /// against the turns after it, never the ones before.
  Set<String> retryable(Iterable<RetryTurn> turns) {
    final newestByAgent = <String, RetryTurn>{};
    for (final turn in turns) {
      newestByAgent[turn.agentId] = turn;
    }
    return {
      for (final turn in newestByAgent.values)
        if (awaitsRetry(turn.metadata)) turn.id,
    };
  }

  /// [retryable] over the messages of one conversation, oldest first.
  Set<String> retryableIn(Iterable<Message> conversation) => retryable([
    for (final message in conversation)
      if (message.isAgentTurn)
        (id: message.id, agentId: message.senderId, metadata: message.metadata),
  ]);
}
