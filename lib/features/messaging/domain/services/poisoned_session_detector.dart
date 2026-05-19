/// Detects known failure signatures in agent output that make the session
/// unsafe to resume.
class PoisonedSessionDetector {
  static const _failureSignatures = [
    'iteration limit reached',
    'maximum iterations exceeded',
    'too many turns',
    'context window exceeded',
    'token limit exceeded',
  ];

  /// Returns `true` if the agent output matches known failure signatures.
  bool isPoisoned(String? output) {
    if (output == null || output.isEmpty) {
      return true;
    }
    final lower = output.toLowerCase();
    return _failureSignatures.any(lower.contains);
  }
}
