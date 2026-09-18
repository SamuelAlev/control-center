import 'dart:convert';

import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';

/// Opaque keyset cursor for the workspace audit trail (`user_activity`).
///
/// Rows are ordered `(createdAt DESC, id DESC)`. [createdAt] is second-grained
/// in SQLite, so [id] is the tie-breaker. "Next page" is strictly older:
/// `createdAt < time OR (createdAt == time AND id < id)`. The wire form is a
/// base64url JSON blob so callers treat it as opaque — including the
/// `?cursor=` query param on the members settings page.
class ActivityCursor {
  /// Creates an [ActivityCursor].
  const ActivityCursor({required this.createdAtMs, required this.id});

  /// Cursor pointing at [entry]'s sort key (the exclusive start of the next
  /// older page).
  factory ActivityCursor.fromEntry(UserActivityEntry entry) => ActivityCursor(
    createdAtMs: entry.createdAt.toUtc().millisecondsSinceEpoch,
    id: entry.id,
  );

  /// `createdAt` of the boundary row, in epoch milliseconds.
  final int createdAtMs;

  /// Primary key of the boundary row (stable tie-breaker).
  final String id;

  /// The boundary instant, UTC.
  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMs, isUtc: true);

  /// Encodes this cursor to its opaque base64url token.
  String encode() {
    final json = jsonEncode({'t': createdAtMs, 'i': id});
    return base64Url.encode(utf8.encode(json));
  }

  /// Decodes an opaque [token], or null when it is missing or malformed
  /// (callers treat a bad cursor as "start from newest").
  static ActivityCursor? decode(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(token)));
      if (decoded is! Map) {
        return null;
      }
      final t = (decoded['t'] as num?)?.toInt();
      final i = decoded['i'] as String?;
      if (t == null || i == null || i.isEmpty) {
        return null;
      }
      return ActivityCursor(createdAtMs: t, id: i);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityCursor &&
          createdAtMs == other.createdAtMs &&
          id == other.id;

  @override
  int get hashCode => Object.hash(createdAtMs, id);
}
