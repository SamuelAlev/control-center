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

/// Mirrors the partial unique index: a key is held only by a delivery that is
/// in flight (`queued`) or was dispatched.
class _FakeDeliveryRepo implements WebhookDeliveryRepository {
  final List<WebhookDelivery> recorded = [];

  @override
  Future<void> record(WebhookDelivery delivery) async => recorded.add(delivery);

  @override
  Future<bool> claim(WebhookDelivery delivery) async {
    final key = delivery.dedupeKey;
    final held =
        key != null &&
        recorded.any(
          (d) =>
              d.triggerId == delivery.triggerId &&
              d.dedupeKey == key &&
              (d.status == WebhookDeliveryStatus.queued ||
                  d.status == WebhookDeliveryStatus.dispatched),
        );
    if (held) {
      return false;
    }
    recorded.add(delivery);
    return true;
  }

  @override
  Future<void> update(WebhookDelivery delivery) async {
    final index = recorded.indexWhere((d) => d.id == delivery.id);
    recorded[index] = delivery;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PipelineTrigger _webhookTrigger({
  String token = 'secret-token',
  Map<String, dynamic> eventFilters = const {},
  Set<String> armedByUserIds = const {},
}) => PipelineTrigger(
  id: 'trg1',
  eventType: PipelineTrigger.webhookEventType,
  templateId: 'on_webhook',
  workspaceId: 'ws1',
  enabled: true,
  webhookToken: token,
  eventFilters: eventFilters,
  armedByUserIds: armedByUserIds,
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
    List<bool> failRuns = const [],
  }) {
    final deliveries = _FakeDeliveryRepo();
    final started = <String>[];
    var ids = 0;
    var runs = 0;
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
            required armedByUserIds,
          }) async {
            final fail = runs < failRuns.length && failRuns[runs];
            runs++;
            if (fail) {
              throw StateError('engine down');
            }
            started.add(
              armedByUserIds.isEmpty
                  ? templateId
                  : '$templateId armed by '
                        '${(armedByUserIds.toList()..sort()).join(', ')}',
            );
            return null;
          },
      idGenerator: () => 'delivery-${ids++}',
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

  test('invalid signature → rejected (401), logged, no run', () async {
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
  });

  test('a run carries every admin who armed the webhook trigger', () async {
    final h = build(
      byToken: {
        token: _webhookTrigger(armedByUserIds: {'admin', 'other'}),
      },
    );
    final result = await h.service.handle(
      token: token,
      headers: {'X-Hub-Signature-256': _sign(body, token)},
      body: body,
    );
    expect(result.statusCode, 202);
    expect(h.started, ['on_webhook armed by admin, other']);
  });

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
    'a re-delivery of a dispatched delivery → ignored (200), no run',
    () async {
      final h = build();
      final headers = {
        'X-Hub-Signature-256': _sign(body, token),
        'X-GitHub-Delivery': 'dup-123',
      };
      await h.service.handle(token: token, headers: headers, body: body);
      final result = await h.service.handle(
        token: token,
        headers: headers,
        body: body,
      );
      expect(result.statusCode, 200);
      expect(result.body, 'duplicate delivery');
      expect(h.started, ['on_webhook']);
      expect(h.deliveries.recorded.map((d) => d.status), [
        WebhookDeliveryStatus.dispatched,
        WebhookDeliveryStatus.ignored,
      ]);
    },
  );

  test('a failed dispatch is dispatched again when retried', () async {
    final h = build(failRuns: [true]);
    final headers = {
      'X-Hub-Signature-256': _sign(body, token),
      'X-GitHub-Delivery': 'retry-1',
    };
    final first = await h.service.handle(
      token: token,
      headers: headers,
      body: body,
    );
    expect(first.statusCode, 500);
    expect(h.started, isEmpty);

    final retry = await h.service.handle(
      token: token,
      headers: headers,
      body: body,
    );
    expect(retry.statusCode, 202);
    expect(h.started, ['on_webhook']);
    expect(h.deliveries.recorded.map((d) => d.status), [
      WebhookDeliveryStatus.failed,
      WebhookDeliveryStatus.dispatched,
    ]);
  });

  test('the log keeps allow-listed headers only, and no body', () async {
    final h = build();
    await h.service.handle(
      token: token,
      headers: {
        'X-Hub-Signature-256': _sign(body, token),
        'Authorization': 'Bearer secret',
        'Cookie': 'session=secret',
        'Content-Type': 'application/json',
        'User-Agent': 'GitHub-Hookshot/1',
        'X-GitHub-Event': 'pull_request',
        'X-GitHub-Delivery': 'd-1',
        'X-Forwarded-For': '10.0.0.1',
      },
      body: body,
    );
    expect(h.deliveries.recorded.single.headers, {
      'content-type': 'application/json',
      'user-agent': 'GitHub-Hookshot/1',
      'x-github-event': 'pull_request',
      'x-github-delivery': 'd-1',
    });
  });

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
}
