import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates pipeline triggers over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one and
/// enforces ownership. Mirrors the `pipeline_trigger.*` ops + the
/// `pipeline_trigger.watchForWorkspace` subscription in the host catalog.
///
/// Two ops are CROSS-WORKSPACE BY DESIGN — `pipeline_trigger.enabledForEvent`
/// and `pipeline_trigger.scheduled` — because the trigger dispatcher fans an
/// event out to every workspace's matching triggers, then filters per-event.
class RemotePipelineTriggerRepository {
  /// Creates a [RemotePipelineTriggerRepository] over [_client].
  RemotePipelineTriggerRepository(this._client);

  final RemoteRpcClient _client;

  /// Inserts [trigger] (the host owns persistence; ownership-checked
  /// server-side against the bound workspace).
  Future<void> insert(PipelineTriggerDto trigger) =>
      _client.call('pipeline_trigger.insert', {'trigger': trigger.toJson()});

  /// Updates [trigger] (ownership-checked server-side).
  Future<void> update(PipelineTriggerDto trigger) =>
      _client.call('pipeline_trigger.update', {'trigger': trigger.toJson()});

  /// Deletes the trigger with [id] (ownership-checked server-side).
  Future<void> deleteById(String id) =>
      _client.call('pipeline_trigger.deleteById', {'id': id});

  /// All triggers in the bound workspace.
  Future<List<PipelineTriggerDto>> forWorkspace() async {
    final data = await _client.call('pipeline_trigger.forWorkspace', const {});
    return _triggers(data);
  }

  /// All enabled triggers for [eventType] across EVERY workspace (the trigger
  /// dispatcher fans out then filters per-event).
  Future<List<PipelineTriggerDto>> enabledForEvent(String eventType) async {
    final data = await _client.call('pipeline_trigger.enabledForEvent', {
      'event_type': eventType,
    });
    return _triggers(data);
  }

  /// A single trigger by id (scoped to the bound workspace server-side), or
  /// null when it does not exist.
  Future<PipelineTriggerDto?> getById(String id) async {
    final data = await _client.call('pipeline_trigger.getById', {'id': id});
    final trigger = data['trigger'];
    return trigger is Map
        ? PipelineTriggerDto.fromJson(trigger.cast<String, dynamic>())
        : null;
  }

  /// All enabled scheduled (time-based) triggers across EVERY workspace.
  Future<List<PipelineTriggerDto>> scheduled() async {
    final data = await _client.call('pipeline_trigger.scheduled', const {});
    return _triggers(data);
  }

  /// Records that a scheduled trigger fired at [when] (ownership-checked
  /// server-side).
  Future<void> markFired(String id, DateTime when) =>
      _client.call('pipeline_trigger.markFired', {
        'id': id,
        'when': when.toIso8601String(),
      });

  /// Live triggers in the bound workspace — a fresh snapshot on every change.
  Stream<List<PipelineTriggerDto>> watchForWorkspace() => _client
      .subscribe('pipeline_trigger.watchForWorkspace', const {})
      .map(_triggers);

  List<PipelineTriggerDto> _triggers(Map<String, dynamic> data) =>
      ((data['triggers'] as List?) ?? const [])
          .whereType<Map>()
          .map((t) => PipelineTriggerDto.fromJson(t.cast<String, dynamic>()))
          .toList();
}
