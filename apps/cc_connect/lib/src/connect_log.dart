import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

/// Where log lines go (every level). Without one, info and warn lines go to
/// stdout and error lines to stderr.
typedef ConnectLogSink = void Function(String line);

/// How bad a line is.
enum ConnectLogLevel {
  /// Routine.
  info,

  /// Refused or degraded, handled.
  warn,

  /// Unexpected; reported to Sentry when a DSN is set.
  error,
}

/// Structured JSON logging with an allowlist: only these fields are ever
/// written, and only short identifier-shaped values. Codes, tokens, seals,
/// states, cookies, message text and raw install ids cannot reach a log line
/// through this API. A field that is not listed, or whose value is not
/// identifier-shaped, is replaced by a `log.field_dropped` line.
const Set<String> connectLogFields = {
  'as',
  'backend',
  'bucket',
  'count',
  'epoch',
  'error',
  'exception',
  'field',
  'generation',
  'github_request_id',
  'github_user_id',
  'granted_scope',
  'hashed_token',
  'install',
  'installation_id',
  'ip',
  'lane',
  'lanes',
  'method',
  'ms',
  'outcome',
  'paused',
  'provider',
  'reason',
  'repo_id',
  'request_id',
  'reused',
  'route',
  'scope',
  'source_event',
  'status',
  'suppressed',
  'team',
  'upstream',
  'upstream_status',
  'version',
};

final RegExp _safeValue = RegExp(r'^[A-Za-z0-9_.:/\-]{0,80}$');

/// The token prefixes GitHub documents (personal, OAuth, user-to-server,
/// installation and refresh tokens, fine-grained personal tokens). A value
/// carrying one at a word start is dropped even when it is identifier-shaped:
/// a user-to-server token is short enough to pass [_safeValue].
final RegExp _githubTokenPrefix = RegExp(
  r'(?:^|[^A-Za-z0-9])(?:gh[pousr]_|github_pat_)',
);

/// Fields with a value shape of their own instead of [_safeValue].
final Map<String, RegExp> _fieldShapes = {
  // Standard base64 of a SHA-256: [githubHashedToken].
  'hashed_token': RegExp(r'^[A-Za-z0-9+/]{43}=$'),
};

/// A GitHub token as GitHub's organization audit log names it
/// (`hashed_token`): base64 of its SHA-256, the same as
/// `echo -n TOKEN | openssl dgst -sha256 -binary | base64`. The only form in
/// which a token may reach a log line.
String githubHashedToken(String token) =>
    base64.encode(crypto.sha256.convert(utf8.encode(token)).bytes);
final RegExp _eventName = RegExp(r'^[a-z][a-z0-9_.]{0,63}$');

/// One request's log context: every line written while it runs carries its
/// [requestId], and its route and install tag unless the line names its own.
final class ConnectRequestScope {
  /// Creates a scope with a fresh 128-bit request id.
  ConnectRequestScope() : requestId = b64url(randomBytes(16));

  static final Object _zoneKey = Object();

  /// The scope of the running request, if any.
  static ConnectRequestScope? get current =>
      Zone.current[_zoneKey] as ConnectRequestScope?;

  /// The request id (also the `x-request-id` response header).
  final String requestId;

  /// The route label.
  String route = 'unknown';

  /// The verified caller's install tag ([ConnectLog.tag]).
  String? install;

  /// Runs [body] inside this scope.
  R run<R>(R Function() body) => runZoned(body, zoneValues: {_zoneKey: this});
}

/// What an error line hands to the error reporter: these values and nothing
/// else.
final class ConnectFailure {
  /// Creates the failure.
  const ConnectFailure({
    required this.type,
    required this.level,
    this.stack,
    this.route,
    this.requestId,
    this.error,
  });

  /// The exception's runtime type, or the event name for an error line.
  final String type;

  /// The log level.
  final ConnectLogLevel level;

  /// The exception's stack trace.
  final StackTrace? stack;

  /// The route label.
  final String? route;

  /// The request id.
  final String? requestId;

  /// The wire error code, when the line carries one.
  final String? error;
}

final class _Sample {
  _Sample(this.since);

  final DateTime since;
  int suppressed = 0;
}

/// The Connect logger.
final class ConnectLog {
  /// Creates a logger. [hmacKey] keys install-id and team-id hashing; a
  /// per-process random key (unlinkable across restarts) when omitted.
  ConnectLog({this._sink, List<int>? hmacKey, DateTime Function()? clock})
    : _hmac = crypto.Hmac(
        crypto.sha256,
        hmacKey == null || hmacKey.isEmpty ? randomBytes(32) : hmacKey,
      ),
      _clock = clock ?? DateTime.now;

  /// How long [sampled] keeps quiet about a key after writing it.
  static const Duration sampleWindow = Duration(minutes: 1);

  static const int _maxSampleKeys = 4096;

  final ConnectLogSink? _sink;
  final crypto.Hmac _hmac;
  final DateTime Function() _clock;
  final Map<String, _Sample> _samples = {};

  /// Receives every error-level line (the Sentry reporter). It must not
  /// throw and must not block.
  void Function(ConnectFailure failure)? reporter;

  /// A stable, unlinkable tag for an opaque id (install id, team id).
  String tag(String id) =>
      _hmac.convert(utf8.encode(id)).toString().substring(0, 16);

  /// Writes one line.
  void event(
    String name, [
    Map<String, Object?> fields = const {},
    ConnectLogLevel level = ConnectLogLevel.info,
  ]) => _emit(name, fields, level, null, null);

  /// Writes an unexpected [error] at error level: its runtime type only,
  /// never its message. The reporter also gets [stack].
  void exception(
    String name,
    Object error,
    StackTrace stack, [
    Map<String, Object?> fields = const {},
  ]) {
    final type = '${error.runtimeType}';
    _emit(
      name,
      {...fields, 'exception': type},
      ConnectLogLevel.error,
      type,
      stack,
    );
  }

  /// Writes [name] for [key] at most once per [sampleWindow]; the next line
  /// for the key counts the ones held back in `suppressed`.
  void sampled(
    String name,
    String key, [
    Map<String, Object?> fields = const {},
    ConnectLogLevel level = ConnectLogLevel.warn,
  ]) {
    final now = _clock();
    var id = '$name\u0000$key';
    if (!_samples.containsKey(id) && _samples.length >= _maxSampleKeys) {
      _samples.removeWhere(
        (_, sample) => now.difference(sample.since) >= sampleWindow,
      );
      if (_samples.length >= _maxSampleKeys) {
        // Too many live keys (a spray of IPs): one shared window per event.
        id = '$name\u0000*';
      }
    }
    final previous = _samples[id];
    if (previous != null && now.difference(previous.since) < sampleWindow) {
      previous.suppressed++;
      return;
    }
    _samples[id] = _Sample(now);
    final suppressed = previous?.suppressed ?? 0;
    _emit(
      name,
      {...fields, if (suppressed > 0) 'suppressed': suppressed},
      level,
      null,
      null,
    );
  }

  void _emit(
    String name,
    Map<String, Object?> fields,
    ConnectLogLevel level,
    String? type,
    StackTrace? stack,
  ) {
    if (!_eventName.hasMatch(name)) {
      sampled('log.event_dropped', '', const {});
      return;
    }
    final scope = ConnectRequestScope.current;
    final out = <String, Object?>{
      'ts': _clock().toUtc().toIso8601String(),
      'level': level.name,
      // Log platforms read `message` and `level` from a single-line JSON log.
      'message': name,
      'event': name,
      'request_id': ?scope?.requestId,
    };
    final dropped = <String>[];
    fields.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (!connectLogFields.contains(key) || key == 'request_id') {
        dropped.add(key);
      } else if (value is num || value is bool) {
        out[key] = value;
      } else if (value is String &&
          (_fieldShapes[key] ?? _safeValue).hasMatch(value) &&
          !_githubTokenPrefix.hasMatch(value)) {
        out[key] = value;
      } else {
        dropped.add(key);
      }
    });
    if (scope != null) {
      out.putIfAbsent('route', () => scope.route);
      final install = scope.install;
      if (install != null) {
        out.putIfAbsent('install', () => install);
      }
    }
    _write(jsonEncode(out), level);
    for (final key in dropped) {
      final field = _eventName.hasMatch(key) ? key : 'other';
      sampled('log.field_dropped', '$name/$field', {
        'source_event': name,
        'field': field,
      });
    }
    final report = reporter;
    if (level == ConnectLogLevel.error && report != null) {
      try {
        report(
          ConnectFailure(
            type: type ?? name,
            level: level,
            stack: stack,
            route: out['route'] as String?,
            requestId: scope?.requestId,
            error: out['error'] as String?,
          ),
        );
      } on Object {
        // Reporting never affects the caller.
      }
    }
  }

  void _write(String line, ConnectLogLevel level) {
    final sink = _sink;
    if (sink != null) {
      sink(line);
    } else if (level == ConnectLogLevel.error) {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }
}

/// Truncates an IP for logs: /24 for IPv4, /48 for IPv6; empty when [ip]
/// is not an address.
String truncateIp(String ip) {
  final address = InternetAddress.tryParse(ip);
  if (address == null) {
    return '';
  }
  final raw = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return '${raw[0]}.${raw[1]}.${raw[2]}.0/24';
  }
  final groups = [
    for (var i = 0; i < 6; i += 2)
      ((raw[i] << 8) | raw[i + 1]).toRadixString(16),
  ];
  return '${groups.join(':')}::/48';
}
