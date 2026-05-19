import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Shared dylib path-resolution policy for the runtime-loaded natives.
///
/// Every native (rift, fff, tree-sitter, aec) is a loose shared library found
/// at runtime — never linked into the app. This file is the SINGLE source of
/// truth for *where* those libraries might live and *how* to open them, so the
/// conventions (`@executable_path/../Frameworks/…`, `<exeDir>/lib/…`, the
/// app-support install, env overrides) live in exactly one place instead of
/// being re-encoded per binding.

/// Environment variable a host process reads to locate the directory that holds
/// the *bundled* platform dylibs (sherpa-onnx, onnxruntime, …) when it has no
/// Flutter-plugin bundling of its own.
///
/// The pure-Dart `cc_server` binary is not a Flutter app, so the
/// `sherpa_onnx_*` plugins never bundle their dylibs into it. The desktop —
/// which DOES bundle them (in its `.app/Contents/Frameworks`) — passes this
/// variable, pointing at its own native-library directory, when it spawns the
/// server, so the server can load the speech recognizer Flutter shipped with
/// the app. See `ensureSherpaInitialized`.
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

/// Canonical bundle-relative + bare candidate paths for [baseName], in load
/// order. These cover a packaged release (macOS `Contents/Frameworks`, Linux
/// `<exeDir>/lib`, Windows beside the exe) plus the bare soname/name for a
/// system or loader-path install. No env / app-support / dev-build entries —
/// those are layered on by [nativeLibraryCandidates].
List<String> bundledLibraryCandidates(String baseName) {
  if (Platform.isMacOS) {
    final f = 'lib$baseName.dylib';
    return [
      '@executable_path/../Frameworks/$f',
      '@executable_path/../Resources/$f',
      f,
    ];
  }
  if (Platform.isLinux) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final f = 'lib$baseName.so';
    // dlopen-by-soname does not honour the executable's `$ORIGIN/lib` RUNPATH,
    // so try the explicit bundled path before the bare soname.
    return ['$exeDir/lib/$f', f, '$f.0'];
  }
  if (Platform.isWindows) {
    return ['$baseName.dll', 'lib$baseName.dll'];
  }
  return const [];
}

/// The full ordered candidate path list for a runtime-loaded native [baseName],
/// tried in order by [tryOpenFirst]:
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

/// Opens the first [candidates] entry that loads, or returns `null` when none
/// resolve (the universal graceful-degradation signal — callers fall back).
///
/// Empty candidates are skipped; an absent path (`ArgumentError`) or any other
/// load failure (wrong arch, missing symbols) moves on to the next candidate.
DynamicLibrary? tryOpenFirst(Iterable<String> candidates) {
  for (final candidate in candidates) {
    if (candidate.isEmpty) {
      continue;
    }
    try {
      return DynamicLibrary.open(candidate);
    } on ArgumentError {
      continue;
    } catch (_) {
      continue;
    }
  }
  return null;
}
