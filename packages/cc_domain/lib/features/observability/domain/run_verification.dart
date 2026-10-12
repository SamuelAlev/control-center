/// Whether a run's output was independently VERIFIED, as opposed to merely
/// finishing.
///
/// The old metrics treated `status == completed` as success. A run that exits
/// cleanly while producing nothing useful — or producing output that fails its
/// task's verifier — is a completed run and a FAILED outcome, and conflating
/// the two is what lets "cost per success" improve by simply lowering quality.
enum VerificationStatus {
  /// No verifier ran; nothing was checked. NOT a pass.
  unverified,

  /// An independent verifier checked the output and accepted it.
  passed,

  /// An independent verifier ran and rejected the output.
  failed;

  /// Stable wire/storage spelling.
  String get wire {
    switch (this) {
      case VerificationStatus.unverified:
        return 'unverified';
      case VerificationStatus.passed:
        return 'passed';
      case VerificationStatus.failed:
        return 'failed';
    }
  }

  /// Parses a wire/storage spelling, defaulting to [unverified] — an unreadable
  /// verdict must never read as a pass.
  static VerificationStatus fromWire(String? value) {
    switch (value) {
      case 'passed':
        return VerificationStatus.passed;
      case 'failed':
        return VerificationStatus.failed;
      case 'unverified':
      default:
        return VerificationStatus.unverified;
    }
  }
}

/// The verification verdict attached to a run.
///
/// [verifier] names WHAT checked the result (a test command, a behavioral
/// check, a reviewer) so a reader can weigh the verdict; it is never inferred.
class RunVerification {
  /// Creates a verification record.
  const RunVerification({
    this.status = VerificationStatus.unverified,
    this.verifier,
    this.verifiedAt,
    this.notes,
  });

  /// Unverified: nothing ran.
  static const none = RunVerification();

  /// The verdict.
  final VerificationStatus status;

  /// Who/what verified the run (an independent verifier, not the producing
  /// agent's own claim).
  final String? verifier;

  /// When the verdict was recorded.
  final DateTime? verifiedAt;

  /// Optional detail (the failing check, the recovered condition).
  final String? notes;

  /// True only when an independent verifier PASSED the output.
  bool get isVerifiedSuccess => status == VerificationStatus.passed;

  /// True when a verifier ran at all (either verdict).
  bool get isChecked => status != VerificationStatus.unverified;

  /// JSON-safe map for storage alongside the run.
  Map<String, dynamic> toJson() => {
    'status': status.wire,
    if (verifier != null) 'verifier': verifier,
    if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
    if (notes != null) 'notes': notes,
  };

  /// Rebuilds a verdict from [toJson] output; a null payload is [none].
  static RunVerification fromJson(Object? raw) {
    if (raw is! Map) {
      return none;
    }
    final verifiedAt = raw['verifiedAt'];
    return RunVerification(
      status: VerificationStatus.fromWire(raw['status'] as String?),
      verifier: raw['verifier'] as String?,
      verifiedAt: verifiedAt is String ? DateTime.tryParse(verifiedAt) : null,
      notes: raw['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunVerification &&
          status == other.status &&
          verifier == other.verifier &&
          verifiedAt == other.verifiedAt &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(status, verifier, verifiedAt, notes);
}
