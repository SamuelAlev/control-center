import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart'
    show RepoScriptKind;

/// The lifecycle hook the worktree provisioner calls to run a repo's
/// configured scripts (see `RepoScripts`). Implemented by the server's
/// `RepoScriptService` and injected into `RepoWorkspaceProvisioner`.
///
/// Keeping this a narrow port (rather than the provisioner depending on the
/// service concrete type) lets the provisioner's tests install a fake and the
/// runtime swap the executor without touching provisioning logic.
abstract class RepoScriptPort {
  /// Whether the repo has a setup script configured — lets the provisioner
  /// skip the progress callback (and its visible "running setup script" step)
  /// for repos with nothing to run.
  Future<bool> hasSetupScript(String workspaceId, String repoId);

  /// Runs the repo's SETUP script in the freshly provisioned worktree.
  ///
  /// A no-op when no setup script is configured. On failure this THROWS
  /// (a typed `RepoScriptException`): a failed setup fails the space
  /// provisioning, which is retryable — the worktree is left in place so a
  /// retry resumes a half-finished install.
  Future<void> runSetup(RepoScriptContext context);

  /// Runs the repo's ARCHIVE script just before the worktree is destroyed.
  ///
  /// A no-op when no archive script is configured. NEVER throws: archive runs
  /// on GC paths with no one to answer a prompt (space deleted, PR merged,
  /// scheduled sweep), so a failure is recorded and the deletion proceeds.
  Future<void> runArchive(RepoScriptContext context);

  /// Tests a script DRAFT ([body]) against a throwaway clone of the repo.
  ///
  /// Unlike [runSetup]/[runArchive] the body is caller-supplied (the draft in
  /// the editor, unsaved edits included) and the execution directory is a
  /// pristine copy-on-write clone of the registered repo, destroyed when the
  /// run ends. [kind] labels the run row with the lifecycle slot the draft
  /// belongs to (`setup` or `archive`); it does not select a stored script.
  ///
  /// Returns the run id IMMEDIATELY — the clone, execution and teardown
  /// continue in the background, streaming into the run row. NEVER throws:
  /// an unavailable clone backend or a missing repo finishes the row as
  /// failed with the reason, and the answer to the caller is still a run id.
  Future<String> runTest({
    required String workspaceId,
    required String repoId,
    required RepoScriptKind kind,
    required String body,
  });
}

/// Everything a script execution needs to know about the worktree it targets.
class RepoScriptContext {
  /// Creates a [RepoScriptContext].
  const RepoScriptContext({
    required this.workspaceId,
    this.spaceId,
    required this.repoId,
    required this.worktreePath,
    required this.sourcePath,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The space whose worktree this is. Null for a TEST run — it has no space,
  /// so the space env vars are simply absent.
  final String? spaceId;

  /// The registered repo (the row whose scripts these are).
  final String repoId;

  /// Absolute path to the provisioned worktree — the script's working
  /// directory, exported as `CC_WORKSPACE_PATH`.
  final String worktreePath;

  /// Absolute path to the registered source repo — the operator's own
  /// checkout, exported as `CC_ROOT_PATH`.
  final String sourcePath;
}
