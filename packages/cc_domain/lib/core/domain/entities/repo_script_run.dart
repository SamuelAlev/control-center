import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';

/// One recorded execution of a repo lifecycle script (see [RepoScripts]).
///
/// A row exists only when a script was actually configured and executed —
/// unset scripts produce no rows. Output is captured as a bounded tail
/// (capped at storage time) so a chatty install cannot grow the row without
/// limit. Rows are workspace-scoped like everything else and retained per repo
/// (most recent first, pruned past a fixed count).
class RepoScriptRun {
  /// Creates a [RepoScriptRun].
  RepoScriptRun({
    required this.id,
    required this.workspaceId,
    this.spaceId,
    required this.repoId,
    required this.repoName,
    required this.kind,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.exitCode,
    this.error,
    this.output = '',
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError('RepoScriptRun.workspaceId must not be empty');
    }
    if (repoId.isEmpty) {
      throw ArgumentError('RepoScriptRun.repoId must not be empty');
    }
    if (repoName.isEmpty) {
      throw ArgumentError('RepoScriptRun.repoName must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// Owning workspace (never null — the isolation boundary).
  final String workspaceId;

  /// The space whose worktree the script ran in. Null for a TEST run, which
  /// executes in a throwaway clone that belongs to no space.
  final String? spaceId;

  /// The registered repo the script belongs to.
  final String repoId;

  /// Display name of the repo at run time (rows outlive repo renames).
  final String repoName;

  /// Which lifecycle moment this run belongs to.
  final RepoScriptKind kind;

  /// Current outcome.
  final RepoScriptRunStatus status;

  /// When the script started.
  final DateTime startedAt;

  /// When the script finished (null while running).
  final DateTime? completedAt;

  /// Process exit code (null while running or when killed by a signal).
  final int? exitCode;

  /// Short failure summary (timeout, spawn error); not the output tail.
  final String? error;

  /// Bounded captured stdout+stderr tail, interleaved.
  final String output;

  /// True while the run has not finished.
  bool get isRunning => status == RepoScriptRunStatus.running;

  /// Copy with.
  RepoScriptRun copyWith({
    String? id,
    String? workspaceId,
    String? spaceId,
    String? repoId,
    String? repoName,
    RepoScriptKind? kind,
    RepoScriptRunStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? exitCode,
    String? error,
    String? output,
  }) {
    return RepoScriptRun(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      spaceId: spaceId ?? this.spaceId,
      repoId: repoId ?? this.repoId,
      repoName: repoName ?? this.repoName,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      exitCode: exitCode ?? this.exitCode,
      error: error ?? this.error,
      output: output ?? this.output,
    );
  }

  /// Wire codec (snake_case keys, matching the repo-RPC convention).
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'repo_id': repoId,
    'repo_name': repoName,
    'kind': kind.wireName,
    'status': status.wireName,
    'started_at': startedAt.toIso8601String(),
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    if (exitCode != null) 'exit_code': exitCode,
    if (error != null) 'error': error,
    if (output.isNotEmpty) 'output': output,
  };

  /// Decodes a wire payload; null when [json] is null or malformed.
  static RepoScriptRun? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    try {
      final kind = RepoScriptKind.fromName(json['kind'] as String?);
      final status = RepoScriptRunStatus.fromName(json['status'] as String?);
      final id = json['id'] as String;
      final workspaceId = json['workspace_id'] as String;
      final spaceId = json['space_id'] as String?;
      final repoId = json['repo_id'] as String;
      final repoName = json['repo_name'] as String? ?? '';
      final startedAt = DateTime.parse(json['started_at'] as String);
      if (kind == null || status == null || repoName.isEmpty) {
        return null;
      }
      return RepoScriptRun(
        id: id,
        workspaceId: workspaceId,
        spaceId: spaceId,
        repoId: repoId,
        repoName: repoName,
        kind: kind,
        status: status,
        startedAt: startedAt,
        completedAt:
            json['completed_at'] is String
                ? DateTime.parse(json['completed_at'] as String)
                : null,
        exitCode:
            json['exit_code'] is num ? (json['exit_code'] as num).toInt() : null,
        error: json['error'] as String?,
        output: json['output'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoScriptRun &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          status == other.status &&
          completedAt == other.completedAt &&
          exitCode == other.exitCode &&
          output == other.output;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    status,
    completedAt,
    exitCode,
    output,
  );
}
