import 'package:cc_data/src/repositories/remote_pipeline_trigger_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PipelineTriggerRepository] backed by the RPC client — the thin-client
/// data path.
///
/// Implements the domain interface over the host's `pipeline_trigger.*` ops +
/// the `pipeline_trigger.watchForWorkspace` subscription, mapping the
/// [PipelineTriggerDto] wire shape back to [PipelineTrigger]. The host owns
/// persistence and enforces workspace ownership; this client never touches a
/// database.
///
/// Two reads are cross-workspace by design — [enabledForEvent] and [scheduled]
/// — because the trigger dispatcher fans an event out to every workspace's
/// matching triggers, then filters per-event.
class RpcPipelineTriggerRepository implements PipelineTriggerRepository {
  /// Creates an [RpcPipelineTriggerRepository] over [client].
  RpcPipelineTriggerRepository(RemoteRpcClient client)
    : _remote = RemotePipelineTriggerRepository(client);

  final RemotePipelineTriggerRepository _remote;

  /// Rebuilds a [PipelineTrigger] from its wire DTO. `match` is a JSON map;
  /// timestamps are ISO-8601 strings.
  static PipelineTrigger _fromDto(PipelineTriggerDto d) => PipelineTrigger(
    id: d.id,
    eventType: d.eventType,
    templateId: d.templateId,
    workspaceId: d.workspaceId,
    enabled: d.enabled,
    cronExpression: d.cronExpression,
    match: d.match,
    lastFiredAt: d.lastFiredAt == null
        ? null
        : DateTime.parse(d.lastFiredAt!),
    createdAt: DateTime.parse(d.createdAt),
  );

  static PipelineTriggerDto _toDto(PipelineTrigger t) => PipelineTriggerDto(
    id: t.id,
    eventType: t.eventType,
    templateId: t.templateId,
    workspaceId: t.workspaceId,
    enabled: t.enabled,
    cronExpression: t.cronExpression,
    match: t.match,
    lastFiredAt: t.lastFiredAt?.toIso8601String(),
    createdAt: t.createdAt.toIso8601String(),
  );

  @override
  Future<void> insert(PipelineTrigger trigger) =>
      _remote.insert(_toDto(trigger));

  @override
  Future<void> update(PipelineTrigger trigger) =>
      _remote.update(_toDto(trigger));

  @override
  Future<void> deleteById(String id) => _remote.deleteById(id);

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async {
    final dtos = await _remote.forWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<PipelineTrigger>> enabledForEvent(String eventType) async {
    final dtos = await _remote.enabledForEvent(eventType);
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId) =>
      _remote.watchForWorkspace().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<PipelineTrigger?> getById(String id) async {
    try {
      final dto = await _remote.getById(id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<PipelineTrigger>> scheduled() async {
    final dtos = await _remote.scheduled();
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<void> markFired(String id, DateTime when) =>
      _remote.markFired(id, when);
}
