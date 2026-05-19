import 'dart:io';

import 'package:path/path.dart' as p;

/// Whether this machine has the natives `runCcServer`'s boot preflight
/// requires, in a location [stageServerNatives] can copy from.
///
/// Mirrors `hostHasServerNatives` in
/// `packages/cc_server_core/test/helpers/native_staging.dart` (not importable
/// from the root package's test tree). CI runners that do not stage natives
/// skip the server-spawning tests instead of failing the job.
bool get hostHasServerNatives {
  for (final dir in _nativeSourceDirs()) {
    for (final name in const [
      'libccpty.so',
      'libccpty.dylib',
      'ccpty.dll',
    ]) {
      if (File(p.join(dir.path, name)).existsSync()) {
        return true;
      }
    }
  }
  return false;
}

/// True on GitHub Actions / generic CI.
bool get runningInCi =>
    Platform.environment['CI'] == 'true' ||
    Platform.environment['GITHUB_ACTIONS'] == 'true';

/// Copies every boot-required native into [dataDir] (a first-class resolver
/// location for `runCcServer`'s preflight), so a spawned-from-source
/// `cc_server` boots the same way a real deployment does.
///
/// Same shape and source priority as cc_server_core's `stageServerNatives`:
/// `$CC_NATIVE_LIB_DIR`, the repo's `build/natives/` staging dir, and the dev
/// app-support install (including its `grammars/` subdir), first source wins.
Future<void> stageServerNatives(String dataDir) async {
  final wanted = RegExp(
    r'^(lib)?(fff_c|ccpty|cc_watcher|rift_ffi|lame_ffi|aec_ffi|cc_inference'
    r'|cc_saml|tree-sitter.*)'
    r'\.(dylib|so|dll)(\..+)?$|\.scm$',
  );
  for (final source in _nativeSourceDirs()) {
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

List<Directory> _nativeSourceDirs() => [
  for (final dir in [
    Platform.environment['CC_NATIVE_LIB_DIR'],
    _repoBuildNatives(),
    _appSupportRoot(),
    _appSupportGrammars(),
  ])
    if (dir != null && Directory(dir).existsSync()) Directory(dir),
];

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
