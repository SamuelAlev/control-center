// -*- mode: dart -*-
// Stamps the shared build identity (packages/cc_domain/lib/src/build_info.dart)
// before CI builds anything. One identity compiles into every artifact — the
// Flutter clients, cc_remote and the cc_server binary — so /healthz,
// `cc_server --version`, the RPC handshake and the About row all agree and
// the stale-binary comparison is honest.
//
// Usage (repo root):
//   dart run tool/gen_build_info.dart                     # version from pubspec
//   dart run tool/gen_build_info.dart --version 1.2.3     # release tag override
//
// The committed file carries the unstamped dev identity (0.0.1 / dev); CI
// rewrites it in the build job checkout, it is never committed stamped.
import 'dart:io';

void main(List<String> args) {
  final version = _flag(args, 'version') ?? _pubspecVersion();
  final sha = _gitSha();
  final builtAt = DateTime.now().toUtc().toIso8601String();

  final file = File('packages/cc_domain/lib/src/build_info.dart');
  file.writeAsStringSync(_template(version, sha, builtAt));
  stdout.writeln(
    'Stamped build identity: $version+$sha -> ${file.path} '
    '(built at $builtAt)',
  );
}

String? _flag(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--$name' && i + 1 < args.length) {
      return args[i + 1];
    }
    if (a.startsWith('--$name=')) {
      return a.substring(name.length + 3);
    }
  }
  return null;
}

String _pubspecVersion() {
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    if (line.startsWith('version:')) {
      final version = line.split(':')[1].trim().split('+').first;
      return version;
    }
  }
  return '0.0.1';
}

String _gitSha() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    if (result.exitCode == 0) {
      final sha = (result.stdout as String).trim();
      if (sha.isNotEmpty) {
        return sha;
      }
    }
  } on Object {
    // No git (or a detached export) — keep the dev marker.
  }
  return 'dev';
}

String _template(String version, String sha, String builtAt) =>
    '''
/// Build identity for every surface shipped from this repo: the Flutter
/// clients (desktop + web), the `cc_remote` PWA and the `cc_server` /
/// `cc_worker` binaries.
///
/// The values are plain `const`s so the SAME identity compiles into both the
/// client and the server (both link this package), which is what makes the
/// stale-binary comparison honest. CI stamps them by re-running
/// `tool/gen_build_info.dart` over this file before building — the committed
/// values are the unstamped dev identity (`0.0.1` / `dev`), so a local
/// `flutter run` or `dart build cli` is self-consistent too.
///
/// This file is data, not logic: pure Dart, no platform imports and the
/// generator writes the same shape every time.
library;

/// Namespace for the CI-stamped build identity constants.
abstract final class BuildInfo {
  /// Release version of this build. Matches the release tag (`vX.Y.Z` →
  /// `X.Y.Z`) on CI builds; the root `pubspec.yaml` version otherwise.
  static const String buildVersion = '$version';

  /// Short git sha this build was compiled from, or `dev` when unstamped.
  static const String buildGitSha = '$sha';

  /// RFC-3339 (UTC) build timestamp, or the empty string when unstamped.
  static const String buildTime = '$builtAt';

  /// One-line identity for logs, `--version` banners and crash reports.
  static const String buildIdentity =
      'control-center \$buildVersion (\$buildGitSha)';
}
''';
