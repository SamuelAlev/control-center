/// Resolution and per-isolate initialization of the `rhttp` native — the Rust
/// HTTP engine (reqwest + rustls) underneath every HTTP client the server
/// builds.
///
/// Control Center consumes rhttp as a PURE-DART dependency: the maintained
/// patch (`patches/rhttp@0.18.0.patch`) strips its Flutter plugin registration
/// and its single `package:flutter` import, `scripts/natives/build_rhttp.sh`
/// compiles the crate under `rust/` into `librhttp` beside the other natives,
/// and this file opens exactly that staged file through
/// `Rhttp.init(libraryPath:)` (also added by the patch). rhttp's own default
/// init is never used here — it resolves `rust/target/release/` inside the
/// package, i.e. a cargokit build tree that exists only in a Flutter-plugin
/// build, which is precisely what the headless server does not have.
///
/// A missing native is a broken install, not a degraded mode: there is no
/// alternative transport to fall back to. [initializeRhttp] throws
/// [RhttpUnavailable] naming the remediation, the boot preflight (see
/// `buildNativeRequirements` in `cc_server_core`) refuses to start without it,
/// and `scripts/release/verify_natives.sh` fails a bundle that does not carry
/// it.
library;

import 'dart:async';
import 'dart:io';

import 'package:cc_natives/src/native_library_paths.dart';
import 'package:cc_natives/src/native_unavailable.dart';
import 'package:path/path.dart' as p;
import 'package:rhttp/rhttp.dart' show Rhttp;

/// Base name of the rhttp native: `librhttp.dylib` (macOS), `librhttp.so`
/// (Linux), `rhttp.dll` (Windows). Must match the cdylib `cargo` emits for the
/// crate built by `scripts/natives/build_rhttp.sh`.
const String rhttpLibraryBaseName = 'rhttp';

/// Env var overriding the rhttp native path (highest-priority candidate, a FULL
/// path to the file — see [rhttpLibraryCandidates]).
const String rhttpLibraryEnvVar = 'RHTTP_DYLIB';

/// Thrown when the `rhttp` native cannot be resolved or opened.
///
/// There is no degraded mode: without it no HTTP request can be made at all,
/// so this propagates out of server startup rather than being handled. See
/// [NativeLibraryUnavailable].
class RhttpUnavailable implements NativeLibraryUnavailable {
  /// Creates an [RhttpUnavailable] with the given [message].
  const RhttpUnavailable(this.message, {this.cause});

  @override
  final String message;

  /// The load failure that produced this, when there was one (a missing file
  /// produces none — the message already names every path searched).
  final Object? cause;

  @override
  String toString() =>
      'RhttpUnavailable: $message${cause == null ? '' : ' ($cause)'}';
}

/// The message a caller should surface when the rhttp native cannot be
/// resolved. Kept here so the preflight, the server and the tests all say the
/// same thing.
String rhttpLibraryUnavailableMessage({String? searchedPath}) =>
    'The rhttp native (${platformLibraryFileName(rhttpLibraryBaseName)}) '
    'could not be loaded'
    '${searchedPath == null ? '' : ' (looked at $searchedPath)'}. '
    'Build it with scripts/natives/build_natives.sh, or point '
    '\$$rhttpLibraryEnvVar at the dylib. HTTP has no fallback transport — this '
    'is a broken install, not a degraded mode.';

/// Candidate paths for the rhttp native, in load order:
///
/// 1. [explicitPath], when the caller already resolved it (tests, workers);
/// 2. [rhttpLibraryEnvVar] — a full path to the dylib itself;
/// 3. [nativeLibDirEnvVar] — the DIRECTORY of bundled natives (what the desktop
///    passes when it spawns a local `cc_server`);
/// 4. [appSupportRoot] — the host data dir, where `build_natives.sh` installs;
/// 5. the `dart build cli` bundle `lib/` and the executable's bundle layout.
///
/// Note the two env vars differ in kind: the dedicated one names a FILE, the
/// shared one names a DIRECTORY. [nativeLibraryCandidates] treats its `envVar`
/// as a complete path, which is right for the per-native var but would misread
/// the shared directory — hence the explicit join here.
Iterable<String> rhttpLibraryCandidates({
  String? explicitPath,
  String? appSupportRoot,
}) sync* {
  final fileName = platformLibraryFileName(rhttpLibraryBaseName);

  if (explicitPath != null && explicitPath.isNotEmpty) {
    yield explicitPath;
  }
  final explicit = Platform.environment[rhttpLibraryEnvVar];
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
  yield* bundledLibraryCandidates(rhttpLibraryBaseName);
}

/// Resolves the ABSOLUTE path of the rhttp native, or null when no candidate
/// holds it.
///
/// Pure path policy: it stats, it never opens — the boot preflight uses this so
/// a probe cannot hang a JIT host, and the real load happens once, in
/// [initializeRhttp]. Loader-relative tokens (`@executable_path/...`) cannot be
/// stat'd; they stay in the open-order list but are not resolvable paths.
String? resolveRhttpLibraryPath({
  String? explicitPath,
  String? appSupportRoot,
}) {
  for (final candidate in rhttpLibraryCandidates(
    explicitPath: explicitPath,
    appSupportRoot: appSupportRoot,
  )) {
    if (candidate.isEmpty || candidate.startsWith('@')) {
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

/// The in-flight or completed initialization of THIS isolate, if any.
///
/// Per isolate by necessity: flutter_rust_bridge's RustLib is initialized per
/// isolate, and a library opened on one isolate is invisible to another. A
/// caller that needs rhttp on a worker isolate must call [initializeRhttp]
/// there too.
Future<void>? _initialized;

/// Initializes the rhttp native for the CURRENT isolate. Idempotent: concurrent
/// and repeated calls share one initialization.
///
/// Resolves the staged native through [rhttpLibraryCandidates] and hands the
/// explicit path to [Rhttp.init]. Throws [RhttpUnavailable] — never falls back
/// to another transport — when nothing resolves or the library will not load.
/// A FAILED initialization is deliberately not memoized, so a developer who
/// rebuilds the native (or a test that stages it later) can retry in the same
/// process instead of inheriting a poisoned isolate.
Future<void> initializeRhttp({String? explicitPath, String? appSupportRoot}) {
  final pending = _initialized;
  if (pending != null) {
    return pending;
  }
  final future = _initialize(
    explicitPath: explicitPath,
    appSupportRoot: appSupportRoot,
  );
  _initialized = future;
  unawaited(
    future.then(
      (_) {},
      onError: (Object _, StackTrace _) {
        if (identical(_initialized, future)) {
          _initialized = null;
        }
      },
    ),
  );
  return future;
}

Future<void> _initialize({String? explicitPath, String? appSupportRoot}) async {
  final resolved = resolveRhttpLibraryPath(
    explicitPath: explicitPath,
    appSupportRoot: appSupportRoot,
  );
  if (resolved == null) {
    throw RhttpUnavailable(
      rhttpLibraryUnavailableMessage(
        searchedPath: rhttpLibraryCandidates(
          explicitPath: explicitPath,
          appSupportRoot: appSupportRoot,
        ).join(', '),
      ),
    );
  }
  try {
    await Rhttp.init(libraryPath: resolved);
  } catch (e) {
    throw RhttpUnavailable(
      rhttpLibraryUnavailableMessage(searchedPath: resolved),
      cause: e,
    );
  }
}
