/// Severity of a piece of advice from the shadow `AdvisorRuntime`.
///
/// Higher severities interrupt the primary agent; a [nit] is passive.
enum AdvisorSeverity {
  /// Minor, non-blocking observation. Delivered as a passive aside.
  nit,

  /// A real concern worth surfacing mid-run. Interrupts at the next boundary.
  concern,

  /// A dangerous step that should stop the agent. Interrupts at the next
  /// boundary with the strongest framing.
  blocker;

  /// Whether advice at this severity should interrupt the primary agent (vs.
  /// arriving as a passive aside).
  bool get interrupts => this != AdvisorSeverity.nit;
}

/// A single piece of advice emitted by the shadow reviewer.
class AdvisorAdvice {
  /// Creates an [AdvisorAdvice].
  const AdvisorAdvice({required this.severity, required this.message});

  /// How urgent the advice is.
  final AdvisorSeverity severity;

  /// The advice body (sentence-case, human-readable).
  final String message;

  /// Renders the advice as a single steering line, tagged by severity so the
  /// primary agent can weight it.
  String format() => '[advisor:${severity.name}] $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvisorAdvice &&
          runtimeType == other.runtimeType &&
          severity == other.severity &&
          message == other.message;

  @override
  int get hashCode => Object.hash(severity, message);

  @override
  String toString() => 'AdvisorAdvice(${severity.name}, "$message")';
}
