import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/rss_articles.dart';
import 'package:cc_persistence/database/tables/rss_feeds.dart';
import 'package:drift/drift.dart';

part 'rss_dao.g.dart';

/// Data access object for [RssFeedsTable] and [RssArticlesTable].
@DriftAccessor(tables: [RssFeedsTable, RssArticlesTable])
class RssDao extends DatabaseAccessor<AppDatabase> with _$RssDaoMixin {
  /// Creates a new [Rss dao].
  RssDao(super.attachedDatabase);

  // ── Feeds ────────────────────────────────────────────────────────────

  /// Watches all RSS feeds, ordered by name.
  Stream<List<RssFeedsTableData>> watchFeeds() => (select(
    rssFeedsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// Gets all enabled RSS feeds.
  Future<List<RssFeedsTableData>> getEnabledFeeds() => (select(
    rssFeedsTable,
  )..where((t) => t.enabled.equals(true))).get();

  /// Get feed by url.
  Future<RssFeedsTableData?> getFeedByUrl(String url) =>
      (select(rssFeedsTable)..where((t) => t.url.equals(url))).getSingleOrNull();

  /// Upsert feed.
  Future<void> upsertFeed(RssFeedsTableCompanion entry) =>
      into(rssFeedsTable).insertOnConflictUpdate(entry);

  /// Update feed fetch result.
  Future<void> updateFeedFetchResult({
    required String feedId,
    required DateTime fetchedAt,
    String? error,
  }) => (update(rssFeedsTable)..where((t) => t.id.equals(feedId))).write(
    RssFeedsTableCompanion(
      lastFetchedAt: Value(fetchedAt),
      lastError: Value(error),
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// Set feed enabled.
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) =>
      (update(rssFeedsTable)..where((t) => t.id.equals(feedId))).write(
        RssFeedsTableCompanion(
          enabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Delete feed.
  Future<int> deleteFeed(String feedId) =>
      (delete(rssFeedsTable)..where((t) => t.id.equals(feedId))).go();

  // ── Articles ─────────────────────────────────────────────────────────

  /// Watches all articles from enabled feeds, ordered by publish time desc.
  Stream<List<RssArticlesTableData>> watchAllArticles({int limit = 200}) {
    final q = customSelect(
      '''
      SELECT a.* FROM rss_articles a
      INNER JOIN rss_feeds f ON f.id = a.feed_id
      WHERE f.enabled = 1
      ORDER BY COALESCE(a.published_at, a.created_at) DESC
      LIMIT ?
      ''',
      variables: [Variable<int>(limit)],
      readsFrom: {rssArticlesTable, rssFeedsTable},
    );
    return q.watch().map(
      (rows) => rows.map((r) => rssArticlesTable.map(r.data)).toList(),
    );
  }

  /// Watches only bookmarked articles.
  Stream<List<RssArticlesTableData>> watchSavedArticles() => (select(
    rssArticlesTable,
  )
        ..where((t) => t.saved.equals(true))
        ..orderBy([
          (t) => OrderingTerm.desc(t.publishedAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
      .watch();

  /// Get article by id.
  Future<RssArticlesTableData?> getArticleById(String id) =>
      (select(rssArticlesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Stale-while-revalidate upsert keyed on `(feedId, guid)`.
  ///
  /// Inserts the article when the `(feedId, guid)` pair is new. When it
  /// already exists, refreshes the mutable content (title, link, summary,
  /// image, author, publish date) so edits made upstream propagate, while
  /// preserving the user-owned `saved`/`read` flags and the original `id`
  /// and `createdAt` so bookmarks, read state and ordering survive a refresh.
  Future<void> upsertArticleFromFeed(RssArticlesTableCompanion entry) async {
    final existing =
        await (select(rssArticlesTable)..where(
              (t) =>
                  t.feedId.equals(entry.feedId.value) &
                  t.guid.equals(entry.guid.value),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await into(rssArticlesTable).insert(
        entry,
        mode: InsertMode.insertOrIgnore,
      );
      return;
    }
    await (update(rssArticlesTable)..where((t) => t.id.equals(existing.id)))
        .write(
          RssArticlesTableCompanion(
            title: entry.title,
            link: entry.link,
            summary: entry.summary,
            imageUrl: entry.imageUrl,
            author: entry.author,
            publishedAt: entry.publishedAt,
          ),
        );
  }

  /// Toggles the saved/bookmarked flag on an article.
  Future<void> setArticleSaved(String articleId, {required bool saved}) =>
      (update(rssArticlesTable)..where((t) => t.id.equals(articleId))).write(
        RssArticlesTableCompanion(saved: Value(saved)),
      );

  /// Toggles the read flag on an article.
  Future<void> setArticleRead(String articleId, {required bool read}) =>
      (update(rssArticlesTable)..where((t) => t.id.equals(articleId))).write(
        RssArticlesTableCompanion(read: Value(read)),
      );

  /// Marks every article as read.
  Future<void> markAllRead() =>
      update(rssArticlesTable).write(
        const RssArticlesTableCompanion(read: Value(true)),
      );
}
