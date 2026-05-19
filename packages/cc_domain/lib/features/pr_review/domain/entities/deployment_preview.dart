/// Where a [DeploymentPreview] was discovered.
enum DeploymentPreviewSource {
  /// A commit-status context (`target_url`) — the structured, canonical source.
  commitStatus,

  /// Scraped from a PR/issue comment or the PR body — the fallback source for
  /// providers that only comment and never post a status.
  comment,
}

/// Deploy state of a discovered preview, when known.
enum DeploymentPreviewState {
  /// The preview is live.
  ready,

  /// The preview is still building.
  building,

  /// The deploy failed.
  failed,

  /// State could not be determined (e.g. a comment-scraped URL).
  unknown,
}

/// A single deployment preview surfaced on a PR — one site's live URL.
///
/// A PR can expose several at once (a monorepo with multiple Netlify/Vercel
/// sites), which is why the review surface renders one tab per [siteName].
class DeploymentPreview {
  /// Creates a [DeploymentPreview].
  const DeploymentPreview({
    required this.siteName,
    required this.url,
    required this.source,
    this.state = DeploymentPreviewState.unknown,
    this.updatedAt,
  });

  /// A short label for the site this preview belongs to (e.g. `test-web-app`, `test-backend`). May be empty when it can't be derived; the UI falls back to a generic label then.
  final String siteName;

  /// The preview URL.
  final String url;

  /// Where this preview was discovered.
  final DeploymentPreviewSource source;

  /// The deploy state, when known.
  final DeploymentPreviewState state;

  /// When the underlying signal last moved.
  final DateTime? updatedAt;

  /// Returns a copy with the given overrides applied.
  DeploymentPreview copyWith({
    String? siteName,
    String? url,
    DeploymentPreviewSource? source,
    DeploymentPreviewState? state,
    DateTime? updatedAt,
  }) => DeploymentPreview(
    siteName: siteName ?? this.siteName,
    url: url ?? this.url,
    source: source ?? this.source,
    state: state ?? this.state,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Equality comparison — identity is `(siteName, url)`.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeploymentPreview &&
          runtimeType == other.runtimeType &&
          siteName == other.siteName &&
          url == other.url;

  /// Hash code.
  @override
  int get hashCode => Object.hash(siteName, url);
}
