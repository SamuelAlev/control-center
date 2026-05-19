/// Canonical, vendor-neutral lifecycle status for a ticket.
///
/// This superset absorbs the five legacy `TaskStatus` states (the pipeline
/// engine relies on the [isTerminal] / success-vs-failure distinction to
/// resume suspended steps) and adds the richer states a tracker needs
/// (backlog / blocked / inReview). A remote provider's native state name is
/// preserved separately in `Ticket.rawStatus`; the normalization tables that
/// map native names to this enum live inside each adapter, not here.
enum TicketStatus {
  /// Captured but not yet triaged into the active queue.
  backlog,

  /// Triaged and ready to be worked, but not started. Legacy `pending`.
  open,

  /// Actively being worked.
  inProgress,

  /// Started but blocked on something external.
  blocked,

  /// Work done, awaiting review.
  inReview,

  /// Finished successfully. Legacy `completed`.
  done,

  /// Finished with an error (Control-Center / pipeline path only).
  failed,

  /// Abandoned.
  cancelled;

  /// Whether this is a terminal state (no further work expected).
  ///
  /// Identical predicate to the legacy `TaskStatus.isTerminal`, so the
  /// pipeline resume listener keeps working unchanged.
  bool get isTerminal =>
      this == TicketStatus.done ||
      this == TicketStatus.failed ||
      this == TicketStatus.cancelled;

  /// Terminal success.
  bool get isSuccess => this == TicketStatus.done;

  /// Terminal failure.
  bool get isFailure => this == TicketStatus.failed;

  /// Whether the ticket is actively being worked.
  bool get isActive => this == TicketStatus.inProgress;

  /// Parses the persisted value. Unknown / null → [open]. Legacy `TaskStatus`
  /// names (`pending`, `completed`) are mapped so migrated rows resolve.
  static TicketStatus fromStorage(String? value) => switch (value) {
        'backlog' => TicketStatus.backlog,
        'open' => TicketStatus.open,
        'pending' => TicketStatus.open,
        'inProgress' => TicketStatus.inProgress,
        'blocked' => TicketStatus.blocked,
        'inReview' => TicketStatus.inReview,
        'done' => TicketStatus.done,
        'completed' => TicketStatus.done,
        'failed' => TicketStatus.failed,
        'cancelled' => TicketStatus.cancelled,
        _ => TicketStatus.open,
      };

  /// Serializes for storage.
  String toStorageString() => name;

  /// Whether a direct transition to [next] is allowed. Terminal states are
  /// dead ends (reopen by transitioning a fresh ticket / explicit override).
  bool canTransitionTo(TicketStatus next) {
    if (this == next) return true;
    return _allowed[this]?.contains(next) ?? false;
  }

  static const Map<TicketStatus, Set<TicketStatus>> _allowed = {
    TicketStatus.backlog: {TicketStatus.open, TicketStatus.cancelled},
    TicketStatus.open: {
      TicketStatus.inProgress,
      TicketStatus.blocked,
      TicketStatus.cancelled,
    },
    TicketStatus.inProgress: {
      TicketStatus.blocked,
      TicketStatus.inReview,
      TicketStatus.done,
      TicketStatus.failed,
      TicketStatus.cancelled,
    },
    TicketStatus.blocked: {TicketStatus.inProgress, TicketStatus.cancelled},
    TicketStatus.inReview: {
      TicketStatus.inProgress,
      TicketStatus.done,
      TicketStatus.failed,
      TicketStatus.cancelled,
    },
    TicketStatus.done: <TicketStatus>{},
    TicketStatus.failed: <TicketStatus>{},
    TicketStatus.cancelled: <TicketStatus>{},
  };
}

/// UI helpers for [TicketStatus].
extension TicketStatusX on TicketStatus {
  /// Whether this status belongs in the "open work" grouping (non-terminal).
  bool get isOpen => !isTerminal;
}
