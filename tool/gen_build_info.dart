// Stamps packages/cc_domain/lib/src/build_info.dart for every shipped artifact.
// Usage: fvm dart run tool/gen_build_info.dart [--version X.Y.Z]
// Without --version, reads the root pubspec. Do not commit stamped output.
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
/// Shared build identity for clients, servers and workers.
/// CI stamps this file with `tool/gen_build_info.dart`; committed values stay
/// unstamped for local development.
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
