import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_folder_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Removes a personal folder. Destruction of its workspace spaces is a
/// separate, explicitly checked action; cancellation changes neither.
Future<void> showDeleteSpaceFolderDialog(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required SpaceFolder folder,
}) async {
  final router = GoRouter.of(context);
  final actions = ref.read(spaceFolderActionsProvider(workspaceId));
  if (folder.spaceIds.isEmpty) {
    await actions.delete(folder.id);
    return;
  }

  final deleteSpaces = await showCcDialog<bool>(
    context: context,
    builder: (_) => const _DeleteFolderDialog(),
  );
  if (deleteSpaces == null || !context.mounted) {
    return;
  }

  if (deleteSpaces) {
    // The folder preference can retain ids for spaces already deleted or
    // archived. Only the current workspace's actual space rows are eligible
    // for deletion, including archived ones left by older clients.
    final spaces = await ref.read(workspaceSpacesProvider(workspaceId).future);
    final ownedIds = {
      for (final Space space in spaces)
        if (space.workspaceId == null || space.workspaceId == workspaceId)
          space.id,
    };
    final service = ref.read(messagingServiceProvider);
    for (final id in folder.spaceIds) {
      if (ownedIds.remove(id)) {
        await service.deleteSpace(workspaceId, id);
      }
    }
  }
  await actions.delete(folder.id);
  if (deleteSpaces) {
    // Removing a folder can unmount its row before navigation runs.
    final selected = selectedSpaceIdFromLocation(
      router.routeInformationProvider.value.uri.path,
      workspaceId,
    );
    if (selected != null && folder.spaceIds.contains(selected)) {
      router.go(spacesRoute(workspaceId));
    }
  }
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
      content: SizedBox(
        width: 400,
        child: CcAlert(
          variant: _deleteSpaces ? CcAlertVariant.danger : CcAlertVariant.info,
          title: _deleteSpaces
              ? l10n.deleteFolderWithSpacesWarning
              : l10n.keepSpacesInFolder,
          action: CcCheckbox(
            value: _deleteSpaces,
            onChanged: (value) => setState(() => _deleteSpaces = value),
            semanticLabel: l10n.deleteSpacesInFolder,
            label: Text(l10n.deleteSpacesInFolder),
          ),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(
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
