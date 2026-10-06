import 'dart:io';

/// Resolves the absolute path to [binary] by probing common install locations.
///
/// Bundled macOS `.app` and Linux `.desktop` launches inherit a minimal PATH
/// from the system launcher (`launchd` / `xdg`) that excludes Homebrew, Nix,
/// MacPorts and user-local prefixes. This helper searches the prefixes a
/// developer would typically install CLIs into and returns the first existing
/// path.
///
/// As a last resort it runs `binary --version` to catch the case where it is
/// already on PATH (e.g. debug builds launched from a terminal). Returns
/// `null` when nothing works — callers should treat that as "not installed".
Future<String?> resolveBinaryPath(String binary) async {
  // VULN-002: the binary name must be a bare executable looked up in known
  // install dirs — never an attacker-supplied absolute/relative path or a
  // traversal. A cliName with a separator or `..` could escape the bin
  // prefixes (or point the last-resort `Process.run` at an arbitrary path).
  if (_isUnsafeBinaryName(binary)) {
    return null;
  }
  for (final candidate in candidateBinaryPaths(binary)) {
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

/// Whether [binary] is not a bare, safely-looked-up executable name.
bool _isUnsafeBinaryName(String binary) =>
    binary.isEmpty ||
    binary.contains('/') ||
    binary.contains('\\') ||
    binary.contains('..') ||
    binary.startsWith('-');

/// The install-location candidates for [binary], without touching disk and
/// without spawning anything.
///
/// Split out of [resolveBinaryPath] for callers that resolve MANY binaries per
/// operation (the sandbox config builder probes ~18 runtime tools) and cannot
/// afford a `--version` subprocess per miss — a first `flutter --version` on a
/// cold machine rebuilds the Flutter tool and can take tens of seconds.
Iterable<String> candidateBinaryPaths(String binary) sync* {
  if (_isUnsafeBinaryName(binary)) {
    return;
  }
  yield* _candidatePaths(binary);
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
    // the newest version comes first.
    yield* versionManagedBinaryPaths(binary, home: home);

    yield '$home/.local/bin/$binary';
    yield '$home/bin/$binary';
  }
}

/// Every version-manager (nvm, fnm) install of [binary] under [home], newest
/// version first, without touching anything but the version directories.
///
/// [candidateBinaryPaths] only needs the newest; the sandbox needs them all.
/// The shell an agent runs in picks its version from the fnm/nvm default or a
/// repo's `.node-version`, which is rarely the newest install — and a version
/// the exec allowlist does not name is refused by the `$HOME` exec deny.
Iterable<String> versionManagedBinaryPaths(
  String binary, {
  required String home,
}) sync* {
  if (_isUnsafeBinaryName(binary) || home.isEmpty) {
    return;
  }
  yield* _versionedBins('$home/.nvm/versions/node', 'bin', binary);
  for (final fnmRoot in [
    '$home/.local/share/fnm',
    '$home/.fnm',
    if (Platform.isMacOS) '$home/Library/Application Support/fnm',
  ]) {
    yield* _versionedBins('$fnmRoot/node-versions', 'installation/bin', binary);
  }
}

Iterable<String> _versionedBins(
  String root,
  String binSubpath,
  String binary,
) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) {
    return;
  }
  final List<String> versions;
  try {
    versions = dir.listSync().whereType<Directory>().map((d) => d.path).toList()
      ..sort(compareVersionDirs);
  } on FileSystemException {
    return;
  }
  for (final v in versions.reversed) {
    yield '$v/$binSubpath/$binary';
  }
}

/// Orders version directories (`v9.11.2`, `v24.18.0`, …) numerically, so
/// `v24` sorts above `v9`. A plain string sort puts `v9` last, and "newest"
/// then meant the oldest install. Names without a version fall back to string
/// order, below every versioned name.
int compareVersionDirs(String a, String b) {
  final va = _versionParts(a);
  final vb = _versionParts(b);
  if (va == null || vb == null) {
    if (va != null) {
      return 1;
    }
    if (vb != null) {
      return -1;
    }
    return a.compareTo(b);
  }
  for (var i = 0; i < va.length || i < vb.length; i++) {
    final x = i < va.length ? va[i] : 0;
    final y = i < vb.length ? vb[i] : 0;
    if (x != y) {
      return x.compareTo(y);
    }
  }
  return a.compareTo(b);
}

List<int>? _versionParts(String path) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  final match = RegExp(r'^v?(\d+(?:\.\d+)*)').firstMatch(name);
  if (match == null) {
    return null;
  }
  return [
    for (final part in match.group(1)!.split('.')) int.tryParse(part) ?? 0,
  ];
}
