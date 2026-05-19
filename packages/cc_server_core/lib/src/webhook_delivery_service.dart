import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/webhook_delivery.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/webhook_delivery_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Starts a pipeline run for a verified webhook delivery. Injected so the
/// delivery service is testable without the full pipeline engine; the runtime
/// wires it to `PipelineEngine.start`.
typedef WebhookPipelineStarter =
    Future<PipelineRun?> Function({
      required String templateId,
      required String workspaceId,
      String? triggerEventType,
      Map<String, dynamic>? triggerPayload,
      String? dedupKey,
    });

/// The HTTP-facing outcome of handling an inbound webhook.
class WebhookHandlerResult {
  /// Creates a [WebhookHandlerResult].
  const WebhookHandlerResult(this.statusCode, this.body);

  /// HTTP status to reply with.
  final int statusCode;

  /// Response body to reply with.
  final String body;
}

/// Verifies, deduplicates, logs and dispatches inbound webhook deliveries.
///
/// An inbound POST to `/webhooks/<token>` is routed here. The token both
/// identifies the trigger and is the HMAC secret: the request's
/// `X-Hub-Signature-256: sha256=<hex>` header is verified against
/// `HMAC-SHA256(body, token)`. A delivery that fails verification is rejected,
/// logged and is **not** replayable. Duplicates (by `dedupe_key`) are ignored.
/// A verified, non-duplicate, filter-passing delivery starts the trigger's
/// pipeline and is logged as `dispatched`.
class WebhookDeliveryService {
  /// Creates a [WebhookDeliveryService].
  WebhookDeliveryService({
    required PipelineTriggerRepository triggerRepository,
    required WebhookDeliveryRepository deliveryRepository,
    required WebhookPipelineStarter startRun,
    String Function()? idGenerator,
  }) : _triggers = triggerRepository,
       _deliveries = deliveryRepository,
       _startRun = startRun,
       _id = idGenerator ?? (() => const Uuid().v4());

  final PipelineTriggerRepository _triggers;
  final WebhookDeliveryRepository _deliveries;
  final WebhookPipelineStarter _startRun;
  final String Function() _id;

  /// Header carrying a GitHub-style HMAC-SHA256 signature.
  static const String signatureHeader = 'x-hub-signature-256';

  /// Headers consulted (in order) for an idempotency / dedupe key.
  static const List<String> _dedupeHeaders = [
    'x-github-delivery',
    'x-idempotency-key',
    'idempotency-key',
  ];

  /// Headers consulted (in order) for the event action.
  static const List<String> _eventHeaders = ['x-github-event', 'x-event-type'];

  /// Handles an inbound webhook POST.
  Future<WebhookHandlerResult> handle({
    required String token,
    required Map<String, String> headers,
    required String body,
  }) async {
    final lower = {
      for (final e in headers.entries) e.key.toLowerCase(): e.value,
    };
    final trigger = await _triggers.byWebhookToken(token);
    if (trigger == null) {
      // No enabled trigger for this token — nothing to log against.
      return const WebhookHandlerResult(404, 'unknown webhook');
    }

    final (dedupeKey, dedupeSource) = _extract(lower, _dedupeHeaders);
    final (eventAction, _) = _extract(lower, _eventHeaders);
    final signatureStatus = _verifySignature(lower, body, token);

    WebhookDelivery delivery = WebhookDelivery(
      id: _id(),
      workspaceId: trigger.workspaceId,
      triggerId: trigger.id,
      status: WebhookDeliveryStatus.queued,
      signatureStatus: signatureStatus,
      dedupeKey: dedupeKey,
      dedupeSource: dedupeSource,
      eventAction: eventAction,
      rawBody: body,
      headers: lower,
      createdAt: DateTime.now().toUtc(),
    );

    // 1. Signature gate (fail closed — not replayable).
    if (signatureStatus != WebhookSignatureStatus.valid) {
      delivery = delivery.copyWith(
        status: WebhookDeliveryStatus.rejected,
        responseStatus: 401,
        responseBody: 'invalid signature',
      );
      await _deliveries.record(delivery);
      return const WebhookHandlerResult(401, 'invalid signature');
    }

    // 2. Dedup.
    if (dedupeKey != null &&
        await _deliveries.existsByDedupeKey(
          trigger.workspaceId,
          trigger.id,
          dedupeKey,
        )) {
      delivery = delivery.copyWith(
        status: WebhookDeliveryStatus.ignored,
        responseStatus: 200,
        responseBody: 'duplicate delivery',
      );
      await _deliveries.record(delivery);
      return const WebhookHandlerResult(200, 'duplicate delivery');
    }

    // 3. Event-action filter.
    if (!_passesEventFilter(trigger, eventAction)) {
      delivery = delivery.copyWith(
        status: WebhookDeliveryStatus.ignored,
        responseStatus: 200,
        responseBody: 'event filtered',
      );
      await _deliveries.record(delivery);
      return const WebhookHandlerResult(200, 'event filtered');
    }

    // 4. Dispatch the pipeline.
    try {
      final payload = _buildPayload(trigger, body, eventAction);
      final run = await _startRun(
        templateId: trigger.templateId,
        workspaceId: trigger.workspaceId,
        triggerEventType: PipelineTrigger.webhookEventType,
        triggerPayload: payload,
        dedupKey: dedupeKey,
      );
      delivery = delivery.copyWith(
        status: WebhookDeliveryStatus.dispatched,
        runId: run?.id,
        responseStatus: 202,
        responseBody: 'accepted',
      );
      await _deliveries.record(delivery);
      return const WebhookHandlerResult(202, 'accepted');
    } on Object catch (e) {
      delivery = delivery.copyWith(
        status: WebhookDeliveryStatus.failed,
        responseStatus: 500,
        responseBody: 'dispatch failed: $e',
      );
      await _deliveries.record(delivery);
      return const WebhookHandlerResult(500, 'dispatch failed');
    }
  }

  /// Re-dispatches a previously-logged delivery. Refuses non-replayable
  /// deliveries (those that failed signature verification).
  Future<WebhookHandlerResult> replay(
    String workspaceId,
    String deliveryId,
  ) async {
    final delivery = await _deliveries.getById(workspaceId, deliveryId);
    if (delivery == null) {
      return const WebhookHandlerResult(404, 'unknown delivery');
    }
    if (!delivery.replayable) {
      return const WebhookHandlerResult(
        409,
        'delivery is not replayable (failed signature verification)',
      );
    }
    final trigger = await _triggers.getById(workspaceId, delivery.triggerId);
    if (trigger == null || trigger.workspaceId != workspaceId) {
      return const WebhookHandlerResult(404, 'unknown trigger');
    }
    final payload = _buildPayload(
      trigger,
      delivery.rawBody ?? '',
      delivery.eventAction,
    );
    final run = await _startRun(
      templateId: trigger.templateId,
      workspaceId: trigger.workspaceId,
      triggerEventType: PipelineTrigger.webhookEventType,
      triggerPayload: payload,
    );
    await _deliveries.update(
      delivery.copyWith(
        status: WebhookDeliveryStatus.dispatched,
        runId: run?.id,
      ),
    );
    return const WebhookHandlerResult(202, 'replayed');
  }

  (String?, String?) _extract(Map<String, String> headers, List<String> keys) {
    for (final key in keys) {
      final value = headers[key];
      if (value != null && value.isNotEmpty) {
        return (value, key);
      }
    }
    return (null, null);
  }

  WebhookSignatureStatus _verifySignature(
    Map<String, String> headers,
    String body,
    String secret,
  ) {
    final header = headers[signatureHeader];
    if (header == null || header.isEmpty) {
      return WebhookSignatureStatus.missing;
    }
    final provided = header.startsWith('sha256=')
        ? header.substring('sha256='.length)
        : header;
    final expected = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(body)).toString();
    return _constantTimeEquals(provided.toLowerCase(), expected.toLowerCase())
        ? WebhookSignatureStatus.valid
        : WebhookSignatureStatus.invalid;
  }

  bool _passesEventFilter(PipelineTrigger trigger, String? eventAction) {
    final filters = trigger.eventFilters;
    if (filters.isEmpty) {
      return true;
    }
    final allowed = filters['events'];
    if (allowed is List) {
      if (eventAction == null) {
        return false;
      }
      return allowed.contains(eventAction);
    }
    return true;
  }

  Map<String, dynamic> _buildPayload(
    PipelineTrigger trigger,
    String body,
    String? eventAction,
  ) {
    final payload = <String, dynamic>{
      'workspaceId': trigger.workspaceId,
      'triggerId': trigger.id,
      'rawBody': body,
    };
    if (eventAction != null) {
      payload['eventAction'] = eventAction;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        payload['payload'] = decoded;
      }
    } on FormatException {
      // Non-JSON body — only the raw text is forwarded.
    }
    return payload;
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
