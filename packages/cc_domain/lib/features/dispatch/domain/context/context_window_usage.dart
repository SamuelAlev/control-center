import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/dispatch/domain/context/token_estimator.dart';

/// The per-turn token breakdown for the most recent assistant turn, mirroring
/// what adapters report via `RunCost`.
class TurnTokenBreakdown {
  /// Creates a [TurnTokenBreakdown].
  const TurnTokenBreakdown({
    this.input = 0,
    this.output = 0,
    this.reasoning = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
  });

  /// Input tokens.
  final int input;

  /// Output tokens.
  final int output;

  /// Reasoning / extended-thinking tokens.
  final int reasoning;

  /// Cache-read tokens.
  final int cacheRead;

  /// Cache-write tokens.
  final int cacheWrite;

  /// Sum of all categories.
  int get total => input + output + reasoning + cacheRead + cacheWrite;
}

/// A live reading of a conversation's context-window pressure: tokens currently
/// in play (the non-compacted live region) against the model's window.
class ContextWindowUsage {
  /// Creates a [ContextWindowUsage].
  const ContextWindowUsage({
    required this.usedTokens,
    required this.windowTokens,
    this.lastTurn,
  });

  /// Estimated tokens occupied by the live (non-compacted) conversation.
  final int usedTokens;

  /// The model's context window in tokens.
  final int windowTokens;

  /// Breakdown of the most recent assistant turn, if any.
  final TurnTokenBreakdown? lastTurn;

  /// Fraction of the window used, clamped to `[0, 1]`.
  double get fraction =>
      windowTokens <= 0 ? 0 : (usedTokens / windowTokens).clamp(0.0, 1.0);

  /// Tokens remaining before the window is full (never negative).
  int get remainingTokens =>
      (windowTokens - usedTokens) < 0 ? 0 : windowTokens - usedTokens;

  /// Whether usage has crossed a warning threshold (75%).
  bool get isWarning => fraction >= 0.75;

  /// Whether usage is critically high (90%) — compaction is imminent/overdue.
  bool get isCritical => fraction >= 0.90;

  /// An empty/unknown reading.
  static const ContextWindowUsage unknown =
      ContextWindowUsage(usedTokens: 0, windowTokens: 0);
}

/// Computes the live context-window usage for a conversation.
///
/// Used tokens = the estimate over every non-compacted message (the live region
/// the next dispatch will actually send), plus a fixed [systemOverheadTokens]
/// approximating the persistent system prompt / tool schemas. The last-turn
/// breakdown is read from the newest agent turn's persisted `turn` metadata.
ContextWindowUsage computeContextWindowUsage({
  required List<ChannelMessage> messages,
  required int windowTokens,
  TokenEstimator estimator = TokenEstimator.instance,
  int systemOverheadTokens = 2000,
}) {
  var used = systemOverheadTokens;
  TurnTokenBreakdown? lastTurn;
  for (final m in messages) {
    if (!m.compacted) {
      used += estimator.estimateMessage(m);
    }
    if (m.isAgentTurn) {
      final reported = m.turnTotalTokens;
      if (reported != null) {
        lastTurn = TurnTokenBreakdown(input: reported);
      }
    }
  }
  return ContextWindowUsage(
    usedTokens: used,
    windowTokens: windowTokens,
    lastTurn: lastTurn,
  );
}
