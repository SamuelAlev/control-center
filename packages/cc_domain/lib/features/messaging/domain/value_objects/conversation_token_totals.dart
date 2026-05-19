import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_token_estimator.dart';
import 'package:cc_harness/context.dart';

/// The size of a conversation's live (non-compacted, non-reverted) region,
/// as two integers.
///
/// This exists so the context meters do not have to hold the conversation to
/// measure it. They render totals and nothing else — a stacked bar and a
/// "145k / 200k" label — but they used to compute those by summing over every
/// message, which meant subscribing to the whole history: an uncapped
/// `SELECT` re-sent in full on every write to `conversation_messages`, paid on
/// every chat open and every sidebar hover. Two numbers are the entire product
/// of that traversal, so the traversal belongs on the side that already has
/// the rows.
///
/// The surface that genuinely needs the messages — the context explorer, which
/// lists them one by one — still reads them, deliberately and only when opened.
class ConversationTokenTotals {
  /// Creates a [ConversationTokenTotals].
  const ConversationTokenTotals({required this.tokens, required this.chars});

  /// Estimated tokens across the live region, summed PER MESSAGE so this
  /// matches `ConversationTokenEstimate.estimateMessages` exactly rather than
  /// rounding once over the total.
  final int tokens;

  /// Characters of message content across the live region.
  final int chars;

  /// An empty conversation.
  static const ConversationTokenTotals empty = ConversationTokenTotals(
    tokens: 0,
    chars: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationTokenTotals &&
          tokens == other.tokens &&
          chars == other.chars;

  @override
  int get hashCode => Object.hash(tokens, chars);

  @override
  String toString() => 'ConversationTokenTotals(tokens: $tokens, chars: $chars)';
}

/// Folds [messages] into their [ConversationTokenTotals], skipping compacted
/// rows (folded context, not live).
///
/// The reference definition of the numbers: an implementation that computes
/// them from a database aggregate has to agree with this, so a fallback and a
/// fast path can never quietly disagree about how full a window is.
ConversationTokenTotals conversationTokenTotals(
  Iterable<Message> messages, {
  TokenEstimator estimator = TokenEstimator.instance,
}) {
  var tokens = 0;
  var chars = 0;
  for (final message in messages) {
    if (message.compacted) {
      continue;
    }
    tokens += estimator.estimateMessage(message);
    chars += message.content.length;
  }
  return ConversationTokenTotals(tokens: tokens, chars: chars);
}
