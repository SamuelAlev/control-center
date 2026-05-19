import 'dart:io';

import 'package:path/path.dart' as p;

/// Pure (FFI-free) dylib path-resolution policy for the runtime-loaded natives.
///
/// This file deliberately imports NO `dart:ffi`: it only *builds candidate
/// paths* (strings), it never opens a library. That keeps it web-compilable, so
/// path-only consumers (e.g. `cc_infra`'s `CcPaths`, which a web-reachable
/// settings screen pulls in) can import it without dragging the FFI subtree —
/// and therefore `dart:ffi`/onnxruntime — into `flutter build web`. The actual
/// loader (`tryOpenFirst`, which needs `DynamicLibrary`) lives in
/// `native_library.dart`, which re-exports everything here so barrel consumers
/// are unaffected. Guarded by the web-reachability test in
/// test/core/architecture_constraints_test.dart.

/// Environment variable a host process reads to locate the DIRECTORY that holds
/// the bundled native dylibs.
///
/// The desktop is a thin client that spawns `cc_server` as a separate process.
/// The natives ship inside the desktop's own bundle (`.app/Contents/Frameworks`
/// and the embedded server bundle), so the desktop sets this variable to that
/// directory when it spawns the server — that is how a pure-Dart server, which
/// has no Flutter-plugin bundling of its own, finds e.g. `libcc_inference`
/// (speech + embeddings). See `resolveInferenceLibraryPath`.
///
/// Note this names a DIRECTORY. The per-native overrides (e.g.
/// `CC_INFERENCE_DYLIB`) name a FILE.
const String nativeLibDirEnvVar = 'CC_NATIVE_LIB_DIR';

/// The primary platform file name for a library [baseName] (no `lib`/`.dylib`
/// decoration in [baseName] itself): `lib<base>.dylib` on macOS, `lib<base>.so`
/// on Linux, `<base>.dll` on Windows.
String platformLibraryFileName(String baseName) {
  if (Platform.isWindows) {
    return '$baseName.dll';
  }
  if (Platform.isMacOS) {
    return 'lib$baseName.dylib';
  }
  return 'lib$baseName.so';
}

/// The `lib/` directory of a `dart build cli` bundle (`<bundle>/bin/<exe>` +
/// `<bundle>/lib/*`), resolved against the running executable. This is where
/// the build hook drops the `DynamicLoadingBundled` code assets — the natives
/// travel there exactly like `libsqlite3`.
String dartBuildBundleLibDir() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return p.normalize(p.join(exeDir, '..', 'lib'));
}

/// Canonical bundle-relative + bare candidate paths for [baseName], in load
/// order. These cover a `dart build cli` bundle (`<exeDir>/../lib`, where the
/// cc_server build hook places the natives beside libsqlite3), a packaged
/// release (macOS `Contents/Frameworks`, Linux `<exeDir>/lib`, Windows beside
/// the exe) plus the bare soname/name for a system or loader-path install. No
/// env / app-support / dev-build entries — those are layered on by
/// [nativeLibraryCandidates].
List<String> bundledLibraryCandidates(String baseName) {
  if (Platform.isMacOS) {
    final f = 'lib$baseName.dylib';
    return [
      p.join(dartBuildBundleLibDir(), f),
      '@executable_path/../Frameworks/$f',
      '@executable_path/../Resources/$f',
      f,
    ];
  }
  if (Platform.isLinux) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final f = 'lib$baseName.so';
    // dlopen-by-soname does not honour the executable's `$ORIGIN/lib` RUNPATH,
    // so try the explicit bundled paths before the bare soname.
    return [p.join(dartBuildBundleLibDir(), f), '$exeDir/lib/$f', f, '$f.0'];
  }
  if (Platform.isWindows) {
    return [
      p.join(dartBuildBundleLibDir(), '$baseName.dll'),
      '$baseName.dll',
      'lib$baseName.dll',
    ];
  }
  return const [];
}

/// The full ordered candidate path list for a runtime-loaded native [baseName],
/// tried in order by `tryOpenFirst`:
///
/// 1. an explicit `[envVar]` override (when set and non-empty),
/// 2. the app-support install (`[appSupportRoot]/<file>`) — the SINGLE dev
///    location, where `scripts/natives/build_*.sh` installs the dylib next to
///    `control_center.db`,
/// 3. the [bundledLibraryCandidates] for a packaged release (macOS
///    `Contents/Frameworks`, Linux `<exeDir>/lib`, Windows beside the exe).
///
/// There is deliberately no repo-relative `macos/Frameworks/` or `build/…`
/// candidate: dev resolves from app-support, release from the signed bundle, so
/// a given dylib lives in exactly one place per context (no duplication). The
/// host injects [appSupportRoot] (it owns where its storage lives) and the
/// per-native [envVar]; the path *policy* stays here.
List<String> nativeLibraryCandidates(
  String baseName, {
  String? appSupportRoot,
  String? envVar,
}) {
  final fileName = platformLibraryFileName(baseName);
  final env = envVar == null ? null : Platform.environment[envVar];
  return [
    if (env != null && env.isNotEmpty) env,
    if (appSupportRoot != null) p.join(appSupportRoot, fileName),
    ...bundledLibraryCandidates(baseName),
  ];
}
