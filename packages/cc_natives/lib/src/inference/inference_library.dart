import 'dart:ffi';
import 'dart:io';

import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/native_library.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// Resolution and per-isolate loading of the `cc_inference` native.
///
/// `libcc_inference` is SELF-CONTAINED: sherpa-onnx and the one ONNX Runtime are
/// statically linked into it, so there is no sibling library to locate, no
/// loader-path search to satisfy, and no second runtime to collide with.

/// The path a host resolved for the inference dylib, consulted by
/// [ensureInferenceBindings] before falling back to its own resolution.
///
/// Per-isolate, because Dart statics do not cross isolate boundaries: this only
/// reaches entry points running on the SAME isolate that set it (the host's main
/// isolate). Worker isolates receive the path explicitly in their `init`
/// message instead — see `TextEmbedderWorker` and `SherpaOnnxTranscriber`.
String? _preferredPath;

/// Bindings for the current isolate, memoized. Per-isolate by necessity: each
/// isolate opens the dylib for itself, which is cheap (dyld returns the
/// already-mapped image) and sidesteps the fact that a binding resolved in one
/// isolate is invisible to every other.
CcInferenceBindings? _bindings;

/// Records the [path] the host resolved for the inference dylib so subsequent
/// [ensureInferenceBindings] calls *on this isolate* load from there. Pass null
/// to clear.
void setPreferredInferenceLibPath(String? path) {
  _preferredPath = path;
  _bindings = null;
}

/// Resolves the ABSOLUTE path of the `cc_inference` dylib, or null when no
/// candidate holds it.
///
/// Pure path policy — this deliberately does NOT open the library. `dlopen` of a
/// large sherpa-linked dylib has been measured HANGING INDEFINITELY under the
/// JIT Dart VM (`dart run` / `dart test`) while taking milliseconds under AOT,
/// so probing by open can freeze a JIT host at boot. The boot preflight
/// therefore stats; the real load happens lazily, on the worker isolate that
/// needs it, where a genuine failure surfaces as an actionable `init_error`
/// instead of a hang.
///
/// See [_candidates] for the search order.
String? resolveInferenceLibraryPath({String? appSupportRoot}) {
  for (final candidate in _candidates(appSupportRoot: appSupportRoot)) {
    if (candidate.isEmpty || candidate.startsWith('@')) {
      // Loader-relative tokens (`@executable_path/...`) cannot be stat'd; they
      // stay in the open-order list but are not resolvable paths.
      continue;
    }
    final file = File(candidate);
    if (file.existsSync()) {
      // MUST be absolute: a hardened program (the `dart build cli` cc_server)
      // rejects `dlopen` of a relative path outright, so a relative data dir
      // (e.g. `--data-dir apps/cc_server/data`) would silently fail to load.
      return file.absolute.path;
    }
  }
  return null;
}

/// Candidate paths for the inference dylib, in load order:
///
/// 1. [inferenceLibraryEnvVar] — a full path to the dylib itself, so ONE native
///    can be swapped without redirecting all of them;
/// 2. [nativeLibDirEnvVar] — the DIRECTORY of bundled dylibs (what the desktop
///    passes when it spawns a local `cc_server`);
/// 3. [appSupportRoot] — the host data dir, where `build_natives.sh` installs;
/// 4. the `dart build cli` bundle `lib/` and the executable's bundle layout.
///
/// Note the two env vars differ in kind: the dedicated one names a FILE, the
/// shared one names a DIRECTORY. [nativeLibraryCandidates] treats its `envVar`
/// as a complete path, which is right for the per-native vars but would
/// misread the shared directory — hence the explicit join here.
Iterable<String> _candidates({String? appSupportRoot}) sync* {
  final fileName = platformLibraryFileName(inferenceLibraryBaseName);

  final explicit = Platform.environment[inferenceLibraryEnvVar];
  if (explicit != null && explicit.isNotEmpty) {
    yield explicit;
  }
  final libDir = Platform.environment[nativeLibDirEnvVar];
  if (libDir != null && libDir.isNotEmpty) {
    yield p.join(libDir, fileName);
  }
  if (appSupportRoot != null && appSupportRoot.isNotEmpty) {
    yield p.join(appSupportRoot, fileName);
  }
  yield* bundledLibraryCandidates(inferenceLibraryBaseName);
}

/// Binds the `cc_inference` dylib for the CURRENT isolate, memoized.
///
/// [explicitPath] wins over everything (worker isolates pass the path the host
/// resolved on their behalf). Returns null when the dylib cannot be found,
/// cannot be opened, or speaks a different ABI version — all of which are a
/// broken install rather than a degraded mode, so callers convert null into a
/// thrown error naming `scripts/natives/build_natives.sh`.
CcInferenceBindings? ensureInferenceBindings({
  String? explicitPath,
  String? appSupportRoot,
}) {
  final cached = _bindings;
  if (cached != null && explicitPath == null) {
    return cached;
  }
  final path =
      explicitPath ??
      _preferredPath ??
      resolveInferenceLibraryPath(appSupportRoot: appSupportRoot);
  final lib = tryOpenFirst([
    ?path,
    ..._candidates(appSupportRoot: appSupportRoot),
  ]);
  if (lib == null) {
    return null;
  }
  final bindings = CcInferenceBindings.tryFrom(lib);
  if (bindings != null && explicitPath == null) {
    _bindings = bindings;
  }
  return bindings;
}

/// The message a caller should throw when [ensureInferenceBindings] returns
/// null, naming what to run. Kept here so every consumer says the same thing.
String inferenceLibraryUnavailableMessage({String? searchedPath}) =>
    'The cc_inference native could not be loaded'
    '${searchedPath == null ? '' : ' (looked at $searchedPath)'}. '
    'Build it with scripts/natives/build_natives.sh, or point '
    '\$$inferenceLibraryEnvVar at the dylib. Speech and semantic embeddings '
    'have no fallback — this is a broken install, not a degraded mode.';

/// Reads (and clears) the native's thread-local error message, falling back to
/// [fallback] when it has none.
///
/// Only meaningful on the isolate that made the failing call — the native slot
/// is thread-local by design, so a message never leaks between isolates.
String readInferenceError(
  CcInferenceBindings bindings, {
  required String fallback,
}) {
  final raw = bindings.lastError();
  if (raw == nullptr) {
    return fallback;
  }
  final message = raw.cast<Utf8>().toDartString();
  return message.isEmpty ? fallback : message;
}
