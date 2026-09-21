import 'package:cc_domain/core/domain/ports/pr_worktree_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers `repos.cleanup` — removes stale CoW worktrees by trigger:
/// `ticketId` → [RepoWorkspaceProvisionerPort.releaseTicketInWorkspace];
/// `repoFullName`+`prNumber` → [PrWorktreePort.release];
/// `spaceId` → [RepoWorkspaceProvisionerPort.releaseSpace] (worktrees + folder);
/// else → [RepoWorkspaceProvisionerPort.sweepStale]. Idempotent; overlaps
/// `WorktreeGcListener` harmlessly. Honors `dryRun`; never cross-workspace.
void registerCleanupReposBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required RepoWorkspaceProvisionerPort provisioner,
  required PrWorktreePort prWorktrees,
}) {
  registry.registerBody(BuiltInBodyKeys.cleanupRepos, (ctx) async {
    final config = (await templateRepository.getById(
      ctx.workspaceId,
      ctx.templateId,
    ))?.step(ctx.stepId)?.config;
    final outputKey = config?.outputKey;

    final ticketId = ctx.optional<String>('ticket_id');
    final repoFullName = ctx.optional<String>('repo_full_name');
    final prNumber = ctx.optional<num>('pr_number')?.toInt();
    // `SpaceDeleted` carries the space it removed.
    final spaceId = ctx.optional<String>('space_id');

    final hasTicket = ticketId != null && ticketId.isNotEmpty;
    final hasPr =
        repoFullName != null && repoFullName.isNotEmpty && prNumber != null;
    final hasSpace =
        !hasTicket && !hasPr && spaceId != null && spaceId.isNotEmpty;

    final target = hasTicket
        ? 'ticket $ticketId'
        : hasPr
        ? 'PR $repoFullName#$prNumber'
        : hasSpace
        ? 'space $spaceId'
        : 'sweep of workspace ${ctx.workspaceId}';

    if (ctx.dryRun) {
      return StepResult.ok(
        mutatedState: {
          ?outputKey: {'dry_run': true, 'target': target},
        },
      );
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
      } else if (hasSpace) {
        await provisioner.releaseSpace(
          workspaceId: ctx.workspaceId,
          spaceId: spaceId,
        );
        summary = 'Released worktrees + folder for space $spaceId';
      } else {
        final reaped = await provisioner.sweepStale(
          workspaceId: ctx.workspaceId,
        );
        summary = reaped == 0
            ? 'No stale worktrees to sweep'
            : 'Swept $reaped stale worktree(s)';
      }
    } catch (e) {
      return StepResult.failed('Worktree cleanup failed: $e');
    }

    return StepResult.ok(mutatedState: {?outputKey: summary});
  });
}
