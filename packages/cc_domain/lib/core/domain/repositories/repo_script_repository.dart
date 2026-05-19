import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';

/// Persistence and playback for per-repo lifecycle scripts (see [RepoScripts])
/// and their recorded runs.
///
/// Scripts are server-executed code configured per repo, so every method
/// takes a required workspace id — the same workspace-scoping rule as
/// `RepoRepository`, enforced structurally by the database split.
abstract class RepoScriptRepository {
  /// The scripts configured for a repo; [RepoScripts.empty] when unset.
  Future<RepoScripts> getScripts(String workspaceId, String repoId);

  /// Replaces the scripts for a repo. An empty [scripts] clears them.
  Future<void> setScripts(String workspaceId, String repoId, RepoScripts scripts);

  /// Watches recorded script runs for a workspace, newest first, optionally
  /// filtered to one repo.
  Stream<List<RepoScriptRun>> watchRuns(String workspaceId, {String? repoId});

  /// Starts a TEST run of a script draft in a throwaway clone of the repo
  /// (see `RepoScriptPort.runTest`). [kind] is the lifecycle slot the draft
  /// belongs to — it labels the run row, it does not select a stored script.
  /// Returns the run id; the output streams through [watchRuns].
  Future<String> testScript(
    String workspaceId,
    String repoId,
    RepoScriptKind kind,
    String body,
  );
}

/// Server-side write path for [RepoScriptRun] rows, used by the script
/// executor while a run is in flight. Deliberately separate from
/// [RepoScriptRepository] so the RPC-backed client adapter never has to
/// stub these out.
abstract class RepoScriptRunRecorder {
  /// Inserts a running row (and prunes old rows past the retention count).
  Future<void> insert(RepoScriptRun run);

  /// Appends a progress write (bounded output tail) while the run is live.
  Future<void> updateOutput(String workspaceId, String runId, String output);

  /// Closes a run with its outcome.
  Future<void> finish(
    String workspaceId,
    String runId, {
    required RepoScriptRunStatus status,
    int? exitCode,
    String? error,
    String? output,
  });
}
