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

  /// Whether a delivery with [dedupeKey] already exists for [triggerId].
  Future<bool> existsByDedupeKey(String triggerId, String dedupeKey) async {
    final row =
        await (select(webhookDeliveriesTable)
              ..where(
                (d) =>
                    d.triggerId.equals(triggerId) &
                    d.dedupeKey.equals(dedupeKey),
              )
              ..limit(1))
            .getSingleOrNull();
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
