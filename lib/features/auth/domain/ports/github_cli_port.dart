import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';

/// Port for probing the local GitHub CLI (`gh`).
abstract interface class GitHubCliPort {
  /// Probes the local `gh` CLI and returns its current status.
  Future<GitHubCliStatus> probe();
}

