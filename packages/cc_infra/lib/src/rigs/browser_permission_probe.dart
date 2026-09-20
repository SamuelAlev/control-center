import 'dart:convert';

/// A page asked the enclosed browser for a capability.
class BrowserPermissionProbe {
  /// Creates a [BrowserPermissionProbe].
  const BrowserPermissionProbe({
    required this.id,
    required this.origin,
    required this.kind,
    this.contextId,
  });

  /// Parses an interceptor payload, or null when it is not a permission ask.
  static BrowserPermissionProbe? parse(Object? raw, {int? contextId}) {
    Map<String, dynamic>? map;
    if (raw is String && raw.isEmpty) {
      return null;
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = decoded.cast<String, dynamic>();
        }
      } on FormatException {
        return null;
      }
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    }
    if (map == null) {
      return null;
    }
    final id = map['id'];
    final kind = map['kind'];
    if (id is! String || id.isEmpty || kind is! String || kind.isEmpty) {
      return null;
    }
    return BrowserPermissionProbe(
      id: id,
      origin: map['origin'] is String ? map['origin'] as String : '',
      kind: kind,
      contextId:
          contextId ??
          (map['context_id'] is int ? map['context_id'] as int : null),
    );
  }

  /// The interceptor's request id.
  final String id;

  /// Page origin that asked.
  final String origin;

  /// Permissions-API kind string.
  final String kind;

  /// Chromium execution context, when known.
  final int? contextId;
}
