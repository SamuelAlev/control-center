import 'dart:io';

import 'package:path/path.dart' as p;

/// True on GitHub Actions / generic CI. Server-boot tests skip here when the
/// natives are not staged — CI does not run `scripts/natives/build_natives.sh`.
bool get runningInCi =>
    Platform.environment['CI'] == 'true' ||
    Platform.environment['GITHUB_ACTIONS'] == 'true';

/// Whether this machine has at least one required native in a location
/// [stageServerNatives] would copy from. Used to skip (CI) or fail (local)
/// server-boot tests before they all hit the same preflight error.
bool get hostHasServerNatives {
  for (final dir in _nativeSourceDirs()) {
    for (final name in const ['libccpty.so', 'libccpty.dylib', 'ccpty.dll']) {
      if (File(p.join(dir.path, name)).existsSync()) {
        return true;
      }
    }
  }
  return false;
}

/// `skip:` for a sentinel "natives are staged" test.
Object skipServerBootWithoutNatives({required String reason}) =>
    (!hostHasServerNatives && runningInCi) ? reason : false;

/// Locations [stageServerNatives] copies from, in priority order.
List<Directory> _nativeSourceDirs() => [
  for (final dir in [
    Platform.environment['CC_NATIVE_LIB_DIR'],
    _repoBuildNatives(),
    _appSupportRoot(),
    _appSupportGrammars(),
  ])
    if (dir != null && Directory(dir).existsSync()) Directory(dir),
];

/// Stages every native library `runCcServer`'s boot preflight REQUIRES into a
/// test's temp `--data-dir`, so tests that boot the real server pass the
/// preflight the same way a real deployment does (the data dir is a
/// first-class resolver location).
///
/// Mirrors the requirement matrix in `cc_server_runtime.dart` — fff, pty,
/// cc_watcher, rift, tree-sitter + its grammars/queries, lame, aec,
/// cc_inference (speech + embeddings) and cc_saml (SSO). Keep the two in
/// step: a native added
/// there without being added here fails every server-booting test with a
/// preflight error rather than the behaviour under test.
///
/// Sources, in priority order per file: `$CC_NATIVE_LIB_DIR`, the repo's
/// `build/natives/` staging dir (populated by
/// `scripts/natives/build_natives.sh`) and the dev app-support install (where
/// the `build_*.sh` scripts install by default, including its `grammars/`
/// subdir). Every native here is first-party and built by those scripts; there
/// is no pub-cache source.
///
/// Deliberately does NOT fail when a native can't be found anywhere: the boot
/// preflight then fails the test with its actionable "run
/// `scripts/natives/build_natives.sh`" message, which is the intended loud
/// failure mode on a machine that never built the natives (same philosophy as
/// `pty_test.dart`). CI runners do not build natives, so server-boot suites
/// skip via [skipServerBootWithoutNatives] instead of failing the job.
Future<void> stageServerNatives(String dataDir) async {
  final sources = _nativeSourceDirs();

  final wanted = RegExp(
    // Every preflight-required lib + the grammars/queries the code graph
    // resolves beside them. `tree-sitter.*` covers the runtime and all five
    // grammars. The versioned-soname tail (`(\..+)?`) stays: it costs nothing
    // and other natives may still carry one.
    r'^(lib)?(fff_c|ccpty|cc_watcher|rift_ffi|lame_ffi|aec_ffi|cc_inference'
    r'|cc_saml|tree-sitter.*)'
    r'\.(dylib|so|dll)(\..+)?$|\.scm$',
  );

  for (final source in sources) {
    for (final entity in source.listSync()) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path);
      if (!wanted.hasMatch(name)) {
        continue;
      }
      final target = File(p.join(dataDir, name));
      if (target.existsSync()) {
        continue; // First source wins.
      }
      entity.copySync(target.path);
    }
  }
}

/// The repo root, found by walking up from CWD (`dart test` runs from the
/// package dir) to the directory that carries `scripts/natives/`.
String? _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (Directory(p.join(dir.path, 'scripts', 'natives')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return null;
}

String? _repoBuildNatives() {
  final root = _repoRoot();
  return root == null ? null : p.join(root, 'build', 'natives');
}

/// The desktop's app-support root, where `scripts/natives/build_*.sh` installs
/// at dev time (mirrors `native_support_root` in natives_common.sh).
String? _appSupportRoot() {
  final home = Platform.environment['HOME'];
  if (Platform.isMacOS && home != null) {
    return p.join(
      home,
      'Library',
      'Application Support',
      'com.alev.control-center',
    );
  }
  if (Platform.isLinux) {
    final xdg =
        Platform.environment['XDG_DATA_HOME'] ??
        (home == null ? null : p.join(home, '.local', 'share'));
    return xdg == null ? null : p.join(xdg, 'control_center');
  }
  return null;
}

String? _appSupportGrammars() {
  final root = _appSupportRoot();
  return root == null ? null : p.join(root, 'grammars');
}
