/// JSON helpers that offload large payloads to a background isolate.
///
/// Covers on-disk SWR cache (de)serialize (Dio already offloads large network
/// bodies). Below ~50 KB runs inline — isolate spawn costs more than a small
/// parse ([Isolate.run] above the threshold).
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
/// [value] must be a plain JSON-serializable graph (maps, lists and
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
