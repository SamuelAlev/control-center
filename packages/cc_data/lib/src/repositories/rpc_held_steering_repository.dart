import 'package:cc_domain/features/messaging/domain/repositories/held_steering_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [HeldSteeringRepository] over the `steering.release` RPC op, always with
/// `held_by: stop`.
class RpcHeldSteeringRepository implements HeldSteeringRepository {
  /// Creates the repository over [_client].
  RpcHeldSteeringRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<int> release({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
  }) async {
    final data = await _client.call('steering.release', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'conversation_id': conversationId,
      // The op requires the holder. A person releases only what their own
      // Stop held; a usage-limit pause's cards go out when the pause resumes
      // and the server refuses to release them here.
      'held_by': 'stop',
    });
    return (data['released'] as num?)?.toInt() ?? 0;
  }
}
