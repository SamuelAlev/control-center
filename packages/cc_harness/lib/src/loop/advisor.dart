/// A secondary "advisor" (watchdog) that reviews the driving agent's turns and
/// can inject a short steering note before the next turn.
///
/// The loop calls `review` after a tool-bearing turn; a non-null return is
/// framed as a `<advisory>` system note (a nudge the main model sees next turn)
/// and surfaced to the UI. Implementations typically drive a cheap second model
/// that watches the running transcript as an append-only stream of deltas.
library;

import 'package:cc_harness/src/messages.dart';

/// How strongly an advisor weighs a note — governs how the loop frames it and
/// (in the emission guard) whether a repeat at a higher severity is a real
/// escalation worth re-delivering.
enum AdvisorSeverity {
  /// A minor suggestion; the agent may weigh and move on.
  nit,

  /// A real concern the agent should address before proceeding.
  concern,

  /// A blocking problem (a bug, an unsafe action, a missed hard requirement).
  blocker;

  /// Ordinal rank used for escalation comparisons (nit < concern < blocker).
  int get rank => index;
}

/// One piece of advice returned by an [Advisor].
class AdvisorNote {
  /// Creates an advisor note.
  const AdvisorNote(this.note, {this.severity = AdvisorSeverity.nit});

  /// The concrete, actionable advice (one terse sentence).
  final String note;

  /// How strongly to weigh it.
  final AdvisorSeverity severity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvisorNote && other.note == note && other.severity == severity;

  @override
  int get hashCode => Object.hash(note, severity);

  @override
  String toString() => 'AdvisorNote(${severity.name}: $note)';
}

/// Reviews the conversation so far and optionally returns a steering note.
abstract interface class Advisor {
  /// Reviews the primary [history] after a turn and returns a note to inject
  /// before the next turn, or null to stay silent. Must not throw — return
  /// null on failure.
  ///
  /// Implementations may keep their own append-only context and only feed the
  /// messages appended since the previous call, so [history] is the full,
  /// live primary transcript each time (the same list the loop mutates).
  Future<AdvisorNote?> review(List<HarnessMessage> history);

  /// Re-primes the advisor after the primary history is rewritten (compaction
  /// or a new session): clears any accumulated advisor context and dedupe
  /// memory so it re-reads the current transcript fresh. Must not throw.
  void reset();
}
