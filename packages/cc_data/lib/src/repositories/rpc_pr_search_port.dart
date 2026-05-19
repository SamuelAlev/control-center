import 'package:cc_data/src/repositories/pr_dto_mapping.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart' show PullRequest;
import 'package:cc_domain/features/pr_review/domain/ports/pr_search_port.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PrSearchPort] backed by the RPC client — the thin-client PR-queue search.
///
/// The raw [PrSearchQuery.text] is sent to the host, parsed + executed there on
/// the gh-authenticated client (`pr.searchForWorkspace`), and the matching open
/// PRs come back grouped by repo id. This joins them to the caller's [Repo]
/// entities (the canonical rows the client already holds) and maps the wire
/// rows to domain [PullRequest]s.
class RpcPrSearchPort implements PrSearchPort {
  /// Creates an [RpcPrSearchPort] over [_client].
  RpcPrSearchPort(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<RepoPullRequests>> search({
    required PrSearchQuery query,
    required List<Repo> repos,
  }) async {
    if (repos.isEmpty) {
      return const [];
    }
    final data = await _client.call('pr.searchForWorkspace', {
      'query': query.text,
    });
    final reposById = {for (final r in repos) r.id: r};
    final out = <RepoPullRequests>[];
    for (final raw in (data['repos'] as List?) ?? const []) {
      if (raw is! Map) {
        continue;
      }
      final m = raw.cast<String, dynamic>();
      final repo = reposById[m['repo_id'] as String? ?? ''];
      if (repo == null) {
        continue;
      }
      final prs = ((m['prs'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => PullRequestDto.fromJson(p.cast<String, dynamic>()))
          .map(pullRequestFromWireDto)
          .toList();
      if (prs.isEmpty) {
        continue;
      }
      out.add(RepoPullRequests(repo: repo, prs: prs));
    }
    return out;
  }
}
