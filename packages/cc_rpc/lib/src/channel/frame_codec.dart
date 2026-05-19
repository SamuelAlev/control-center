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

/// Cheap "is this frame big?" probe: sums the length of top-level String
/// values, which is where a large frame's bytes actually are (a document
/// body, a diff, a base64 blob). Nested structures are not walked — the point
/// is to spend O(top-level fields), not O(payload), deciding.
bool _looksLarge(Map<String, dynamic> frame) {
  var chars = 0;
  for (final value in frame.values) {
    if (value is String) {
      chars += value.length;
      if (chars >= kIsolateEncodeThresholdChars) {
        return true;
      }
    } else if (value is Map) {
      for (final nested in value.values) {
        if (nested is String) {
          chars += nested.length;
          if (chars >= kIsolateEncodeThresholdChars) {
            return true;
          }
        }
      }
    }
  }
  return false;
}
