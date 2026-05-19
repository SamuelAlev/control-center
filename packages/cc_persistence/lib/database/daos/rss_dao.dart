import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/rss_articles.dart';
import 'package:cc_persistence/database/tables/rss_feeds.dart';
import 'package:drift/drift.dart';

part 'rss_dao.g.dart';

/// Data access object for [RssFeedsTable] and [RssArticlesTable].
///
/// The feed list is PER-USER: every read and write takes the owning user's id
/// and an id-only lookup (`getFeedById`, `getArticleById`) cannot prove
/// ownership by itself, so it is scoped by user too — a foreign row is simply
/// not found.
@DriftAccessor(tables: [RssFeedsTable, RssArticlesTable])
class RssDao extends DatabaseAccessor<GlobalDatabase> with _$RssDaoMixin {
  /// Creates a new [Rss dao].
  RssDao(super.attachedDatabase);

  // ── Feeds ────────────────────────────────────────────────────────────

  /// Watches the user's RSS feeds, ordered by name.
  Stream<List<RssFeedsTableData>> watchFeeds(String userId) => (select(
    rssFeedsTable,
  )..where((t) => t.userId.equals(userId))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();

  /// Gets the user's enabled RSS feeds.
  Future<List<RssFeedsTableData>> getEnabledFeeds(String userId) =>
      (select(
        rssFeedsTable,
      )..where((t) => t.userId.equals(userId) & t.enabled.equals(true))).get();

  /// Get the user's feed by url (dedupe is per-user).
  Future<RssFeedsTableData?> getFeedByUrl(String userId, String url) => (
    select(rssFeedsTable)
          ..where((t) => t.userId.equals(userId) & t.url.equals(url))
        )
        .getSingleOrNull();

  /// Get a feed by id, scoped to the owning user: a foreign feed row is
  /// indistinguishable from a missing one.
  Future<RssFeedsTableData?> getFeedById(String userId, String feedId) => (
    select(rssFeedsTable)
          ..where((t) => t.userId.equals(userId) & t.id.equals(feedId))
        )
        .getSingleOrNull();

  /// Upsert feed. The [RssFeedsTableCompanion.userId] carries the owner.
  Future<void> upsertFeed(RssFeedsTableCompanion entry) =>
      into(rssFeedsTable).insertOnConflictUpdate(entry);

  /// Update feed fetch result. Feed-id keyed; callers must have verified
  /// ownership (see [getFeedById]).
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

  /// Persists the feed's resolved icon URL (channel image or site favicon).
  /// Feed-id keyed; callers must have verified ownership.
  Future<void> updateFeedIcon({
    required String feedId,
    required String iconUrl,
  }) => (update(rssFeedsTable)..where((t) => t.id.equals(feedId))).write(
    RssFeedsTableCompanion(
      iconUrl: Value(iconUrl),
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// Set feed enabled, scoped to the owning user.
  Future<void> setFeedEnabled(
    String userId,
    String feedId, {
    required bool enabled,
  }) => (update(
    rssFeedsTable,
  )..where((t) => t.userId.equals(userId) & t.id.equals(feedId))).write(
        RssFeedsTableCompanion(
          enabled: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Delete feed, scoped to the owning user.
  Future<int> deleteFeed(String userId, String feedId) =>
      (delete(
        rssFeedsTable,
      )..where((t) => t.userId.equals(userId) & t.id.equals(feedId))).go();

  // ── Articles ─────────────────────────────────────────────────────────

  /// Watches all articles from the user's enabled feeds, ordered by publish
  /// time desc.
  Stream<List<RssArticlesTableData>> watchAllArticles(
    String userId, {
    int limit = 200,
  }) {
    final q = customSelect(
      '''
      SELECT a.* FROM rss_articles a
      INNER JOIN rss_feeds f ON f.id = a.feed_id
      WHERE f.user_id = ? AND f.enabled = 1
      ORDER BY COALESCE(a.published_at, a.created_at) DESC
      LIMIT ?
      ''',
      variables: [Variable<String>(userId), Variable<int>(limit)],
      readsFrom: {rssArticlesTable, rssFeedsTable},
    );
    return q.watch().map(
      (rows) => rows.map((r) => rssArticlesTable.map(r.data)).toList(),
    );
  }

  /// Watches only the user's bookmarked articles.
  Stream<List<RssArticlesTableData>> watchSavedArticles(String userId) {
    final q = customSelect(
      '''
      SELECT a.* FROM rss_articles a
      INNER JOIN rss_feeds f ON f.id = a.feed_id
      WHERE f.user_id = ? AND a.saved = 1
      ORDER BY COALESCE(a.published_at, a.created_at) DESC
      ''',
      variables: [Variable<String>(userId)],
      readsFrom: {rssArticlesTable, rssFeedsTable},
    );
    return q.watch().map(
      (rows) => rows.map((r) => rssArticlesTable.map(r.data)).toList(),
    );
  }

  /// Get article by id, scoped to the owning user via its feed.
  Future<RssArticlesTableData?> getArticleById(String userId, String id) async {
    final rows = await customSelect(
      '''
      SELECT a.* FROM rss_articles a
      INNER JOIN rss_feeds f ON f.id = a.feed_id
      WHERE f.user_id = ? AND a.id = ?
      LIMIT 1
      ''',
      variables: [Variable<String>(userId), Variable<String>(id)],
      readsFrom: {rssArticlesTable, rssFeedsTable},
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    return rssArticlesTable.map(rows.first.data);
  }

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
      await into(
        rssArticlesTable,
      ).insert(entry, mode: InsertMode.insertOrIgnore);
      return;
    }
    await (update(
      rssArticlesTable,
    )..where((t) => t.id.equals(existing.id))).write(
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

  /// Bulk variant of [upsertArticleFromFeed] that runs every entry inside a
  /// single transaction.
  ///
  /// Drift coalesces stream-query update notifications at transaction commit,
  /// so this collapses what would be `entries.length` separate
  /// [watchAllArticles] emissions into a single one. A feed refresh of N
  /// articles therefore rebuilds the newsfeed list once per feed instead of N
  /// times — the difference between a smooth refresh and the UI freezing.
  Future<void> upsertArticlesFromFeed(
    Iterable<RssArticlesTableCompanion> entries,
  ) {
    return attachedDatabase.transaction(() async {
      for (final entry in entries) {
        await upsertArticleFromFeed(entry);
      }
    });
  }

  /// Toggles the saved/bookmarked flag on one of the user's articles.
  Future<void> setArticleSaved(
    String userId,
    String articleId, {
    required bool saved,
  }) => customUpdate(
    'UPDATE rss_articles SET saved = ? WHERE id = ? AND feed_id IN '
        '(SELECT id FROM rss_feeds WHERE user_id = ?)',
    variables: [Variable<bool>(saved), Variable<String>(articleId), Variable<String>(userId)],
    updates: {rssArticlesTable},
  );

  /// Toggles the read flag on one of the user's articles.
  Future<void> setArticleRead(
    String userId,
    String articleId, {
    required bool read,
  }) => customUpdate(
    'UPDATE rss_articles SET read = ? WHERE id = ? AND feed_id IN '
        '(SELECT id FROM rss_feeds WHERE user_id = ?)',
    variables: [Variable<bool>(read), Variable<String>(articleId), Variable<String>(userId)],
    updates: {rssArticlesTable},
  );

  /// Marks every one of the user's articles as read.
  Future<void> markAllRead(String userId) => customUpdate(
    'UPDATE rss_articles SET read = 1 WHERE feed_id IN '
        '(SELECT id FROM rss_feeds WHERE user_id = ?)',
    variables: [Variable<String>(userId)],
    updates: {rssArticlesTable},
  );
}
