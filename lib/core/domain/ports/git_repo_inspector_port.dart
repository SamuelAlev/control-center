import 'package:control_center/core/domain/entities/git_repo_info.dart';

/// Port for extracting metadata (owner, repo, branch) from a local Git repo.
abstract interface class GitRepoInspectorPort {
  /// Inspect.
  Future<GitRepoInfo> inspect(String path);
}
