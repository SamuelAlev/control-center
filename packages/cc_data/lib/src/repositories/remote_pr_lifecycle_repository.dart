import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads + writes the local PR-lifecycle records (the compose-PR draft → publish
/// → created lifecycle) over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The PR-lifecycle surface
/// is workspace-scoped (`PullRequests.workspace_id`), and the workspace is bound
/// server-side (via `session/set_workspace`), so the reads/writes never pass a
/// `workspace_id` — the host injects the authoritative one, scopes every query
/// by it, and validates an id-keyed row belongs to it before mutating. Mirrors
/// the `pr_lifecycle.*` ops + the `pr_lifecycle.watchByWorkspace` subscription
/// in the host catalog.
///
/// Publishing ([createOnGitHub]) runs server-side against the HOST-resident
/// GitHub token (the client never holds one), so a connected web/remote client
/// drives it through this helper and gets back the GitHub API result map.
class RemotePrLifecycleRepository {
  /// Creates a [RemotePrLifecycleRepository] over [_client].
  RemotePrLifecycleRepository(this._client);

  final RemoteRpcClient _client;

  /// Live PR-lifecycle records in the bound workspace, newest first.
  Stream<List<PrGenerationDto>> watchByWorkspace() => _client
      .subscribe('pr_lifecycle.watchByWorkspace', const {})
      .map(_list);

  /// A single PR-lifecycle record by id in the bound workspace (null when absent
  /// or owned by another workspace).
  Future<PrGenerationDto?> getById(String id) async {
    final data = await _client.call('pr_lifecycle.getById', {'id': id});
    final pr = data['pr'];
    return pr is Map
        ? PrGenerationDto.fromJson(pr.cast<String, dynamic>())
        : null;
  }

  /// Creates a draft in the bound workspace; returns the new record id.
  Future<String> createDraft({
    required String title,
    required String body,
    String? diffSummary,
  }) async {
    final data = await _client.call('pr_lifecycle.createDraft', {
      'title': title,
      'body': body,
      'diff_summary': ?diffSummary,
    });
    return data['id'] as String;
  }

  /// Updates a draft by id in the bound workspace.
  Future<void> updateDraft(
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  }) async {
    await _client.call('pr_lifecycle.updateDraft', {
      'pr_id': prId,
      'title': ?title,
      'body': ?body,
      'status': ?status,
      'github_pr_number': ?githubPrNumber,
      'github_pr_url': ?githubPrUrl,
    });
  }

  /// Publishes a draft to GitHub (server-side, host token). Returns the GitHub
  /// API result map (e.g. `{number, html_url, …}`).
  Future<Map<String, dynamic>> createOnGitHub({
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

  /// Deletes a record by id in the bound workspace.
  Future<void> delete(String id) async {
    await _client.call('pr_lifecycle.delete', {'id': id});
  }

  List<PrGenerationDto> _list(Map<String, dynamic> data) =>
      ((data['prs'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => PrGenerationDto.fromJson(p.cast<String, dynamic>()))
          .toList();
}
