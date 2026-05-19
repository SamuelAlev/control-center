import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/browser_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/editor_tab_bar.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/file_viewer_pane.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart'
    if (dart.library.js_interop) 'package:control_center/features/sandboxing/presentation/terminal_panel_web.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kind of content hosted in an editor tab.
enum EditorTabKind {
  /// The active conversation (chat) surface.
  chat,
  /// An interactive sandbox terminal.
  terminal,
  /// An in-app webview browser.
  browser,
  /// A read-only repo file.
  file,
  /// A single file's working-tree diff (a changed file).
  fileDiff,
}

/// A single tab in an editor tab-group.
///
/// `args` carries the kind-specific payload:
///   * `chat`      → `{channelId: String}`
///   * `terminal`  → `{}` (cwd resolved from the active repo; session owned by
///                   the [EditorTabGroup] widget, keyed by this tab's identity)
///   * `browser`   → `{url?: String}`
///   * `file`      → `{repoId: String, path: String}`
///   * `fileDiff`  → `{repoId: String, prFile: PrFile}`
@immutable
class EditorTab {
  /// Creates an [EditorTab].
  const EditorTab({
    required this.kind,
    required this.label,
    this.args = const {},
  });

  /// Content kind — drives the rendered pane + tab icon.
  final EditorTabKind kind;

  /// Header label (already localised).
  final String label;

  /// Kind-specific payload (see class docs).
  final Map<String, Object?> args;
}

/// Owns the open tabs + selection for one editor tab-group.
///
/// Held by the parent layout (`MessagingIdeLayout`) so the tab set survives
/// pane rebuilds; this is ephemeral UI state, NOT Riverpod-managed.
class EditorTabGroupController extends ChangeNotifier {
  final List<EditorTab> _tabs = [];
  int _selectedIndex = 0;

  /// The current tabs (unmodifiable view).
  List<EditorTab> get tabs => List.unmodifiable(_tabs);

  /// Selected tab index, clamped to the valid range (0 when empty).
  int get selectedIndex =>
      _tabs.isEmpty ? 0 : _selectedIndex.clamp(0, _tabs.length - 1);

  set selectedIndex(int value) {
    _selectedIndex = value;
    notifyListeners();
  }

  /// Appends [tab] and selects it. A `chat` tab is unique-per-group: opening a
  /// second one refocuses (replaces) the existing chat tab instead of stacking.
  void openTab(EditorTab tab) {
    if (tab.kind == EditorTabKind.chat) {
      final idx = _tabs.indexWhere((t) => t.kind == EditorTabKind.chat);
      if (idx >= 0) {
        _tabs[idx] = tab;
        _selectedIndex = idx;
        notifyListeners();
        return;
      }
    }
    _tabs.add(tab);
    _selectedIndex = _tabs.length - 1;
    notifyListeners();
  }

  /// Removes the currently-selected tab and clamps the selection.
  void closeSelected() {
    if (_tabs.isEmpty) {
      return;
    }
    final i = selectedIndex;
    _tabs.removeAt(i);
    _selectedIndex = i.clamp(0, _tabs.isEmpty ? 0 : _tabs.length - 1);
    notifyListeners();
  }

  /// Opens (or refocuses) the chat tab for [channelId]. `null` is a no-op.
  void selectChat(String? channelId) {
    if (channelId == null) {
      return;
    }
    openTab(
      EditorTab(
        kind: EditorTabKind.chat,
        label: 'Chat',
        args: {'channelId': channelId},
      ),
    );
  }
}

/// One editor tab-group: an [EditorTabBar] header over a body of stacked panes.
///
/// Hosts chat / terminal / browser / file / file-diff panes behind click-select
/// tabs, with a header action row: close-active-tab, split group, close group
/// (when >1 group), and a `[+]` menu to open new terminal / browser / chat tabs.
class EditorTabGroup extends ConsumerStatefulWidget {
  /// Creates an [EditorTabGroup].
  const EditorTabGroup({
    super.key,
    required this.groupId,
    required this.controller,
    required this.onSplitGroup,
    required this.onCloseGroup,
    required this.canCloseGroup,
    required this.onFocusSourceControl,
  });

  /// Stable id of this group within the parent pane layout.
  final String groupId;

  /// Owns the tab set + selection for this group.
  final EditorTabGroupController controller;

  /// Request the parent split this group into a second tab-group.
  final VoidCallback onSplitGroup;

  /// Request the parent close this tab-group (only callable when
  /// [canCloseGroup] is true).
  final VoidCallback onCloseGroup;

  /// Whether more than one group exists (enables the close-group action).
  final bool canCloseGroup;

  /// Switch the IDE sidebar to the Source Control tab.
  final VoidCallback onFocusSourceControl;

  @override
  ConsumerState<EditorTabGroup> createState() => _EditorTabGroupState();
}

class _EditorTabGroupState extends ConsumerState<EditorTabGroup> {
  // Terminal sessions are owned here (per tab identity) and built lazily: each
  // terminal tab resolves its own session + cwd the first time it renders.
  final Map<int, TerminalSession> _terminalSessions = {};
  final Set<int> _creatingSessions = {};

  // Tabs that have been selected at least once. Their content is hosted in an
  // IndexedStack (see [build]) so it stays mounted — only hidden — when another
  // tab is active. This keeps platform views alive across tab switches: the
  // browser's macOS `AppKitView` webview (and terminals' PTYs) would otherwise
  // be torn down and recreated on every switch, and the recreated webview fails
  // to re-attach, leaving the in-app browser blank. Unvisited tabs stay unbuilt
  // (no eager terminal/webview spawn). Keyed by tab identity, mirroring
  // [_terminalSessions]; pruned in [_onTabsChanged].
  final Set<int> _visitedTabs = {};

  EditorTabGroupController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    _c.removeListener(_onTabsChanged);
    super.dispose();
  }

  /// Drops session cache entries for terminal tabs that were removed. The PTY
  /// itself is disposed by the unmounted [TerminalPanel]; this only reclaims the
  /// metadata cache.
  void _onTabsChanged() {
    if (!mounted) {
      return;
    }
    final activeTerminals = <int>{};
    final activeTabs = <int>{};
    for (final t in _c.tabs) {
      final id = identityHashCode(t);
      activeTabs.add(id);
      if (t.kind == EditorTabKind.terminal) {
        activeTerminals.add(id);
      }
    }
    _terminalSessions.removeWhere((key, _) => !activeTerminals.contains(key));
    _creatingSessions.removeWhere((key) => !activeTerminals.contains(key));
    _visitedTabs.removeWhere((key) => !activeTabs.contains(key));
  }

  /// Resolves a terminal session for a fresh terminal tab. Cwd is the active
  /// repo's working tree (resolved over RPC, so this is web-safe). No repo →
  /// empty; the server-side terminal then picks a sane default cwd.
  Future<TerminalSession> _resolveTerminalSession() async {
    final repo = ref.read(activeRepoProvider);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    return TerminalSession(
      sessionId: 'ide-terminal-${DateTime.now().microsecondsSinceEpoch}',
      agentDirHostPath: repo?.path ?? '',
      workspaceId: workspaceId ?? '',
    );
  }

  /// Selects an existing terminal tab, or opens a fresh one.
  void _focusTerminalTab(AppLocalizations l10n) {
    final idx = _c.tabs.indexWhere((t) => t.kind == EditorTabKind.terminal);
    if (idx >= 0) {
      _c.selectedIndex = idx;
      return;
    }
    _c.openTab(_newTerminalTab(l10n));
  }

  EditorTab _newTerminalTab(AppLocalizations l10n) => EditorTab(
        kind: EditorTabKind.terminal,
        label: l10n.ideNewTerminal,
      );

  Widget _buildTerminalPane(EditorTab tab) {
    final key = identityHashCode(tab);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final session = _terminalSessions[key];
    if (session != null) {
      return TerminalPanel(
        session: session,
        backgroundColor: t.bgPrimary,
        onShellExit: () {
          // Defer until the tab index has settled, then close *this* tab
          // (selecting it first so closeSelected targets the right one).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            final idx = _c.tabs.indexOf(tab);
            if (idx >= 0) {
              _c.selectedIndex = idx;
              _c.closeSelected();
            }
          });
        },
      );
    }
    if (_creatingSessions.add(key)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final resolved = await _resolveTerminalSession();
        if (!mounted) {
          return;
        }
        // Tab may have been closed while the session was resolving.
        if (!_c.tabs.any((t) => identical(t, tab))) {
          return;
        }
        setState(() {
          _terminalSessions[key] = resolved;
          _creatingSessions.remove(key);
        });
      });
    }
    return const Center(child: CcSpinner());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Hoist reactive reads to this ConsumerState's build so Riverpod tracks
    // them (watching inside the AnimatedBuilder builder would not).
    final selectedChannelId = ref.watch(selectedChannelIdProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final tabs = _c.tabs;
        final selected = _c.selectedIndex;
        // Mark the visible tab visited so its body stays mounted from now on.
        if (tabs.isNotEmpty) {
          _visitedTabs.add(identityHashCode(tabs[selected]));
        }
        return Column(
          children: [
            EditorTabBar(
              // Browser tabs render a platform-aware name ("Web browser" on
              // desktop = the native in-app browser; "Simple web browser" on web
              // = a plain iframe), resolved here so it stays localized/reactive.
              labels: tabs
                  .map(
                    (t) => t.kind == EditorTabKind.browser
                        ? _browserLabel(l10n)
                        : t.label,
                  )
                  .toList(growable: false),
              icons: tabs.map(_iconFor).toList(growable: false),
              selectedIndex: selected,
              onTabSelected: (i) => _c.selectedIndex = i,
              actions: _buildActions(l10n, selectedChannelId),
            ),
            Expanded(
              child: _buildBody(
                context,
                tabs,
                selected,
                l10n: l10n,
                selectedChannelId: selectedChannelId,
                workspaceId: workspaceId,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the stacked tab bodies under the header.
  ///
  /// All visited tab bodies are hosted in an [IndexedStack] so they stay mounted
  /// (just hidden) across switches — the browser's macOS webview (and terminal
  /// PTYs) are created once, onstage, and survive tab switches rather than being
  /// torn down and recreated. Visibility is driven off `selected`.
  Widget _buildBody(
    BuildContext context,
    List<EditorTab> tabs,
    int selected, {
    required AppLocalizations l10n,
    required String? selectedChannelId,
    required String? workspaceId,
  }) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (tabs.isEmpty) {
      return ColoredBox(
        color: t.bgPrimary,
        child: _buildTabContent(
          context,
          tabs,
          0,
          l10n: l10n,
          selectedChannelId: selectedChannelId,
          workspaceId: workspaceId,
        ),
      );
    }
    return IndexedStack(
      index: selected,
      sizing: StackFit.expand,
      children: [
        for (var j = 0; j < tabs.length; j++)
          KeyedSubtree(
            // Stable identity prevents a positional rebuild from recycling one
            // tab's live webview onto another.
            key: ValueKey(identityHashCode(tabs[j])),
            child: ColoredBox(
              color: t.bgPrimary,
              // Build a tab's body only once it has been visited; keep it
              // mounted thereafter. Unvisited tabs render nothing so
              // terminals/webviews aren't spawned until first shown.
              child: _visitedTabs.contains(identityHashCode(tabs[j]))
                  ? _buildTabContent(
                      context,
                      tabs,
                      j,
                      l10n: l10n,
                      selectedChannelId: selectedChannelId,
                      workspaceId: workspaceId,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    List<EditorTab> tabs,
    int i, {
    required AppLocalizations l10n,
    required String? selectedChannelId,
    required String? workspaceId,
  }) {
    if (tabs.isEmpty) {
      final t = context.designSystem!;
      return Center(
        child: Text(
          l10n.ideNoOpenTabs,
          style: TextStyle(color: t.textTertiary),
        ),
      );
    }
    final idx = i.clamp(0, tabs.length - 1);
    final tab = tabs[idx];
    switch (tab.kind) {
      case EditorTabKind.chat:
        final channelId = tab.args['channelId'] as String;
        return ConversationPane(
          channelId: channelId,
          onFocusTerminal: () => _focusTerminalTab(l10n),
          onFocusSourceControl: widget.onFocusSourceControl,
        );
      case EditorTabKind.terminal:
        return _buildTerminalPane(tab);
      case EditorTabKind.browser:
        return BrowserPane(initialUrl: tab.args['url'] as String?);
      case EditorTabKind.file:
        final repoId = tab.args['repoId'] as String;
        final path = tab.args['path'] as String;
        if (workspaceId == null) {
          return const SizedBox.shrink();
        }
        return FileViewerPane(
          workspaceId: workspaceId,
          repoId: repoId,
          path: path,
        );
      case EditorTabKind.fileDiff:
        final prFile = tab.args['prFile'] as PrFile;
        return PrDiffView(files: [prFile], comments: const []);
    }
  }

  List<Widget> _buildActions(AppLocalizations l10n, String? selectedChannelId) {
    return [
      CcIconButton(
        icon: AppIcons.x,
        size: CcButtonSize.sm,
        tooltip: l10n.ideCloseTab,
        onPressed: _c.tabs.isEmpty ? null : _c.closeSelected,
      ),
      CcIconButton(
        icon: AppIcons.columns,
        size: CcButtonSize.sm,
        tooltip: l10n.ideSplitEditor,
        onPressed: widget.onSplitGroup,
      ),
      if (widget.canCloseGroup)
        CcIconButton(
          icon: AppIcons.xCircle,
          size: CcButtonSize.sm,
          tooltip: l10n.ideCloseGroup,
          onPressed: widget.onCloseGroup,
        ),
      const SizedBox(width: 2),
      CcMenu(
        target: const _PlusMenuTrigger(),
        items: [
          CcMenuItem(
            label: l10n.ideNewTerminal,
            icon: AppIcons.terminal,
            onSelected: () => _c.openTab(_newTerminalTab(l10n)),
          ),
          CcMenuItem(
            label: _browserLabel(l10n),
            icon: AppIcons.globe,
            onSelected: () => _c.openTab(
              EditorTab(
                kind: EditorTabKind.browser,
                label: _browserLabel(l10n),
              ),
            ),
          ),
          CcMenuItem(
            label: l10n.ideOpenChat,
            icon: AppIcons.messageSquareText,
            enabled: selectedChannelId != null,
            onSelected: () => _c.selectChat(selectedChannelId),
          ),
        ],
      ),
    ];
  }
}

/// Name for a browser tab + its menu entry. Desktop has a real in-app webview
/// ("Web browser"); web only has a plain iframe ("Simple web browser").
String _browserLabel(AppLocalizations l10n) =>
    kIsWeb ? l10n.ideSimpleWebBrowser : l10n.ideWebBrowser;

IconData _iconFor(EditorTab tab) {
  switch (tab.kind) {
    case EditorTabKind.chat:
      return AppIcons.messageSquareText;
    case EditorTabKind.terminal:
      return AppIcons.terminal;
    case EditorTabKind.browser:
      return AppIcons.globe;
    case EditorTabKind.file:
      return AppIcons.fileCode;
    case EditorTabKind.fileDiff:
      return AppIcons.fileDiff;
  }
}

/// The `[+]` trigger for the new-tab menu. A plain (non-button) icon box so
/// [CcMenu]'s tappable wrapper owns the press without contesting hit-testing.
class _PlusMenuTrigger extends StatelessWidget {
  const _PlusMenuTrigger();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(child: Icon(AppIcons.plus, size: 16, color: t.fg)),
    );
  }
}
