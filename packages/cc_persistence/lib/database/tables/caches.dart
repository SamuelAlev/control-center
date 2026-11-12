import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Drift table for the generic stale-while-revalidate cache.
///
/// Stores opaque payloads keyed by `(kind, key)` (and the file's workspace).
/// Consumers (repositories) decide the payload shape — this table never
/// inspects it, so the payload carries no JSON check: kinds hold raw text too.
///
/// Only kinds `CacheKindRegistry` declares are stored, by a check on [kind]:
/// state whose loss changes behaviour has a table of its own, and a row of a
/// kind that moved there is left behind when an existing file converges.
// The retention sweep deletes each kind's rows not written since its cutoff.
@TableIndex(name: 'idx_caches_kind_updated', columns: {#kind, #updatedAt})
class CachesTable extends Table {
  /// Workspace this entry belongs to.
  TextColumn get workspaceId => text()();

  /// Logical kind, e.g. `prDetail`, `prFiles`, `prDiff`: a declared
  /// `CacheKind` name.
  TextColumn get kind =>
      // ignore: recursive_getters
      text().check(kind.isIn(PlatformStoredValues.cacheKind))();

  /// Sub-key within the kind, e.g. the PR number as a string.
  TextColumn get key => text()();

  /// Serialized payload (JSON string, raw text, …).
  TextColumn get payload => text()();

  /// When the entry was last refreshed.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'caches';

  @override
  Set<Column> get primaryKey => {kind, key, workspaceId};
}
