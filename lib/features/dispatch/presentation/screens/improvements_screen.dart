import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvement_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvements_list.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';

/// Improvements: the inbox of what agents' reviews proposed, and one
/// proposal's page. The list and a proposal are sibling routes sharing one
/// page, so the inbox stays mounted under an open proposal.
class ImprovementsScreen extends StatelessWidget {
  /// Creates the screen, showing proposal [proposalId] when given.
  const ImprovementsScreen({super.key, this.proposalId});

  /// The open proposal, or null for the inbox.
  final String? proposalId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final id = proposalId;
    return PageWrapper(
      title: l10n.improvementsTitle,
      subtitle: l10n.improvementsSubtitle,
      child: IndexedStack(
        index: id == null ? 0 : 1,
        sizing: StackFit.expand,
        children: [
          ImprovementsList(workspaceId: workspaceId),
          if (id == null)
            const SizedBox.shrink()
          else
            ImprovementPage(
              key: ValueKey(id),
              workspaceId: workspaceId,
              proposalId: id,
            ),
        ],
      ),
    );
  }
}
