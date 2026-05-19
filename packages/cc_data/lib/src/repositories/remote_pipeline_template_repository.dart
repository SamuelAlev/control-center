import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates pipeline templates over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one and
/// enforces that any template read/written/deleted belongs to that workspace.
/// Mirrors the `pipeline_template.*` ops + the
/// `pipeline_template.watchForWorkspace` subscription in the host catalog.
class RemotePipelineTemplateRepository {
  /// Creates a [RemotePipelineTemplateRepository] over [_client].
  RemotePipelineTemplateRepository(this._client);

  final RemoteRpcClient _client;

  /// Live templates for the bound workspace — a fresh snapshot
  /// ([PipelineTemplateDto] list) on every change, built-ins first then alpha.
  Stream<List<PipelineTemplateDto>> watchForWorkspace() => _client
      .subscribe('pipeline_template.watchForWorkspace', const {})
      .map(_templates);

  /// One-shot fetch of every template in the bound workspace.
  Future<List<PipelineTemplateDto>> forWorkspace() async {
    final data = await _client.call(
      'pipeline_template.forWorkspace',
      const {},
    );
    return _templates(data);
  }

  /// A single template by id (scoped to the bound workspace server-side), or
  /// null when it does not exist.
  Future<PipelineTemplateDto?> getById(String templateId) async {
    final data = await _client.call('pipeline_template.getById', {
      'template_id': templateId,
    });
    final template = data['template'];
    return template is Map
        ? PipelineTemplateDto.fromJson(template.cast<String, dynamic>())
        : null;
  }

  /// Inserts or replaces [template] (the host owns persistence + validation +
  /// version bumping).
  Future<void> upsert(PipelineTemplateDto template) => _client.call(
    'pipeline_template.upsert',
    {'template': template.toJson()},
  );

  /// Deletes a template by id in the bound workspace. Returns the number of
  /// rows removed.
  Future<int> deleteById(String templateId) async {
    final data = await _client.call('pipeline_template.deleteById', {
      'template_id': templateId,
    });
    return (data['deleted'] as num?)?.toInt() ?? 0;
  }

  List<PipelineTemplateDto> _templates(Map<String, dynamic> data) =>
      ((data['templates'] as List?) ?? const [])
          .whereType<Map>()
          .map((t) => PipelineTemplateDto.fromJson(t.cast<String, dynamic>()))
          .toList();
}
