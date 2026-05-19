/// A registered RSS or Atom feed.
class RssFeed {
  /// Creates a new [RssFeed].
  RssFeed({
    required this.id,
    required this.name,
    required this.url,
    this.description = '',
    this.iconUrl = '',
    this.userAgent = '',
    this.enabled = true,
    this.lastFetchedAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(id.isNotEmpty, 'Feed id must not be empty'),
       assert(name.isNotEmpty, 'Feed name must not be empty'),
       assert(url.isNotEmpty, 'Feed url must not be empty');

  /// Unique feed identifier.
  final String id;

  /// Display name of the feed.
  final String name;

  /// Feed URL.
  final String url;

  /// Feed description.
  final String description;

  /// URL of the feed icon, if any.
  final String iconUrl;

  /// Custom User-Agent for this feed (empty = use default).
  final String userAgent;

  /// Whether the feed is enabled for fetching.
  final bool enabled;

  /// Last successful fetch timestamp.
  final DateTime? lastFetchedAt;

  /// Last error message, if any.
  final String? lastError;

  /// When the feed was first added.
  final DateTime createdAt;

  /// When the feed was last updated.
  final DateTime updatedAt;

  /// Whether the feed has a recorded error.
  bool get hasError => lastError != null && lastError!.isNotEmpty;

  /// Copy with.
  RssFeed copyWith({
    String? name,
    String? url,
    String? description,
    String? iconUrl,
    String? userAgent,
    bool? enabled,
    DateTime? lastFetchedAt,
    String? lastError,
    DateTime? updatedAt,
  }) {
    return RssFeed(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      userAgent: userAgent ?? this.userAgent,
      enabled: enabled ?? this.enabled,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      lastError: lastError,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RssFeed && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
