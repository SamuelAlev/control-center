/// Stream-rule course-correction for the built-in agent loop.
///
/// A [StreamRule] fires when the model's streamed output matches `pattern`. The
/// loop then abandons the in-flight turn, injects `reminder` as a system
/// message and restarts the turn — so the model course-corrects without the
/// rule sitting in every prompt. Each rule fires at most once per run.
library;

/// A pattern-triggered course-correction rule.
class StreamRule {
  /// Creates a [StreamRule].
  const StreamRule({required this.pattern, required this.reminder});

  /// The trigger, matched against accumulated streamed text (and thinking).
  final Pattern pattern;

  /// The system reminder injected before the turn is retried.
  final String reminder;

  /// Whether [text] triggers this rule.
  bool matches(String text) => pattern.allMatches(text).isNotEmpty;
}
