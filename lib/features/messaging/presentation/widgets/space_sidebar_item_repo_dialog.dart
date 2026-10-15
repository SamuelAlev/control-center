part of 'space_sidebar_item.dart';

/// Opens [space]'s repository editor: the same repo multi-select the create
/// dialog offers, WITHOUT the agent picker — agents on a space are managed
/// from the space header, never from here. Saving a selection that drops
/// repos tears those worktree folders down server-side, and one that ADDS a
/// repo re-provisions the space so the new checkout is materialized; the
/// dialog says so before the user commits to it.
///
/// Save returns as soon as the selection is written — the checkout runs in the
/// background and the space reports it through its ordinary provisioning
/// status (the composer parks behind "preparing workspace" and shows the same
/// per-repo progress a new space does), so there is nothing to await here.
Future<void> showEditSpaceReposDialog(
  BuildContext context,
  WidgetRef ref,
  Space space,
) async {
  final workspaceId = ref.requireWorkspaceId();
  final repos = await ref.read(reposForWorkspaceProvider(workspaceId).future);
  final current = await ref
      .read(messagingServiceProvider)
      .getSpaceRepos(workspaceId, space.id);
  if (!context.mounted) {
    return;
  }
  final saved = await showCcDialog<({List<String>? repoIds})>(
    context: context,
    builder: (_) => _EditSpaceReposDialog(repos: repos, current: current),
  );
  if (saved == null || !context.mounted) {
    return;
  }
  await ref
      .read(messagingServiceProvider)
      .setSpaceRepos(workspaceId, space.id, saved.repoIds);
}

class _EditSpaceReposDialog extends StatefulWidget {
  const _EditSpaceReposDialog({required this.repos, required this.current});

  /// Every repo linked to the workspace (the picker's universe).
  final List<Repo> repos;

  /// The space's effective selection on open: null → all workspace repos,
  /// an EMPTY list → explicitly none, a subset → those ids.
  final List<String>? current;

  @override
  State<_EditSpaceReposDialog> createState() => _EditSpaceReposDialogState();
}

class _EditSpaceReposDialogState extends State<_EditSpaceReposDialog> {
  /// "All workspace repos" is the default, so a null (unrestricted) selection
  /// starts as every repo checked — the same default the create dialog uses.
  late final Set<String> _selected = {
    for (final r in widget.repos)
      if (widget.current == null || widget.current!.contains(r.id)) r.id,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.editSpaceReposTitle,
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcMultiSelect<String>(
              values: _selected,
              hintText: l10n.spaceReposHint,
              options: widget.repos
                  .map(
                    (repo) =>
                        CcSelectOption(value: repo.id, label: repo.fullName),
                  )
                  .toList(),
              onChanged: (next) => setState(
                () => _selected
                  ..clear()
                  ..addAll(next),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.editSpaceReposWarning,
              style: CcTypography.caption.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () {
            // Everything checked (or a repo-less workspace) is the "all
            // repos" default — persisted as null so repos added to the
            // workspace later follow the space. An explicitly emptied
            // selection stays an empty list: the space checks out nothing.
            final repoIds = _selected.length == widget.repos.length
                ? null
                : _selected.toList();
            Navigator.of(context).pop((repoIds: repoIds));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
