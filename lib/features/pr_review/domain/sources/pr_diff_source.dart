import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';

/// Contextual data passed to a [PrDiffSource] to identify the PR.
class PrSourceRequest {
  const PrSourceRequest({
    required this.prNumber,
    required this.owner,
    required this.repo,
    required this.baseRef,
    required this.headRef,
    required this.headSha,
    required this.changedFiles,
    required this.workspaceId,
    this.localCheckoutPath,
  });

  final int prNumber;
  final String owner;
  final String repo;
  final String baseRef;
  final String headRef;
  final String headSha;
  final int changedFiles;
  final String workspaceId;

  /// Absolute path to the user's local checkout of this repo. May be empty.
  final String? localCheckoutPath;
}

/// Load state for a file list emission.
class PrFilesLoad {
  const PrFilesLoad({
    required this.files,
    this.isComplete = false,
    this.clonePhase,
    this.cloneMessage = '',
    this.error,
  });

  final List<PrFile> files;

  /// True once all files (including patches) have been loaded.
  final bool isComplete;

  /// Non-null while the local-clone pipeline is running (clone/fetch/compute).
  final ClonePhase? clonePhase;
  final String cloneMessage;
  final Object? error;

  bool get isCloning =>
      clonePhase != null && clonePhase != ClonePhase.ready && clonePhase != ClonePhase.error;
}

/// Simplified clone-phase enum exposed to the UI layer.
enum ClonePhase {
  cloning,
  fetching,
  computing,
  ready,
  error,
}

/// Abstract source of PR diff data (files, patches, commits).
///
/// There are two implementations (in the data layer):
/// - `GitHubApiPrDiffSource`: GitHub REST API (up to 3 000 files).
/// - `LocalGitPrDiffSource`: local blobless clone (unlimited files).
abstract interface class PrDiffSource {
  /// Stream of file lists with progressive patch loading.
  ///
  /// For the API source this mirrors existing streaming-page behavior.
  /// For the local source it emits first with empty patches (fast tree render)
  /// then progressively fills patches as `git diff` output is parsed.
  Stream<PrFilesLoad> watchFiles(PrSourceRequest req);

  /// Stream of commits for the PR.
  Stream<List<PrCommit>> watchCommits(PrSourceRequest req);

  /// Stream of files changed in a single commit.
  Stream<List<PrFile>> watchCommitFiles(PrSourceRequest req, String sha);
}
