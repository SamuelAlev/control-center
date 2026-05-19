/// JSON (de)serialization helpers that move large payloads onto a background
/// isolate so parsing/serialization never blocks the UI thread.
///
/// HTTP IO in `dart:io` is already asynchronous and does not block the UI
/// isolate — the only CPU-bound cost of a request is encoding the body and
/// decoding the response. Dio's transformer already off-loads decoding of large
/// *network* responses (see `createDio`); these helpers cover the other place
/// the app does heavy JSON work on the UI thread: reading and writing the
/// on-disk SWR cache of GitHub data (PR file lists with patches, long comment
/// threads, contribution calendars, …).
///
/// Both helpers are threshold-guarded. Small payloads are (de)serialized inline
/// because spawning an isolate (a few hundred microseconds to a couple of
/// milliseconds) costs more than parsing a few kilobytes; only larger payloads
/// are handed to a background isolate via [Isolate.run]. The 50 KB threshold
/// mirrors the one Flutter and Dio use for the same trade-off.
library;

import 'dart:convert';
import 'dart:isolate';

/// Payloads at or above this many UTF-16 code units are decoded on a background
/// isolate. Below it, decoding happens inline on the calling isolate.
const int kJsonIsolateThresholdBytes = 50 * 1024;

/// Decodes [source] as a JSON object, off-loading to a background isolate when
/// it is large enough to risk dropping a frame. Returns `null` when the payload
/// is not a JSON object.
Future<Map<String, dynamic>?> decodeJsonMapInIsolate(String source) {
  if (source.length < kJsonIsolateThresholdBytes) {
    return Future.value(_decodeJsonMap(source));
  }
  return Isolate.run(() => _decodeJsonMap(source));
}

/// Decodes [source] as a JSON array of objects, off-loading to a background
/// isolate when it is large enough to risk dropping a frame. Non-object entries
/// are dropped; a non-array payload yields an empty list.
Future<List<Map<String, dynamic>>> decodeJsonListInIsolate(String source) {
  if (source.length < kJsonIsolateThresholdBytes) {
    return Future.value(_decodeJsonList(source));
  }
  return Isolate.run(() => _decodeJsonList(source));
}

/// Encodes [value] to a JSON string. Pass `large: true` when serializing a big
/// collection (a file list, a comment thread) so the work runs on a background
/// isolate; leave it false for small single-object writes where the isolate
/// hand-off would cost more than the encode itself.
///
/// [value] must be a plain JSON-serializable graph (maps, lists, and
/// primitives) so it can cross the isolate boundary — which the cache
/// `*ToCacheJson` builders already guarantee.
Future<String> encodeJsonInIsolate(Object? value, {bool large = false}) {
  if (!large) {
    return Future.value(jsonEncode(value));
  }
  return Isolate.run(() => jsonEncode(value));
}

Map<String, dynamic>? _decodeJsonMap(String source) {
  final decoded = jsonDecode(source);
  return decoded is Map<String, dynamic> ? decoded : null;
}

List<Map<String, dynamic>> _decodeJsonList(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) {
    return const <Map<String, dynamic>>[];
  }
  return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
}
