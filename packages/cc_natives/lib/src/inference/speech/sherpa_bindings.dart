import 'dart:ffi';
import 'dart:io';

import 'package:cc_natives/src/native_library.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Whether [ensureSherpaInitialized] has already wired up the sherpa-onnx FFI
/// bindings *in the current isolate*.
///
/// sherpa-onnx resolves its native symbols into an isolate-local static
/// (`SherpaOnnxBindings`), and Dart statics are NOT shared across isolates — so
/// every isolate that touches sherpa must call `initBindings()` for itself.
/// Initializing in one isolate (e.g. the transcriber's decode worker) does
/// nothing for any other (e.g. the main isolate that runs Silero VAD); skipping
/// it there makes a sherpa constructor throw "Please initialize sherpa-onnx
/// first". This flag is therefore deliberately per-isolate: it makes the call
/// idempotent *within* an isolate without pretending the work carries across
/// isolate boundaries.
bool _initialized = false;

/// A directory a host resolved (with its full context — data dir, install
/// location) for the sherpa/onnx dylibs, consulted by [ensureSherpaInitialized]
/// before the env/auto fallback. Set once at startup by a pure-Dart host
/// (`cc_server`) via [setPreferredSherpaLibDir].
///
/// This is per-isolate (Dart statics don't cross isolate boundaries), so it only
/// reaches sherpa entry points that run on the SAME isolate that set it — i.e.
/// the host's main isolate (diarization, VAD). The transcriber's decode worker
/// is a different isolate and receives its directory explicitly via the `init`
/// message instead (see `SherpaOnnxTranscriber`).
String? _preferredDir;

/// Records the directory [dir] the host resolved for the sherpa/onnx dylibs, so
/// subsequent [ensureSherpaInitialized] calls *on this isolate* load from there.
/// Pass null to clear. See [_preferredDir].
void setPreferredSherpaLibDir(String? dir) => _preferredDir = dir;

/// Idempotently initializes sherpa-onnx's native bindings for the current
/// isolate.
///
/// Call it before every sherpa entry point — constructing a
/// [sherpa.VoiceActivityDetector], [sherpa.OfflineRecognizer], or
/// [sherpa.OfflineSpeakerDiarization] — on whatever isolate that entry point
/// runs on. [explicitDir], when given, wins over everything (the transcriber
/// worker passes the directory the host resolved on its behalf).
///
/// **Two host shapes, one resolver.** In the Flutter desktop app the
/// `sherpa_onnx_macos`/`_linux`/`_windows` plugin bundles the dylib onto the
/// loader's search path (`@rpath`), so sherpa's bare `initBindings()` load
/// succeeds. The pure-Dart `cc_server` binary has NO plugin bundling, so a bare
/// load throws "image not found" and every transcription decode fails silently
/// (the worker isolate reports `init_error`, no segments are ever produced).
/// To make the server load the recognizer too, this resolves the directory that
/// actually holds `libsherpa-onnx-c-api` (+ its sibling `libonnxruntime`, which
/// the sherpa dylib finds via its own `@loader_path` rpath) and points sherpa
/// at it via `initBindings(dir)`. Resolution order: [explicitDir], the
/// host-set [_preferredDir], then [resolveSherpaLibraryDir] (env override → the
/// host's data dir → the executable's own bundle layout); if none resolves, it
/// falls back to the bare load (the Flutter-app path).
void ensureSherpaInitialized([String? explicitDir]) {
  if (_initialized) {
    return;
  }
  final dir = explicitDir ?? _preferredDir ?? resolveSherpaLibraryDir();
  if (dir == null) {
    // Bare load: the Flutter plugin put the dylib on the loader's search path.
    sherpa.initBindings();
  } else {
    // Explicit directory: a pure-Dart host with no plugin bundling. Opening the
    // sherpa dylib from this dir also satisfies its `@loader_path`-relative
    // onnxruntime dependency (the sibling lives in the same directory).
    sherpa.initBindings(dir);
  }
  _initialized = true;
}

/// The sherpa-onnx C-API native, undecorated (see [platformLibraryFileName]).
const String _sherpaLibBaseName = 'sherpa-onnx-c-api';

/// Resolves the directory that holds the sherpa-onnx + onnxruntime dylibs for a
/// pure-Dart host, or null to fall back to a bare loader-path load.
///
/// Probes, in priority order, returning the first whose sherpa dylib actually
/// opens (a successful open proves the dir also satisfies the dylib's
/// `@loader_path`-relative `libonnxruntime` dependency):
///
/// 1. [nativeLibDirEnvVar] — an explicit override (the desktop points it at its
///    own bundled-dylib dir when it spawns a local `cc_server`);
/// 2. [appSupportRoot] — the host's data dir, where a deployment may install the
///    dylibs beside the models the server already hosts (covers a remote /
///    headless server that no desktop spawns);
/// 3. the running executable's own bundle layout (macOS
///    `Contents/Frameworks`/`Resources`, Linux `<exeDir>/lib`, Windows beside
///    the exe) — covers a self-contained server shipped with its natives.
///
/// A host with full context calls this once at startup and feeds the result to
/// [setPreferredSherpaLibDir] + the transcriber, so every isolate loads from the
/// same place. With no arg it serves the env + executable-relative cases.
String? resolveSherpaLibraryDir({String? appSupportRoot}) {
  final fileName = platformLibraryFileName(_sherpaLibBaseName);
  for (final dir in _candidateDirs(appSupportRoot: appSupportRoot)) {
    if (dir.isEmpty) {
      continue;
    }
    try {
      DynamicLibrary.open(p.join(dir, fileName));
      return dir;
    } on Object {
      // Wrong dir, missing dependency, or wrong arch — try the next candidate.
      continue;
    }
  }
  return null;
}

/// Candidate directories that may hold the bundled sherpa/onnxruntime dylibs, in
/// priority order (see [resolveSherpaLibraryDir]). Executable-relative paths use
/// concrete [Platform.resolvedExecutable] paths, not `@executable_path` tokens,
/// so they work for any host process, not just one dyld treats as the main
/// executable.
Iterable<String> _candidateDirs({String? appSupportRoot}) sync* {
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
