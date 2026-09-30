import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/widgets.dart';

/// What the user picked in [showRepoLinkWorkspaceDialog].
@immutable
class RepoLinkWorkspaceDecision {
  /// Creates a [RepoLinkWorkspaceDecision].
  const RepoLinkWorkspaceDecision({
    required this.workspaceId,
    required this.remember,
  });

  /// The workspace to open the link in.
  final String workspaceId;

  /// Whether later links to the same repository skip the question.
  final bool remember;
}

/// Asks which workspace a link to [repoFullName] opens in, when the repository
/// is linked in more than one.
///
/// [workspaces] are those linking it, in the operator's workspace order, with
/// [initialWorkspaceId] preselected. Resolves to null when dismissed.
Future<RepoLinkWorkspaceDecision?> showRepoLinkWorkspaceDialog({
  required BuildContext context,
  required String repoFullName,
  required List<Workspace> workspaces,
  required String initialWorkspaceId,
}) => showCcDialog<RepoLinkWorkspaceDecision>(
  context: context,
  builder: (_) => RepoLinkWorkspaceDialog(
    repoFullName: repoFullName,
    workspaces: workspaces,
    initialWorkspaceId: initialWorkspaceId,
  ),
);

/// The body of [showRepoLinkWorkspaceDialog].
class RepoLinkWorkspaceDialog extends StatefulWidget {
  /// Creates a [RepoLinkWorkspaceDialog].
  const RepoLinkWorkspaceDialog({
    super.key,
    required this.repoFullName,
    required this.workspaces,
    required this.initialWorkspaceId,
  });

  /// The repository the link names, as `owner/name`.
  final String repoFullName;

  /// The workspaces linking the repository, in display order.
  final List<Workspace> workspaces;

  /// The workspace selected when the dialog opens.
  final String initialWorkspaceId;

  @override
  State<RepoLinkWorkspaceDialog> createState() =>
      _RepoLinkWorkspaceDialogState();
}

class _RepoLinkWorkspaceDialogState extends State<RepoLinkWorkspaceDialog> {
  late String _selected = widget.initialWorkspaceId;
  bool _remember = false;

  void _select(String workspaceId) => setState(() => _selected = workspaceId);

  void _open() => Navigator.pop(
    context,
    RepoLinkWorkspaceDecision(workspaceId: _selected, remember: _remember),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CcDialog(
      title: l10n.repoLinkWorkspaceDialogTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.repoLinkWorkspaceDialogBody(widget.repoFullName)),
          const SizedBox(height: AppSpacing.md),
          for (final workspace in widget.workspaces)
            CcTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CcRadio<String>(
                    value: workspace.id,
                    groupValue: _selected,
                    onChanged: _select,
                    semanticLabel: workspace.name,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  WorkspaceAvatar(
                    workspaceId: workspace.id,
                    name: workspace.name,
                    hasLogo: workspace.logoPath?.isNotEmpty ?? false,
                    size: 20,
                  ),
                ],
              ),
              title: workspace.name,
              selected: workspace.id == _selected,
              onTap: () => _select(workspace.id),
            ),
          const SizedBox(height: AppSpacing.md),
          CcCheckbox(
            value: _remember,
            onChanged: (remember) => setState(() => _remember = remember),
            label: Text(l10n.repoLinkWorkspaceRemember),
          ),
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(onPressed: _open, child: Text(l10n.repoLinkWorkspaceOpen)),
      ],
    );
  }
}
