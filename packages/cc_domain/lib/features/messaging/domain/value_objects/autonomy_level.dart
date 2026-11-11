/// The graduated autonomy a principal may act with, ordered least→most
/// (PRD 16 §12 / PRD 22 §3 / PRD 24): propose-only → act-with-approval →
/// act-freely.
///
/// This is THE autonomy vocabulary — the per-(space, agent) dial stored in
/// `space_autonomy.autonomy_level`, the value `autonomy.setForSpace`
/// validates, the ceiling the delegation guards enforce and the one a
/// reliability score recommends. One enum, one wire form.
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

  /// Parses a wire name; null for `null`/unknown — the client's "no explicit
  /// level, use the server default".
  static AutonomyLevel? tryFromWire(String? value) {
    if (value == null) {
      return null;
    }
    for (final level in values) {
      if (level.wire == value) {
        return level;
      }
    }
    return null;
  }

  /// Parses a wire name, defaulting to the SAFEST level on `null`/unknown —
  /// the guard-side reading, where an unparseable ceiling must never read as
  /// a permissive one.
  static AutonomyLevel fromWire(String? value) =>
      tryFromWire(value) ?? AutonomyLevel.proposeOnly;

  /// Whether this level is within (≤) the [ceiling].
  bool atMost(AutonomyLevel ceiling) => index <= ceiling.index;
}
