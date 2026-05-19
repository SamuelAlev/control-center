/// How strongly the advisor wants the primary agent to weigh a note.
enum AdvisorSeverity {
  /// A minor suggestion; queued passively, never interrupts.
  nit,

  /// A real worry; interrupts the agent via the steering channel.
  concern,

  /// A serious problem; interrupts immediately.
  blocker;

  /// Monotonic rank for escalation de-dup (`nit` < `concern` < `blocker`).
  int get rank => switch (this) {
    AdvisorSeverity.nit => 1,
    AdvisorSeverity.concern => 2,
    AdvisorSeverity.blocker => 3,
  };

  /// Whether this severity interrupts the primary agent (concern/blocker).
  bool get interrupts => this == AdvisorSeverity.concern ||
      this == AdvisorSeverity.blocker;

  /// The wire string.
  String get wire => name;

  /// Parses a wire string, defaulting to [nit].
  static AdvisorSeverity fromWire(String? raw) => switch (raw) {
    'concern' => AdvisorSeverity.concern,
    'blocker' => AdvisorSeverity.blocker,
    _ => AdvisorSeverity.nit,
  };
}

/// One message in the transcript the advisor watches.
class AdvisorMessage {
  /// Creates an [AdvisorMessage].
  const AdvisorMessage({
    required this.role,
    required this.text,
    this.isAdvisor = false,
  });

  /// `user` | `assistant` | `tool` | `system` (free-form; only used for
  /// rendering).
  final String role;

  /// The rendered text content.
  final String text;

  /// Whether this message originated from the advisor itself (excluded from
  /// the delta so the advisor never reviews its own notes).
  final bool isAdvisor;
}

/// A piece of advice the advisor emitted.
class AdvisorVerdict {
  /// Creates an [AdvisorVerdict].
  const AdvisorVerdict({required this.note, required this.severity});

  /// Terse, specific, actionable advice for the primary agent.
  final String note;

  /// How strongly to weigh it.
  final AdvisorSeverity severity;
}

/// How the advice should reach the primary agent.
enum AdvisorDelivery {
  /// Passive — queued for the next step boundary (a `nit`).
  aside,

  /// Interrupting — pushed onto the steering channel now (concern/blocker).
  steer,
}
