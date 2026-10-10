import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_folder_delete_dialog.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_layout.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/space_folder_providers.dart';
import 'package:control_center/features/shell/providers/shell_route_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'space_folders_list_drag_row.dart';

typedef _SpaceDragData = ({String workspaceId, String spaceId});

/// Creates a folder in the current workspace's personal space list.
Future<void> showNewSpaceFolderDialog(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  final l10n = AppLocalizations.of(context);
  final name = await showRenameDialog(
    context,
    title: l10n.newSpaceFolder,
    initialValue: '',
    hintText: l10n.folderName,
    confirmLabel: l10n.create,
  );
  if (name != null && context.mounted) {
    await ref.read(spaceFolderActionsProvider(workspaceId)).create(name);
  }
}

/// Renders human spaces in personal folders, followed by unfiled spaces.
/// The caller supplies its existing row so the two sidebar layouts keep their
/// own selection and conversation treatment.
class SpaceFoldersList extends ConsumerStatefulWidget {
  /// Renders workspace folders and unfiled [spaces].
  const SpaceFoldersList({
    super.key,
    required this.workspaceId,
    required this.spaces,
    required this.spaceBuilder,
    this.filter = '',
  });

  /// Workspace whose personal folder preference is displayed.
  final String workspaceId;

  /// Visible, human-facing spaces in their current recency order.
  final List<Space> spaces;

  /// Builds the layout-specific row for one space.
  final Widget Function(Space space) spaceBuilder;

  /// Optional name filter applied by the contextual sidebar.
  final String filter;

  @override
  ConsumerState<SpaceFoldersList> createState() => _SpaceFoldersListState();
}

class _SpaceFoldersListState extends ConsumerState<SpaceFoldersList> {
  final Map<String, bool> _expanded = {};
  String? _draggingSpaceId;

  Widget _draggableSpace(Space space, Map<String, Space> available) {
    final workspaceId = widget.workspaceId;
    return _DraggableSpaceRow(
      key: ValueKey(space.id),
      space: space,
      available: available,
      workspaceId: workspaceId,
      onDropOnSpace: (sourceId, targetId) =>
          unawaited(_createFolderFromDrop(sourceId, targetId)),
      onDragStarted: () {
        if (mounted && widget.workspaceId == workspaceId) {
          setState(() => _draggingSpaceId = space.id);
        }
      },
      onDragEnd: (details) {
        if (mounted &&
            widget.workspaceId == workspaceId &&
            _draggingSpaceId == space.id) {
          setState(() => _draggingSpaceId = null);
        }
        _unfileOnFreeDrop(details, space.id, workspaceId);
      },
      child: widget.spaceBuilder(space),
    );
  }

  Widget _unfileDropZone(Map<String, Space> available) {
    final workspaceId = widget.workspaceId;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
      child: DragTarget<_SpaceDragData>(
        onWillAcceptWithDetails: (details) =>
            details.data.workspaceId == workspaceId &&
            available.containsKey(details.data.spaceId) &&
            ref
                .read(spaceFoldersProvider(workspaceId))
                .any(
                  (folder) => folder.spaceIds.contains(details.data.spaceId),
                ),
        onAcceptWithDetails: (details) {
          if (workspaceId != widget.workspaceId ||
              details.data.workspaceId != workspaceId ||
              !available.containsKey(details.data.spaceId)) {
            return;
          }
          final spaceId = details.data.spaceId;
          if (ref
              .read(spaceFoldersProvider(workspaceId))
              .any((folder) => folder.spaceIds.contains(spaceId))) {
            unawaited(
              ref
                  .read(spaceFolderActionsProvider(workspaceId))
                  .move(spaceId, null),
            );
          }
        },
        builder: (context, candidates, _) {
          final tokens = context.ds;
          final active = candidates.isNotEmpty;
          return AnimatedContainer(
            key: const ValueKey('unfile-space-drop-zone'),
            duration: CcMotion.resolve(context, CcMotion.fast),
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: active ? tokens.accentSoft : tokens.bgSecondary,
              border: Border.all(
                color: active ? tokens.accent : tokens.borderSecondary,
              ),
              borderRadius: AppRadii.brSm,
            ),
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(AppIcons.folder, size: 16, color: tokens.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).removeSpaceFromFolder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createFolderFromDrop(String sourceId, String targetId) async {
    if (sourceId == targetId) {
      return;
    }
    final workspaceId = widget.workspaceId;
    final l10n = AppLocalizations.of(context);
    final name = await showRenameDialog(
      context,
      title: l10n.newSpaceFolder,
      initialValue: '',
      hintText: l10n.folderName,
      confirmLabel: l10n.create,
    );
    if (!mounted || name == null || workspaceId != widget.workspaceId) {
      return;
    }
    final visible = {for (final space in widget.spaces) space.id};
    if (!visible.contains(sourceId) || !visible.contains(targetId)) {
      return;
    }
    await ref
        .read(spaceFolderActionsProvider(workspaceId))
        .create(name, spaceIds: [targetId, sourceId]);
  }

  void _unfileOnFreeDrop(
    DraggableDetails details,
    String spaceId,
    String workspaceId,
  ) {
    if (details.wasAccepted || !mounted || workspaceId != widget.workspaceId) {
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return;
    }
    // RTL carve-out: global pointer coordinates and viewport bounds are
    // physical geometry. Never unfile when dropping into the main pane.
    final origin = box.localToGlobal(Offset.zero);
    final position = details.offset;
    if (position.dx < origin.dx ||
        position.dx >= origin.dx + box.size.width ||
        position.dy < origin.dy ||
        position.dy >= MediaQuery.sizeOf(context).height) {
      return;
    }
    final folders = ref.read(spaceFoldersProvider(workspaceId));
    if (folders.any((folder) => folder.spaceIds.contains(spaceId))) {
      unawaited(
        ref.read(spaceFolderActionsProvider(workspaceId)).move(spaceId, null),
      );
    }
  }

  @override
  void didUpdateWidget(covariant SpaceFoldersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      _draggingSpaceId = null;
      _expanded.clear();
    }
  }

  /// A newly opened space must not be hidden behind a previously closed
  /// folder. A manual collapse of the currently selected folder still holds.
  void _revealRouteSpace(String? spaceId) {
    if (spaceId == null) {
      return;
    }
    final reopened = [
      for (final folder in ref.read(spaceFoldersProvider(widget.workspaceId)))
        if (folder.spaceIds.contains(spaceId) &&
            _expanded.containsKey(folder.id))
          folder.id,
    ];
    if (reopened.isNotEmpty) {
      setState(() => reopened.forEach(_expanded.remove));
    }
  }

  @override
  Widget build(BuildContext context) {
    // The route's space through a listener, not a watch: the list reacts to
    // a navigation only when it has a folder to reopen, and otherwise never
    // rebuilds for one.
    ref.listen<String?>(
      routeSpaceIdProvider((
        router: GoRouter.of(context),
        workspaceId: widget.workspaceId,
      )),
      (_, spaceId) => _revealRouteSpace(spaceId),
    );
    final folders = ref.watch(spaceFoldersProvider(widget.workspaceId));
    final filter = widget.filter.trim().toLowerCase();
    final available = {for (final space in widget.spaces) space.id: space};
    final filed = <String>{};
    final children = <Widget>[];

    for (final folder in folders) {
      // Only workspace-visible spaces render; older archived memberships
      // remain in the preference until explicitly removed.
      final members = <Space>[];
      for (final id in folder.spaceIds) {
        final space = available[id];
        if (space != null && filed.add(id)) {
          members.add(space);
        }
      }
      if (filter.isNotEmpty && members.isEmpty) {
        continue;
      }
      final expanded = _expanded[folder.id] ?? true;
      children.add(
        _FolderRow(
          key: ValueKey(folder.id),
          folder: folder,
          hasSpaces: members.isNotEmpty,
          available: available,
          expanded: expanded,
          onToggle: () => setState(() => _expanded[folder.id] = !expanded),
          workspaceId: widget.workspaceId,
        ),
      );
      children.add(
        CcCollapsible(
          key: ValueKey('children-${folder.id}'),
          expanded: expanded || filter.isNotEmpty,
          child: CcSidebarBranch(
            children: [
              for (final space in members) _draggableSpace(space, available),
            ],
          ),
        ),
      );
    }
    if (_draggingSpaceId != null && filed.contains(_draggingSpaceId)) {
      children.add(_unfileDropZone(available));
    }
    for (final space in widget.spaces) {
      if (!filed.contains(space.id)) {
        children.add(_draggableSpace(space, available));
      }
    }
    return children.isEmpty
        ? const SizedBox.shrink()
        : CcSidebarGroup(children: children);
  }
}

class _FolderRow extends ConsumerStatefulWidget implements CcFluidHoverTarget {
  const _FolderRow({
    super.key,
    required this.folder,
    required this.hasSpaces,
    required this.available,
    required this.expanded,
    required this.onToggle,
    required this.workspaceId,
  });

  final SpaceFolder folder;
  final bool hasSpaces;
  final Map<String, Space> available;
  final bool expanded;
  final VoidCallback onToggle;
  final String workspaceId;

  @override
  bool get fluidHoverEnabled => true;

  @override
  ConsumerState<_FolderRow> createState() => _FolderRowState();
}

class _FolderRowState extends ConsumerState<_FolderRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(spaceFolderActionsProvider(widget.workspaceId));
    final folder = widget.folder;
    return DragTarget<_SpaceDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.workspaceId == widget.workspaceId &&
          widget.available.containsKey(details.data.spaceId),
      onAcceptWithDetails: (details) =>
          unawaited(actions.move(details.data.spaceId, folder.id)),
      builder: (context, candidates, _) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: candidates.isEmpty
                ? const Color(0x00000000)
                : context.ds.accent,
          ),
          borderRadius: AppRadii.brSm,
        ),
        child: Focus(
          canRequestFocus: false,
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Stack(
              children: [
                CcSidebarItem(
                  icon: widget.expanded ? AppIcons.folderOpen : AppIcons.folder,
                  label: folder.name,
                  onPressed: widget.onToggle,
                  badge: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: kSpaceSidebarOverflowSlot,
                    ),
                    child: widget.hasSpaces
                        ? AnimatedRotation(
                            duration: CcMotion.resolveToggle(
                              context,
                              CcMotion.fast,
                            ),
                            turns: widget.expanded
                                ? 0
                                : Directionality.of(context) ==
                                      TextDirection.rtl
                                ? 0.25
                                : -0.25,
                            child: Icon(
                              AppIcons.chevronDown,
                              size: 14,
                              color: context.ds.textSecondary,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: kSpaceSidebarPad,
                  child: Center(
                    // The row reveals this action, but only the trigger's
                    // own pointer hover should paint its active wash.
                    child: CcFluidHover.consumeTappable(
                      SpaceRowOverflowMenu(
                        semanticLabel: l10n.spaceFolderActions,
                        color: context.ds.textSecondary,
                        revealed:
                            _hovered ||
                            (_focused && FocusModality.instance.isKeyboard),
                        selected: false,
                        items: [
                          CcMenuItem(
                            label: l10n.renameSpaceFolder,
                            icon: AppIcons.pencil,
                            onSelected: () =>
                                unawaited(_rename(context, actions)),
                          ),
                          const CcMenuItem.divider(),
                          CcMenuItem(
                            label: l10n.deleteSpaceFolder,
                            icon: AppIcons.trash2,
                            destructive: true,
                            onSelected: () => unawaited(
                              showDeleteSpaceFolderDialog(
                                context,
                                ref,
                                workspaceId: widget.workspaceId,
                                folder: folder,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, SpaceFolderActions actions) async {
    final name = await showRenameDialog(
      context,
      title: AppLocalizations.of(context).renameSpaceFolder,
      initialValue: widget.folder.name,
      hintText: AppLocalizations.of(context).folderName,
    );
    if (name != null) {
      await actions.rename(widget.folder.id, name);
    }
  }
}
