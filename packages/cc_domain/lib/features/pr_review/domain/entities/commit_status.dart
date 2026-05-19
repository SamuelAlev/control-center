/// Combined-status state for a single commit-status context.
///
/// The GitHub Statuses API (`GET /commits/{sha}/status`) — distinct from the
/// Checks API — is what integrations like Netlify and (some) Vercel setups use
/// to publish a deploy-preview URL via [CommitStatus.targetUrl]. GitHub's own
/// PR UI merges statuses and check-runs into one list, which is why a green
/// "check" can actually be a status carrying the preview link.
enum CommitStatusState {
  /// The context succeeded (e.g. the deploy preview is live).
  success,

  /// The context is still running (e.g. the preview is building).
  pending,

  /// The context failed.
  failure,

  /// The context errored.
  error,
}

/// CommitStatusStateExtension helpers.
extension CommitStatusStateExtension on CommitStatusState {
  /// Wire/name form.
  String get name => switch (this) {
    CommitStatusState.success => 'success',
    CommitStatusState.pending => 'pending',
    CommitStatusState.failure => 'failure',
    CommitStatusState.error => 'error',
  };

  /// Parses a GitHub status `state` string, defaulting to [pending].
  static CommitStatusState fromString(String? value) => switch (value) {
    'success' => CommitStatusState.success,
    'failure' => CommitStatusState.failure,
    'error' => CommitStatusState.error,
    _ => CommitStatusState.pending,
  };
}

/// A single commit-status context for a PR head SHA.
class CommitStatus {
  /// Creates a [CommitStatus].
  const CommitStatus({
    required this.context,
    required this.state,
    this.targetUrl = '',
    this.description = '',
    this.updatedAt,
  });

  /// The status context, e.g. `netlify/test-web-app/deploy-preview`.
  final String context;

  /// The status state.
  final CommitStatusState state;

  /// The URL the status points at — for a deploy-preview context this is the
  /// preview site itself (custom domains included).
  final String targetUrl;

  /// Human-readable status description (e.g. "Deploy preview ready!").
  final String description;

  /// When the status last moved.
  final DateTime? updatedAt;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitStatus &&
          runtimeType == other.runtimeType &&
          context == other.context &&
          state == other.state &&
          targetUrl == other.targetUrl;

  /// Hash code.
  @override
  int get hashCode => Object.hash(context, state, targetUrl);
}
