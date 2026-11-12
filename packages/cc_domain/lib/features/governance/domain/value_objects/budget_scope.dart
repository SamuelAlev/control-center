/// What a budget policy or incident is about (`budget_policy.scope_type`,
/// `budget_incidents.scope_type`).
enum BudgetScopeType {
  /// One agent.
  agent,

  /// A team of agents.
  team,

  /// The whole company (every agent of the workspace).
  company,

  /// The workspace.
  workspace;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static BudgetScopeType parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'not a BudgetScopeType'),
  );
}

/// Whether a budget policy is in force (`budget_policy.status`).
enum BudgetPolicyStatus {
  /// The policy caps spend.
  active,

  /// The policy is suspended.
  paused;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static BudgetPolicyStatus parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'not a BudgetPolicyStatus'),
  );
}
