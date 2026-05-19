import 'package:cc_domain/features/pipelines/domain/entities/webhook_delivery.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/webhook_delivery_repository.dart';
import 'package:cc_persistence/database/daos/webhook_delivery_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/webhook_delivery_mappers.dart';

/// Drift-backed implementation of [WebhookDeliveryRepository].
///
/// Deliveries are recorded in the workspace that owns the trigger they hit —
/// resolved from the inbound token before this repository is reached — so the
/// `workspaceId` on each method (or on the [WebhookDelivery] being written)
/// selects the database file.
class WebhookDeliveryRepositoryImpl implements WebhookDeliveryRepository {
  /// Creates a [WebhookDeliveryRepositoryImpl] over the per-workspace
  /// databases.
  WebhookDeliveryRepositoryImpl(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  WebhookDeliveryDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).webhookDeliveryDao;

  @override
  Future<void> record(WebhookDelivery delivery) =>
      _dao(delivery.workspaceId).record(webhookDeliveryToCompanion(delivery));

  @override
  Future<void> update(WebhookDelivery delivery) => _dao(
    delivery.workspaceId,
  ).updateDelivery(delivery.id, webhookDeliveryToCompanion(delivery));

  @override
  Future<WebhookDelivery?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(workspaceId, id);
    return row != null ? webhookDeliveryFromRow(row) : null;
  }

  @override
  Future<List<WebhookDelivery>> forTrigger(
    String workspaceId,
    String triggerId,
  ) async {
    final rows = await _dao(workspaceId).forTrigger(workspaceId, triggerId);
    return rows.map(webhookDeliveryFromRow).toList();
  }

  @override
  Stream<List<WebhookDelivery>> watchForWorkspace(String workspaceId) {
    return _dao(workspaceId)
        .watchForWorkspace(workspaceId)
        .map((rows) => rows.map(webhookDeliveryFromRow).toList());
  }

  @override
  Future<bool> existsByDedupeKey(
    String workspaceId,
    String triggerId,
    String dedupeKey,
  ) => _dao(workspaceId).existsByDedupeKey(triggerId, dedupeKey);
}
