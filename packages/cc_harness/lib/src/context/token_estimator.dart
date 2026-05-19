/// Heuristic token estimation for context-window accounting.
///
/// The kernel has no provider-side tokenizer, so we approximate. The
/// widely-used rule of thumb for English+code is ~4 characters per token;
/// code and JSON skew a little denser, so we bias slightly toward
/// over-counting (which is the safe direction for a budget: it triggers
/// compaction a touch early rather than overflowing the real window).
///
/// Estimates are intentionally cheap and deterministic — no I/O, no model
/// call. When an adapter reports real usage, prefer that for the live meter
/// and use these estimates only to plan ahead (deciding what to keep
/// verbatim, where to cut, how much a prune would reclaim).
///
/// Message-shaped helpers over Control Center's `Message` /
/// `TranscriptSegment` live host-side as an extension
/// (`ConversationTokenEstimate` in `cc_domain`); this class stays text-level
/// so the kernel never sees conversation entities.
class TokenEstimator {
  /// Creates a [TokenEstimator] with the given [charsPerToken] divisor.
  const TokenEstimator({this.charsPerToken = 3.8});

  /// Average characters per token. Lower = more tokens per char (denser).
  final double charsPerToken;

  /// A shared default instance.
  static const TokenEstimator instance = TokenEstimator();

  /// Estimated token count for an arbitrary [text]. Always `>= 0`.
  int estimate(String text) {
    if (text.isEmpty) {
      return 0;
    }
    return (text.length / charsPerToken).ceil();
  }

  /// Estimated token count for a raw character count. Always `>= 0`.
  int estimateChars(int chars) =>
      chars <= 0 ? 0 : (chars / charsPerToken).ceil();

  /// Converts a character budget (CC's `Agent.contextSize`, measured in
  /// characters) into an estimated token window for the same content.
  int windowTokensFromChars(int chars) => (chars / charsPerToken).floor();
}
