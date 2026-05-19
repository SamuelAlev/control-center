/// Result of a completed git command.
class GitResult {
  const GitResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get isSuccess => exitCode == 0;
}

/// Port for executing git commands. Adapters shell out to the system `git`
/// binary. All operations are read-only with respect to tracked files; the
/// only side effects are fetches/clones to the clone cache.
abstract interface class GitCommandPort {
  /// Runs a git command and returns when it completes.
  ///
  /// [args] are passed directly to `git`. The [workdir] must exist.
  /// [env] is merged with the ambient environment; use it to inject
  /// credentials (e.g. `http.extraHeader`) without storing them on disk.
  /// [onProgress] receives stderr lines as they arrive — useful for clone/fetch
  /// progress without blocking on completion.
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
  });

  /// Runs a git command and streams non-empty stderr lines as they arrive.
  ///
  /// Unlike [run], this yields each progress line immediately rather than
  /// buffering until completion. git writes progress using both `\r` (to
  /// overwrite the current line) and `\n` (new line); both delimiters are
  /// handled. Throws a [StateError] if git exits with a non-zero code.
  Stream<String> runStreaming(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
  });
}
