import 'package:cc_data/src/repositories/remote_pipeline_trigger_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PipelineTriggerConfigRepository] backed by the RPC client — the
/// thin-client data path.
///
/// Implements the domain interface over the host's `pipeline_trigger.*` ops +
/// the `pipeline_trigger.watchForWorkspace` subscription, mapping the
/// [PipelineTriggerDto] wire shape back to [PipelineTrigger]. The host owns
/// persistence and enforces workspace ownership; this client never touches a
/// database.
///
/// The dispatcher's and scheduler's reads and writes (`enabledForEvent`,
/// `scheduled`, `markFired`, ...) are server-side only and have no op.
class RpcPipelineTriggerRepository implements PipelineTriggerConfigRepository {
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
    timezone: d.timezone,
    nextRunAt: d.nextRunAt == null ? null : DateTime.parse(d.nextRunAt!),
    webhookToken: d.webhookToken,
    eventFilters: d.eventFilters,
    match: d.match,
    lastFiredAt: d.lastFiredAt == null ? null : DateTime.parse(d.lastFiredAt!),
    catchUpPolicy: CronCatchUpPolicy.fromName(d.catchUpPolicy),
    createdAt: DateTime.parse(d.createdAt),
  );

  static PipelineTriggerDto _toDto(PipelineTrigger t) => PipelineTriggerDto(
    id: t.id,
    eventType: t.eventType,
    templateId: t.templateId,
    workspaceId: t.workspaceId,
    enabled: t.enabled,
    cronExpression: t.cronExpression,
    timezone: t.timezone,
    nextRunAt: t.nextRunAt?.toIso8601String(),
    webhookToken: t.webhookToken,
    eventFilters: t.eventFilters,
    match: t.match,
    lastFiredAt: t.lastFiredAt?.toIso8601String(),
    catchUpPolicy: t.catchUpPolicy.name,
    createdAt: t.createdAt.toIso8601String(),
  );

  @override
  Future<void> insert(PipelineTrigger trigger) =>
      _remote.insert(_toDto(trigger));

  @override
  Future<void> update(PipelineTrigger trigger) =>
      _remote.update(_toDto(trigger));

  @override
  Future<void> deleteById(String workspaceId, String id) =>
      _remote.deleteById(workspaceId, id);

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async {
    final dtos = await _remote.forWorkspace(workspaceId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId) => _remote
      .watchForWorkspace(workspaceId)
      .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<PipelineTrigger?> getById(String workspaceId, String id) async {
    try {
      final dto = await _remote.getById(workspaceId, id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }
}
