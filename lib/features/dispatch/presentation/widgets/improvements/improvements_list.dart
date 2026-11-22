import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_list_row.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_record_states.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The improvements inbox: every proposal of the workspace the viewer may
/// read, grouped by status (proposed first), newest first in each group.
class ImprovementsList extends ConsumerWidget {
  /// Creates the list.
  const ImprovementsList({super.key, required this.workspaceId});

  /// The workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return WorkListStates<ImprovementProposalView>(
      value: ref.watch(workspaceImprovementsProvider(workspaceId)),
      emptyIcon: AppIcons.lightbulb,
      empty: l10n.improvementsEmpty,
      emptyDescription: l10n.improvementsEmptyHint,
      builder: (all) => ListView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        children: [
          for (final status in ImprovementStatus.values)
            if (all.where((v) => v.proposal.status == status).toList()
                case final group when group.isNotEmpty) ...[
              WorkListGroupHeading(
                label: improvementStatusLabel(l10n, status),
                count: group.length,
              ),
              for (var i = 0; i < group.length; i++)
                ImprovementRow(view: group[i], first: i == 0),
            ],
        ],
      ),
    );
  }
}

/// One proposal in the inbox: its status, what it changes, its kind and
/// scope, who proposed it, and whether it needs an admin.
class ImprovementRow extends ConsumerWidget {
  /// Creates the row.
  const ImprovementRow({super.key, required this.view, this.first = false});

  /// The proposal.
  final ImprovementProposalView view;

  /// Whether this is the first row of its group.
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final p = view.proposal;
    final agent =
        ref.watch(
          workAgentNameProvider((
            workspaceId: p.workspaceId,
            agentId: p.agentId,
          )),
        ) ??
        l10n.workAgentUnknown;
    return WorkListRow(
      first: first,
      tag: CcStatusTag(
        label: improvementStatusLabel(l10n, p.status),
        tone: improvementStatusTone(p.status),
      ),
      title: inertText(p.change, singleLine: true),
      meta: [
        l10n.improvementMeta(
          improvementKindLabel(l10n, p.kind),
          improvementScopeLabel(l10n, p.scope),
          agent,
        ),
        if (view.needsAdmin && p.status == ImprovementStatus.proposed)
          l10n.improvementRowNeedsAdmin,
      ],
      trailing: AppTimestamp.relative(
        p.createdAt,
        style: CcTypography.caption.copyWith(color: ds.textTertiary),
      ),
      onPressed: () => context.go(improvementRoute(p.workspaceId, p.id)),
    );
  }
}
