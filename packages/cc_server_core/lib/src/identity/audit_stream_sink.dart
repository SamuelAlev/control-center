import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:dio/dio.dart';

/// Streams authorization audit rows to an external SIEM.
///
/// Enterprise buyers do not ask "do you have an audit log" — they ask "can I
/// get it into Splunk / Elastic / Sentinel". The transport they all accept is
/// an HTTP POST of newline-delimited JSON with a bearer token, so that is what
/// this is: one endpoint, one optional token, batched.
///
/// **Delivery is best-effort by design, and the local chain is the source of
/// truth.** A SIEM that is down must never block an agent's tool call or lose
/// the record: rows are appended locally first (that is what
/// `GuardDecisionRepository.append` does), and this ships a copy. A failed
/// batch is retried on the next flush and then dropped with a warning rather
/// than growing without bound — the durable, verifiable copy is still on
/// disk and `audit.export` can replay any range.
class AuditStreamSink {
  /// Creates an [AuditStreamSink].
  AuditStreamSink({
    required this.endpoint,
    this.token,
    this.batchSize = 50,
    this.flushInterval = const Duration(seconds: 10),
    this.maxBuffered = 1000,
    Dio? client,
    void Function(String message)? onWarn,
  }) : _dio = client ?? Dio(),
       _onWarn = onWarn;

  /// The HTTPS endpoint batches are POSTed to.
  final String endpoint;

  /// Optional bearer token.
  final String? token;

  /// How many rows are sent per request.
  final int batchSize;

  /// How often the buffer is flushed.
  final Duration flushInterval;

  /// The buffer's hard cap. Past it the OLDEST rows are dropped: an unbounded
  /// buffer in front of a dead endpoint is a memory leak, and the durable
  /// copy is on disk either way.
  final int maxBuffered;

  final Dio _dio;
  final void Function(String message)? _onWarn;
  final List<GuardDecision> _buffer = [];
  Timer? _timer;
  var _flushing = false;

  /// Starts the periodic flush.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(flushInterval, (_) => unawaited(flush()));
  }

  /// Stops the periodic flush and drains what is buffered.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await flush();
  }

  /// Queues one decision for delivery.
  void add(GuardDecision decision) {
    _buffer.add(decision);
    if (_buffer.length > maxBuffered) {
      final overflow = _buffer.length - maxBuffered;
      _buffer.removeRange(0, overflow);
      _onWarn?.call(
        'audit stream buffer full — dropped $overflow row(s); they remain in '
        'the local chain and can be replayed with audit.export',
      );
    }
    if (_buffer.length >= batchSize) {
      unawaited(flush());
    }
  }

  /// Sends everything buffered, oldest first.
  Future<void> flush() async {
    if (_flushing || _buffer.isEmpty) {
      return;
    }
    _flushing = true;
    try {
      while (_buffer.isNotEmpty) {
        final batch = _buffer.take(batchSize).toList();
        final body = batch.map((d) => jsonEncode(_toEvent(d))).join('\n');
        try {
          await _dio.post<void>(
            endpoint,
            data: body,
            options: Options(
              headers: {
                'content-type': 'application/x-ndjson',
                if (token != null && token!.isNotEmpty)
                  'authorization': 'Bearer $token',
              },
            ),
          );
        } catch (e) {
          _onWarn?.call('audit stream delivery failed ($e); will retry');
          return; // Keep the batch buffered for the next flush.
        }
        _buffer.removeRange(0, batch.length);
      }
    } finally {
      _flushing = false;
    }
  }

  /// The SIEM-facing event shape. Flat, prefixed and stable: a SIEM's field
  /// extraction is configured once and must not move under it.
  Map<String, Object?> _toEvent(GuardDecision d) => {
    'timestamp': d.occurredAt.toUtc().toIso8601String(),
    'source': 'control-center',
    'event_type': 'authorization.decision',
    'workspace_id': d.workspaceId,
    'seq': d.seq,
    'actor_type': d.actorType,
    'actor_id': d.actorId,
    'on_behalf_of': d.onBehalfOfUserId,
    'surface': d.surface.wire,
    'action': d.actionName,
    'action_classes': d.actionClasses.join(','),
    'permission': d.permission,
    'decision': d.decision.wire,
    'enforcement': d.enforcement?.wire,
    'source_scope': d.sourceScope,
    'rule_id': d.ruleId,
    'prompted': d.prompted,
    'responder': d.responderUserId,
    'device_id': d.deviceId,
    'ip': d.ip,
    'entry_hash': d.entryHash,
  };
}
