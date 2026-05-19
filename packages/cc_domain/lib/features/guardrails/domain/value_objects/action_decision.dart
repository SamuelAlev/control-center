/// A guardrail decision (PRD 24). Ordered by restrictiveness so conflicts
/// resolve most-restrictive: `deny > prompt > allow`.
enum ActionDecision {
  /// Allow without asking.
  allow('allow', 0),

  /// Ask the operator once (fail-closed if no approver).
  prompt('prompt', 1),

  /// Refuse, terminally, with an informative reason.
  deny('deny', 2);

  const ActionDecision(this.wire, this.restrictiveness);

  /// Stable wire/storage string.
  final String wire;

  /// Higher = more restrictive (used for most-restrictive combination).
  final int restrictiveness;

  /// Parses an [ActionDecision] from its [wire] string, defaulting to [prompt]
  /// (the safe middle when a stored value is unrecognized).
  static ActionDecision fromWire(String value) => ActionDecision.values
      .firstWhere((d) => d.wire == value, orElse: () => ActionDecision.prompt);

  /// Whether this decision is strictly more restrictive than [other].
  bool isMoreRestrictiveThan(ActionDecision other) =>
      restrictiveness > other.restrictiveness;

  /// The more restrictive of two decisions (deny > prompt > allow).
  static ActionDecision mostRestrictive(ActionDecision a, ActionDecision b) =>
      a.restrictiveness >= b.restrictiveness ? a : b;
}

/// The scope a rule applies at (PRD 24 §2). Precedence when resolving:
/// `channel > agent > workspace`.
enum ActionScopeType {
  /// Applies to a whole workspace (least specific).
  workspace('workspace'),

  /// Applies to a single agent.
  agent('agent'),

  /// Applies to a single channel (most specific).
  channel('channel');

  const ActionScopeType(this.wire);

  /// Stable wire/storage string.
  final String wire;

  /// Parses an [ActionScopeType] from its [wire] string.
  static ActionScopeType fromWire(String value) =>
      ActionScopeType.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => ActionScopeType.workspace,
      );
}
