import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Reads an upstream reply whole as text, refusing one past [maxBytes] with
/// an [HttpException] as soon as it gets there, and an idle gap past
/// [timeout] with a `TimeoutException`. Malformed UTF-8 is replaced, never
/// thrown: the caller's JSON parse is what judges the body.
///
/// The one body reader for Connect, provider sign-in and manifest replies,
/// so none of them buffers an unbounded answer.
Future<String> readBoundedText(
  Stream<List<int>> body, {
  required int maxBytes,
  required Duration timeout,
}) async {
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in body.timeout(timeout)) {
    if (bytes.length + chunk.length > maxBytes) {
      throw const HttpException('oversized reply');
    }
    bytes.add(chunk);
  }
  return utf8.decode(bytes.takeBytes(), allowMalformed: true);
}
