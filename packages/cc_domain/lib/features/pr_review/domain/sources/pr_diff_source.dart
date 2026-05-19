import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';

/// Contextual data passed to a [PrDiffSource] to identify the PR.
class PrSourceRequest {
  /// Creates a [PrSourceRequest] with the given parameters.
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

  /// The PR number.
  final int prNumber;

  /// The repository owner (user or organization).
  final String owner;

  /// The repository name.
  final String repo;

  /// The base branch ref.
  final String baseRef;

  /// The head branch ref.
  final String headRef;

  /// The full SHA of the head commit.
  final String headSha;

  /// The total number of changed files in this PR.
  final int changedFiles;

  /// The workspace ID associated with this request.
  final String workspaceId;

  /// Absolute path to the user's local checkout of this repo. May be empty.
  final String? localCheckoutPath;
}

/// Load state for a file list emission.
class PrFilesLoad {
  /// Creates a [PrFilesLoad] with the given [files] list.
  const PrFilesLoad({
    required this.files,
    this.isComplete = false,
    this.clonePhase,
    this.cloneMessage = '',
    this.error,
  });

  /// The list of changed files.
  final List<PrFile> files;

  /// True once all files (including patches) have been loaded.
  final bool isComplete;

  /// Non-null while the local-clone pipeline is running (clone/fetch/compute).
  final ClonePhase? clonePhase;

  /// A human-readable message describing the current clone phase.
  final String cloneMessage;

  /// An error object if loading failed.
  final Object? error;

  /// True when the local-clone pipeline is actively running.
  bool get isCloning =>
      clonePhase != null &&
      clonePhase != ClonePhase.ready &&
      clonePhase != ClonePhase.error;
}

/// Simplified clone-phase enum exposed to the UI layer.
enum ClonePhase {
  /// Cloning in progress.
  cloning,

  /// Fetching data.
  fetching,

  /// Computing diff.
  computing,

  /// Ready.
  ready,

  /// Error occurred.
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
