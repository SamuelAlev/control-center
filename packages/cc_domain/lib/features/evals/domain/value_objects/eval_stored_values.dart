/// How a golden session gates (`golden_sessions.mode`).
enum GoldenMode {
  /// Exact replay: free and the default.
  deterministic,

  /// A live re-run: advisory only.
  live;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static GoldenMode parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'not a GoldenMode'),
  );
}

/// The outcome of a golden's last run (`golden_sessions.last_status`).
enum GoldenStatus {
  /// The run matched the golden.
  pass,

  /// The run diverged from the golden.
  fail,

  /// The golden has not run yet.
  unknown;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static GoldenStatus parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'not a GoldenStatus'),
  );
}

/// Where an eval batch is in its life (`eval_runs.status`).
enum EvalRunStatus {
  /// Waiting to start.
  queued,

  /// Executing.
  running,

  /// Finished with a scorecard.
  done,

  /// Could not finish.
  failed,

  /// Stopped before finishing.
  cancelled;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static EvalRunStatus parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'not a EvalRunStatus'),
  );
}

/// What started an eval batch (`eval_runs.triggered_by`).
enum EvalTrigger {
  /// A person.
  manual,

  /// A config canary.
  canary,

  /// A golden check.
  golden,

  /// Continuous integration.
  ci;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static EvalTrigger parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'not a EvalTrigger'),
  );
}

/// The lifecycle of a versioned agent config (`agent_config_versions.status`).
enum AgentConfigVersionStatus {
  /// The config agents run with.
  live,

  /// A candidate being evaluated against the live config.
  canary,

  /// A config no longer in use.
  retired;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static AgentConfigVersionStatus parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw ArgumentError.value(
      value,
      'value',
      'not a AgentConfigVersionStatus',
    ),
  );
}
