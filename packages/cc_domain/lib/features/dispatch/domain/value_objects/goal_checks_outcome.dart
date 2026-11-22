import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';

/// Whether a goal's checks ran.
enum GoalChecksStatus {
  /// Every check ran (or was attempted): see the results.
  ran,

  /// A worktree check had no sandbox to run in, so nothing ran. Its refusal
  /// kind is [GoalChecksOutcome.sandboxUnavailableKind].
  sandboxUnavailable,
}

/// What running a goal's checks gave (`GoalCheckRunner.run`): one result per
/// check, in contract order, and the worktree fingerprint taken before the
/// first check started.
final class GoalChecksOutcome {
  /// Creates an outcome. Throws [ArgumentError] when a
  /// [GoalChecksStatus.sandboxUnavailable] outcome carries results.
  GoalChecksOutcome({
    required this.status,
    required List<GoalCheckResult> results,
    required this.fingerprint,
  }) : results = List.unmodifiable(results) {
    if (status == GoalChecksStatus.sandboxUnavailable && results.isNotEmpty) {
      throw ArgumentError.value(
        results,
        'results',
        'nothing runs without a sandbox',
      );
    }
  }

  /// The checks could not run: no sandbox. [fingerprint] is still taken.
  factory GoalChecksOutcome.sandboxUnavailable({
    required String? fingerprint,
  }) => GoalChecksOutcome(
    status: GoalChecksStatus.sandboxUnavailable,
    results: const [],
    fingerprint: fingerprint,
  );

  /// The refusal kind of [GoalChecksStatus.sandboxUnavailable], the one a
  /// run refused for want of a sandbox carries.
  static const String sandboxUnavailableKind = 'sandbox_unavailable';

  /// Whether the checks ran.
  final GoalChecksStatus status;

  /// One per check, in contract order; empty when nothing ran.
  final List<GoalCheckResult> results;

  /// The conversation's worktree fingerprint before the checks ran; null
  /// when it has no worktree or it could not be fingerprinted.
  final String? fingerprint;

  /// Whether any check could not run as written (a person must fix the
  /// contract).
  bool get anyBroken => results.any((result) => result.broken);

  /// Whether the checks ran and every one passed. True for a goal without
  /// checks.
  bool get allPassed =>
      status == GoalChecksStatus.ran && results.every((r) => r.passed);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalChecksOutcome &&
          status == other.status &&
          fingerprint == other.fingerprint &&
          _sameResults(results, other.results);

  @override
  int get hashCode => Object.hash(status, fingerprint, Object.hashAll(results));

  static bool _sameResults(List<GoalCheckResult> a, List<GoalCheckResult> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'GoalChecksOutcome(${status.name}, ${results.length} results, '
      'fingerprint: $fingerprint)';
}
