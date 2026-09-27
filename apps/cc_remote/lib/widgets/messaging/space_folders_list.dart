import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/space_folders.dart';
import 'package:cc_remote/widgets/messaging/space_folder_dialogs.dart';
import 'package:cc_remote/widgets/messaging/space_folder_rows.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef _SpaceRow = ({SpaceFolder? folder, SpaceDto? space, String? parentId});

enum _FolderAction { rename, delete }

/// Personal folders before the workspace's remaining active spaces.
class RemoteSpaceFoldersList extends ConsumerStatefulWidget {
  /// Builds the phone's grouped, touch-actionable space list.
  const RemoteSpaceFoldersList({
    required this.workspaceId,
    required this.spaces,
    required this.folders,
    super.key,
  });

  /// Explicit workspace scope for preferences and every mutation.
  final String workspaceId;

  /// Server-owned spaces; only active rows owned by [workspaceId] render.
  final List<SpaceDto> spaces;

  /// The signed-in user's live folder arrangement for [workspaceId].
  final List<SpaceFolder> folders;

  @override
  ConsumerState<RemoteSpaceFoldersList> createState() =>
      _RemoteSpaceFoldersListState();
}

class _RemoteSpaceFoldersListState
    extends ConsumerState<RemoteSpaceFoldersList> {
  final _expanded = <String, bool>{};
  bool _failed = false;

  bool get _isCurrent =>
      mounted &&
      ref.read(activeWorkspaceIdProvider).value == widget.workspaceId;

  Future<void> _run(Future<void> Function() action) async {
    if (!_isCurrent) return;
    setState(() => _failed = false);
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _createFolder([SpaceDto? space]) async {
    final l10n = AppLocalizations.of(context);
    final name = await showSpaceFolderNameDialog(
      context,
      title: l10n.newSpaceFolder,
      initialName: '',
      confirmLabel: l10n.create,
    );
    if (name == null || !_isCurrent) return;
    if (space != null &&
        !(ref.read(spacesProvider).value ?? const <SpaceDto>[]).any(
          (row) =>
              row.id == space.id &&
              row.workspaceId == widget.workspaceId &&
              row.archivedAt == null,
        )) {
      return;
    }
    await _run(() async {
      await ref
          .read(spaceFolderActionsProvider(widget.workspaceId))
          .create(name, spaceIds: space == null ? const [] : [space.id]);
    });
  }

  Future<void> _moveSpace(SpaceDto space, String? currentFolderId) async {
    final destination = await showSpaceFolderDestinationDialog(
      context,
      folders: widget.folders,
      currentFolderId: currentFolderId,
    );
    if (destination == null || !_isCurrent) return;
    if (destination.create) {
      await _createFolder(space);
    } else if (destination.folderId != currentFolderId) {
      await _run(
        () => ref
            .read(spaceFolderActionsProvider(widget.workspaceId))
            .move(space.id, destination.folderId),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final available = <String, SpaceDto>{
      for (final space in widget.spaces)
        if (space.workspaceId == widget.workspaceId && space.archivedAt == null)
          space.id: space,
    };
    final filed = <String>{};
    final rows = <_SpaceRow>[];
    for (final folder in widget.folders) {
      rows.add((folder: folder, space: null, parentId: null));
      if (_expanded[folder.id] ?? true) {
        for (final id in folder.spaceIds) {
          final space = available[id];
          if (space != null && filed.add(id)) {
            rows.add((folder: null, space: space, parentId: folder.id));
          }
        }
      } else {
        // Collapsing a folder must not list its members again as unfiled.
        for (final id in folder.spaceIds) {
          if (available.containsKey(id)) filed.add(id);
        }
      }
    }
    final unfiled = [
      for (final space in available.values)
        if (!filed.contains(space.id)) space,
    ];
    if (unfiled.isNotEmpty && widget.folders.isNotEmpty) {
      rows.add((folder: null, space: null, parentId: null));
    }
    for (final space in unfiled) {
      rows.add((folder: null, space: space, parentId: null));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
          child: CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.plus,
            onPressed: () => unawaited(_createFolder()),
            child: Text(l10n.newSpaceFolder),
          ),
        ),
        if (_failed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CcAlert(
              variant: CcAlertVariant.danger,
              title: l10n.folderUpdateFailed,
              onClose: () => setState(() => _failed = false),
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? CcEmptyState(
                  icon: AppIcons.messageCircle,
                  message: l10n.noSpaces,
                  description: l10n.spacesEmptyDescription,
                )
              : ListView.builder(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    if (row.folder case final folder?) {
                      final expanded = _expanded[folder.id] ?? true;
                      return RemoteSpaceFolderRow(
                        key: ValueKey('folder-${folder.id}'),
                        folder: folder,
                        expanded: expanded,
                        onToggle: () =>
                            setState(() => _expanded[folder.id] = !expanded),
                        onActions: () => unawaited(_folderAction(folder)),
                      );
                    }
                    if (row.space case final space?) {
                      return RemoteSpaceCard(
                        key: ValueKey('space-${space.id}'),
                        space: space,
                        inFolder: row.parentId != null,
                        onMove: () =>
                            unawaited(_moveSpace(space, row.parentId)),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        16,
                        0,
                        8,
                      ),
                      child: Text(
                        l10n.otherSpaces,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.fgSecondary,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
