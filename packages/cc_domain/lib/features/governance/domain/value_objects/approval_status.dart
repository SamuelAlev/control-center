/// Decision state of a board approval.
///
/// The state machine: `pending` → `approved` | `rejected` |
/// `revisionRequested`; a `revisionRequested` approval can be resubmitted back
/// to `pending`. `approved` and `rejected` are terminal.
enum ApprovalStatus {
  /// Awaiting a decision.
  pending('Pending'),

  /// Approved — the gated action may proceed.
  approved('Approved'),

  /// Rejected — the gated action must not proceed.
  rejected('Rejected'),

  /// Sent back for revision; can be resubmitted.
  revisionRequested('Revision requested');

  /// Creates an [ApprovalStatus] with a display [label].
  const ApprovalStatus(this.label);

  /// Human-readable display label.
  final String label;

  /// Whether this is a terminal decision (no further transitions).
  bool get isTerminal =>
      this == ApprovalStatus.approved || this == ApprovalStatus.rejected;

  /// Whether the gated action is cleared to proceed.
  bool get isApproved => this == ApprovalStatus.approved;

  /// Storage key for this status (snake_case to match the table column).
  String get storage => switch (this) {
    ApprovalStatus.pending => 'pending',
    ApprovalStatus.approved => 'approved',
    ApprovalStatus.rejected => 'rejected',
    ApprovalStatus.revisionRequested => 'revision_requested',
  };

  /// Parses a stored value (accepts snake_case and camelCase), defaulting to
  /// [pending].
  static ApprovalStatus fromStorage(String? value) {
    switch (value) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'revision_requested':
      case 'revisionRequested':
        return ApprovalStatus.revisionRequested;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }
}

/// A decision action applied to an approval, driving its state transition.
enum ApprovalDecision {
  /// Approve the request → `approved`.
  approve,

  /// Reject the request → `rejected`.
  reject,

  /// Request a revision → `revisionRequested`.
  requestRevision,

  /// Resubmit a revision-requested approval → `pending`.
  resubmit;

  /// The status this decision transitions an approval into.
  ApprovalStatus get resultingStatus => switch (this) {
    ApprovalDecision.approve => ApprovalStatus.approved,
    ApprovalDecision.reject => ApprovalStatus.rejected,
    ApprovalDecision.requestRevision => ApprovalStatus.revisionRequested,
    ApprovalDecision.resubmit => ApprovalStatus.pending,
  };

  /// Whether [from] permits this decision.
  bool isValidFrom(ApprovalStatus from) => switch (this) {
    // A pending approval can be approved, rejected, or sent for revision.
    ApprovalDecision.approve ||
    ApprovalDecision.reject ||
    ApprovalDecision.requestRevision => from == ApprovalStatus.pending,
    // Only a revision-requested approval can be resubmitted.
    ApprovalDecision.resubmit => from == ApprovalStatus.revisionRequested,
  };

  /// Parses a stored / wire value, or null if unrecognized.
  static ApprovalDecision? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    return ApprovalDecision.values
        .where((d) => d.name.toLowerCase() == value.toLowerCase())
        .firstOrNull;
  }
}
