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
  static const String buildVersion = '0.0.1';

  /// Short git sha this build was compiled from, or `dev` when unstamped.
  static const String buildGitSha = 'dev';

  /// RFC-3339 (UTC) build timestamp, or the empty string when unstamped.
  static const String buildTime = '';

  /// One-line identity for logs, `--version` banners and crash reports.
  static const String buildIdentity =
      'control-center $buildVersion ($buildGitSha)';
}
