// ignore_for_file: avoid_classes_with_only_static_members — a stateless rule set, not a service to inject.

import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_id.dart';

/// One property `AnalyticsPropertyPolicy` refused, and why.
class AnalyticsPolicyViolation {
  /// Creates an [AnalyticsPolicyViolation].
  const AnalyticsPolicyViolation(this.key, this.reason);

  /// The refused property key.
  final String key;

  /// Why it was refused. Never contains the value.
  final String reason;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsPolicyViolation &&
      other.key == key &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(key, reason);

  @override
  String toString() => '$key: $reason';
}

/// The PII guard every analytics property passes through.
///
/// The tracking plan is written to send only enums, counts, durations,
/// flags, versions and pseudonymized IDs. This policy enforces that shape so
/// a mistake drops the property instead of leaking it:
///
/// - string values under keys naming personal or free-form data (`email`,
///   `*_name`, `path`, `url`, `title`, `prompt`, `content`, `token`, …) are
///   refused; counts and flags under such keys (`file_count`) are fine;
/// - strings must be short tokens (`[A-Za-z0-9][A-Za-z0-9_.:+-]*`, at most
///   100 characters), which rules out free text, paths, URLs and email
///   addresses;
/// - ID-shaped strings (UUIDs, long hex/base64 runs) are refused, because an
///   ID must arrive wrapped in [AnalyticsId] to be pseudonymized;
/// - numbers must be finite; everything else is refused.
abstract final class AnalyticsPropertyPolicy {
  /// Key segments (between underscores) that mark personal or free-form
  /// data.
  static const Set<String> deniedKeySegments = {
    'address',
    'body',
    'branch',
    'content',
    'cwd',
    'dir',
    'directory',
    'email',
    'file',
    'filename',
    'handle',
    'host',
    'hostname',
    'ip',
    'login',
    'mail',
    'name',
    'password',
    'passphrase',
    'path',
    'phone',
    'prompt',
    'query',
    'secret',
    'text',
    'title',
    'token',
    'uri',
    'url',
    'username',
  };

  static final _token = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:+-]{0,99}$');
  static final _uuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}',
  );
  // No `-`/`_`: model IDs (`claude-opus-5-5-20260101`) are tokens, while
  // dashless hex/base64 runs are opaque identifiers.
  static final _longOpaque = RegExp(r'[A-Za-z0-9+/=]{24,}');
  static final _digit = RegExp('[0-9]');

  /// Checks [properties], returning the accepted subset and the refusals.
  ///
  /// [AnalyticsId] values pass through unchanged (they are hashed later);
  /// everything else in the result is a `String`, finite `num` or `bool`.
  static ({
    Map<String, Object> accepted,
    List<AnalyticsPolicyViolation> refused,
  })
  apply(Map<String, Object> properties) {
    final accepted = <String, Object>{};
    final refused = <AnalyticsPolicyViolation>[];
    for (final MapEntry(:key, :value) in properties.entries) {
      final reason = _refusal(key, value);
      if (reason == null) {
        accepted[key] = value;
      } else {
        refused.add(AnalyticsPolicyViolation(key, reason));
      }
    }
    return (accepted: accepted, refused: refused);
  }

  static String? _refusal(String key, Object value) {
    // `_id` keys may only hold an AnalyticsId, and no string may sit under a
    // key that names personal data.
    final segments = key.split('_');
    final idKey = segments.last == 'id' || segments.last == 'ids';
    switch (value) {
      case AnalyticsId():
        return null;
      case bool():
        return idKey ? 'IDs must be wrapped in AnalyticsId' : null;
      case num():
        if (!value.isFinite) {
          return 'number is not finite';
        }
        return idKey ? 'IDs must be wrapped in AnalyticsId' : null;
      case String():
        if (idKey) {
          return 'IDs must be wrapped in AnalyticsId';
        }
        if (segments.any(deniedKeySegments.contains)) {
          return 'key names personal or free-form data';
        }
        if (!_token.hasMatch(value)) {
          return 'string is not a short token';
        }
        if (_uuid.hasMatch(value) ||
            (_longOpaque.hasMatch(value) && _digit.hasMatch(value))) {
          return 'string looks like a raw identifier';
        }
        return null;
      default:
        return 'unsupported type ${value.runtimeType}';
    }
  }
}
