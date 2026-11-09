import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates pipeline triggers over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. A workspace id selects
/// the database file server-side, so every workspace-scoped call names its
/// `workspace_id` in the args — a trigger id resolves only inside its own
/// workspace. Mirrors the `pipeline_trigger.*` ops + the
/// `pipeline_trigger.watchForWorkspace` subscription in the host catalog.
///
/// The dispatcher's and scheduler's cross-workspace reads are server-side only
/// and have no op: an enabled trigger carries its webhook token (route and HMAC
/// secret both).
class RemotePipelineTriggerRepository {
  /// Creates a [RemotePipelineTriggerRepository] over [_client].
  RemotePipelineTriggerRepository(this._client);

  final RemoteRpcClient _client;

  /// Inserts [trigger] (the host owns persistence; ownership-checked
  /// server-side against the bound workspace). The host mints a webhook
  /// trigger's token; one sent here is ignored.
  Future<void> insert(PipelineTriggerDto trigger) =>
      _client.call('pipeline_trigger.insert', {'trigger': trigger.toJson()});

  /// Updates [trigger] (ownership-checked server-side).
  Future<void> update(PipelineTriggerDto trigger) =>
      _client.call('pipeline_trigger.update', {'trigger': trigger.toJson()});

  /// Deletes the trigger with [id] from [workspaceId]. A trigger owned by
  /// another workspace is not matched.
  Future<void> deleteById(String workspaceId, String id) => _client.call(
    'pipeline_trigger.deleteById',
    {'workspace_id': workspaceId, 'id': id},
  );

  /// All triggers in [workspaceId].
  Future<List<PipelineTriggerDto>> forWorkspace(String workspaceId) async {
    final data = await _client.call('pipeline_trigger.forWorkspace', {
      'workspace_id': workspaceId,
    });
    return _triggers(data);
  }

  /// A single trigger by id within [workspaceId], or null when it does not
  /// exist there.
  Future<PipelineTriggerDto?> getById(String workspaceId, String id) async {
    final data = await _client.call('pipeline_trigger.getById', {
      'workspace_id': workspaceId,
      'id': id,
    });
    final trigger = data['trigger'];
    return trigger is Map
        ? PipelineTriggerDto.fromJson(trigger.cast<String, dynamic>())
        : null;
  }

  /// Live triggers in [workspaceId] — a fresh snapshot on every change.
  Stream<List<PipelineTriggerDto>> watchForWorkspace(String workspaceId) =>
      _client
          .subscribe('pipeline_trigger.watchForWorkspace', {
            'workspace_id': workspaceId,
          })
          .map(_triggers);

  List<PipelineTriggerDto> _triggers(Map<String, dynamic> data) =>
      ((data['triggers'] as List?) ?? const [])
          .whereType<Map>()
          .map((t) => PipelineTriggerDto.fromJson(t.cast<String, dynamic>()))
          .toList();
}
