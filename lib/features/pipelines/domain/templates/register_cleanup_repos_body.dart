import 'package:control_center/core/domain/ports/pr_worktree_port.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the `repos.cleanup` body — removes stale isolated copy-on-write
/// worktrees, picking its mode from the trigger payload:
///
///  * `ticketId` present (ticket done/cancelled) → releases that ticket's
///    worktrees, scoped to the run's workspace
///    ([RepoWorkspaceProvisionerPort.releaseTicketInWorkspace]).
///  * `repoFullName` + `prNumber` present (PR merged/closed) → releases the
///    ephemeral PR-editor worktree ([PrWorktreePort.release]).
///  * neither (a manual run or the scheduled sweep) → sweeps every orphaned
///    worktree in the workspace whose on-disk copy has vanished
///    ([RepoWorkspaceProvisionerPort.sweepStale]).
///
/// All teardown ports are idempotent and no-op-safe, so this overlaps
/// harmlessly with the always-on `WorktreeGcListener` while adding an
/// auditable pipeline run and the manual / periodic sweep the listener does
/// not provide. Honors the context's `dryRun` flag and never reaches across
/// workspaces.
void registerCleanupReposBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required RepoWorkspaceProvisionerPort provisioner,
  required PrWorktreePort prWorktrees,
}) {
  registry.registerBody(BuiltInBodyKeys.cleanupRepos, (ctx) async {
    final config =
        (await templateRepository.getById(ctx.workspaceId, ctx.templateId))
            ?.step(ctx.stepId)
            ?.config;
    final outputKey = config?.outputKey;

    final ticketId = ctx.optional<String>('ticketId');
    final repoFullName = ctx.optional<String>('repoFullName');
    final prNumber = ctx.optional<num>('prNumber')?.toInt();

    final hasTicket = ticketId != null && ticketId.isNotEmpty;
    final hasPr =
        repoFullName != null && repoFullName.isNotEmpty && prNumber != null;

    final target = hasTicket
        ? 'ticket $ticketId'
        : hasPr
            ? 'PR $repoFullName#$prNumber'
            : 'sweep of workspace ${ctx.workspaceId}';

    if (ctx.dryRun) {
      return StepResult.ok(mutatedState: {
        ?outputKey: {'dryRun': true, 'target': target},
      });
    }

    final String summary;
    try {
      if (hasTicket) {
        final n = await provisioner.releaseTicketInWorkspace(
          workspaceId: ctx.workspaceId,
          ticketId: ticketId,
        );
        summary = n == 0
            ? 'No worktrees to release for ticket $ticketId'
            : 'Released $n worktree(s) for ticket $ticketId';
      } else if (hasPr) {
        await prWorktrees.release(
          repoFullName: repoFullName,
          prNumber: prNumber,
        );
        summary = 'Released PR worktree $repoFullName#$prNumber';
      } else {
        final reaped = await provisioner.sweepStale(workspaceId: ctx.workspaceId);
        summary = reaped == 0
            ? 'No stale worktrees to sweep'
            : 'Swept $reaped stale worktree(s)';
      }
    } catch (e) {
      return StepResult.failed('Worktree cleanup failed: $e');
    }

    return StepResult.ok(mutatedState: {
      ?outputKey: summary,
    });
  });
}
