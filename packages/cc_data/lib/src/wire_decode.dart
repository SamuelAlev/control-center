/// Wire→entity decode helpers.
///
/// Decode row-by-row and drop failures: a throw inside `stream.map` errors the
/// whole stream (blank list). Prefer a short list over a dead subscription.
library;

import 'dart:developer' as developer;

/// Decodes [rows] with [decode], dropping any row that will not decode.
///
/// [what] names the entity in the diagnostic. Only [ArgumentError] and
/// [FormatException] are treated as "this row is bad" — anything else is a
/// programming error in the decoder itself and is rethrown, because swallowing
/// it would turn a bug into a permanently short list.
List<T> decodeRows<T>(
  Iterable<Map<String, dynamic>> rows,
  T Function(Map<String, dynamic> row) decode, {
  required String what,
}) {
  final out = <T>[];
  var dropped = 0;
  Object? firstError;
  for (final row in rows) {
    try {
      out.add(decode(row));
    } on ArgumentError catch (e) {
      dropped += 1;
      firstError ??= e;
    } on FormatException catch (e) {
      dropped += 1;
      firstError ??= e;
    }
  }
  if (dropped > 0) {
    developer.log(
      'dropped $dropped malformed $what row(s) from the wire: $firstError',
      name: 'cc_data',
      level: 900, // WARNING
    );
  }
  return out;
}
