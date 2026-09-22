/// Cross-platform WebSocket frame JSON decoding.
///
/// Large frames — e.g. a full transcript pull for a huge turn — decode off the
/// UI/main isolate so they never jank it. `isolate_manager` gives one code path
/// for this: a real one-off isolate on the VM and (when no Web Worker is wired)
/// an inline main-isolate decode on the web. Web list frames are lite/windowed,
/// so big frames are rare there and a dedicated Web Worker is not warranted;
/// small frames decode inline on every platform. This replaced an `_io`/`_web`
/// conditional-import seam and a direct `dart:isolate` dependency.
library;

import 'dart:convert';

import 'package:isolate_manager/isolate_manager.dart';

/// Frames at/above this many characters decode off the UI/main isolate (on the
/// VM). Below it, the isolate hand-off would cost more than the decode itself.
const int kIsolateDecodeThresholdChars = 50 * 1024;

/// Decodes one JSON wire frame; large frames run off the UI/main isolate.
Future<Map<String, dynamic>> decodeJsonFrame(String data) async {
  if (data.length < kIsolateDecodeThresholdChars) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  // No `workerName`: on the VM this runs in a one-off isolate (like
  // `Isolate.run`); on the web it runs inline on the main isolate.
  return IsolateManager.run(() => jsonDecode(data) as Map<String, dynamic>);
}

/// Frames whose ENCODED size is expected to reach this many characters are
/// encoded off the UI/main isolate.
///
/// Measured against the map's own scale rather than the output length (which
/// is what we are trying to avoid computing), so the gate is deliberately
/// coarse: only an obviously-large payload takes the isolate.
const int kIsolateEncodeThresholdChars = 50 * 1024;

/// Encodes one JSON wire frame; large frames run off the UI/main isolate.
///
/// The decode side has always been offloaded above a threshold; the ENCODE
/// side ran inline for everything, so a client sending a large mutation
/// (a pasted document, a big tool result relayed on) serialized megabytes on
/// the isolate that also has to keep the UI at 60 fps.
Future<String> encodeJsonFrame(Map<String, dynamic> frame) async {
  if (!_looksLarge(frame)) {
    return jsonEncode(frame);
  }
  return IsolateManager.run(() => jsonEncode(frame));
}

/// Whether [encodeJsonFrame] will leave this isolate to encode [frame].
///
/// Exposed for tests. Production call sites should use [encodeJsonFrame].
bool frameLooksLarge(Map<String, dynamic> frame) => _looksLarge(frame);

/// Cheap "is this frame big?" probe.
///
/// Maps are walked, because a request only has a handful of objects
/// (`params`, `args`, a snapshot's `data`). Lists are not: a `sub/snapshot`
/// is a list of row maps, and visiting every row is most of the cost of
/// encoding it. A few rows are sampled and scaled by the list length, which
/// is enough to tell a short list from one that belongs off this isolate.
/// [String.length] is constant-time, so the probe never copies payload bytes.
bool _looksLarge(Map<String, dynamic> frame) {
  var chars = 0;
  for (final value in frame.values) {
    chars += _probeChars(value, 0);
    if (chars >= kIsolateEncodeThresholdChars) {
      return true;
    }
  }
  return false;
}

int _probeChars(Object? value, int depth) {
  if (value is String) {
    return value.length;
  }
  if (value is List) {
    return _sampledListChars(value, depth);
  }
  if (value is! Map) {
    return 0;
  }
  var chars = 0;
  for (final nested in value.values) {
    chars += depth >= 8
        ? (nested is String ? nested.length : 0)
        : _probeChars(nested, depth + 1);
    if (chars >= kIsolateEncodeThresholdChars) {
      return chars;
    }
  }
  return chars;
}

int _sampledListChars(List<dynamic> items, int depth) {
  final length = items.length;
  if (length == 0) {
    return 0;
  }
  final indexes = <int>{
    0,
    length ~/ 4,
    length ~/ 2,
    (length * 3) ~/ 4,
    length - 1,
  };
  var sample = 0;
  for (final index in indexes) {
    final item = _probeChars(items[index], depth + 1);
    if (item >= kIsolateEncodeThresholdChars) {
      return item;
    }
    sample += item;
  }
  return (sample / indexes.length * length).ceil();
}
