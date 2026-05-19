import 'package:cc_domain/features/pipelines/domain/entities/webhook_delivery.dart';

/// Persists the inbound webhook delivery log and answers the dedup query.
abstract class WebhookDeliveryRepository {
  /// Records a delivery.
  Future<void> record(WebhookDelivery delivery);

  /// Updates a delivery's mutable fields (status / run id / response).
  Future<void> update(WebhookDelivery delivery);

  /// Fetches a delivery by id (workspace-scoped: a foreign id is not matched).
  Future<WebhookDelivery?> getById(String workspaceId, String id);

  /// Recent deliveries for a trigger, newest first, workspace-scoped.
  Future<List<WebhookDelivery>> forTrigger(
    String workspaceId,
    String triggerId,
  );

  /// Streams recent deliveries for a workspace, newest first.
  Stream<List<WebhookDelivery>> watchForWorkspace(String workspaceId);

  /// Whether a delivery with [dedupeKey] already exists for [triggerId] in
  /// [workspaceId] — the idempotency guard that drops re-delivered webhooks.
  ///
  /// The workspace is the one the inbound token resolved to, so re-delivery is
  /// judged against that workspace's log and no other.
  Future<bool> existsByDedupeKey(
    String workspaceId,
    String triggerId,
    String dedupeKey,
  );
}
