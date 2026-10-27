/// Shared build identity for clients, servers and workers.
/// CI stamps this file with `tool/gen_build_info.dart`; committed values stay
/// unstamped for local development.
library;

/// Namespace for the CI-stamped build identity constants.
abstract final class BuildInfo {
  /// Release version of this build. Matches the release tag (`vX.Y.Z` →
  /// `X.Y.Z`) on CI builds; the root `pubspec.yaml` version otherwise.
  static const String buildVersion = '0.0.11';

  /// Short git sha this build was compiled from, or `dev` when unstamped.
  static const String buildGitSha = 'dev';

  /// RFC-3339 (UTC) build timestamp, or the empty string when unstamped.
  static const String buildTime = '';

  /// One-line identity for logs, `--version` banners and crash reports.
  static const String buildIdentity =
      'control-center $buildVersion ($buildGitSha)';
}
