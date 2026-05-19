import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';

/// Memory domains written by deterministic system harvesters (not by agents
/// reasoning). Centralized so every writer uses the same slug and the
/// policy-promotion hint can exclude them (a policy rarely makes sense for a
/// running log of decisions / outcomes).
class SystemMemoryDomains {
  const SystemMemoryDomains._();

  /// Decisions captured from meetings, tickets and orchestrations.
  static const String decisions = 'decisions';

  /// Outcomes of completed, schema-validated tickets.
  static const String ticketOutcomes = 'ticket-outcomes';

  /// Finalized PR review verdicts.
  static const String prReviews = 'pr-reviews';

  /// Dismissed review findings (suppression signal).
  static const String reviewSuppressions = 'review-suppressions';

  /// Standing review instructions, optionally scoped to a path glob (the
  /// fact's topic). Unlike [reviewSuppressions] — which is harvested from what
  /// a human dismissed — these are written deliberately, and they take
  /// precedence over a learned suppression when the two disagree.
  static const String reviewGuidelines = 'review-guidelines';

  /// Approved orchestration plans.
  static const String orchestration = 'orchestration';

  /// All system domains — excluded from the propose-policy nudge.
  static const Set<String> all = {
    decisions,
    ticketOutcomes,
    prReviews,
    reviewSuppressions,
    reviewGuidelines,
    orchestration,
  };

  /// True when [domainSlug] names a system domain, whether or not it is scoped
  /// to a repo.
  ///
  /// Compares the BARE name, so `repo:owner-project/pr-reviews` is recognized
  /// exactly like `pr-reviews`. A raw `all.contains(slug)` test silently
  /// returns false for every repo-scoped variant, which would put a running log
  /// of PR verdicts back into the propose-policy nudge.
  static bool isSystem(String domainSlug) =>
      all.contains(MemoryDomainScope.bareName(domainSlug));
}
