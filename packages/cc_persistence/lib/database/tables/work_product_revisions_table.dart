import 'package:cc_persistence/database/tables/work_products_table.dart';
import 'package:drift/drift.dart';

/// Drift table for versioned work-product revisions — one immutable row per
/// saved version of a [WorkProductsTable] artifact.
///
/// Each revision records the [baseRevisionId] it was edited from, so a write
/// that targets a stale base can be rejected (optimistic concurrency) and the
/// full history enables restore-to-revision (undo). Revisions cascade-delete
/// with their parent work product.
@TableIndex(
  name: 'idx_work_product_revisions_product',
  columns: {#workProductId},
)
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
  TextColumn get baseRevisionId => text().nullable()();

  /// Actor type that authored the revision (`user`, `agent`, `system`).
  TextColumn get authorType => text().withDefault(const Constant('agent'))();

  /// Identifier of the authoring actor, if known.
  TextColumn get authorId => text().nullable()();

  /// Optional short summary of what changed.
  TextColumn get summary => text().nullable()();

  /// When the revision was written.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'work_product_revisions';

  @override
  Set<Column> get primaryKey => {id};
}
