/// Memory domains written by deterministic system harvesters (not by agents
/// reasoning). Centralized so every writer uses the same slug and the
/// policy-promotion hint can exclude them (a policy rarely makes sense for a
/// running log of decisions / outcomes).
class SystemMemoryDomains {
  const SystemMemoryDomains._();

  /// Decisions captured from meetings, tickets, and orchestrations.
  static const String decisions = 'decisions';

  /// Outcomes of completed, schema-validated tickets.
  static const String ticketOutcomes = 'ticket-outcomes';

  /// Finalized PR review verdicts.
  static const String prReviews = 'pr-reviews';

  /// Dismissed review findings (suppression signal).
  static const String reviewSuppressions = 'review-suppressions';

  /// Approved orchestration plans.
  static const String orchestration = 'orchestration';

  /// All system domains — excluded from the propose-policy nudge.
  static const Set<String> all = {
    decisions,
    ticketOutcomes,
    prReviews,
    reviewSuppressions,
    orchestration,
  };
}
