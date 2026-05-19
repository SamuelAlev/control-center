import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/webhook_delivery.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/webhook_delivery_repository.dart';
import 'package:cc_server_core/src/webhook_delivery_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTriggerRepo implements PipelineTriggerRepository {
  _FakeTriggerRepo(this._byToken);
  final Map<String, PipelineTrigger> _byToken;

  @override
  Future<PipelineTrigger?> byWebhookToken(String token) async =>
      _byToken[token];

  @override
  Future<PipelineTrigger?> getById(String workspaceId, String id) async {
    for (final t in _byToken.values) {
      if (t.id == id) {
        return t;
      }
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeliveryRepo implements WebhookDeliveryRepository {
  _FakeDeliveryRepo({Set<String> existingDedupe = const {}})
    : _existing = existingDedupe;
  final Set<String> _existing;
  final List<WebhookDelivery> recorded = [];

  @override
  Future<void> record(WebhookDelivery delivery) async => recorded.add(delivery);

  @override
  Future<void> update(WebhookDelivery delivery) async {
    recorded
      ..removeWhere((d) => d.id == delivery.id)
      ..add(delivery);
  }

  @override
  Future<bool> existsByDedupeKey(
    String workspaceId,
    String triggerId,
    String dedupeKey,
  ) async => _existing.contains(dedupeKey);

  @override
  Future<WebhookDelivery?> getById(String workspaceId, String id) async {
    for (final d in recorded) {
      if (d.id == id && d.workspaceId == workspaceId) {
        return d;
      }
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PipelineTrigger _webhookTrigger({
  String token = 'secret-token',
  Map<String, dynamic> eventFilters = const {},
}) => PipelineTrigger(
  id: 'trg1',
  eventType: PipelineTrigger.webhookEventType,
  templateId: 'on_webhook',
  workspaceId: 'ws1',
  enabled: true,
  webhookToken: token,
  eventFilters: eventFilters,
);

String _sign(String body, String secret) =>
    'sha256=${Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(body))}';

void main() {
  const token = 'secret-token';
  const body = '{"action":"opened"}';

  ({
    WebhookDeliveryService service,
    _FakeDeliveryRepo deliveries,
    List<String> started,
  })
  build({
    Map<String, PipelineTrigger>? byToken,
    Set<String> existingDedupe = const {},
  }) {
    final deliveries = _FakeDeliveryRepo(existingDedupe: existingDedupe);
    final started = <String>[];
    final service = WebhookDeliveryService(
      triggerRepository: _FakeTriggerRepo(
        byToken ?? {token: _webhookTrigger()},
      ),
      deliveryRepository: deliveries,
      startRun:
          ({
            required templateId,
            required workspaceId,
            triggerEventType,
            triggerPayload,
            dedupKey,
          }) async {
            started.add(templateId);
            return null;
          },
      idGenerator: () => 'delivery-id',
    );
    return (service: service, deliveries: deliveries, started: started);
  }

  test('valid signature → dispatched (202) and a run is started', () async {
    final h = build();
    final result = await h.service.handle(
      token: token,
      headers: {'X-Hub-Signature-256': _sign(body, token)},
      body: body,
    );
    expect(result.statusCode, 202);
    expect(h.started, ['on_webhook']);
    expect(
      h.deliveries.recorded.single.status,
      WebhookDeliveryStatus.dispatched,
    );
    expect(
      h.deliveries.recorded.single.signatureStatus,
      WebhookSignatureStatus.valid,
    );
  });

  test(
    'invalid signature → rejected (401), logged, NOT replayable, no run',
    () async {
      final h = build();
      final result = await h.service.handle(
        token: token,
        headers: {'X-Hub-Signature-256': 'sha256=deadbeef'},
        body: body,
      );
      expect(result.statusCode, 401);
      expect(h.started, isEmpty);
      final delivery = h.deliveries.recorded.single;
      expect(delivery.status, WebhookDeliveryStatus.rejected);
      expect(delivery.signatureStatus, WebhookSignatureStatus.invalid);
      expect(delivery.replayable, isFalse);
    },
  );

  test('missing signature → rejected, no run', () async {
    final h = build();
    final result = await h.service.handle(
      token: token,
      headers: {},
      body: body,
    );
    expect(result.statusCode, 401);
    expect(h.started, isEmpty);
    expect(
      h.deliveries.recorded.single.signatureStatus,
      WebhookSignatureStatus.missing,
    );
  });

  test('unknown token → 404 with no delivery logged', () async {
    final h = build();
    final result = await h.service.handle(
      token: 'wrong',
      headers: {'X-Hub-Signature-256': _sign(body, 'wrong')},
      body: body,
    );
    expect(result.statusCode, 404);
    expect(h.deliveries.recorded, isEmpty);
  });

  test(
    'duplicate delivery (valid signature) → ignored (200), no run',
    () async {
      final h = build(existingDedupe: {'dup-123'});
      final result = await h.service.handle(
        token: token,
        headers: {
          'X-Hub-Signature-256': _sign(body, token),
          'X-GitHub-Delivery': 'dup-123',
        },
        body: body,
      );
      expect(result.statusCode, 200);
      expect(h.started, isEmpty);
      expect(
        h.deliveries.recorded.single.status,
        WebhookDeliveryStatus.ignored,
      );
    },
  );

  test('event filter excludes the action → ignored (200), no run', () async {
    final h = build(
      byToken: {
        token: _webhookTrigger(
          eventFilters: {
            'events': ['push'],
          },
        ),
      },
    );
    final result = await h.service.handle(
      token: token,
      headers: {
        'X-Hub-Signature-256': _sign(body, token),
        'X-GitHub-Event': 'pull_request', // not in the allowed list
      },
      body: body,
    );
    expect(result.statusCode, 200);
    expect(h.started, isEmpty);
    expect(h.deliveries.recorded.single.status, WebhookDeliveryStatus.ignored);
  });

  test(
    'replay refuses a delivery that failed signature verification',
    () async {
      final h = build();
      // Log an invalid-signature delivery first.
      await h.service.handle(
        token: token,
        headers: {'X-Hub-Signature-256': 'sha256=bad'},
        body: body,
      );
      final result = await h.service.replay('ws1', 'delivery-id');
      expect(result.statusCode, 409);
      expect(h.started, isEmpty);
    },
  );
}
