/// Decoding helpers for the wire→entity boundary.
///
/// Domain entities validate their own invariants in their constructors, and as
/// of the assert→throw conversion they do so IN RELEASE — which is the point,
/// but it moves a failure that used to be silent onto a code path that cannot
/// afford it. Every `*FromWire` in this package runs inside
/// `stream.map((data) => rows.map(decode).toList())`, and a throw inside that
/// `map` errors the WHOLE STREAM: one malformed row would blank an entire
/// conversation, meeting list or todo list rather than dropping one item.
///
/// The mappers also manufacture required fields with `?? ''` — a habit from
/// when the constructors only asserted. That is not reachable on today's wire
/// (the server's `*ToWire` emits these unconditionally), but "not reachable
/// today" means the client's crash-freedom rests on a server invariant it
/// cannot see, across a version skew it does not control.
///
/// So: decode row by row, drop what will not decode, and say so once. A list
/// short by one row is a visible, survivable degradation; an errored stream is
/// a blank screen with no explanation.
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

/// Decodes one [row], returning null when it will not decode.
///
/// For the single-object reads (`getById`, a `watch` of one entity) where the
/// honest answer to an undecodable payload is "not found" rather than a throw
/// that reaches a widget.
T? decodeRow<T>(
  Map<String, dynamic>? row,
  T Function(Map<String, dynamic> row) decode, {
  required String what,
}) {
  if (row == null) {
    return null;
  }
  final decoded = decodeRows<T>([row], decode, what: what);
  return decoded.isEmpty ? null : decoded.first;
}
