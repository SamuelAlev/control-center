import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_drop_overlay.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Builds the keyed, kept-alive body for one [tab]. `isVisible` is true for the
/// tab currently shown in its leaf, letting the host mark it visited (and so
/// build it) while leaving unvisited tabs unbuilt.
typedef EditorBodyBuilder =
    Widget Function(EditorTab tab, {required bool isVisible});

/// Feature-specific chrome injected into the (otherwise kind-agnostic) editor
/// tab groups: how to render a tab's icon/label, what the `[+]` new-tab menu
/// offers and the optional sidebar toggle. Everything here is provided by the
/// host (messaging, the PR page, …); the engine itself knows no tab vocabulary.
class EditorChrome {
  /// Creates an [EditorChrome].
  const EditorChrome({
    this.iconFor,
    this.leadingFor,
    this.labelFor,
    this.dirtyFor,
    this.confirmClose,
    this.newTabMenuItems,
    this.tabContextMenuExtras,
    this.onUntitledDraft,
    this.onToggleSidebar,
    this.sidebarVisible = true,
  });

  /// Resolves a tab's leading icon. Defaults to the tab's own `icon`.
  final IconData? Function(EditorTab tab)? iconFor;

  /// Resolves a tab's leading as a WIDGET, taking precedence over [iconFor]
  /// when it returns non-null. For leadings the bundled icon font cannot
  /// express (a per-engine browser logo is an SVG asset, not a glyph): the
  /// builder receives the strip's resolved label color so the widget can tint
  /// itself like an icon.
  final Widget Function(Color color)? Function(EditorTab tab)? leadingFor;

  /// Resolves a tab's header label. Defaults to the tab's own `label`.
  final String Function(EditorTab tab)? labelFor;

  /// Resolves whether a tab has unsaved changes (drives the tab strip's dirty
  /// dot). Defaults to never-dirty. Host-owned because "dirty" is a
  /// feature-specific notion (e.g. messaging maps it from code-server reports).
  final bool Function(EditorTab tab)? dirtyFor;

  /// Intercepts a tab close (the strip's × or a middle-click). Returns true to
  /// proceed with the close, false to cancel — letting the host prompt about
  /// unsaved changes (Save / Don't save / Cancel). Null closes immediately.
  final Future<bool> Function(EditorTab tab)? confirmClose;

  /// Builds the `[+]` new-tab menu for a given leaf id. Return an empty list
  /// (or leave null) to hide the `[+]` menu entirely (e.g. a fixed tab set like
  /// the PR page).
  final List<CcMenuItem> Function(String leafId)? newTabMenuItems;

  /// Extra rows injected into a tab's right-click menu, below the universal
  /// Close actions — e.g. Copy path / Copy relative path for a file tab. Return
  /// an empty list for tabs with no extras. Null (or empty) shows only the
  /// engine's Close / Split actions.
  final List<CcMenuItem> Function(EditorTab tab)? tabContextMenuExtras;

  /// Opens a fresh (untitled) tab on a double-click of the tab-strip void. Null
  /// disables it.
  final VoidCallback? onUntitledDraft;

  /// Toggles a host-owned sidebar (⌘B / the panel button). Null hides the
  /// toggle (surfaces with no sidebar, like the PR page).
  final VoidCallback? onToggleSidebar;

  /// Whether the host sidebar is currently visible (drives the toggle icon).
  final bool sidebarVisible;

  IconData? _icon(EditorTab tab) => (iconFor ?? (t) => t.icon)(tab);
  Widget Function(Color color)? _leading(EditorTab tab) =>
      leadingFor?.call(tab);
  String _label(EditorTab tab) => (labelFor ?? (t) => t.label)(tab);
  bool _dirty(EditorTab tab) => (dirtyFor ?? (t) => false)(tab);
}

/// One editor tab-group: a single leaf of the split tree.
///
/// Renders an [EditorTabBar] header (drag-to-reorder) over a body that is a
/// [DragTarget] for splitting — drop a tab on an edge to split this pane, or in
/// the center to move it here. Tab bodies themselves are built (and kept alive
/// across moves) by the host via [buildBody]; this widget owns only the chrome,
/// the header actions and the drop affordance.
class EditorTabGroup extends StatefulWidget {
  /// Creates an [EditorTabGroup].
  const EditorTabGroup({
    super.key,
    required this.leafId,
    required this.controller,
    required this.layout,
    required this.buildBody,
    required this.canCloseGroup,
    required this.chrome,
  });

  /// Id of this leaf within the layout tree.
  final String leafId;

  /// Owns this leaf's tabs + selection.
  final EditorTabGroupController controller;

  /// The layout controller, for structural ops (split / move / close).
  final EditorLayoutController layout;

  /// Builds a tab's kept-alive body (provided by the host).
  final EditorBodyBuilder buildBody;

  /// Whether more than one leaf exists (enables close-group).
  final bool canCloseGroup;

  /// Feature-specific chrome (icons / labels / menus / sidebar toggle).
  final EditorChrome chrome;

  @override
  State<EditorTabGroup> createState() => _EditorTabGroupState();
}

class _EditorTabGroupState extends State<EditorTabGroup> {
  /// Key on the body area so a hovering drag can measure it for edge detection.
  final GlobalKey _bodyKey = GlobalKey();

  /// The split edge a hovering drag currently targets, or null.
  DropEdge? _dropEdge;

  EditorTabGroupController get _c => widget.controller;

  void _onBodyDragMove(DragTargetDetails<TabDragData> details) {
    final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final edge = computeDropEdge(box.globalToLocal(details.offset), box.size);
    if (edge != _dropEdge) {
      setState(() => _dropEdge = edge);
    }
  }

  void _clearEdge() {
    if (_dropEdge != null) {
      setState(() => _dropEdge = null);
    }
  }

  /// Closes the tab at [index], first giving the host a chance to intercept
  /// (e.g. an unsaved-changes prompt). Because the confirmation is async and the
  /// tab set can shift while it is open, the tab is re-located by identity before
  /// the actual close so the right one is removed.
  Future<void> _closeTab(int index) async {
    final tabs = _c.tabs;
    if (index < 0 || index >= tabs.length) {
      return;
    }
    final tab = tabs[index];
    final confirm = widget.chrome.confirmClose;
    if (confirm != null) {
      final proceed = await confirm(tab);
      if (!proceed) {
        return;
      }
    }
    final current = _c.indexOfIdentity(tab);
    if (current >= 0) {
      widget.layout.closeTab(widget.leafId, current);
    }
  }

  /// Closes each tab in [targets] in turn, re-locating it by identity before the
  /// close (the tab set shifts as each one goes) and giving the host's
  /// [EditorChrome.confirmClose] a chance to intercept a dirty tab. A cancelled
  /// prompt aborts the remainder of the batch (VS Code parity).
  Future<void> _closeMany(List<EditorTab> targets) async {
    final confirm = widget.chrome.confirmClose;
    for (final tab in targets) {
      if (confirm != null) {
        final proceed = await confirm(tab);
        if (!proceed) {
          return;
        }
      }
      final idx = _c.indexOfIdentity(tab);
      if (idx >= 0) {
        widget.layout.closeTab(widget.leafId, idx);
      }
    }
  }

  /// Opens the right-click context menu for the tab at [index]: the universal
  /// Close actions, any host-provided extras (e.g. Copy path) and a Split
  /// submenu. Returns a future completing when the menu closes, which is what
  /// the strip washes the tab for.
  ///
  /// The tab is deliberately NOT selected (nor is its leaf made active): the
  /// point of the menu is to act on a tab without going into it. So every row
  /// addresses the right-clicked tab by IDENTITY rather than riding the
  /// selection — an index would be stale by the time the menu is used anyway,
  /// since a neighbouring close can shift it while the menu stands open.
  Future<void> _showTabMenu(AppLocalizations l10n, int index, Offset position) {
    final tabs = _c.tabs;
    if (index < 0 || index >= tabs.length) {
      return Future.value();
    }
    final tab = tabs[index];

    final hasOthers = tabs.length > 1;
    final hasRight = index < tabs.length - 1;
    final hasSaved = tabs.any((t) => !widget.chrome._dirty(t));
    final extras =
        widget.chrome.tabContextMenuExtras?.call(tab) ?? const <CcMenuItem>[];

    void split(DropEdge edge) {
      final at = _c.indexOfIdentity(tab);
      if (at >= 0) {
        widget.layout.splitTabToward(widget.leafId, at, edge);
      }
    }

    final closed = Completer<void>();
    showCcMenuAt(
      context: context,
      position: position,
      onDismissed: () {
        if (!closed.isCompleted) {
          closed.complete();
        }
      },
      items: [
        CcMenuItem(label: l10n.close, onSelected: () => _closeMany([tab])),
        CcMenuItem(
          label: l10n.ideCloseOthers,
          enabled: hasOthers,
          onSelected: () => _closeMany([
            for (final t in tabs)
              if (!identical(t, tab)) t,
          ]),
        ),
        CcMenuItem(
          label: l10n.ideCloseToRight,
          enabled: hasRight,
          onSelected: () => _closeMany(tabs.sublist(index + 1)),
        ),
        CcMenuItem(
          label: l10n.ideCloseSaved,
          enabled: hasSaved,
          onSelected: () => _closeMany([
            for (final t in tabs)
              if (!widget.chrome._dirty(t)) t,
          ]),
        ),
        CcMenuItem(
          label: l10n.ideCloseAll,
          onSelected: () => _closeMany(tabs.toList()),
        ),
        if (extras.isNotEmpty) ...[const CcMenuItem.divider(), ...extras],
        const CcMenuItem.divider(),
        CcMenuItem.submenu(
          label: l10n.ideSplit,
          children: [
            CcMenuItem(
              label: l10n.ideSplitUp,
              onSelected: () => split(DropEdge.top),
            ),
            CcMenuItem(
              label: l10n.ideSplitDown,
              onSelected: () => split(DropEdge.bottom),
            ),
            CcMenuItem(
              label: l10n.ideSplitLeft,
              onSelected: () => split(DropEdge.left),
            ),
            CcMenuItem(
              label: l10n.ideSplitRight,
              onSelected: () => split(DropEdge.right),
            ),
          ],
        ),
      ],
    );
    return closed.future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chrome = widget.chrome;
    final tabs = _c.tabs;
    final selected = _c.selectedIndex;
    return Column(
      children: [
        EditorTabBar(
          leafId: widget.leafId,
          tabs: tabs,
          labels: [for (final t in tabs) chrome._label(t)],
          icons: [for (final t in tabs) chrome._icon(t) ?? AppIcons.fileCode],
          leadings: chrome.leadingFor == null
              ? null
              : [for (final t in tabs) chrome._leading(t)],
          dirty: [for (final t in tabs) chrome._dirty(t)],
          selectedIndex: selected,
          onTabSelected: (i) {
            widget.layout.setActiveLeaf(widget.leafId);
            _c.selectedIndex = i;
          },
          onTabClosed: _closeTab,
          onTabContextMenu: (index, position) =>
              _showTabMenu(l10n, index, position),
          onReorderDrop: (data, insertIndex) =>
              widget.layout.moveTab(data, widget.leafId, insertIndex),
          onUntitledDraft: chrome.onUntitledDraft,
          // The `[+]` new-tab menu scrolls inline next to the last tab.
          inlineActions: _buildInlineActions(l10n),
          // Split / close-group / sidebar-toggle stay pinned on the right.
          actions: _buildTrailingActions(l10n),
        ),
        Expanded(child: _buildBodyArea(l10n, tabs, selected)),
      ],
    );
  }

  Widget _buildBodyArea(
    AppLocalizations l10n,
    List<EditorTab> tabs,
    int selected,
  ) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final body = tabs.isEmpty
        ? ColoredBox(
            color: t.bgPrimary,
            child: Center(
              child: Text(
                l10n.ideNoOpenTabs,
                style: TextStyle(color: t.textTertiary),
              ),
            ),
          )
        : IndexedStack(
            index: selected,
            sizing: StackFit.expand,
            children: [
              for (var i = 0; i < tabs.length; i++)
                widget.buildBody(tabs[i], isVisible: i == selected),
            ],
          );
    return DragTarget<TabDragData>(
      onWillAcceptWithDetails: (_) => true,
      onMove: _onBodyDragMove,
      onLeave: (_) => _clearEdge(),
      onAcceptWithDetails: (details) {
        final edge = _dropEdge ?? DropEdge.center;
        _clearEdge();
        widget.layout.splitWithTab(widget.leafId, edge, details.data);
      },
      builder: (context, candidate, rejected) {
        return Stack(
          key: _bodyKey,
          fit: StackFit.expand,
          children: [
            body,
            EditorDropOverlay(edge: _dropEdge),
          ],
        );
      },
    );
  }

  /// The `[+]` new-tab menu — rendered inline, immediately after the last tab,
  /// scrolling with the strip. Hidden when the host offers no menu items.
  List<Widget> _buildInlineActions(AppLocalizations l10n) {
    final items = widget.chrome.newTabMenuItems?.call(widget.leafId);
    if (items == null || items.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(width: 2),
      CcMenu(
        target: _MenuTrigger(AppIcons.plus, tooltip: l10n.ideNewTabMenu),
        items: items,
        // Always searchable, never "searchable once it gets long": the row
        // count here swings with what is already open, and a field that comes
        // and goes is a worse menu than a field that is always there. Typing
        // two characters is also the one way to reach a row whose position
        // moved — keystroke memory survives what position memory cannot.
        searchable: true,
        searchHint: l10n.ideMenuSearchHint,
        emptySearchLabel: l10n.ideMenuNoMatches,
        maxWidth: 280,
      ),
    ];
  }

  /// Split / sidebar-toggle / close-group — pinned at the far right of the strip
  /// (outside the scroller). The sidebar toggle (when provided) leads so it sits
  /// next to the split button.
  List<Widget> _buildTrailingActions(AppLocalizations l10n) {
    return [
      if (widget.chrome.onToggleSidebar != null)
        CcIconButton(
          icon: widget.chrome.sidebarVisible
              ? AppIcons.panelLeftOpen
              : AppIcons.panelLeftClose,
          size: CcButtonSize.sm,
          tooltip: l10n.ideToggleSidebar,
          onPressed: widget.chrome.onToggleSidebar,
        ),
      CcMenu(
        semanticLabel: l10n.ideSplitEditor,
        target: _MenuTrigger(AppIcons.columns, tooltip: l10n.ideSplitEditor),
        items: [
          CcMenuItem(
            label: l10n.ideSplitRight,
            onSelected: () => widget.layout.splitActiveTabToward(
              widget.leafId,
              DropEdge.right,
            ),
          ),
          CcMenuItem(
            label: l10n.ideSplitDown,
            onSelected: () => widget.layout.splitActiveTabToward(
              widget.leafId,
              DropEdge.bottom,
            ),
          ),
          CcMenuItem(
            label: l10n.ideSplitLeft,
            onSelected: () => widget.layout.splitActiveTabToward(
              widget.leafId,
              DropEdge.left,
            ),
          ),
          CcMenuItem(
            label: l10n.ideSplitUp,
            onSelected: () =>
                widget.layout.splitActiveTabToward(widget.leafId, DropEdge.top),
          ),
        ],
      ),
      if (widget.canCloseGroup)
        CcIconButton(
          icon: AppIcons.xCircle,
          size: CcButtonSize.sm,
          tooltip: l10n.ideCloseGroup,
          onPressed: () => widget.layout.closeLeaf(widget.leafId),
        ),
    ];
  }
}

/// A [CcMenu] trigger that LOOKS like a ghost [CcIconButton] (32px box, `brSm`
/// radius, a [DesignSystemTokens.hover] wash + pointer cursor on hover) but owns
/// no gesture of its own — the menu's [CcTappable] wrapper handles the press.
/// This keeps the split / new-tab triggers visually consistent with their
/// real-button neighbours (sidebar-toggle, close-group) instead of bare icons.
/// An optional [tooltip] wraps it in a [CcTooltip], matching [CcIconButton].
class _MenuTrigger extends StatefulWidget {
  const _MenuTrigger(this.icon, {this.tooltip});

  final IconData icon;
  final String? tooltip;

  @override
  State<_MenuTrigger> createState() => _MenuTriggerState();
}

class _MenuTriggerState extends State<_MenuTrigger> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final box = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: 32,
        height: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _hovered ? t.hover : const Color(0x00000000),
            borderRadius: AppRadii.brSm,
          ),
          child: Center(child: Icon(widget.icon, size: 16, color: t.fg)),
        ),
      ),
    );
    if (widget.tooltip == null) {
      return box;
    }
    return CcTooltip(message: widget.tooltip!, child: box);
  }
}
