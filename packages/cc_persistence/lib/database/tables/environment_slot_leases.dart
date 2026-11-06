import 'package:drift/drift.dart';

/// Drift table of the host port blocks held by spaces.
///
/// **CROSS-WORKSPACE BY DESIGN**, which is why this lives in `global.db`: TCP
/// ports belong to the host, so two workspaces on one server must not be handed
/// the same block, and no per-workspace file could enforce that. Rows hold IDs
/// and port numbers only, never a name, path or any other workspace content.
///
/// Three constraints do the allocator's work: [block] is the primary key, a
/// pool slot has one holder, and a space holds one block per definition. NULLs
/// are distinct in a SQLite unique key, so leases outside a pool never collide.
class EnvironmentSlotLeasesTable extends Table {
  /// Block index in the configured range.
  IntColumn get block => integer()();

  /// First port.
  IntColumn get firstPort => integer()();

  /// Ports in the block.
  IntColumn get size => integer()();

  /// Holding workspace.
  TextColumn get workspaceId => text()();

  /// Holding space.
  TextColumn get spaceId => text()();

  /// The definition.
  TextColumn get definitionId => text()();

  /// A name pool, when the environment uses one.
  TextColumn get poolKey => text().nullable()();

  /// The pool slot.
  IntColumn get poolSlot => integer().nullable()();

  /// When it was taken.
  DateTimeColumn get createdAt => dateTime()();

  @override
  String get tableName => 'environment_slot_leases';

  @override
  Set<Column> get primaryKey => {block};

  @override
  List<Set<Column>> get uniqueKeys => [
    {poolKey, poolSlot},
    {workspaceId, spaceId, definitionId},
  ];
}
