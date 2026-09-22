import 'package:cc_domain/core/domain/entities/message.dart';

/// The slice of a conversation an agent dispatch turns into a prompt.
///
/// [messages] is only the live tail, walking back from the newest row until
/// the verbatim budget is filled. [summaries] is every summary in the
/// conversation, including ones older than that tail. [lastAgentTurn] is the
/// one row whose transcript the run digest reads. Older transcripts are not
/// in any of these.
class ConversationContextHistory {
  /// Creates a dispatch history slice.
  const ConversationContextHistory({
    required this.messages,
    required this.summaries,
    this.lastAgentTurn,
  });

  /// Live rows from the tip, oldest first, far enough to fill the verbatim
  /// budget. Metadata has no transcript `segments`.
  final List<Message> messages;

  /// Every context summary, oldest first.
  final List<Message> summaries;

  /// The newest live agent turn, with its transcript, or null when the
  /// conversation has none.
  final Message? lastAgentTurn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationContextHistory &&
          _sameMessages(messages, other.messages) &&
          _sameMessages(summaries, other.summaries) &&
          lastAgentTurn == other.lastAgentTurn;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(messages),
    Object.hashAll(summaries),
    lastAgentTurn,
  );
}

bool _sameMessages(List<Message> a, List<Message> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Whether [message] consumes the dispatch verbatim-window budget.
///
/// Context summaries, system, ticket, and review rows do not. Neither does a
/// queued steering row: it has not reached an agent yet, and copying it into
/// the prompt would leak it ahead of its turn and double it when the harness
/// injects the same row. Compacted rows are already represented by a summary.
///
/// The paged history loader stops on this same predicate, so the tail and a
/// full scan build the same window.
bool messageCountsTowardContextBudget(Message message) {
  if (message.isContextSummary) {
    return false;
  }
  if (message.isSystem || message.isTicket || message.isReviewNode) {
    return false;
  }
  if (message.isSteeringQueued) {
    return false;
  }
  if (message.compacted) {
    return false;
  }
  return true;
}
