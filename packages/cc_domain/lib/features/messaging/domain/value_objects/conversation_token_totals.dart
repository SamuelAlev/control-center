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
  const ConversationTokenTotals({
    required this.tokens,
    required this.chars,
    this.reportedContextTokens,
    this.reportedWindowTokens,
  });

  /// Estimated tokens across the live region, summed PER MESSAGE so this
  /// matches `ConversationTokenEstimate.estimateMessages` exactly rather than
  /// rounding once over the total.
  final int tokens;

  /// Characters of message content across the live region.
  final int chars;

  /// How full the model's context was on its newest call, as the provider
  /// reported it — or null when no turn in this conversation reported one.
  ///
  /// This, not [tokens], is what the model actually holds. [tokens] measures
  /// the stored transcript, which is neither what a Claude Code turn resends
  /// (each run starts fresh with a capped history block) nor what a harness
  /// run replays after its own in-loop compaction.
  final int? reportedContextTokens;

  /// The window [reportedContextTokens] was measured against, when the runner
  /// knew it.
  final int? reportedWindowTokens;

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
          chars == other.chars &&
          reportedContextTokens == other.reportedContextTokens &&
          reportedWindowTokens == other.reportedWindowTokens;

  @override
  int get hashCode =>
      Object.hash(tokens, chars, reportedContextTokens, reportedWindowTokens);

  @override
  String toString() =>
      'ConversationTokenTotals(tokens: $tokens, chars: $chars, '
      'reportedContextTokens: $reportedContextTokens, '
      'reportedWindowTokens: $reportedWindowTokens)';
}
