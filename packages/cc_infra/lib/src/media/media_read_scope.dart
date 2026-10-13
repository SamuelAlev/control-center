/// File-read authority from an active dispatch, never from tool arguments.
class MediaReadScope {
  /// Uses the same working directory and shared roots as the run's Read tool.
  const MediaReadScope({
    required this.workingDirectory,
    this.sharedRoots = const [],
    this.abandoned,
  });

  /// Absolute directory against which relative source paths are resolved.
  final String workingDirectory;

  /// Server-provisioned repositories and materialized attachments.
  final List<String> sharedRoots;

  /// Completes when the owning dispatch is cancelled.
  final Future<void>? abandoned;
}
