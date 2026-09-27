import 'package:cc_data/cc_data.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/space_folders.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A dismissed picker returns null; an unfiled destination has a null folder id.
typedef SpaceFolderDestination = ({String? folderId, bool create});

/// Prompts for a non-empty folder name without writing until confirmation.
Future<String?> showSpaceFolderNameDialog(
  BuildContext context, {
  required String title,
  required String initialName,
  required String confirmLabel,
}) => showCcDialog<String>(
  context: context,
  builder: (_) => _FolderNameDialog(
    title: title,
    initialName: initialName,
    confirmLabel: confirmLabel,
  ),
);

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({
    required this.title,
    required this.initialName,
    required this.confirmLabel,
  });

  final String title;
  final String initialName;
  final String confirmLabel;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _controller.text.trim();
    return CcDialog(
      title: widget.title,
      content: CcTextField(
        controller: _controller,
        label: l10n.folderName,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (name.isNotEmpty) Navigator.pop(context, name);
        },
      ),
      actions: [
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(
          size: CcButtonSize.lg,
          onPressed: name.isEmpty ? null : () => Navigator.pop(context, name),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// A touch-sized destination picker, including the explicit unfile action.
Future<SpaceFolderDestination?> showSpaceFolderDestinationDialog(
  BuildContext context, {
  required List<SpaceFolder> folders,
  required String? currentFolderId,
}) => showCcDialog<SpaceFolderDestination>(
  context: context,
  builder: (dialogContext) {
    final l10n = AppLocalizations.of(dialogContext);
    return CcDialog(
      title: l10n.moveSpaceToFolder,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: ListView(
          shrinkWrap: true,
          children: [
            CcButton(
              size: CcButtonSize.lg,
              fullWidth: true,
              variant: CcButtonVariant.secondary,
              icon: AppIcons.plus,
              onPressed: () =>
                  Navigator.pop(dialogContext, (folderId: null, create: true)),
              child: Text(l10n.newSpaceFolder),
            ),
            if (currentFolderId != null) ...[
              const SizedBox(height: 8),
              CcButton(
                size: CcButtonSize.lg,
                fullWidth: true,
                variant: CcButtonVariant.secondary,
                onPressed: () => Navigator.pop(dialogContext, (
                  folderId: null,
                  create: false,
                )),
                child: Text(l10n.removeSpaceFromFolder),
              ),
            ],
            for (final folder in folders) ...[
              const SizedBox(height: 8),
              CcButton(
                size: CcButtonSize.lg,
                fullWidth: true,
                variant: CcButtonVariant.secondary,
                icon: folder.id == currentFolderId
                    ? AppIcons.check
                    : AppIcons.folder,
                onPressed: () => Navigator.pop(dialogContext, (
                  folderId: folder.id,
                  create: false,
                )),
                child: Text(folder.name),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
      ],
    );
  },
);

/// Deletes a personal folder, optionally deleting its actual workspace spaces.
/// Stale ids in the preference never authorize deletion in another workspace.
Future<void> deleteRemoteSpaceFolder(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required SpaceFolder folder,
}) async {
  final actions = ref.read(spaceFolderActionsProvider(workspaceId));
  if (folder.spaceIds.isEmpty) {
    await actions.delete(folder.id);
    return;
  }
  final client = ref.read(rpcClientProvider).value;
  final deleteSpaces = await showCcDialog<bool>(
    context: context,
    builder: (_) => const _DeleteFolderDialog(),
  );
  if (deleteSpaces == null ||
      !context.mounted ||
      ref.read(activeWorkspaceIdProvider).value != workspaceId) {
    return;
  }
  if (deleteSpaces) {
    final connected = client ?? await ref.read(rpcClientProvider.future);
    if (connected == null) throw StateError('Connection unavailable');
    final owned = {
      for (final space in await RemoteMessagingRepository(
        connected,
      ).listSpaces(workspaceId))
        if (space.workspaceId == workspaceId) space.id,
    };
    final dispatch = RemoteMessagingDispatch(connected);
    for (final id in folder.spaceIds) {
      if (owned.remove(id)) await dispatch.deleteSpace(workspaceId, id);
    }
  }
  await actions.delete(folder.id);
}

class _DeleteFolderDialog extends StatefulWidget {
  const _DeleteFolderDialog();

  @override
  State<_DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<_DeleteFolderDialog> {
  bool _deleteSpaces = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: l10n.deleteSpaceFolder,
      content: CcAlert(
        variant: _deleteSpaces ? CcAlertVariant.danger : CcAlertVariant.info,
        title: _deleteSpaces
            ? l10n.deleteFolderWithSpacesWarning
            : l10n.keepSpacesInFolder,
        action: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          child: CcCheckbox(
            value: _deleteSpaces,
            onChanged: (value) => setState(() => _deleteSpaces = value),
            semanticLabel: l10n.deleteSpacesInFolder,
            label: Text(l10n.deleteSpacesInFolder),
          ),
        ),
      ),
      actions: [
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.destructive,
          onPressed: () => Navigator.pop(context, _deleteSpaces),
          child: Text(
            _deleteSpaces ? l10n.deleteFolderAndSpaces : l10n.deleteSpaceFolder,
          ),
        ),
      ],
    );
  }
}
