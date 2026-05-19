import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/repositories/repo_script_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [RepoScriptRepository] + [RepoScriptRunRecorder].
///
/// Holds the [WorkspaceDatabaseManager] and resolves the DAOs per call — a
/// cached per-workspace DAO field is the one way to reintroduce a
/// cross-workspace leak, so there is none (pinned by the isolation ratchet
/// test).
class DaoRepoScriptRepository
    implements RepoScriptRepository, RepoScriptRunRecorder {
  /// Creates a [DaoRepoScriptRepository] over the per-workspace databases.
  DaoRepoScriptRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<RepoScripts> getScripts(String workspaceId, String repoId) async {
    final columns = await _dbs.of(workspaceId).repoDao.getScripts(repoId);
    return RepoScripts(setup: columns.setup, archive: columns.archive);
  }

  @override
  Future<void> setScripts(
    String workspaceId,
    String repoId,
    RepoScripts scripts,
  ) => _dbs.of(workspaceId).repoDao.setScripts(
    repoId,
    setup: scripts.setup,
    archive: scripts.archive,
  );

  // Executing a script draft is the SERVER EXECUTOR's job (RepoScriptPort,
  // wired from RepoScriptService); the row store never spawns anything. The
  // method exists on this interface only because the RPC client shares it.
  @override
  Future<String> testScript(
    String workspaceId,
    String repoId,
    RepoScriptKind kind,
    String body,
  ) => throw UnsupportedError('the DAO repository does not execute scripts');

  @override
  Stream<List<RepoScriptRun>> watchRuns(String workspaceId, {String? repoId}) =>
      _dbs
          .of(workspaceId)
          .repoScriptRunDao
          .watchRuns(repoId: repoId)
          .map((rows) => rows.map(_toEntity).whereType<RepoScriptRun>().toList());

  @override
  Future<void> insert(RepoScriptRun run) => _dbs
      .of(run.workspaceId)
      .repoScriptRunDao
      .insertRun(_toCompanion(run));

  @override
  Future<void> updateOutput(String workspaceId, String runId, String output) =>
      _dbs.of(workspaceId).repoScriptRunDao.updateOutput(runId, output);

  @override
  Future<void> finish(
    String workspaceId,
    String runId, {
    required RepoScriptRunStatus status,
    int? exitCode,
    String? error,
    String? output,
  }) => _dbs
      .of(workspaceId)
      .repoScriptRunDao
      .finishRun(
        runId,
        status: status.wireName,
        exitCode: exitCode,
        error: error,
        output: output,
      );

  RepoScriptRunsTableCompanion _toCompanion(RepoScriptRun run) =>
      RepoScriptRunsTableCompanion(
        id: Value(run.id),
        workspaceId: Value(run.workspaceId),
        // The column is NOT NULL; a test run (no space) stores the empty
        // string and [_toEntity] maps it back to null.
        spaceId: Value(run.spaceId ?? ''),
        repoId: Value(run.repoId),
        repoName: Value(run.repoName),
        kind: Value(run.kind.wireName),
        status: Value(run.status.wireName),
        startedAt: Value(run.startedAt),
        completedAt: Value(run.completedAt),
        exitCode: Value(run.exitCode),
        error: Value(run.error),
        outputText: Value(run.output),
      );

  /// Row → entity. A row whose kind/status names no longer parse (a value
  /// retired in a later version) maps to null and is filtered out by
  /// [watchRuns] rather than throwing the whole watch lane.
  RepoScriptRun? _toEntity(RepoScriptRunsTableData row) {
    final kind = RepoScriptKind.fromName(row.kind);
    final status = RepoScriptRunStatus.fromName(row.status);
    if (kind == null || status == null) {
      return null;
    }
    return RepoScriptRun(
      id: row.id,
      workspaceId: row.workspaceId,
      spaceId: row.spaceId.isEmpty ? null : row.spaceId,
      repoId: row.repoId,
      repoName: row.repoName,
      kind: kind,
      status: status,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      exitCode: row.exitCode,
      error: row.error,
      output: row.outputText ?? '',
    );
  }
}
