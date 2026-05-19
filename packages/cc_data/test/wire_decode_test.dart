import 'package:cc_data/src/wire_decode.dart';
import 'package:test/test.dart';

/// One malformed row must cost one row, not the whole list.
///
/// Entity constructors validate their invariants in RELEASE now (the
/// assert→throw conversion). That is right, and it puts a throw on a path that
/// cannot take one: every `*FromWire` in this package runs inside
/// `stream.map((data) => rows.map(decode).toList())`, where a throw errors the
/// WHOLE stream — one bad row would blank an entire conversation or meeting
/// list rather than dropping an item from it.
void main() {
  Map<String, dynamic> row(String name) => {'name': name};

  String decodeName(Map<String, dynamic> r) {
    final name = r['name'] as String? ?? '';
    if (name.isEmpty) {
      throw ArgumentError('name must not be empty');
    }
    return name;
  }

  group('decodeRows', () {
    test('drops only the rows that will not decode', () {
      final out = decodeRows(
        [row('a'), row(''), row('b'), row('')],
        decodeName,
        what: 'thing',
      );
      expect(out, ['a', 'b']);
    });

    test('an all-good list is unchanged', () {
      expect(decodeRows([row('a'), row('b')], decodeName, what: 'thing'), [
        'a',
        'b',
      ]);
    });

    test('a FormatException is treated the same as a bad argument', () {
      final out = decodeRows<String>([row('a'), row('b')], (r) {
        if (r['name'] == 'b') {
          throw const FormatException('bad');
        }
        return r['name'] as String;
      }, what: 'thing');
      expect(out, ['a']);
    });

    test('any OTHER error is rethrown, not swallowed', () {
      // A bug in the decoder must not present as a permanently short list —
      // that is a silent failure nobody would ever chase.
      expect(
        () => decodeRows<String>(
          [row('a')],
          (_) => throw StateError('decoder bug'),
          what: 'thing',
        ),
        throwsStateError,
      );
    });
  });

  group('decodeRow', () {
    test('returns null for an undecodable payload', () {
      expect(decodeRow(row(''), decodeName, what: 'thing'), isNull);
      expect(decodeRow(null, decodeName, what: 'thing'), isNull);
    });

    test('returns the value for a good one', () {
      expect(decodeRow(row('a'), decodeName, what: 'thing'), 'a');
    });
  });
}
