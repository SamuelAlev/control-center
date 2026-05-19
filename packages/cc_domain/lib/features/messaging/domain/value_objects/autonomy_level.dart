/// The graduated autonomy a principal may act with, ordered least→most
/// (PRD 16 §12 / PRD 22 §3 / PRD 24): propose-only → act-with-approval →
/// act-freely.
///
/// This is THE autonomy vocabulary — the per-(space, agent) dial stored in
/// `space_autonomy.autonomy_level`, the value `autonomy.setForSpace`
/// validates, and the ceiling the delegation guards enforce. It used to exist
/// twice with two different wire vocabularies (`observe_only` in the
/// delegation guards, `proposeOnly` in the client provider and the database),
/// which meant a ceiling read from the dial could never equal a ceiling the
/// guards parsed. One enum, one wire form, one legacy alias table.
enum AutonomyLevel {
  /// Gated tools are denied; the agent can only propose actions.
  proposeOnly('proposeOnly'),

  /// The default: risky actions hit a fail-closed approval gate.
  actWithApproval('actWithApproval'),

  /// Actions are pre-approved (a hard `deny` still blocks).
  actFreely('actFreely');

  const AutonomyLevel(this.wire);

  /// The stable wire/storage name (the `space_autonomy` column value).
  final String wire;

  /// Legacy snake-case wire forms the delegation guards used to write.
  static const Map<String, AutonomyLevel> _legacy = {
    'observe_only': AutonomyLevel.proposeOnly,
    'propose_only': AutonomyLevel.proposeOnly,
    'act_with_approval': AutonomyLevel.actWithApproval,
    'act_free': AutonomyLevel.actFreely,
    'act_freely': AutonomyLevel.actFreely,
  };

  /// Parses a wire name (current or legacy); null for `null`/unknown — the
  /// client's "no explicit level, use the server default".
  static AutonomyLevel? tryFromWire(String? value) {
    if (value == null) {
      return null;
    }
    for (final level in values) {
      if (level.wire == value) {
        return level;
      }
    }
    return _legacy[value];
  }

  /// Parses a wire name, defaulting to the SAFEST level on `null`/unknown —
  /// the guard-side reading, where an unparseable ceiling must never read as
  /// a permissive one.
  static AutonomyLevel fromWire(String? value) =>
      tryFromWire(value) ?? AutonomyLevel.proposeOnly;

  /// Whether this level is within (≤) the [ceiling].
  bool atMost(AutonomyLevel ceiling) => index <= ceiling.index;
}
