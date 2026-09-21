/// Heuristic token estimates (~4 chars/token, slight over-count). Cheap and
/// deterministic; prefer provider usage for the live meter. Text-level only —
/// conversation helpers live in cc_domain.
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
