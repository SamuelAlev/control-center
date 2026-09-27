import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/space_folder_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selects an existing folder, creates one for this space, or removes the
/// current association. The menu always offers this action, even if empty.
Future<void> showMoveSpaceToFolderDialog(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required String spaceId,
}) async {
  final actions = ref.read(spaceFolderActionsProvider(workspaceId));
  final choice = await showCcDialog<({String? folderId})>(
    context: context,
    builder: (_) =>
        _MoveSpaceDialog(workspaceId: workspaceId, spaceId: spaceId),
  );
  if (choice != null) {
    await actions.move(spaceId, choice.folderId);
  }
}

class _MoveSpaceDialog extends ConsumerStatefulWidget {
  const _MoveSpaceDialog({required this.workspaceId, required this.spaceId});

  final String workspaceId;
  final String spaceId;

  @override
  ConsumerState<_MoveSpaceDialog> createState() => _MoveSpaceDialogState();
}

class _MoveSpaceDialogState extends ConsumerState<_MoveSpaceDialog> {
  final TextEditingController _name = TextEditingController();
  bool _creating = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _createAndMove() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final actions = ref.read(spaceFolderActionsProvider(widget.workspaceId));
      final id = await actions.create(name);
      await actions.move(widget.spaceId, id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final folders = ref.watch(spaceFoldersProvider(widget.workspaceId));
    final current = folders
        .where((folder) => folder.spaceIds.contains(widget.spaceId))
        .firstOrNull;
    return CcDialog(
      title: l10n.moveSpaceToFolder,
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (folders.isEmpty && !_creating)
              CcAlert(title: l10n.noSpaceFoldersYet),
            if (folders.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (current != null)
                      CcTile(
                        title: l10n.removeSpaceFromFolder,
                        onTap: () => Navigator.pop(context, (folderId: null)),
                      ),
                    for (final folder in folders)
                      CcTile(
                        title: folder.name,
                        leadingIcon: AppIcons.folder,
                        selected: folder.id == current?.id,
                        onTap: () =>
                            Navigator.pop(context, (folderId: folder.id)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (_creating)
              Row(
                children: [
                  Expanded(
                    child: CcTextField(
                      controller: _name,
                      hintText: l10n.folderName,
                      autofocus: true,
                      onSubmitted: (_) => unawaited(_createAndMove()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcButton(
                    onPressed: _busy ? null : () => unawaited(_createAndMove()),
                    child: Text(l10n.create),
                  ),
                ],
              )
            else
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: () => setState(() => _creating = true),
                child: Text(l10n.newSpaceFolder),
              ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
