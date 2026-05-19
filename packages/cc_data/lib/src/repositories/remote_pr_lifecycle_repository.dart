import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads + writes the local PR-lifecycle records (the compose-PR draft → publish
/// → created lifecycle) over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The PR-lifecycle surface
/// is workspace-scoped (`PullRequests.workspace_id`) and a workspace id selects
/// the database file server-side, so every read/write names its `workspace_id` —
/// an id-keyed row from another workspace must not resolve. Mirrors the
/// `pr_lifecycle.*` ops + the `pr_lifecycle.watchByWorkspace` subscription in
/// the host catalog.
///
/// Publishing ([createOnGitHub]) runs server-side against the HOST-resident
/// GitHub token (the client never holds one), so a connected web/remote client
/// drives it through this helper and gets back the GitHub API result map.
class RemotePrLifecycleRepository {
  /// Creates a [RemotePrLifecycleRepository] over [_client].
  RemotePrLifecycleRepository(this._client);

  final RemoteRpcClient _client;

  /// Live PR-lifecycle records in [workspaceId], newest first.
  Stream<List<PrGenerationDto>> watchByWorkspace(String workspaceId) => _client
      .subscribe('pr_lifecycle.watchByWorkspace', {'workspace_id': workspaceId})
      .map(_list);

  /// A single PR-lifecycle record by id within [workspaceId] (null when absent
  /// there).
  Future<PrGenerationDto?> getById(String workspaceId, String id) async {
    final data = await _client.call('pr_lifecycle.getById', {
      'workspace_id': workspaceId,
      'id': id,
    });
    final pr = data['pr'];
    return pr is Map
        ? PrGenerationDto.fromJson(pr.cast<String, dynamic>())
        : null;
  }

  /// Creates a draft in [workspaceId]; returns the new record id.
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  }) async {
    final data = await _client.call('pr_lifecycle.createDraft', {
      'workspace_id': workspaceId,
      'title': title,
      'body': body,
      'diff_summary': ?diffSummary,
    });
    return data['id'] as String;
  }

  /// Updates a draft by id within [workspaceId].
  Future<void> updateDraft(
    String workspaceId,
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  }) async {
    await _client.call('pr_lifecycle.updateDraft', {
      'workspace_id': workspaceId,
      'pr_id': prId,
      'title': ?title,
      'body': ?body,
      'status': ?status,
      'github_pr_number': ?githubPrNumber,
      'github_pr_url': ?githubPrUrl,
    });
  }

  /// Publishes a draft in [workspaceId] to GitHub (server-side, host token).
  /// Returns the GitHub API result map (e.g. `{number, html_url, …}`).
  Future<Map<String, dynamic>> createOnGitHub({
    required String workspaceId,
    required String prId,
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
    List<String> assignees = const [],
    List<String> reviewerUsers = const [],
    List<String> reviewerTeams = const [],
  }) async {
    final data = await _client.call('pr_lifecycle.createOnGitHub', {
      'workspace_id': workspaceId,
      'pr_id': prId,
      'owner': owner,
      'repo': repo,
      'title': title,
      'body': body,
      'head': head,
      'base': base,
      'draft': draft,
      'assignees': assignees,
      'reviewer_users': reviewerUsers,
      'reviewer_teams': reviewerTeams,
    });
    return (data['result'] as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Deletes a record by id within [workspaceId].
  Future<void> delete(String workspaceId, String id) async {
    await _client.call('pr_lifecycle.delete', {
      'workspace_id': workspaceId,
      'id': id,
    });
  }

  List<PrGenerationDto> _list(Map<String, dynamic> data) =>
      ((data['prs'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => PrGenerationDto.fromJson(p.cast<String, dynamic>()))
          .toList();
}
