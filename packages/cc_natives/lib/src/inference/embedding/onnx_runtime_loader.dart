import 'dart:ffi';
import 'dart:io';

import 'package:cc_natives/src/native_library.dart' show nativeLibDirEnvVar;
import 'package:path/path.dart' as p;

/// File name of the onnxruntime dynamic library the embedder's `onnxruntime_v2`
/// package opens. These MUST match `onnxruntime_v2`'s own loader
/// (`bindings.dart`) exactly — a pre-loaded image only dedupes a later leaf
/// open when the names match. Bump these in lock-step with an `onnxruntime_v2`
/// upgrade.
String? _onnxRuntimeFileName() {
  if (Platform.isMacOS) {
    return 'libonnxruntime.1.21.0.dylib';
  }
  if (Platform.isLinux) {
    return 'libonnxruntime.so.1.22.0';
  }
  if (Platform.isWindows) {
    return 'onnxruntime.dll';
  }
  return null;
}

/// Directories that may hold the bundled onnxruntime dylib, in priority order
/// (mirrors `resolveSherpaLibraryDir` — the embedder's onnxruntime is bundled
/// beside sherpa's): an explicit [nativeLibDirEnvVar] override, the host data
/// dir ([appSupportRoot]), then the running executable's bundle layout.
Iterable<String> _candidateDirs(String? appSupportRoot) sync* {
  final env = Platform.environment[nativeLibDirEnvVar];
  if (env != null && env.isNotEmpty) {
    yield env;
  }
  if (appSupportRoot != null && appSupportRoot.isNotEmpty) {
    yield appSupportRoot;
  }
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  if (Platform.isMacOS) {
    yield p.normalize(p.join(exeDir, '..', 'Frameworks'));
    yield p.normalize(p.join(exeDir, '..', 'Resources'));
  } else if (Platform.isLinux) {
    yield p.join(exeDir, 'lib');
  } else if (Platform.isWindows) {
    yield exeDir;
  }
}

/// Pre-loads the onnxruntime dynamic library by FULL PATH so the embedder's
/// `onnxruntime_v2` package finds it on a pure-Dart host.
///
/// `onnxruntime_v2` opens onnxruntime by a BARE leaf name. That works in the
/// desktop app (the CocoaPods framework is linked, so the image is already in
/// the process and dyld returns it by name), but a hardened `dart build cli`
/// binary — the headless `cc_server` — rejects a relative/leaf `dlopen`
/// outright ("relative path not allowed in hardened program"), and `DYLD_*`
/// search paths are ignored under the hardened runtime. So without this the
/// leaf open fails and embeddings silently degrade to keyword/FTS.
///
/// Opening the dylib once by ABSOLUTE path loads it into the process; the
/// later leaf open then dedupes to this same image. Best-effort + idempotent:
/// returns `true` once the library is resolvable, `false` (no throw) when the
/// dylib can't be found or this platform isn't supported — callers that want
/// embeddings on a pure-Dart host call it at startup, before the first embed.
bool ensureOnnxRuntimeLoaded({String? appSupportRoot}) {
  final name = _onnxRuntimeFileName();
  if (name == null) {
    return false;
  }
  for (final dir in _candidateDirs(appSupportRoot)) {
    if (dir.isEmpty) {
      continue;
    }
    final file = File(p.join(dir, name));
    if (!file.existsSync()) {
      continue;
    }
    // MUST be absolute: a hardened program (this `dart build cli` binary)
    // rejects `dlopen` of a relative path outright, so a relative data dir
    // (e.g. `--data-dir apps/cc_server/data`) would silently fail to load.
    try {
      DynamicLibrary.open(file.absolute.path);
      return true;
    } on Object {
      // Wrong arch / corrupt dylib — try the next candidate dir.
      continue;
    }
  }
  return false;
}
