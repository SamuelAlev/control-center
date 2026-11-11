import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/repositories/workspace_connect_repository.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [WorkspaceConnectRepository] over the `workspaceConnect.*` ops.
///
/// Every call names its workspace explicitly; the server checks membership
/// (status) or admin rights (everything else) per call.
class RpcWorkspaceConnectRepository implements WorkspaceConnectRepository {
  /// Creates an [RpcWorkspaceConnectRepository] over [_client].
  RpcWorkspaceConnectRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<WorkspaceConnectStatus> status(String workspaceId) async =>
      workspaceConnectStatusFromJson(
        await _client.call('workspaceConnect.status', {
          'workspace_id': workspaceId,
        }),
      );

  @override
  Future<WorkspaceConnectStatus> set(
    String workspaceId,
    WorkspaceConnectMode mode, {
    String? url,
  }) async => workspaceConnectStatusFromJson(
    await _client.call('workspaceConnect.set', {
      'workspace_id': workspaceId,
      'mode': mode.wireName,
      if (mode == WorkspaceConnectMode.custom && url != null) 'url': url,
    }),
  );

  @override
  Future<WorkspaceConnectStatus> test(String workspaceId) async =>
      workspaceConnectStatusFromJson(
        await _client.call('workspaceConnect.test', {
          'workspace_id': workspaceId,
        }),
      );

  @override
  Future<WorkspaceConnectStatus> confirmPins(String workspaceId) async =>
      workspaceConnectStatusFromJson(
        await _client.call('workspaceConnect.confirmPins', {
          'workspace_id': workspaceId,
        }),
      );
}

/// Decodes a `workspaceConnect.status` payload (also what `set`, `test` and
/// `confirmPins` return).
///
/// Lanes without a provider id are dropped; `install_id` and `pending_pins`
/// stay null when the server omits them (it does for members).
WorkspaceConnectStatus workspaceConnectStatusFromJson(
  Map<String, dynamic> json,
) {
  final pins = json['pending_pins'];
  final installId = json['install_id'];
  final epoch = (json['epoch'] as num?)?.toInt();
  return WorkspaceConnectStatus(
    mode: WorkspaceConnectMode.fromWire(json['mode'] as String?),
    url: json['url'] as String? ?? '',
    serverMode: ServerConnectChoice.fromWire(json['server_mode']),
    serverUrl: json['server_url'] as String? ?? '',
    effectiveMode: WorkspaceConnectEffective.fromWire(json['effective_mode']),
    locked: json['locked'] as bool? ?? false,
    health: WorkspaceConnectHealth.fromWire(json['health']),
    error: ConnectHealthError.fromWire(json['error']),
    stale: json['stale'] as bool? ?? false,
    epoch: epoch == null || epoch < 0 ? null : epoch,
    lanes: [
      for (final entry in (json['lanes'] as List? ?? const []).whereType<Map>())
        if (entry['provider'] case final String provider
            when provider.isNotEmpty)
          WorkspaceConnectLane(
            provider: provider,
            source: WorkspaceLaneSource.fromWire(entry['source']),
            error: entry['error'] as String? ?? '',
          ),
    ],
    installId: installId is String ? installId : null,
    pendingPins: pins is Map
        ? {for (final e in pins.entries) '${e.key}': '${e.value}'}
        : null,
  );
}
