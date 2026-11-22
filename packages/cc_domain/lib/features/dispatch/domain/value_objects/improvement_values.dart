/// What an improvement proposal would change.
enum ImprovementKind {
  /// A memory fact.
  memoryFact,

  /// A memory policy.
  policy,

  /// One of the agent's notes.
  agentNote,

  /// An existing skill (a candidate revision).
  skillEdit,

  /// A new skill.
  skillNew,
}

/// Wire names for [ImprovementKind] (persisted as TEXT).
extension ImprovementKindWire on ImprovementKind {
  /// Persisted wire name.
  String get wire => switch (this) {
    ImprovementKind.memoryFact => 'memory_fact',
    ImprovementKind.policy => 'policy',
    ImprovementKind.agentNote => 'agent_note',
    ImprovementKind.skillEdit => 'skill_edit',
    ImprovementKind.skillNew => 'skill_new',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in ImprovementKind.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static ImprovementKind? tryParse(String? raw) {
    for (final value in ImprovementKind.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Where an accepted improvement applies.
enum ImprovementScope {
  /// The agent that did the work.
  agent,

  /// One repository (the proposal's `scopeRefId`).
  repository,

  /// The whole workspace.
  workspace,
}

/// Wire names for [ImprovementScope] (persisted as TEXT).
extension ImprovementScopeWire on ImprovementScope {
  /// Persisted wire name.
  String get wire => switch (this) {
    ImprovementScope.agent => 'agent',
    ImprovementScope.repository => 'repository',
    ImprovementScope.workspace => 'workspace',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in ImprovementScope.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static ImprovementScope? tryParse(String? raw) {
    for (final value in ImprovementScope.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// The single change a proposal makes.
enum ImprovementOperation {
  /// Adds new text.
  add,

  /// Replaces the text named by `targetRef`.
  replace,

  /// Removes the text named by `targetRef`.
  remove,
}

/// Wire names for [ImprovementOperation] (persisted as TEXT).
extension ImprovementOperationWire on ImprovementOperation {
  /// Persisted wire name.
  String get wire => switch (this) {
    ImprovementOperation.add => 'add',
    ImprovementOperation.replace => 'replace',
    ImprovementOperation.remove => 'remove',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in ImprovementOperation.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static ImprovementOperation? tryParse(String? raw) {
    for (final value in ImprovementOperation.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Where an improvement proposal is. Nothing changes until a person
/// accepts it.
enum ImprovementStatus {
  /// Waiting for a person.
  proposed,

  /// A person accepted it and the change was written.
  accepted,

  /// A person rejected it.
  rejected,

  /// It was accepted, then the earlier text was restored.
  rolledBack,

  /// Nobody decided within 30 days.
  expired,
}

/// Wire names for [ImprovementStatus] (persisted as TEXT).
extension ImprovementStatusWire on ImprovementStatus {
  /// Persisted wire name.
  String get wire => switch (this) {
    ImprovementStatus.proposed => 'proposed',
    ImprovementStatus.accepted => 'accepted',
    ImprovementStatus.rejected => 'rejected',
    ImprovementStatus.rolledBack => 'rolled_back',
    ImprovementStatus.expired => 'expired',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in ImprovementStatus.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static ImprovementStatus? tryParse(String? raw) {
    for (final value in ImprovementStatus.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Where the evaluation campaign that gates a skill change is.
enum ImprovementCampaignState {
  /// No campaign: the proposal is not a skill change, or none ran yet.
  none,

  /// A start claimed the proposal and is staging its candidate; nothing is
  /// launched yet. A second start is refused while it lasts.
  staging,

  /// The campaign is running.
  running,

  /// No regression observed (not evidence that the change improves
  /// anything); the change may be accepted.
  passed,

  /// It reported a regression; the change may not be accepted.
  failed,
}

/// Wire names for [ImprovementCampaignState] (persisted as TEXT).
extension ImprovementCampaignStateWire on ImprovementCampaignState {
  /// Persisted wire name.
  String get wire => switch (this) {
    ImprovementCampaignState.none => 'none',
    ImprovementCampaignState.staging => 'staging',
    ImprovementCampaignState.running => 'running',
    ImprovementCampaignState.passed => 'passed',
    ImprovementCampaignState.failed => 'failed',
  };

  /// Every wire name, for the stored-value check on the column.
  static List<String> get wireNames => [
    for (final value in ImprovementCampaignState.values) value.wire,
  ];

  /// Parses a wire name. Null for a missing or unknown value.
  static ImprovementCampaignState? tryParse(String? raw) {
    for (final value in ImprovementCampaignState.values) {
      if (value.wire == raw) {
        return value;
      }
    }
    return null;
  }
}
