import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';

/// Deletes the pipeline template [templateId] of [workspaceId] together with
/// its triggers, and returns how many templates went (0 or 1).
///
/// The triggers go first, through their own repository: a webhook trigger
/// owns a route and a stored secret that only that repository knows how to
/// forget. Deleting the template alone would take the trigger rows with it
/// (the schema cascades) and leave the route and the secret behind.
Future<int> deletePipelineTemplate({
  required PipelineTemplateRepository templates,
  required PipelineTriggerRepository triggers,
  required String workspaceId,
  required String templateId,
}) async {
  for (final trigger in await triggers.forWorkspace(workspaceId)) {
    if (trigger.templateId == templateId) {
      await triggers.deleteById(workspaceId, trigger.id);
    }
  }
  return templates.deleteById(workspaceId, templateId);
}
