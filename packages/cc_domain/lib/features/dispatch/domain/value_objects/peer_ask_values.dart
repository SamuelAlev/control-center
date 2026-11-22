/// What one agent asked another for (a `PeerAsk`).
enum PeerAskKind {
  /// `ask_agent`: a question whose answer is the recipient's final message.
  ask,

  /// `consult_agent`: advice on the asker's own work.
  consult,

  /// `request_peer_review`: a review of the asker's work.
  review,
}

/// Wire names for [PeerAskKind] (persisted as TEXT).
extension PeerAskKindWire on PeerAskKind {
  /// Persisted wire name.
  String get wire => switch (this) {
    PeerAskKind.ask => 'ask',
    PeerAskKind.consult => 'consult',
    PeerAskKind.review => 'review',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in PeerAskKind.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static PeerAskKind? tryParse(String? raw) {
    for (final value in PeerAskKind.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Whether the asking tool call waited for the answer.
enum PeerAskMode {
  /// The call blocked until the answer or its timeout.
  wait,

  /// The call returned at once; the answer comes back as a wake.
  background,
}

/// Wire names for [PeerAskMode] (persisted as TEXT).
extension PeerAskModeWire on PeerAskMode {
  /// Persisted wire name.
  String get wire => switch (this) {
    PeerAskMode.wait => 'wait',
    PeerAskMode.background => 'background',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in PeerAskMode.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static PeerAskMode? tryParse(String? raw) {
    for (final value in PeerAskMode.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Where a peer ask is.
enum PeerAskStatus {
  /// The recipient has not answered yet.
  pending,

  /// The recipient's run completed with an answer.
  answered,

  /// The recipient's run failed or was stopped.
  failed,

  /// Nothing came back within the ask's lifetime (24 hours).
  expired,

  /// A person or the asker withdrew it.
  cancelled,
}

/// Wire names for [PeerAskStatus] (persisted as TEXT).
extension PeerAskStatusWire on PeerAskStatus {
  /// Persisted wire name.
  String get wire => switch (this) {
    PeerAskStatus.pending => 'pending',
    PeerAskStatus.answered => 'answered',
    PeerAskStatus.failed => 'failed',
    PeerAskStatus.expired => 'expired',
    PeerAskStatus.cancelled => 'cancelled',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in PeerAskStatus.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static PeerAskStatus? tryParse(String? raw) {
    for (final value in PeerAskStatus.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// The limits `PeerAskRepository.insertWithinLimits` holds a new ask to,
/// checked in one transaction with the insert.
final class PeerAskInsertLimits {
  /// Creates the limits. Both caps must be positive.
  PeerAskInsertLimits({
    required DateTime duplicateSince,
    required this.perAsker,
    required this.perRecipient,
  }) : duplicateSince = duplicateSince.toUtc() {
    if (perAsker < 1 || perRecipient < 1) {
      throw ArgumentError('the caps must be positive');
    }
  }

  /// A pending ask of the same pair and question made at or after this
  /// instant is a duplicate.
  final DateTime duplicateSince;

  /// Most pending asks the asker may hold, the new one excluded.
  final int perAsker;

  /// Most pending asks the recipient may hold, the new one excluded.
  final int perRecipient;
}

/// The limit a new ask was refused on, first match in this order.
enum PeerAskLimit {
  /// The same asker asked the same recipient the same question, and that
  /// ask is still pending.
  duplicate,

  /// The asker holds [PeerAskInsertLimits.perAsker] pending asks.
  asker,

  /// The recipient holds [PeerAskInsertLimits.perRecipient] pending asks.
  recipient,
}

/// Why `PeerAskRepository.insertWithinLimits` did not write an ask.
final class PeerAskLimitHit {
  /// Creates the refusal. [duplicateAskId] is given exactly for
  /// [PeerAskLimit.duplicate].
  PeerAskLimitHit(this.limit, {this.duplicateAskId}) {
    if ((limit == PeerAskLimit.duplicate) != (duplicateAskId != null)) {
      throw ArgumentError.value(
        duplicateAskId,
        'duplicateAskId',
        'is given exactly for a duplicate',
      );
    }
  }

  /// The limit that refused.
  final PeerAskLimit limit;

  /// The pending ask the new one repeats, for [PeerAskLimit.duplicate].
  final String? duplicateAskId;
}
