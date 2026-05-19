import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/features/pr_review/data/mappers/pr_review_mapper.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:dio/dio.dart';

/// PrDiffSource backed by the GitHub REST API.
///
/// Streams file pages as they arrive (up to GitHub's 3 000-file cap) and
/// paginates commits up to GitHub's ceiling (~250).
class GitHubApiPrDiffSource implements PrDiffSource {
  const GitHubApiPrDiffSource(this._client);

  final GitHubApiClient _client;

  @override
  Stream<PrFilesLoad> watchFiles(PrSourceRequest req) async* {
    final cancelToken = CancelToken();
    final accumulator = <PrFile>[];

    await for (final page in _client.pr.streamPullRequestFiles(
      req.owner,
      req.repo,
      req.prNumber,
      cancelToken: cancelToken,
    )) {
      for (final gh in page) {
        accumulator.add(prFileFromGitHub(gh));
      }
      yield PrFilesLoad(files: List<PrFile>.unmodifiable(accumulator));
    }

    yield PrFilesLoad(
      files: List<PrFile>.unmodifiable(accumulator),
      isComplete: true,
    );
  }

  @override
  Stream<List<PrCommit>> watchCommits(PrSourceRequest req) async* {
    final commits = await _client.pr.listAllPullRequestCommits(
      req.owner,
      req.repo,
      req.prNumber,
    );
    yield commits.map(prCommitFromGitHub).toList(growable: false);
  }

  @override
  Stream<List<PrFile>> watchCommitFiles(
    PrSourceRequest req,
    String sha,
  ) async* {
    final files = await _client.pr.getCommitFiles(req.owner, req.repo, sha);
    yield files.map(prFileFromGitHub).toList(growable: false);
  }
}
