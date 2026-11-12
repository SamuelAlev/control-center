import 'package:cc_domain/features/pipelines/domain/entities/webhook_delivery.dart';

/// Persists the inbound webhook delivery log and claims dedupe keys.
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

  /// Records [delivery] (in flight, `queued`) as the one delivery holding its
  /// dedupe key for its trigger; returns false, recording nothing, when a
  /// delivery holding that key is already in flight or was dispatched.
  ///
  /// The idempotency guard for re-delivered webhooks, judged against the
  /// log of the workspace the inbound token resolved to and no other. A
  /// delivery that failed holds no key, so a provider's retry of a failed
  /// dispatch is claimed again. Atomic: two concurrent identical deliveries
  /// cannot both be claimed.
  Future<bool> claim(WebhookDelivery delivery);
}
