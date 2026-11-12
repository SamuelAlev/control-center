import 'package:cc_persistence/database/tables/webhook_deliveries_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'webhook_delivery_dao.g.dart';

/// Data access for the inbound webhook delivery log.
@DriftAccessor(tables: [WebhookDeliveriesTable])
class WebhookDeliveryDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WebhookDeliveryDaoMixin {
  /// Creates a [WebhookDeliveryDao].
  WebhookDeliveryDao(super.db);

  /// Records a new delivery.
  Future<void> record(WebhookDeliveriesTableCompanion delivery) =>
      into(webhookDeliveriesTable).insert(delivery);

  /// Updates a delivery's mutable fields (status / run id / response).
  Future<void> updateDelivery(
    String id,
    WebhookDeliveriesTableCompanion delivery,
  ) => (update(
    webhookDeliveriesTable,
  )..where((d) => d.id.equals(id))).write(delivery);

  /// A delivery by id, scoped to its workspace.
  Future<WebhookDeliveriesTableData?> getById(String workspaceId, String id) =>
      (select(webhookDeliveriesTable)
            ..where((d) => d.id.equals(id) & d.workspaceId.equals(workspaceId)))
          .getSingleOrNull();

  /// Recent deliveries for a trigger, newest first, workspace-scoped.
  Future<List<WebhookDeliveriesTableData>> forTrigger(
    String workspaceId,
    String triggerId,
  ) =>
      (select(webhookDeliveriesTable)
            ..where(
              (d) =>
                  d.workspaceId.equals(workspaceId) &
                  d.triggerId.equals(triggerId),
            )
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .get();

  /// Streams recent deliveries for a workspace, newest first.
  Stream<List<WebhookDeliveriesTableData>> watchForWorkspace(
    String workspaceId,
  ) =>
      (select(webhookDeliveriesTable)
            ..where((d) => d.workspaceId.equals(workspaceId))
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .watch();

  /// The `WHERE` of `uq_webhook_deliveries_dedupe`, spelled exactly as the
  /// index spells it: a conflict target with a condition must match it.
  static const CustomExpression<bool> _dedupeHeld = CustomExpression<bool>(
    "dedupe_key IS NOT NULL AND status IN ('queued', 'dispatched')",
  );

  /// Records [delivery] unless its trigger already has a delivery holding the
  /// same dedupe key (in flight or dispatched); returns whether it was
  /// recorded.
  ///
  /// One insert whose conflict target is the partial unique index
  /// `uq_webhook_deliveries_dedupe` on `(trigger_id, dedupe_key)` (the target
  /// repeats its `WHERE`, which is how SQLite names a partial index), so of
  /// two concurrent identical deliveries exactly one is recorded, and only
  /// that one may dispatch. A conflict on anything else (a reused id) still
  /// throws instead of reading as "duplicate".
  ///
  /// The conflict action is an update that never applies (`WHERE 0`), which
  /// is SQLite's `DO NOTHING` for a target with a condition: no row is written
  /// and none is returned.
  Future<bool> claim(WebhookDeliveriesTableCompanion delivery) async {
    final row = await into(webhookDeliveriesTable).insertReturningOrNull(
      delivery,
      onConflict: DoUpdate(
        (old) => WebhookDeliveriesTableCompanion.custom(id: old.id),
        target: [
          webhookDeliveriesTable.triggerId,
          webhookDeliveriesTable.dedupeKey,
        ],
        targetCondition: (_) => _dedupeHeld,
        where: (_) => const Constant(false),
      ),
    );
    return row != null;
  }

  /// Deletes delivery-log rows created before [cutoff] (retention). This is an
  /// append-only audit log that otherwise grows without bound. Returns the
  /// number of rows deleted.
  ///
  /// Retention: drops this workspace's old rows. The nightly sweep runs it once
  /// per workspace.
  Future<int> deleteOlderThan(DateTime cutoff) => (delete(
    webhookDeliveriesTable,
  )..where((d) => d.createdAt.isSmallerThanValue(cutoff))).go();
}
