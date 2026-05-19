/// A durable record of a budget threshold being crossed for a scope
/// (agent / team / company).
///
/// A soft incident ([isHardStop] is false) records a warning; a hard incident
/// records the auto-pause that flips an agent's lifecycle status to `paused`.
class BudgetIncident {
  /// Creates a [BudgetIncident].
  const BudgetIncident({
    required this.id,
    required this.workspaceId,
    this.policyId,
    required this.scopeType,
    required this.scopeId,
    required this.spentCents,
    required this.budgetCents,
    this.isHardStop = false,
    required this.reason,
    required this.triggeredAt,
  });

  /// Unique incident identifier.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Budget policy that triggered the incident, if any.
  final String? policyId;

  /// Scope type: `agent`, `team`, or `company`.
  final String scopeType;

  /// Identifier within the scope.
  final String scopeId;

  /// Cents spent when the incident fired.
  final int spentCents;

  /// Budget ceiling when the incident fired.
  final int budgetCents;

  /// Whether this incident hard-stopped the scope.
  final bool isHardStop;

  /// Human-readable reason.
  final String reason;

  /// When the incident fired.
  final DateTime triggeredAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetIncident &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          policyId == other.policyId &&
          scopeType == other.scopeType &&
          scopeId == other.scopeId &&
          spentCents == other.spentCents &&
          budgetCents == other.budgetCents &&
          isHardStop == other.isHardStop &&
          reason == other.reason &&
          triggeredAt == other.triggeredAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    policyId,
    scopeType,
    scopeId,
    spentCents,
    budgetCents,
    isHardStop,
    reason,
    triggeredAt,
  );
}
