/// Cross-platform WebSocket frame JSON decoding.
///
/// Large frames — e.g. a full transcript pull for a huge turn — decode off the
/// UI/main isolate so they never jank it. `isolate_manager` gives one code path
/// for this: a real one-off isolate on the VM, and (when no Web Worker is wired)
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
