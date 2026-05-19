import 'dart:io';

/// Resolves the absolute path to [binary] by probing common install locations.
///
/// Bundled macOS `.app` and Linux `.desktop` launches inherit a minimal PATH
/// from the system launcher (`launchd` / `xdg`) that excludes Homebrew, Nix,
/// MacPorts, and user-local prefixes. This helper searches the prefixes a
/// developer would typically install CLIs into and returns the first existing
/// path.
///
/// As a last resort it runs `binary --version` to catch the case where it is
/// already on PATH (e.g. debug builds launched from a terminal). Returns
/// `null` when nothing works — callers should treat that as "not installed".
Future<String?> resolveBinaryPath(String binary) async {
  for (final candidate in _candidatePaths(binary)) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  try {
    final result = await Process.run(binary, ['--version']);
    if (result.exitCode == 0) {
      return binary;
    }
  } on ProcessException {
    // Fall through.
  }

  return null;
}

Iterable<String> _candidatePaths(String binary) sync* {
  final home = Platform.environment['HOME'];
  final user = Platform.environment['USER'];

  // Nix — applies to macOS and Linux.
  if (home != null && home.isNotEmpty) {
    yield '$home/.nix-profile/bin/$binary';
  }
  yield '/nix/var/nix/profiles/default/bin/$binary';
  yield '/run/current-system/sw/bin/$binary';
  if (user != null && user.isNotEmpty) {
    yield '/etc/profiles/per-user/$user/bin/$binary';
  }

  if (Platform.isMacOS) {
    yield '/opt/homebrew/bin/$binary';
    yield '/usr/local/bin/$binary';
    yield '/opt/local/bin/$binary';
  }
  if (Platform.isLinux) {
    yield '/usr/local/bin/$binary';
    yield '/home/linuxbrew/.linuxbrew/bin/$binary';
  }
  yield '/usr/bin/$binary';

  if (home != null && home.isNotEmpty) {
    // JavaScript runtime global installs.
    yield '$home/.bun/bin/$binary';
    yield '$home/.deno/bin/$binary';
    yield '$home/.npm-global/bin/$binary';
    yield '$home/.npm/bin/$binary';
    yield '$home/.yarn/bin/$binary';
    yield '$home/.asdf/shims/$binary';
    if (Platform.isMacOS) {
      yield '$home/Library/pnpm/$binary';
    }
    yield '$home/.local/share/pnpm/$binary';

    // Version-manager installs (nvm, fnm) — version dirs are dynamic, so
    // pick the lexicographically latest match.
    yield* _latestVersionedBin('$home/.nvm/versions/node', 'bin', binary);
    yield* _latestVersionedBin(
      '$home/.local/share/fnm/node-versions',
      'installation/bin',
      binary,
    );
    yield* _latestVersionedBin('$home/.fnm/node-versions', 'installation/bin', binary);

    yield '$home/.local/bin/$binary';
    yield '$home/bin/$binary';
  }
}

Iterable<String> _latestVersionedBin(
  String root,
  String binSubpath,
  String binary,
) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) {
    return;
  }
  final versions = dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path)
      .toList()
    ..sort();
  for (final v in versions.reversed) {
    yield '$v/$binSubpath/$binary';
  }
}
