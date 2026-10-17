part of 'space_folders_list.dart';

extension _FolderActions on _RemoteSpaceFoldersListState {
  Future<void> _folderAction(SpaceFolder folder) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showCcDialog<_FolderAction>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.spaceFolderActions,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              onPressed: () =>
                  Navigator.pop(dialogContext, _FolderAction.rename),
              child: Text(l10n.renameSpaceFolder),
            ),
            const SizedBox(height: 8),
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.destructive,
              onPressed: () =>
                  Navigator.pop(dialogContext, _FolderAction.delete),
              child: Text(l10n.deleteSpaceFolder),
            ),
          ],
        ),
        actions: [
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (choice == null || !mounted || !_isCurrent) return;
    if (choice == _FolderAction.rename) {
      final name = await showSpaceFolderNameDialog(
        context,
        title: l10n.renameSpaceFolder,
        initialName: folder.name,
        confirmLabel: l10n.save,
      );
      if (name != null && _isCurrent) {
        await _run(
          () => ref
              .read(spaceFolderActionsProvider(widget.workspaceId))
              .rename(folder.id, name),
        );
      }
    } else {
      await _run(
        () => deleteRemoteSpaceFolder(
          context,
          ref,
          workspaceId: widget.workspaceId,
          folder: folder,
        ),
      );
    }
  }
}
