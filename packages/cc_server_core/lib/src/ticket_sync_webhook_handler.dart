import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
import 'package:cc_domain/features/ticketing/domain/webhook/vendor_webhook_payload.dart';
import 'package:cc_server_core/src/webhook_delivery_service.dart'
    show WebhookHandlerResult;
import 'package:crypto/crypto.dart';

/// Handles an inbound vendor ticket webhook at
/// `POST /api/webhooks/tickets/<vendor>?ws=<workspaceId>`.
///
/// Security: the request body is HMAC-SHA256 verified against the workspace's
/// configured `webhookSecret` for that vendor (GitHub's `X-Hub-Signature-256`,
/// Linear's `Linear-Signature`, or a generic `X-CC-Signature`, all hex
/// HMAC-SHA256 of the raw body). A config with no secret, or a request that
/// fails verification, is rejected — a sync webhook is never processed
/// unauthenticated. Verified deliveries are parsed into provider-neutral deltas
/// and applied through the [TicketSyncEngine] (which also de-duplicates by the
/// delivery id), then an [ExternalTicketWebhookReceived] event is published so
/// pipeline triggers can react.
class TicketSyncWebhookHandler {
  /// Creates a [TicketSyncWebhookHandler].
  TicketSyncWebhookHandler({
    required TicketSyncEngine engine,
    required TicketSyncConfigRepository configRepository,
    required DomainEventBus eventBus,
    DateTime Function()? now,
    VendorWebhookParser parser = const VendorWebhookParser(),
  }) : _engine = engine,
       _configs = configRepository,
       _eventBus = eventBus,
       _parser = parser,
       _now = now ?? DateTime.now;

  final TicketSyncEngine _engine;
  final TicketSyncConfigRepository _configs;
  final DomainEventBus _eventBus;
  final VendorWebhookParser _parser;
  final DateTime Function() _now;

  static const _signatureHeaders = [
    'x-hub-signature-256', // GitHub
    'linear-signature', // Linear
    'x-cc-signature', // generic
  ];
  static const _deliveryHeaders = [
    'x-github-delivery',
    'linear-delivery',
    'x-idempotency-key',
    'idempotency-key',
  ];

  /// Handles a verified-or-rejected webhook delivery.
  Future<WebhookHandlerResult> handle({
    required String vendor,
    required String? workspaceId,
    required Map<String, String> headers,
    required String body,
  }) async {
    if (workspaceId == null || workspaceId.isEmpty) {
      return const WebhookHandlerResult(400, 'missing ws');
    }
    final lower = {
      for (final e in headers.entries) e.key.toLowerCase(): e.value,
    };

    final config = await _configs.forVendor(workspaceId, vendor);
    if (config == null || !config.enabled) {
      return const WebhookHandlerResult(404, 'no sync config');
    }
    final secret = config.webhookSecret;
    if (secret == null || secret.isEmpty) {
      return const WebhookHandlerResult(401, 'webhook secret not configured');
    }
    if (!_verify(lower, body, secret)) {
      return const WebhookHandlerResult(401, 'invalid signature');
    }

    final deliveryId = _firstHeader(lower, _deliveryHeaders);

    Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(body);
      decoded = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    } on FormatException {
      return const WebhookHandlerResult(400, 'invalid JSON');
    }

    final parsed = _parser.parse(vendor, decoded, deliveryId: deliveryId);
    if (parsed.deltas.isEmpty) {
      // Recognized but nothing to apply (e.g. a ping / unhandled event).
      return const WebhookHandlerResult(200, 'no actionable change');
    }

    await _engine.applyPull(
      workspaceId: workspaceId,
      vendor: vendor,
      deltas: parsed.deltas,
      batchDedupeKey: deliveryId,
    );

    _eventBus.publish(
      ExternalTicketWebhookReceived(
        vendor: vendor,
        workspaceId: workspaceId,
        eventType: parsed.eventType,
        externalId: parsed.deltas.first.externalId,
        occurredAt: _now(),
      ),
    );

    return const WebhookHandlerResult(202, 'accepted');
  }

  bool _verify(Map<String, String> headers, String body, String secret) {
    final raw = _firstHeader(headers, _signatureHeaders);
    if (raw == null || raw.isEmpty) {
      return false;
    }
    final provided = raw.startsWith('sha256=')
        ? raw.substring('sha256='.length)
        : raw;
    final expected = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(body)).toString();
    return _constantTimeEquals(provided.toLowerCase(), expected.toLowerCase());
  }

  static String? _firstHeader(Map<String, String> headers, List<String> keys) {
    for (final key in keys) {
      final value = headers[key];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static bool _constantTimeEquals(String a, String b) {
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
