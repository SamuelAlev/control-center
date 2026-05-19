import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates isolated repos (CoW worktrees) over the RPC client instead of
/// a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one. The
/// two cross-workspace teardown lookups (`forChannelAcrossWorkspaces` /
/// `forTicketAcrossWorkspaces`) are declared exemptions and pass only their id.
/// Mirrors the `isolated_repo.*` ops + `isolated_repo.watchForWorkspace`
/// subscription in the host catalog.
class RemoteIsolatedRepoRepository {
  /// Creates a [RemoteIsolatedRepoRepository] over [_client].
  RemoteIsolatedRepoRepository(this._client);

  final RemoteRpcClient _client;

  /// The worktree for a specific `(workspace, channel, repo)`, or null.
  /// Workspace is bound server-side.
  Future<IsolatedRepoDto?> forUnitRepo(String channelId, String repoId) async {
    final data = await _client.call('isolated_repo.forUnitRepo', {
      'channel_id': channelId,
      'repo_id': repoId,
    });
    final repo = data['repo'];
    return repo is Map
        ? IsolatedRepoDto.fromJson(repo.cast<String, dynamic>())
        : null;
  }

  /// All worktrees for a conversation in the bound workspace.
  Future<List<IsolatedRepoDto>> forChannel(String channelId) async {
    final data = await _client.call('isolated_repo.forChannel', {
      'channel_id': channelId,
    });
    return _repos(data);
  }

  /// All worktrees for a ticket in the bound workspace.
  Future<List<IsolatedRepoDto>> forTicket(String ticketId) async {
    final data = await _client.call('isolated_repo.forTicket', {
      'ticket_id': ticketId,
    });
    return _repos(data);
  }

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by globally-unique channel id.
  /// Each row carries its own workspace; the server op is workspace-exempt.
  Future<List<IsolatedRepoDto>> forChannelAcrossWorkspaces(
    String channelId,
  ) async {
    final data = await _client.call('isolated_repo.forChannelAcrossWorkspaces', {
      'channel_id': channelId,
    });
    return _repos(data);
  }

  /// CROSS-WORKSPACE BY DESIGN: teardown lookup by ticket id. Each row carries
  /// its own workspace; the server op is workspace-exempt.
  Future<List<IsolatedRepoDto>> forTicketAcrossWorkspaces(
    String ticketId,
  ) async {
    final data = await _client.call('isolated_repo.forTicketAcrossWorkspaces', {
      'ticket_id': ticketId,
    });
    return _repos(data);
  }

  /// Inserts or updates [repo] (the host owns persistence).
  Future<void> upsert(IsolatedRepoDto repo) =>
      _client.call('isolated_repo.upsert', {'repo': repo.toJson()});

  /// Deletes the worktree row [id].
  Future<void> deleteById(String id) =>
      _client.call('isolated_repo.deleteById', {'id': id});

  /// Live worktrees in the bound workspace — a fresh snapshot on every change.
  Stream<List<IsolatedRepoDto>> watch() =>
      _client.subscribe('isolated_repo.watchForWorkspace', const {}).map(_repos);

  List<IsolatedRepoDto> _repos(Map<String, dynamic> data) =>
      ((data['repos'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => IsolatedRepoDto.fromJson(r.cast<String, dynamic>()))
          .toList();
}
