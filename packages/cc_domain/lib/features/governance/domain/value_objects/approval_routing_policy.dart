/// Who an agent's approval gate asks first, per workspace.
enum ApprovalRoutingMode {
  /// Ask the human whose action triggered the work (fall back to admins when
  /// unknown).
  requestingUser,

  /// Ask every admin (and the owner) at once.
  anyAdmin,

  /// Ask only the workspace owner.
  owner;

  /// The value persisted and sent over the wire.
  String get wireName => name;

  /// Parses a stored/wire value; null for unknown values.
  static ApprovalRoutingMode? fromWire(String? value) {
    for (final mode in ApprovalRoutingMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return null;
  }
}

/// Per-workspace policy for routing approval requests when N humans are
/// members: who is asked first and when an unanswered gate escalates to the
/// next tier. Decisions themselves stay first-wins with full attribution —
/// this policy only governs who is *asked*.
class ApprovalRoutingPolicy {
  /// Creates an [ApprovalRoutingPolicy].
  const ApprovalRoutingPolicy({
    this.mode = ApprovalRoutingMode.requestingUser,
    this.escalationTimeout = const Duration(hours: 1),
  });

  /// Decodes the persisted JSON form; malformed input yields the defaults.
  factory ApprovalRoutingPolicy.fromJson(Map<String, dynamic> json) =>
      ApprovalRoutingPolicy(
        mode:
            ApprovalRoutingMode.fromWire(json['mode'] as String?) ??
            ApprovalRoutingMode.requestingUser,
        escalationTimeout: Duration(
          minutes: (json['escalation_timeout_minutes'] as num?)?.toInt() ?? 60,
        ),
      );

  /// The default policy for a workspace that never configured one.
  static const defaults = ApprovalRoutingPolicy();

  /// Who is asked first.
  final ApprovalRoutingMode mode;

  /// How long an unanswered gate waits before escalating to the next tier.
  final Duration escalationTimeout;

  /// Encodes the persisted JSON form.
  Map<String, dynamic> toJson() => {
    'mode': mode.wireName,
    'escalation_timeout_minutes': escalationTimeout.inMinutes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalRoutingPolicy &&
          mode == other.mode &&
          escalationTimeout == other.escalationTimeout;

  @override
  int get hashCode => Object.hash(mode, escalationTimeout);
}
