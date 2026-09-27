import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the workspace-only backup and age-based retention nodes.
/// Neither node can address whole-install snapshots or another workspace.
void registerWorkspaceBackupBodies(
  PipelineBodyRegistry registry, {
  required DatabaseBackupPort? backups,
  required PipelineTemplateRepository templateRepository,
}) {
  registry.registerBody(BuiltInBodyKeys.backupWorkspace, (ctx) async {
    if (backups == null) {
      return StepResult.failed(
        'Workspace backups are unavailable on this host',
      );
    }
    final config = (await templateRepository.getById(
      ctx.workspaceId,
      ctx.templateId,
    ))?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed(
        'Workspace backup step configuration is missing',
      );
    }
    if (ctx.dryRun) {
      return StepResult.ok();
    }
    try {
      final path = await backups.backupWorkspace(ctx.workspaceId);
      return StepResult.ok(mutatedState: {?config.outputKey: path});
    } on Object catch (error) {
      return StepResult.failed('Workspace backup failed: $error');
    }
  });

  registry.registerBody(BuiltInBodyKeys.deleteOldBackups, (ctx) async {
    if (backups == null) {
      return StepResult.failed(
        'Workspace backups are unavailable on this host',
      );
    }
    final config = (await templateRepository.getById(
      ctx.workspaceId,
      ctx.templateId,
    ))?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed(
        'Workspace retention step configuration is missing',
      );
    }
    final rawDays = config.extras['retentionDays'] ?? 30;
    if (rawDays is! int || rawDays <= 0) {
      return StepResult.failed(
        'Backup retention days must be a positive integer',
      );
    }
    if (ctx.dryRun) {
      return StepResult.ok();
    }
    try {
      final removed = await backups.deleteBackupsOlderThan(
        age: Duration(days: rawDays),
        workspaceId: ctx.workspaceId,
      );
      return StepResult.ok(mutatedState: {?config.outputKey: removed});
    } on Object catch (error) {
      return StepResult.failed('Workspace backup retention failed: $error');
    }
  });
}
