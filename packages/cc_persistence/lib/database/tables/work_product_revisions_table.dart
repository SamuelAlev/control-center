import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/work_products_table.dart';
import 'package:drift/drift.dart';

/// Drift table for versioned work-product revisions — one immutable row per
/// saved version of a [WorkProductsTable] artifact.
///
/// Each revision records the [baseRevisionId] it was edited from, so a write
/// that targets a stale base can be rejected (optimistic concurrency) and the
/// full history enables restore-to-revision (undo). Revisions cascade-delete
/// with their parent work product.
///
/// A revision number is unique within its work product: two writers that
/// computed the same next number cannot both land, and the second write is
/// refused as a concurrency conflict. That key is also the index the
/// newest-first history reads use.
@TableIndex(name: 'idx_work_product_revisions_base', columns: {#baseRevisionId})
class WorkProductRevisionsTable extends Table {
  /// Unique revision identifier.
  TextColumn get id => text()();

  /// Work product this revision belongs to.
  TextColumn get workProductId =>
      text().references(WorkProductsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace (mirrors the parent work product's workspace).
  TextColumn get workspaceId => text()();

  /// Monotonic revision number within the work product (1-based).
  IntColumn get revisionNumber => integer()();

  /// The revision's full content (markdown).
  TextColumn get content => text()();

  /// The revision this one was edited from (optimistic-concurrency base), or
  /// null for the first revision.
  /// `SET NULL`: history keeps a revision whose base is gone.
  TextColumn get baseRevisionId => text().nullable().references(
    WorkProductRevisionsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Actor type that authored the revision: an `ActorKind` wire name.
  TextColumn get authorType => text()
      // ignore: recursive_getters
      .check(authorType.isIn(AgentsStoredValues.actorKind))
      .withDefault(const Constant('agent'))();

  /// Identifier of the authoring actor, if known. No foreign key: a user id
  /// lives in `global.db`.
  TextColumn get authorId => text().nullable()();

  /// Optional short summary of what changed.
  TextColumn get summary => text().nullable()();

  /// When the revision was written.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'work_product_revisions';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workProductId, revisionNumber},
  ];
}
