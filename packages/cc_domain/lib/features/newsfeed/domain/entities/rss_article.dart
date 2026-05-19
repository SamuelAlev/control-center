/// A single article from an RSS feed.
class RssArticle {
  /// Creates a new [RssArticle].
  RssArticle({
    required this.id,
    required this.feedId,
    required this.guid,
    required this.title,
    required this.link,
    this.summary = '',
    this.imageUrl = '',
    this.author = '',
    this.publishedAt,
    this.saved = false,
    this.read = false,
    required this.createdAt,
  }) : assert(id.isNotEmpty, 'Article id must not be empty'),
       assert(feedId.isNotEmpty, 'Article feedId must not be empty'),
       assert(title.isNotEmpty, 'Article title must not be empty'),
       assert(link.isNotEmpty, 'Article link must not be empty');

  /// Unique article identifier.
  final String id;

  /// ID of the feed this article belongs to.
  final String feedId;

  /// GUID provided by the feed.
  final String guid;

  /// Article title.
  final String title;

  /// Article URL.
  final String link;

  /// Short summary or description.
  final String summary;

  /// URL of the cover image, if any.
  final String imageUrl;

  /// Author name, if provided.
  final String author;

  /// Original publication date, if known.
  final DateTime? publishedAt;

  /// Whether the article has been bookmarked.
  final bool saved;

  /// Whether the article has been read.
  final bool read;

  /// When the article was first persisted locally.
  final DateTime createdAt;

  /// Best timestamp to sort on.
  DateTime get effectivePublishedAt => publishedAt ?? createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RssArticle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
