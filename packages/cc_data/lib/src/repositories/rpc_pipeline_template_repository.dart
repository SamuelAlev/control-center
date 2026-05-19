import 'package:cc_data/src/repositories/remote_pipeline_template_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PipelineTemplateRepository] backed by the RPC client — the thin-client
/// data path.
///
/// Implements the domain interface over the host's `pipeline_template.*` ops +
/// the `pipeline_template.watchForWorkspace` subscription, mapping the
/// [PipelineTemplateDto] wire shape back to [PipelineDefinition]. The host owns
/// persistence (including validation + version bumping on upsert); this client
/// never touches a database. Every call is scoped to the bound workspace
/// server-side, so the `workspaceId` arguments the interface threads are used
/// only to populate the entity the host already owns.
class RpcPipelineTemplateRepository implements PipelineTemplateRepository {
  /// Creates an [RpcPipelineTemplateRepository] over [client].
  RpcPipelineTemplateRepository(RemoteRpcClient client)
    : _remote = RemotePipelineTemplateRepository(client);

  final RemotePipelineTemplateRepository _remote;

  /// Rebuilds a [PipelineDefinition] from its wire DTO. Enum fields are encoded
  /// as `.name`; nested steps/inputs/config round-trip as inline maps.
  static PipelineDefinition _fromDto(PipelineTemplateDto d) =>
      PipelineDefinition(
        templateId: d.templateId,
        workspaceId: d.workspaceId,
        name: d.name,
        description: d.description,
        steps: d.steps.map(_stepFromDto).toList(),
        inputs: d.inputs.map(PipelineInput.fromJson).toList(),
        isBuiltIn: d.isBuiltIn,
        isEnabled: d.isEnabled,
        version: d.version,
      );

  static PipelineStepDefinition _stepFromDto(Map<String, dynamic> s) =>
      PipelineStepDefinition(
        id: s['id'] as String,
        kind: StepKind.values.asNameMap()[s['kind'] as String?] ??
            StepKind.listen,
        bodyKey: s['bodyKey'] as String,
        triggers: ((s['triggers'] as List?) ?? const [])
            .whereType<Map>()
            .map((t) => _triggerFromJson(t.cast<String, dynamic>()))
            .toList(),
        waitForStepIds:
            (s['waitForStepIds'] as List?)?.cast<String>() ?? const [],
        config: s['config'] is Map
            ? PipelineNodeConfig.fromJson(
                (s['config'] as Map).cast<String, dynamic>(),
              )
            : PipelineNodeConfig.empty,
        x: (s['x'] as num?)?.toDouble(),
        y: (s['y'] as num?)?.toDouble(),
      );

  static StepTrigger _triggerFromJson(Map<String, dynamic> t) => StepTrigger(
    sourceStepIds: (t['sourceStepIds'] as List?)?.cast<String>() ?? const [],
    routeKey: t['routeKey'] as String?,
  );

  static PipelineTemplateDto _toDto(PipelineDefinition d) => PipelineTemplateDto(
    templateId: d.templateId,
    workspaceId: d.workspaceId,
    name: d.name,
    description: d.description,
    steps: d.steps.map(_stepToJson).toList(),
    inputs: d.inputs.map((i) => i.toJson()).toList(),
    isBuiltIn: d.isBuiltIn,
    isEnabled: d.isEnabled,
    version: d.version,
  );

  static Map<String, dynamic> _stepToJson(PipelineStepDefinition s) => {
    'id': s.id,
    'kind': s.kind.name,
    'bodyKey': s.bodyKey,
    if (s.triggers.isNotEmpty)
      'triggers': s.triggers.map(_triggerToJson).toList(),
    if (s.waitForStepIds.isNotEmpty) 'waitForStepIds': s.waitForStepIds,
    'config': s.config.toJson(),
    if (s.x != null) 'x': s.x,
    if (s.y != null) 'y': s.y,
  };

  static Map<String, dynamic> _triggerToJson(StepTrigger t) => {
    'sourceStepIds': t.sourceStepIds,
    if (t.routeKey != null) 'routeKey': t.routeKey,
  };

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) =>
      _remote
          .watchForWorkspace()
          .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async {
    final dtos = await _remote.forWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async {
    try {
      final dto = await _remote.getById(templateId);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> upsert(PipelineDefinition definition) =>
      _remote.upsert(_toDto(definition));

  @override
  Future<int> deleteById(String workspaceId, String templateId) =>
      _remote.deleteById(templateId);
}
