/// What an [EnvironmentRun] ran.
enum EnvironmentRunKind {
  /// Starting an environment.
  start,

  /// Stopping it.
  stop,

  /// Resetting it.
  reset,

  /// Refreshing it after a sync.
  refresh,

  /// Destroying it.
  destroy,

  /// One task.
  task,

  /// A throwaway test of a definition.
  test;

  /// Parses [wire], defaulting to [task].
  static EnvironmentRunKind parse(String? wire) =>
      values.firstWhere((kind) => kind.name == wire, orElse: () => task);
}

/// How an [EnvironmentRun] went.
enum EnvironmentRunStatus {
  /// Still going.
  running,

  /// Finished cleanly.
  succeeded,

  /// Finished with a failure.
  failed,

  /// Stopped by its deadline.
  timedOut;

  /// Parses [wire], defaulting to [failed].
  static EnvironmentRunStatus parse(String? wire) =>
      values.firstWhere((status) => status.name == wire, orElse: () => failed);
}

/// One recorded execution, with a bounded output tail.
class EnvironmentRun {
  /// Creates an [EnvironmentRun].
  EnvironmentRun({
    required this.id,
    required this.workspaceId,
    this.spaceId,
    this.environmentId,
    this.definitionId,
    this.repoId,
    required this.kind,
    this.label,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.exitCode,
    this.error,
    this.output = '',
  }) {
    if (id.isEmpty || workspaceId.isEmpty) {
      throw ArgumentError('EnvironmentRun needs ids');
    }
  }

  /// Run id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The space, or null for a test on a throwaway clone.
  final String? spaceId;

  /// The environment, or null for a worktree task.
  final String? environmentId;

  /// The definition.
  final String? definitionId;

  /// The repo of a worktree task.
  final String? repoId;

  /// What ran.
  final EnvironmentRunKind kind;

  /// A component id or verb.
  final String? label;

  /// How it went.
  final EnvironmentRunStatus status;

  /// When it started.
  final DateTime startedAt;

  /// When it finished.
  final DateTime? completedAt;

  /// The exit code.
  final int? exitCode;

  /// A failure message.
  final String? error;

  /// The redacted output tail.
  final String output;

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    if (spaceId != null) 'space_id': spaceId,
    if (environmentId != null) 'environment_id': environmentId,
    if (definitionId != null) 'definition_id': definitionId,
    if (repoId != null) 'repo_id': repoId,
    'kind': kind.name,
    if (label != null) 'label': label,
    'status': status.name,
    'started_at': startedAt.toUtc().toIso8601String(),
    if (completedAt != null)
      'completed_at': completedAt!.toUtc().toIso8601String(),
    if (exitCode != null) 'exit_code': exitCode,
    if (error != null) 'error': error,
    'output': output,
  };

  @override
  bool operator ==(Object other) =>
      other is EnvironmentRun &&
      other.id == id &&
      other.workspaceId == workspaceId &&
      other.status == status &&
      other.completedAt == completedAt &&
      other.exitCode == exitCode &&
      other.output == output;

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, status, completedAt, exitCode, output);
}
