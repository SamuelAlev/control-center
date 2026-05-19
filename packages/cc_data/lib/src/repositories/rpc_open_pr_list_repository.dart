import 'package:cc_data/src/repositories/pr_dto_mapping.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [OpenPrListRepository] backed by the RPC client — the thin-client data
/// path for the PR-list screen, the dashboard priority reviews, and the user
/// profile PR history.
///
/// All GitHub fetching runs SERVER-SIDE on the host's gh-authenticated client
/// (the thin client holds no token). This repository issues the `pr.*` ops and
/// maps the [PullRequestDto] rows back to domain [PullRequest]s via the shared
/// [pullRequestFromWireDto]. Reactions are not carried by these list/search
/// queries, so rows have none (the row UI doesn't render them).
class RpcOpenPrListRepository implements OpenPrListRepository {
  /// Creates an [RpcOpenPrListRepository] over [_client].
  RpcOpenPrListRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<WorkspaceOpenPrs> listOpenForWorkspace(String workspaceId) async {
    final data = await _client.call('pr.listOpenForWorkspace', const {});
    final authenticated = data['authenticated'] as bool? ?? false;
    final groups = <RepoOpenPrs>[
      for (final raw in (data['repos'] as List?) ?? const [])
        if (raw is Map)
          RepoOpenPrs(
            repoId: (raw['repo_id'] as String?) ?? '',
            hasMore: (raw['has_more'] as bool?) ?? false,
            prs: _prsOf(raw),
          ),
    ];
    return WorkspaceOpenPrs(authenticated: authenticated, groups: groups);
  }

  @override
  Future<List<({String repoId, PullRequest pr})>> reviewRequestedForWorkspace(
    String workspaceId,
  ) async {
    final data = await _client.call(
      'pr.searchReviewRequestedForWorkspace',
      const {},
    );
    return [
      for (final raw in (data['reviews'] as List?) ?? const [])
        if (raw is Map && raw['pr'] is Map)
          (
            repoId: (raw['repo_id'] as String?) ?? '',
            pr: pullRequestFromWireDto(
              PullRequestDto.fromJson(
                (raw['pr'] as Map).cast<String, dynamic>(),
              ),
            ),
          ),
    ];
  }

  @override
  Future<Set<String>> reviewedByKeysForWorkspace(String workspaceId) async {
    final data = await _client.call(
      'pr.searchReviewedByForWorkspace',
      const {},
    );
    return {
      for (final k in (data['keys'] as List?) ?? const [])
        if (k is String) k,
    };
  }

  @override
  Future<List<RepoOpenPrs>> closedByAuthorForWorkspace(
    String workspaceId,
    String login,
  ) async {
    final data = await _client.call('pr.closedByAuthorForWorkspace', {
      'login': login,
    });
    return [
      for (final raw in (data['repos'] as List?) ?? const [])
        if (raw is Map)
          RepoOpenPrs(
            repoId: (raw['repo_id'] as String?) ?? '',
            hasMore: (raw['has_more'] as bool?) ?? false,
            prs: _prsOf(raw),
          ),
    ];
  }

  /// Maps a per-repo group's `prs` wire list to domain [PullRequest]s.
  static List<PullRequest> _prsOf(Map raw) => ((raw['prs'] as List?) ?? const [])
      .whereType<Map>()
      .map((p) => PullRequestDto.fromJson(p.cast<String, dynamic>()))
      .map(pullRequestFromWireDto)
      .toList();
}
