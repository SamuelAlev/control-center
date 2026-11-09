import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';

/// A `PrDiffSource` backed by whatever forge the repo lives on.
///
/// GitHub has a bespoke source that exploits its paged files endpoint; every
/// other forge gets this one, which simply asks the forge client. The client
/// already returns domain entities, so there is nothing forge-specific left
/// here — the source exists only to satisfy the streaming shape the file
/// loader expects.
///
/// Pinned to one repository, like the PR repository that owns it: [_client]
/// answers for its own repo only, so a request for another is refused.
class ForgeClientPrDiffSource implements PrDiffSource {
  /// Creates a [ForgeClientPrDiffSource] over [_client].
  const ForgeClientPrDiffSource(this._client);

  final ForgePrClient _client;

  ForgePrClient _clientFor(PrSourceRequest req) {
    if (req.owner.toLowerCase() != _client.owner.toLowerCase() ||
        req.repo.toLowerCase() != _client.repo.toLowerCase()) {
      throw ArgumentError(
        'This diff source serves ${_client.owner}/${_client.repo}, not '
        '${req.owner}/${req.repo}.',
      );
    }
    return _client;
  }

  @override
  Stream<PrFilesLoad> watchFiles(PrSourceRequest req) async* {
    final listing = await _clientFor(req).listFiles(req.prNumber);
    yield PrFilesLoad(
      files: listing.files,
      isComplete: true,
      truncated: listing.truncated,
    );
  }

  @override
  Stream<List<PrCommit>> watchCommits(PrSourceRequest req) async* {
    yield await _clientFor(req).listCommits(req.prNumber);
  }

  @override
  Stream<List<PrFile>> watchCommitFiles(
    PrSourceRequest req,
    String sha,
  ) async* {
    yield await _clientFor(req).listCommitFiles(sha);
  }
}
