import 'dart:convert';

/// An opaque pagination cursor pointing at one message by its stable sort key.
///
/// History is ordered `(createdAt, rowid)`; `createdAt` is only second-grained,
/// so the implicit `rowid` is the real tie-breaker. A cursor therefore carries
/// both, and "load earlier" fetches strictly-older rows: `createdAt < time OR
/// (createdAt == time AND rowid < rowid)`. The wire form is a base64url JSON
/// blob so callers treat it as opaque.
class MessageCursor {
  /// Creates a [MessageCursor].
  const MessageCursor({required this.createdAtMs, required this.rowid});

  /// `createdAt` of the boundary message, in epoch milliseconds.
  final int createdAtMs;

  /// Implicit SQLite rowid of the boundary message (stable tie-breaker).
  final int rowid;

  /// Encodes this cursor to its opaque base64url token.
  String encode() {
    final json = jsonEncode({'t': createdAtMs, 'r': rowid});
    return base64Url.encode(utf8.encode(json));
  }

  /// Decodes an opaque [token] back to a [MessageCursor], or null when the
  /// token is malformed (callers treat a bad cursor as "start from newest").
  static MessageCursor? decode(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(token)));
      if (decoded is! Map) {
        return null;
      }
      final t = (decoded['t'] as num?)?.toInt();
      final r = (decoded['r'] as num?)?.toInt();
      if (t == null || r == null) {
        return null;
      }
      return MessageCursor(createdAtMs: t, rowid: r);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageCursor &&
          createdAtMs == other.createdAtMs &&
          rowid == other.rowid;

  @override
  int get hashCode => Object.hash(createdAtMs, rowid);
}
