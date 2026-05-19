import 'package:cc_persistence/database/tables/rss_feeds.dart';
import 'package:drift/drift.dart';

/// Drift table definition for individual articles pulled from a feed.
///
/// `(feedId, guid)` is unique — feeds may reuse GUIDs across reboots so we
/// dedupe at the (feed, guid) level rather than globally.
@TableIndex(name: 'idx_rss_articles_feedId_guid', columns: {#feedId, #guid}, unique: true)
class RssArticlesTable extends Table {
  /// Article id.
  TextColumn get id => text()();

  /// Feed id.
  TextColumn get feedId => text().references(
    RssFeedsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Feed-provided GUID (or link as fallback).
  TextColumn get guid => text()();

  /// Article title.
  TextColumn get title => text()();

  /// Link.
  TextColumn get link => text()();

  /// Excerpt / description as raw HTML (we strip on render).
  TextColumn get summary => text().withDefault(const Constant(''))();

  /// First image URL extracted from media:thumbnail / enclosure / content.
  TextColumn get imageUrl => text().withDefault(const Constant(''))();

  /// Article author.
  TextColumn get author => text().withDefault(const Constant(''))();

  /// When the article was originally published.
  DateTimeColumn get publishedAt => dateTime().nullable()();

  /// Whether the user has bookmarked this article.
  BoolColumn get saved => boolean().withDefault(const Constant(false))();

  /// Whether the user has opened (read) this article.
  BoolColumn get read => boolean().withDefault(const Constant(false))();

  /// When the article was ingested into the local database.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'rss_articles';

  @override
  Set<Column> get primaryKey => {id};
}
