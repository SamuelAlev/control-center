import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/editor_tab_group.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panes/panes.dart';

/// The IDE-style messaging surface: a single [MultiPane] owning a fixed
/// activity-sidebar pane plus one or more tabbed editor groups.
///
/// Layout state (pane geometry + per-group tab state) is **ephemeral** UI state
/// held here — it is NOT persisted and NOT Riverpod. Workspace-scoped *data*
/// (repos, changes, PRs) still flows through providers inside the child widgets.
class MessagingIdeLayout extends ConsumerStatefulWidget {
  /// Creates the IDE layout.
  const MessagingIdeLayout({
    super.key,
    required this.workspaceId,
    this.selectedChannelId,
  });

  /// The active workspace (isolation scope for the sidebar's data).
  final String workspaceId;

  /// The currently-selected conversation, or null when none is open. Drives the
  /// Chat tab; the global app sidebar (out of scope) sets this.
  final String? selectedChannelId;

  @override
  ConsumerState<MessagingIdeLayout> createState() => _MessagingIdeLayoutState();
}

class _MessagingIdeLayoutState extends ConsumerState<MessagingIdeLayout> {
  /// Pane id of the fixed activity sidebar.
  static const String _sidebarPaneId = 'sidebar';

  late final PaneController _rootPaneController;
  late final ValueNotifier<int> _sidebarTab;

  /// Per-group tab state. One controller per editor-group pane.
  final Map<String, EditorTabGroupController> _tabGroups = {};

  /// Monotonic counter for generating unique group pane ids.
  int _groupCounter = 0;

  @override
  void initState() {
    super.initState();
    _sidebarTab = ValueNotifier<int>(0);
    _rootPaneController = PaneController(
      entries: [
        // Editor area on the LEFT.
        PaneEntry(
          id: _firstGroupId,
          initialSize: PaneSize.fraction(1),
        ),
        // Activity sidebar on the RIGHT.
        PaneEntry(
          id: _sidebarPaneId,
          initialSize: PaneSize.pixel(300),
          minSize: PaneSize.pixel(200),
        ),
      ],
    );
    _tabGroups[_firstGroupId] = _seedGroup(widget.selectedChannelId);
  }

  String get _firstGroupId => 'group-0';

  @override
  void didUpdateWidget(covariant MessagingIdeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChannelId != widget.selectedChannelId) {
      // Update the first group's Chat tab to follow the conversation selection.
      _tabGroups[_firstGroupId]?.selectChat(widget.selectedChannelId);
    }
  }

  @override
  void dispose() {
    _sidebarTab.dispose();
    for (final c in _tabGroups.values) {
      c.dispose();
    }
    _rootPaneController.dispose();
    super.dispose();
  }

  /// Seeds a fresh editor group with the default tabs: Chat (when a
  /// conversation is selected), Terminal, Browser.
  EditorTabGroupController _seedGroup(String? channelId) {
    final controller = EditorTabGroupController();
    if (channelId != null) {
      controller.openTab(
        EditorTab(
          kind: EditorTabKind.chat,
          label: 'Chat',
          args: {'channelId': channelId},
        ),
      );
    }
    controller.openTab(
      const EditorTab(kind: EditorTabKind.terminal, label: 'Terminal'),
    );
    controller.openTab(
      const EditorTab(kind: EditorTabKind.browser, label: 'Browser'),
    );
    // Select the first tab (Chat when a conversation is open) so entering a
    // conversation lands on chat, not the last-seeded tab.
    controller.selectedIndex = 0;
    return controller;
  }

  void _splitGroup(String sourceGroupId) {
    final source = _tabGroups[sourceGroupId];
    final id = 'group-$_groupCounter';
    _groupCounter++;
    final newController = EditorTabGroupController();
    // VS Code split-editor behavior: open the source group's active tab in the
    // new pane so both panes show content. The source group keeps all its tabs.
    if (source != null) {
      final tabs = source.tabs;
      final i = source.selectedIndex;
      if (i < tabs.length) {
        newController.openTab(tabs[i]);
      }
    }
    _tabGroups[id] = newController;
    // Insert BEFORE the sidebar (the last entry) so new editor groups stay
    // grouped on the left rather than landing past the sidebar.
    _rootPaneController.addPane(
      PaneEntry(id: id, initialSize: PaneSize.fraction(0.5)),
      index: _rootPaneController.entries.length - 1,
    );
  }

  void _closeGroup(String id) {
    // Never remove the last editor group — keep the surface usable.
    final editorIds = _rootPaneController.entries
        .where((e) => e.id != _sidebarPaneId)
        .map((e) => e.id)
        .toList();
    if (editorIds.length <= 1) {
      return;
    }
    _rootPaneController.removePane(id);
    _tabGroups.remove(id)?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return PaneTheme(
      // Only resizer styling is sourced from PaneTheme now; editor tab chrome is
      // owned by EditorTabBar (see editor_tab_group.dart).
      data: PaneThemeData(
        resizerColor: t.borderPrimary,
        resizerHoverColor: t.accent,
        resizerFocusedColor: t.accent,
        resizerThickness: 1.0,
        resizerHitTestThickness: 14.0,
      ),
      child: MultiPane(
        direction: Axis.horizontal,
        controller: _rootPaneController,
        paneBuilder: (context, paneId, _) {
          if (paneId == _sidebarPaneId) {
            return IdeSidebar(
              tabNotifier: _sidebarTab,
              workspaceId: widget.workspaceId,
              onOpenFile: (target) {
                _tabGroups.values.first.openTab(
                  EditorTab(
                    kind: EditorTabKind.file,
                    label: target.path.split('/').last,
                    args: {
                      'repoId': target.repoId,
                      'path': target.path,
                    },
                  ),
                );
              },
              onOpenFileDiff: (target) {
                _tabGroups.values.first.openTab(
                  EditorTab(
                    kind: EditorTabKind.fileDiff,
                    label: target.file.filename.split('/').last,
                    args: {
                      'repoId': target.repoId,
                      'prFile': target.file,
                    },
                  ),
                );
              },
            );
          }
          final controller = _tabGroups[paneId];
          if (controller == null) {
            return const SizedBox.shrink();
          }
          final editorIds = _rootPaneController.entries
              .where((e) => e.id != _sidebarPaneId)
              .map((e) => e.id)
              .toList();
          return EditorTabGroup(
            key: ValueKey(paneId),
            groupId: paneId,
            controller: controller,
            onSplitGroup: () => _splitGroup(paneId),
            onCloseGroup: () => _closeGroup(paneId),
            canCloseGroup: editorIds.length > 1,
            onFocusSourceControl: () => _sidebarTab.value = 1,
          );
        },
      ),
    );
  }
}

