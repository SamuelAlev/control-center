import 'package:cc_domain/features/messaging/domain/value_objects/message_cursor.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips through encode/decode', () {
    const cursor = MessageCursor(createdAtMs: 1735689600000, rowid: 4242);
    final decoded = MessageCursor.decode(cursor.encode());
    expect(decoded, cursor);
  });

  test('decode tolerates null/empty/garbage tokens', () {
    expect(MessageCursor.decode(null), isNull);
    expect(MessageCursor.decode(''), isNull);
    expect(MessageCursor.decode('not-base64-!!!'), isNull);
    expect(MessageCursor.decode('e30='), isNull); // {} — missing fields
  });

  test('token is opaque base64url (no padding-breaking chars)', () {
    const cursor = MessageCursor(createdAtMs: 1, rowid: 2);
    final token = cursor.encode();
    expect(token, isNot(contains('+')));
    expect(token, isNot(contains('/')));
  });
}
