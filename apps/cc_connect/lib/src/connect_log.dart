import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:crypto/crypto.dart' as crypto;

/// Where log lines go.
typedef ConnectLogSink = void Function(String line);

/// Structured JSON logging with an allowlist: only these fields are ever
/// written, and only short identifier-shaped values. Codes, tokens, seals,
/// states, cookies, message text and raw install ids cannot reach a log line
/// through this API.
const Set<String> connectLogFields = {
  'route',
  'method',
  'status',
  'ms',
  'lane',
  'provider',
  'error',
  'reason',
  'install',
  'team',
  'installation_id',
  'repo_id',
  'github_user_id',
  'scope',
  'granted_scope',
  'count',
  'generation',
  'ip',
  'epoch',
  'backend',
  'host',
  'port',
  'version',
};

final RegExp _safeValue = RegExp(r'^[A-Za-z0-9_.:/\-]{0,80}$');
final RegExp _eventName = RegExp(r'^[a-z][a-z0-9_.]{0,63}$');

/// The Connect logger.
final class ConnectLog {
  /// Creates a logger. [hmacKey] keys install-id and team-id hashing; a
  /// per-process random key (unlinkable across restarts) when omitted.
  ConnectLog({
    ConnectLogSink? sink,
    List<int>? hmacKey,
    DateTime Function()? clock,
  }) : _sink = sink ?? stderr.writeln,
       _hmac = crypto.Hmac(
         crypto.sha256,
         hmacKey == null || hmacKey.isEmpty ? randomBytes(32) : hmacKey,
       ),
       _clock = clock ?? DateTime.now;

  final ConnectLogSink _sink;
  final crypto.Hmac _hmac;
  final DateTime Function() _clock;

  /// A stable, unlinkable tag for an opaque id (install id, team id).
  String tag(String id) =>
      _hmac.convert(utf8.encode(id)).toString().substring(0, 16);

  /// Writes one event. Unknown fields and unsafe values are dropped.
  void event(String name, [Map<String, Object?> fields = const {}]) {
    if (!_eventName.hasMatch(name)) {
      return;
    }
    final out = <String, Object?>{
      'ts': _clock().toUtc().toIso8601String(),
      'event': name,
    };
    fields.forEach((key, value) {
      if (!connectLogFields.contains(key) || value == null) {
        return;
      }
      if (value is num || value is bool) {
        out[key] = value;
      } else if (value is String && _safeValue.hasMatch(value)) {
        out[key] = value;
      }
    });
    _sink(jsonEncode(out));
  }
}

/// Truncates an IP for logs: /24 for IPv4, /48 for IPv6.
String truncateIp(String ip) {
  if (ip.contains(':')) {
    final parts = ip.split(':');
    return '${parts.take(3).join(':')}::/48';
  }
  final parts = ip.split('.');
  if (parts.length != 4) {
    return '';
  }
  return '${parts.take(3).join('.')}.0/24';
}
