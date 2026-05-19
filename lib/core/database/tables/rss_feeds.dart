import 'package:drift/drift.dart';

/// Drift table definition for RSS/Atom feeds the user is subscribed to.
class RssFeedsTable extends Table {
  /// Unique feed identifier (uuid v4).
  TextColumn get id => text()();

  /// Display name (e.g. "The Verge").
  TextColumn get name => text()();

  /// Feed URL.
  TextColumn get url => text()();

  /// Optional description shown in feed-management UI.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Optional icon URL parsed from the feed (or favicon fallback).
  TextColumn get iconUrl => text().withDefault(const Constant(''))();

  /// Optional custom User-Agent for this feed (empty = use default).
  TextColumn get userAgent => text().withDefault(const Constant(''))();

  /// Whether this feed is active (off = not fetched, not shown).
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Last successful fetch timestamp. Null if never fetched.
  DateTimeColumn get lastFetchedAt => dateTime().nullable()();

  /// Last error message if the last fetch failed.
  TextColumn get lastError => text().nullable()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'rss_feeds';

  @override
  Set<Column> get primaryKey => {id};
}

