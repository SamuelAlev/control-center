import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [WorkspaceSettingsRepository] over the RPC client — the thin-client path to
/// one workspace's settings.
///
/// Unlike per-user preferences, these are NOT mirrored into a local store:
/// they are server-authoritative and read through a subscription, so every
/// member of a workspace sees the same value and a change made by an admin
/// lands on the others without a reload.
///
/// The server forces every write into the SESSION workspace and gates it behind
/// the admin role, so the `workspaceId` passed here selects what to read, never
/// what a client is trusted to write.
class RemoteWorkspaceSettingsRepository implements WorkspaceSettingsRepository {
  /// Creates a [RemoteWorkspaceSettingsRepository] over [_client].
  RemoteWorkspaceSettingsRepository(this._client);

  final RemoteRpcClient _client;

  static Map<String, String> _decode(Object? raw) => raw is Map
      ? raw.map((k, v) => MapEntry(k as String, v as String))
      : const {};

  @override
  Future<String?> get(String workspaceId, String key) async =>
      (await getAll(workspaceId))[key];

  @override
  Future<Map<String, String>> getAll(String workspaceId) async {
    final data = await _client.call('workspace_settings.getAll', {
      'workspace_id': workspaceId,
    });
    return _decode(data['settings']);
  }

  @override
  Stream<Map<String, String>> watchAll(String workspaceId) => _client
      .subscribe('workspace_settings.watchForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map((data) => _decode(data['settings']));

  @override
  Future<void> set(String workspaceId, String key, String? value) =>
      _client.call('workspace_settings.set', {
        'workspace_id': workspaceId,
        'key': key,
        'value': ?value,
      });
}
