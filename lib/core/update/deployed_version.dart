import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';

/// The build identity deployed at the web origin, as served by
/// `/deploy.json` (written by the deploy pipeline on every push to `main`).
///
/// The web client compares this against its compiled-in [BuildInfo] to detect
/// that a newer deploy is live. The comparison key is the git sha — the
/// version string (from `pubspec.yaml`) can stay identical across many
/// main-branch deploys, while every deploy has a distinct sha.
class DeployedVersion {
  /// Creates a [DeployedVersion].
  const DeployedVersion({
    required this.version,
    required this.gitSha,
    this.builtAt,
  });

  /// The release version the origin reports (from `pubspec.yaml` at deploy).
  final String version;

  /// The git sha the origin was built from — the identity the running build
  /// compares against.
  final String gitSha;

  /// When the deploy pipeline built it (RFC-3339), if reported.
  final String? builtAt;

  /// Parses the `/deploy.json` body. Returns null on any shape mismatch —
  /// a malformed manifest is ignored, never treated as an update.
  static DeployedVersion? parse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) {
        return null;
      }
      final version = json['version'] as String?;
      final gitSha = json['gitSha'] as String?;
      if (version == null ||
          version.isEmpty ||
          gitSha == null ||
          gitSha.isEmpty) {
        return null;
      }
      return DeployedVersion(
        version: version,
        gitSha: gitSha,
        builtAt: json['builtAt'] as String?,
      );
    } on FormatException {
      return null;
    }
  }

  /// Whether this deploy differs from the running build (the sha is the
  /// identity; an unstamped local build (`dev`) never matches a CI deploy, so
  /// `flutter run` against a deployed origin shows the banner once — that is
  /// correct: the origin really is a different build).
  bool differsFromRunningBuild() => gitSha != BuildInfo.buildGitSha;

  @override
  bool operator ==(Object other) =>
      other is DeployedVersion &&
      other.version == version &&
      other.gitSha == gitSha;

  @override
  int get hashCode => Object.hash(version, gitSha);

  @override
  String toString() => 'DeployedVersion($version+$gitSha)';
}
