import 'package:drift/drift.dart';

/// Drift table for the generic stale-while-revalidate cache.
///
/// Stores opaque JSON payloads keyed by the triple
/// `(workspaceId, kind, key)`. Consumers (repositories) decide the
/// payload shape — this table never inspects it.
class CachesTable extends Table {
  /// Workspace this entry belongs to.
  TextColumn get workspaceId => text()();

  /// Logical kind, e.g. `prDetail`, `prFiles`, `prDiff`.
  TextColumn get kind => text()();

  /// Sub-key within the kind, e.g. the PR number as a string.
  TextColumn get key => text()();

  /// Serialized payload (JSON string, raw text, …).
  TextColumn get payload => text()();

  /// When the entry was last refreshed.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {workspaceId, kind, key};
}
