import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_evaluation_summary.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_verification_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/widgets/inline_diff_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// What an improvement changes: the operation, what it targets and where it
/// applies, and the text (a before and after diff for a replace; the new
/// text for an add; the removed text for a remove), then the effect the
/// agent expects.
class ImprovementChangeSection extends ConsumerWidget {
  /// Creates the section.
  const ImprovementChangeSection({super.key, required this.proposal});

  /// The proposal.
  final ImprovementProposal proposal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final p = proposal;
    final codeFont = ref.watch(codeFontFamilyProvider);
    final label = workSectionLabelStyle(ds);
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    final before = p.beforeText;
    final after = p.afterText;
    return WorkSection(
      title: l10n.improvementSectionChange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${improvementKindLabel(l10n, p.kind)} · '
            '${improvementOperationLabel(l10n, p.operation)}',
            style: body,
          ),
          if (p.targetRef case final target?) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Text(l10n.improvementTarget, style: label),
                const SizedBox(width: AppSpacing.xs),
                Flexible(child: WorkCode(target)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.improvementScopeLine(improvementScopeLabel(l10n, p.scope)),
            style: label,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(inertText(p.change), style: body),
          const SizedBox(height: AppSpacing.sm),
          // RTL carve-out: the before and after texts are shown as a diff,
          // which lays its lines out left to right in every locale.
          if (p.operation == ImprovementOperation.replace &&
              before != null &&
              after != null)
            InlineDiffView(
              oldText: before,
              newText: after,
              codeFont: codeFont,
              tokens: ds,
              maxHeight: 420,
            )
          else if (after != null && after.isNotEmpty)
            buildLabeledToolBlock(
              context,
              label: l10n.improvementNewText,
              body: after,
              codeFont: codeFont,
              tokens: ds,
            )
          else if (before != null && before.isNotEmpty)
            buildLabeledToolBlock(
              context,
              label: l10n.improvementRemovedText,
              body: before,
              codeFont: codeFont,
              tokens: ds,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.improvementExpected, style: label),
          Text(inertText(p.expected), style: body),
        ],
      ),
    );
  }
}

/// Why the agent proposed it: the runs and messages it points to (each
/// message opens in its conversation) and the check results it cites; then
/// the evaluation of a skill change and the decision.
class ImprovementEvidenceSection extends ConsumerWidget {
  /// Creates the section.
  const ImprovementEvidenceSection({
    super.key,
    required this.proposal,
    required this.evaluation,
  });

  /// The proposal.
  final ImprovementProposal proposal;

  /// The campaign report's numbers of a skill change, when it has one.
  final ImprovementEvaluationSummary? evaluation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final p = proposal;
    final e = p.evidence;
    final label = workSectionLabelStyle(ds);
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    final space = p.spaceId;
    final decider = p.decidedByUserId == null
        ? null
        : ref.watch(
            workMemberNameProvider((
              workspaceId: p.workspaceId,
              userId: p.decidedByUserId!,
            )),
          );
    final decidedAt = p.decidedAt;
    return WorkSection(
      title: l10n.improvementSectionEvidence,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (e.runIds.isEmpty &&
              e.messageIds.isEmpty &&
              e.checkResults.isEmpty)
            Text(l10n.improvementNoEvidence, style: body),
          if (e.runIds.isNotEmpty) ...[
            Text(l10n.improvementEvidenceRuns, style: label),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              children: [for (final id in e.runIds) WorkCode(id)],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (e.messageIds.isNotEmpty) ...[
            Text(l10n.improvementEvidenceMessages, style: label),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              children: [
                for (var i = 0; i < e.messageIds.length; i++)
                  if (space == null)
                    WorkCode(e.messageIds[i])
                  else
                    CcButton(
                      variant: CcButtonVariant.ghost,
                      size: CcButtonSize.sm,
                      onPressed: () => context.go(
                        spaceRoute(
                          p.workspaceId,
                          space,
                          messageId: e.messageIds[i],
                        ),
                      ),
                      child: Text(l10n.improvementOpenMessage(i + 1)),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (e.checkResults.isNotEmpty) ...[
            Text(l10n.improvementEvidenceChecks, style: label),
            for (final r in e.checkResults) GoalCheckResultLine(result: r),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (p.isSkillChange) ...[
            Text(l10n.improvementEvaluation, style: label),
            Text(switch (p.campaignState) {
              ImprovementCampaignState.none => l10n.improvementCampaignNone,
              // Staging is the start claiming the proposal: it reads as running.
              ImprovementCampaignState.staging ||
              ImprovementCampaignState.running =>
                l10n.improvementCampaignRunning,
              ImprovementCampaignState.passed => l10n.improvementCampaignPassed,
              ImprovementCampaignState.failed => l10n.improvementCampaignFailed,
            }, style: body),
            if (evaluation case final e?)
              Text(
                improvementEvaluationSentences(l10n, e).join(' '),
                style: body,
              ),
            // The candidate is a stored revision until a person accepts it;
            // a start stores it, and a refused accept on a moved skill drops it.
            if (p.status == ImprovementStatus.proposed &&
                p.candidateRevisionId != null)
              Text(l10n.improvementCandidateStaged, style: body),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (decidedAt != null)
            WorkTime(
              at: decidedAt,
              text: l10n.improvementDecided(
                improvementStatusLabel(l10n, p.status),
                decider ?? l10n.improvementSomeone,
                workTimeLabel(context, decidedAt),
              ),
              style: body,
            )
          else if (p.status == ImprovementStatus.proposed)
            WorkTime(
              at: p.expiresAt,
              text: l10n.improvementExpires(
                workTimeLabel(context, p.expiresAt),
              ),
              style: body,
            ),
          if (p.status == ImprovementStatus.accepted && p.appliedRef != null)
            _AppliedLink(proposal: p),
        ],
      ),
    );
  }
}

class _AppliedLink extends StatelessWidget {
  const _AppliedLink({required this.proposal});

  final ImprovementProposal proposal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = proposal;
    final ref = p.appliedRef!;
    final target = switch (p.kind) {
      ImprovementKind.memoryFact => memoryFactRoute(p.workspaceId, ref),
      ImprovementKind.policy => memoryPolicyRoute(p.workspaceId, ref),
      ImprovementKind.skillEdit ||
      ImprovementKind.skillNew => settingsSkillsRoute(p.workspaceId),
      ImprovementKind.agentNote => null,
    };
    if (target == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: () => context.go(target),
          child: Text(l10n.improvementOpenApplied),
        ),
      ),
    );
  }
}
