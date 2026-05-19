import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';

/// Builds a [ForgePrClient] for one repo coordinate.
typedef ForgePrClientFor =
    ForgePrClient Function({required String owner, required String repo});

/// A `PrDiffSource` backed by whatever forge the repo lives on.
///
/// GitHub has a bespoke source that exploits its paged files endpoint; every
/// other forge gets this one, which simply asks the forge client. The client
/// already returns domain entities, so there is nothing forge-specific left
/// here — the source exists only to satisfy the streaming shape the file
/// loader expects.
///
/// The client is rebuilt per request because a source instance is shared across
/// repos while a client is pinned to one `(owner, repo)`.
class ForgeClientPrDiffSource implements PrDiffSource {
  /// Creates a [ForgeClientPrDiffSource] over [_clientFor].
  const ForgeClientPrDiffSource(this._clientFor);

  final ForgePrClientFor _clientFor;

  ForgePrClient _client(PrSourceRequest req) =>
      _clientFor(owner: req.owner, repo: req.repo);

  @override
  Stream<PrFilesLoad> watchFiles(PrSourceRequest req) async* {
    final files = await _client(req).listFiles(req.prNumber);
    yield PrFilesLoad(files: files, isComplete: true);
  }

  @override
  Stream<List<PrCommit>> watchCommits(PrSourceRequest req) async* {
    yield await _client(req).listCommits(req.prNumber);
  }

  @override
  Stream<List<PrFile>> watchCommitFiles(
    PrSourceRequest req,
    String sha,
  ) async* {
    yield await _client(req).listCommitFiles(sha);
  }
}
