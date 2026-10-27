import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:http/http.dart' as http;

/// [AnalyticsSink] for an [Umami](https://umami.is) instance.
///
/// Posts each envelope to `<host>/api/send`, serially, from a bounded
/// in-memory queue:
///
/// - a network failure, a timeout, `429` or a `5xx` keeps the record and
///   retries with exponential backoff (1 s doubling to 5 min, with jitter);
/// - any other `4xx` drops the record, since resending a payload the server
///   refused cannot succeed;
/// - when the queue is full the oldest record is dropped.
///
/// Nothing is persisted: a record still queued when the process exits is
/// lost, which is the right trade for analytics.
///
/// Mapping: a screen view becomes a page view (`url` = route template,
/// `title` = screen name); an event becomes a custom event (`name`, `data`)
/// placed on the screen it happened on. The surface is the Umami hostname,
/// so the dashboard splits desktop / web / remote / server natively. The
/// pseudonymous device ID is the Umami distinct ID, and the `timestamp` is
/// the recording time, so a retried record still lands when it happened.
class UmamiAnalyticsSink implements AnalyticsSink {
  /// Creates a sink for [websiteId] on the instance at [host].
  ///
  /// [userAgent] is sent on native platforms, where Umami derives OS and
  /// device from it; pass null on the web, where the browser sets its own.
  /// Inject [client] to control transport (the server passes rhttp's
  /// compatible client). A sink built with a [client] does not close it.
  UmamiAnalyticsSink({
    required Uri host,
    required this.websiteId,
    this.userAgent,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
    this.maxQueue = 200,
    this._onDiagnostic,
    Random? random,
  }) : endpoint = host.resolve('api/send'),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _random = random ?? Random();

  /// The `/api/send` URL.
  final Uri endpoint;

  /// Umami website ID.
  final String websiteId;

  /// User-Agent for native platforms; null on the web.
  final String? userAgent;

  /// Per-request deadline.
  final Duration requestTimeout;

  /// Most records waiting for delivery.
  final int maxQueue;

  static const _initialBackoff = Duration(seconds: 1);
  static const _maxBackoff = Duration(minutes: 5);

  final http.Client _client;
  final bool _ownsClient;
  final void Function(String message)? _onDiagnostic;
  final Random _random;
  final _queue = Queue<AnalyticsEnvelope>();

  /// Session cache token Umami returns, echoed back as `x-umami-cache`.
  String? _cacheToken;
  Future<void>? _pump;
  Timer? _retryTimer;
  Duration _backoff = _initialBackoff;
  var _closed = false;

  /// Records waiting for delivery.
  int get queued => _queue.length;

  @override
  void record(AnalyticsEnvelope envelope) {
    if (_closed) {
      return;
    }
    if (_queue.length >= maxQueue) {
      _queue.removeFirst();
      _diagnose('queue full; dropped the oldest record');
    }
    _queue.add(envelope);
    if (_retryTimer == null) {
      _schedulePump();
    }
  }

  @override
  Future<void> flush() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await (_pump ?? _schedulePump());
  }

  @override
  Future<void> close({bool flush = true}) async {
    if (_closed) {
      return;
    }
    if (flush) {
      await this.flush().timeout(requestTimeout, onTimeout: () {});
    }
    _closed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _queue.clear();
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<void> _schedulePump() => _pump ??= _drain().whenComplete(() {
    _pump = null;
  });

  Future<void> _drain() async {
    while (_queue.isNotEmpty && !_closed) {
      final envelope = _queue.first;
      final outcome = await _send(envelope);
      if (_closed) {
        return;
      }
      switch (outcome) {
        case _Outcome.delivered:
          _queue.removeFirst();
          _backoff = _initialBackoff;
        case _Outcome.rejected:
          _queue.removeFirst();
        case _Outcome.retry:
          _scheduleRetry();
          return;
      }
    }
  }

  void _scheduleRetry() {
    final jitterMs = _random.nextInt(_backoff.inMilliseconds ~/ 2 + 1);
    _retryTimer = Timer(_backoff + Duration(milliseconds: jitterMs), () {
      _retryTimer = null;
      _schedulePump();
    });
    final doubled = _backoff * 2;
    _backoff = doubled > _maxBackoff ? _maxBackoff : doubled;
  }

  Future<_Outcome> _send(AnalyticsEnvelope envelope) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': ?userAgent,
              'x-umami-cache': ?_cacheToken,
            },
            body: jsonEncode(umamiPayload(envelope, websiteId: websiteId)),
          )
          .timeout(requestTimeout);
    } on Object catch (e) {
      _diagnose('send failed (${e.runtimeType}); will retry');
      return _Outcome.retry;
    }
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      _rememberCacheToken(response.body);
      return _Outcome.delivered;
    }
    if (status == 429 || status >= 500) {
      _diagnose('server answered $status; will retry');
      return _Outcome.retry;
    }
    _diagnose('server refused ${envelope.name} with $status; dropped');
    return _Outcome.rejected;
  }

  void _rememberCacheToken(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['cache'] is String) {
        _cacheToken = decoded['cache'] as String;
      }
    } on FormatException {
      // Older instances answer with an empty or plain-text body.
    }
  }

  void _diagnose(String message) => _onDiagnostic?.call('umami: $message');
}

enum _Outcome { delivered, rejected, retry }

/// The Umami `/api/send` body for [envelope].
Map<String, Object> umamiPayload(
  AnalyticsEnvelope envelope, {
  required String websiteId,
}) => {
  'type': 'event',
  'payload': {
    'website': websiteId,
    'hostname': envelope.appType.wire,
    'url': envelope.path ?? '/',
    'referrer': '',
    'language': ?envelope.locale?.replaceAll('_', '-'),
    'screen': ?envelope.screen,
    'title': ?(envelope.kind == AnalyticsEnvelopeKind.screenView
        ? envelope.name
        : null),
    'name': ?(envelope.kind == AnalyticsEnvelopeKind.event
        ? envelope.name
        : null),
    'id': ?envelope.distinctId,
    'timestamp': envelope.occurredAt.millisecondsSinceEpoch ~/ 1000,
    'data': envelope.properties,
  },
};

/// A browser-style User-Agent that lets Umami's parser recognize the OS of
/// a native Control Center process ([platform] as in `AnalyticsContext`).
/// Carries no machine detail beyond the OS family and the app version.
String umamiUserAgent({
  required String platform,
  required String appVersion,
  String product = 'ControlCenter',
}) {
  final os = switch (platform) {
    'macos' => 'Macintosh; Intel Mac OS X 10_15_7',
    'windows' => 'Windows NT 10.0; Win64; x64',
    'linux' => 'X11; Linux x86_64',
    'ios' => 'iPhone; CPU iPhone OS 18_0 like Mac OS X',
    'android' => 'Linux; Android 15',
    _ => 'X11; Linux x86_64',
  };
  return 'Mozilla/5.0 ($os) $product/$appVersion';
}
