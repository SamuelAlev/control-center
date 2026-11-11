import 'dart:async';
import 'dart:convert';

import 'package:cc_connect/src/connect_log.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// A parsed Sentry DSN (`https://<public key>@<host>/<project id>`).
final class SentryDsn {
  SentryDsn._(this.publicKey, this.host, this.envelopeUrl);

  /// Parses [raw], or null when it is not an https DSN with a numeric
  /// project id.
  static SentryDsn? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return null;
    }
    final key = uri.userInfo.split(':').first;
    final segments = [
      for (final segment in uri.pathSegments)
        if (segment.isNotEmpty) segment,
    ];
    if (key.isEmpty ||
        segments.isEmpty ||
        !RegExp(r'^\d+$').hasMatch(segments.last) ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return SentryDsn._(
      key,
      uri.host,
      Uri(
        scheme: 'https',
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        pathSegments: [
          ...segments.take(segments.length - 1),
          'api',
          segments.last,
          'envelope',
          '',
        ],
      ),
    );
  }

  /// The public key (`sentry_key`).
  final String publicKey;

  /// The ingest host (added to the upstream allowlist).
  final String host;

  /// `https://<host>/api/<project>/envelope/`.
  final Uri envelopeUrl;
}

final RegExp _frame = RegExp(r'^#\d+\s+(.+?) \((.+?):(\d+)(?::\d+)?\)$');

/// Reports error-level log lines to Sentry without the SDK. An event holds,
/// by construction, only an event id, timestamp, level, logger, release,
/// environment, the `route`, `request_id` and `error` tags, and for an
/// exception its runtime type and code positions: never its message, a
/// request body, header, cookie, query or install id.
///
/// Fire-and-forget: at most [maxInFlight] sends at once, each bounded by
/// [timeout]; at most [maxPerMinute] events a minute, one per (type, route).
/// A failed send is logged once a minute at warn and never reaches the
/// request.
final class SentryReporter {
  /// Creates a reporter.
  SentryReporter({
    required this.dsn,
    required this._http,
    required this._log,
    required this.release,
    required this.environment,
    DateTime Function()? clock,
    this.maxInFlight = 4,
    this.maxPerMinute = 30,
    this.timeout = const Duration(seconds: 5),
  }) : _clock = clock ?? DateTime.now;

  /// Where events go.
  final SentryDsn dsn;

  /// `CONNECT_VERSION`.
  final String release;

  /// `hosted`, `self-hosted` or `CONNECT_SENTRY_ENVIRONMENT`.
  final String environment;

  /// Concurrent sends.
  final int maxInFlight;

  /// Events per minute.
  final int maxPerMinute;

  /// Bound on one send.
  final Duration timeout;

  final UpstreamHttp _http;
  final ConnectLog _log;
  final DateTime Function() _clock;
  final Set<String> _seen = {};
  DateTime? _windowStart;
  int _inFlight = 0;

  /// Queues [failure] unless a bound holds it back.
  void report(ConnectFailure failure) {
    final now = _clock();
    final start = _windowStart;
    if (start == null || now.difference(start) >= const Duration(minutes: 1)) {
      _windowStart = now;
      _seen.clear();
    }
    if (_inFlight >= maxInFlight ||
        _seen.length >= maxPerMinute ||
        !_seen.add('${failure.type}\u0000${failure.route}')) {
      return;
    }
    _inFlight++;
    unawaited(_send(envelope(failure, now)).whenComplete(() => _inFlight--));
  }

  Future<void> _send(List<int> body) async {
    try {
      final response = await _http
          .send(
            UpstreamRequest(
              'POST',
              dsn.envelopeUrl,
              headers: {
                'content-type': 'application/x-sentry-envelope',
                'x-sentry-auth':
                    'Sentry sentry_version=7, sentry_key=${dsn.publicKey}, '
                    'sentry_client=cc-connect/$release',
              },
              body: body,
            ),
          )
          .timeout(timeout);
      if (!response.ok) {
        _failed('status_${response.status}');
      }
    } on TimeoutException {
      _failed('timeout');
    } on UpstreamUnavailable {
      _failed('unavailable');
    } on Object {
      _failed('error');
    }
  }

  void _failed(String reason) =>
      _log.sampled('sentry.report_failed', '', {'reason': reason});

  /// The envelope for [failure] (exposed for tests).
  List<int> envelope(ConnectFailure failure, DateTime now) {
    final eventId = [
      for (final byte in randomBytes(16))
        byte.toRadixString(16).padLeft(2, '0'),
    ].join();
    final timestamp = now.toUtc().toIso8601String();
    final frames = _frames(failure.stack);
    final event = <String, Object?>{
      'event_id': eventId,
      'timestamp': timestamp,
      'level': failure.level == ConnectLogLevel.error ? 'error' : 'warning',
      'logger': 'cc_connect',
      'release': release,
      'environment': environment,
      'tags': {
        'route': ?failure.route,
        'request_id': ?failure.requestId,
        'error': ?failure.error,
      },
      'exception': {
        'values': [
          {
            'type': failure.type.length > 100
                ? failure.type.substring(0, 100)
                : failure.type,
            if (frames.isNotEmpty) 'stacktrace': {'frames': frames},
          },
        ],
      },
    };
    return utf8.encode(
      '${jsonEncode({'event_id': eventId, 'sent_at': timestamp})}\n'
      '${jsonEncode({'type': 'event'})}\n'
      '${jsonEncode(event)}\n',
    );
  }

  /// Function, file and line of each Dart frame, oldest first.
  static List<Map<String, Object>> _frames(StackTrace? stack) {
    if (stack == null) {
      return const [];
    }
    final frames = <Map<String, Object>>[];
    for (final line in LineSplitter.split(stack.toString())) {
      final match = _frame.firstMatch(line.trim());
      if (match == null) {
        continue;
      }
      frames.add({
        'function': match.group(1)!,
        'filename': match.group(2)!,
        'lineno': int.parse(match.group(3)!),
      });
      if (frames.length == 64) {
        break;
      }
    }
    return frames.reversed.toList();
  }
}
