import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;

/// True on GitHub Actions / generic CI. Native FFI suites skip here when the
/// dylibs are not staged — CI does not run `scripts/natives/build_natives.sh`.
/// A developer machine still fails loudly: an absent native is a broken tree.
bool get runningInCi =>
    Platform.environment['CI'] == 'true' ||
    Platform.environment['GITHUB_ACTIONS'] == 'true';

/// The directory `scripts/natives/build_*.sh` installs into (next to
/// `control_center.db`). Matches `native_support_root` in natives_common.sh.
String? get devAppSupportRoot {
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

/// Repo `build/natives/` staging dir. `dart test` runs from the package dir.
String get repoBuildNativesDir =>
    p.normalize(p.join(Directory.current.path, '..', '..', 'build', 'natives'));

/// Candidate paths a native-FFI test should search: env override, app-support
/// (plus its `grammars/` subdir for tree-sitter), bundled layout, then the
/// repo staging dir.
List<String> devNativeCandidates(String baseName, {String? envVar}) {
  final fileName = platformLibraryFileName(baseName);
  final appSupport = devAppSupportRoot;
  return [
    ...nativeLibraryCandidates(
      baseName,
      appSupportRoot: appSupport,
      envVar: envVar,
    ),
    if (appSupport != null) p.join(appSupport, 'grammars', fileName),
    p.join(repoBuildNativesDir, fileName),
  ];
}

/// `skip:` value for a sentinel "natives are built" test: skip on CI when the
/// dylib is missing, otherwise `false` so the test body can `fail()` locally.
Object skipIfMissingInCi(bool available, String reason) =>
    (!available && runningInCi) ? reason : false;
