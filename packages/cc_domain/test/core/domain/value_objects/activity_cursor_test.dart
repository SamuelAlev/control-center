import 'dart:convert';

import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/user_activity_page.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips through encode/decode', () {
    const cursor = ActivityCursor(createdAtMs: 1735689600000, id: 'act-9');
    expect(ActivityCursor.decode(cursor.encode()), cursor);
  });

  test('fromEntry uses the row sort key', () {
    final entry = UserActivityEntry(
      id: 'a-1',
      workspaceId: 'w-1',
      userId: 'u-1',
      action: 'agents.upsert',
      createdAt: DateTime.utc(2026, 1, 3, 12),
    );
    expect(
      ActivityCursor.fromEntry(entry),
      ActivityCursor(
        createdAtMs: DateTime.utc(2026, 1, 3, 12).millisecondsSinceEpoch,
        id: 'a-1',
      ),
    );
  });

  test('decode tolerates null/empty/garbage tokens', () {
    expect(ActivityCursor.decode(null), isNull);
    expect(ActivityCursor.decode(''), isNull);
    expect(ActivityCursor.decode('not-base64-!!!'), isNull);
    expect(ActivityCursor.decode('e30='), isNull); // {}
    final listToken = base64Url.encode(utf8.encode('[1,2,3]'));
    expect(ActivityCursor.decode(listToken), isNull);
  });

  test('token is opaque base64url', () {
    const cursor = ActivityCursor(createdAtMs: 1, id: 'x');
    final token = cursor.encode();
    expect(token, isNot(contains('+')));
    expect(token, isNot(contains('/')));
  });

  test('UserActivityPage reports the inclusive end index', () {
    const page = UserActivityPage(entries: [], total: 47, start: 11);
    expect(page.end, 10);
    expect(page.hasMore, isFalse);
    expect(
      const UserActivityPage(entries: [], total: 0, start: 1),
      UserActivityPage.empty,
    );
  });
}
