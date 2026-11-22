import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvement_page_header.dart';
import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvement_sections.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_record_states.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One improvement's page: loading, refused, not found, or the proposal with
/// what it changes, its evidence and the decision.
class ImprovementPage extends ConsumerWidget {
  /// Creates the page of [proposalId] in [workspaceId].
  const ImprovementPage({
    super.key,
    required this.workspaceId,
    required this.proposalId,
  });

  /// The workspace.
  final String workspaceId;

  /// The proposal.
  final String proposalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void back() => ref
        .read(navigationHistoryProvider.notifier)
        .backOr(improvementsRoute(workspaceId));
    return WorkRecordStates<ImprovementProposalView>(
      value: ref.watch(
        improvementViewProvider((workspaceId: workspaceId, id: proposalId)),
      ),
      notFound: l10n.improvementNotFound,
      backLabel: l10n.improvementsBackToList,
      onBack: back,
      builder: (view) => ListView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        children: [
          ImprovementPageHeader(view: view, onBack: back),
          const SizedBox(height: AppSpacing.lg),
          ImprovementChangeSection(proposal: view.proposal),
          ImprovementEvidenceSection(
            proposal: view.proposal,
            evaluation: view.evaluation,
          ),
        ],
      ),
    );
  }
}
