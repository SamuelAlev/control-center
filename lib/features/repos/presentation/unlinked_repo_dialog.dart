import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/widgets.dart';

/// What the user picked in [showUnlinkedRepoDialog].
enum UnlinkedRepoAction {
  /// Add the repository's checkout to the current workspace.
  addToCurrentWorkspace,

  /// Create a workspace, then add the repository's checkout to it.
  createWorkspace,
}

/// Asks what a link to [repoFullName] should do when no workspace links the
/// repository: add it to [currentWorkspace], create a workspace for it, or
/// nothing.
///
/// Without a [currentWorkspace] only creating one is offered. Resolves to null
/// when dismissed.
Future<UnlinkedRepoAction?> showUnlinkedRepoDialog({
  required BuildContext context,
  required String repoFullName,
  required Workspace? currentWorkspace,
}) => showCcDialog<UnlinkedRepoAction>(
  context: context,
  builder: (_) => UnlinkedRepoDialog(
    repoFullName: repoFullName,
    currentWorkspace: currentWorkspace,
  ),
);

/// The body of [showUnlinkedRepoDialog].
class UnlinkedRepoDialog extends StatefulWidget {
  /// Creates an [UnlinkedRepoDialog].
  const UnlinkedRepoDialog({
    super.key,
    required this.repoFullName,
    required this.currentWorkspace,
  });

  /// The repository the link names, as `owner/name`.
  final String repoFullName;

  /// The workspace the user is in, offered as the place to add the repository.
  final Workspace? currentWorkspace;

  @override
  State<UnlinkedRepoDialog> createState() => _UnlinkedRepoDialogState();
}

class _UnlinkedRepoDialogState extends State<UnlinkedRepoDialog> {
  late UnlinkedRepoAction _selected = widget.currentWorkspace == null
      ? UnlinkedRepoAction.createWorkspace
      : UnlinkedRepoAction.addToCurrentWorkspace;

  void _select(UnlinkedRepoAction action) => setState(() => _selected = action);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final current = widget.currentWorkspace;

    return CcDialog(
      title: l10n.repoLinkUnlinkedTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.repoLinkUnlinkedBody(widget.repoFullName)),
          const SizedBox(height: AppSpacing.md),
          if (current != null)
            _ActionTile(
              action: UnlinkedRepoAction.addToCurrentWorkspace,
              selected: _selected,
              onSelect: _select,
              icon: WorkspaceAvatar(
                workspaceId: current.id,
                name: current.name,
                hasLogo: current.logoPath?.isNotEmpty ?? false,
                size: 20,
              ),
              title: l10n.repoLinkUnlinkedAddTo(current.name),
              hint: l10n.repoLinkUnlinkedAddToHint,
            ),
          _ActionTile(
            action: UnlinkedRepoAction.createWorkspace,
            selected: _selected,
            onSelect: _select,
            icon: SizedBox.square(
              dimension: 20,
              child: Icon(CcIcons.plus, size: 16, color: tokens?.textSecondary),
            ),
            title: l10n.repoLinkUnlinkedCreate,
            hint: l10n.repoLinkUnlinkedCreateHint,
          ),
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(switch (_selected) {
            UnlinkedRepoAction.addToCurrentWorkspace => l10n.addRepository,
            UnlinkedRepoAction.createWorkspace => l10n.addWorkspace,
          }),
        ),
      ],
    );
  }
}

/// One choice: a radio, the destination's [icon], and what picking it does.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.selected,
    required this.onSelect,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final UnlinkedRepoAction action;
  final UnlinkedRepoAction selected;
  final ValueChanged<UnlinkedRepoAction> onSelect;
  final Widget icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return CcTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcRadio<UnlinkedRepoAction>(
            value: action,
            groupValue: selected,
            onChanged: onSelect,
            semanticLabel: title,
          ),
          const SizedBox(width: AppSpacing.sm),
          icon,
        ],
      ),
      title: title,
      subtitle: Text(hint),
      selected: action == selected,
      onTap: () => onSelect(action),
    );
  }
}
