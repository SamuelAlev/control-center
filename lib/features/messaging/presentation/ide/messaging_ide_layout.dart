import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_window_pool.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/editor_layout_snapshot.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_browser_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_conversation_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_editor_chrome.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_host.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_rig_host.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar_divider.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_tab_actions.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_tab_body.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_tab_openers.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_terminal_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_terminal_sessions.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/tab_close_guard.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_browser_tabs_provider.dart';
import 'package:control_center/features/messaging/providers/space_takeover_provider.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/features/sandboxing/providers/terminal_registry_provider.dart';
import 'package:control_center/features/sandboxing/providers/terminal_sessions_provider.dart';
import 'package:control_center/features/shell/providers/shell_route_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_dirty_support.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:control_center/shared/editor/host/editor_body_host.dart';
import 'package:control_center/shared/editor/host/editor_layout_persistence.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Command sink the IDE layout populates for keyboard shortcuts (open editor,
/// close tab, toggle sidebar) without reaching into private [State].
class MessagingIdeActions {
  /// Opens the code-server editor pane (keyboard-shortcut driven).
  VoidCallback? openEditor;

  /// Closes the currently active editor tab.
  VoidCallback? closeActiveTab;

  /// Toggles the IDE sidebar visibility.
  VoidCallback? toggleSidebar;

  /// Opens the quick open file picker (⌘P / Ctrl+P).
  VoidCallback? quickOpen;
}

/// IDE messaging surface: editor split-tree plus activity sidebar.
///
/// [EditorLayoutController] owns the tree; tab bodies stay under stable
/// [GlobalKey]s (reparent on drag, keep webview/terminal). Layout persisted
/// per conversation (space id); sidebar geometry is session-ephemeral.
///
/// The state composes the IDE's hosts: [IdeTerminalSessions] (terminal
/// claims), [IdeRigHost] (machine tabs), [IdeBrowserTabs] (host webviews),
/// [TabCloseGuard] (close prompts), [IdeTabActions] (context menus) and
/// [EditorLayoutPersistence] (the per-space layout). What stays here is the
/// per-space lifecycle: seeding, restoring, revalidating and saving the
/// layout, and mirroring the space's conversations into chat tabs.
class MessagingIdeLayout extends ConsumerStatefulWidget {
  /// Creates the IDE layout.
  const MessagingIdeLayout({
    super.key,
    required this.workspaceId,
    this.selectedSpaceId,
    this.focusedTabKey,
    required this.actions,
  });

  /// The active workspace (isolation scope for the sidebar's data + the cache).
  final String workspaceId;

  /// The currently-selected conversation, or null when none is open. Each
  /// conversation owns its own restored editor layout.
  final String? selectedSpaceId;

  /// The focused editor tab's key from the URL's `?tab=` param, or null when
  /// the URL names no tab (the seeded/restored selection then stands). The
  /// layout writes tab switches back into the URL, so back/forward steps
  /// through tab focus and a refresh lands on the same tab.
  final String? focusedTabKey;

  /// Command sink populated by the state (keyboard shortcuts call into it).
  final MessagingIdeActions actions;

  @override
  ConsumerState<MessagingIdeLayout> createState() => _MessagingIdeLayoutState();
}

class _MessagingIdeLayoutState extends ConsumerState<MessagingIdeLayout>
    with WidgetsBindingObserver
    implements TabCloseHost, IdeHost {
  late final TabCloseGuard _closeGuard = TabCloseGuard(this);
  late final IdeTabActions _tabActions = IdeTabActions(this);
  late final IdeTabOpeners _open = IdeTabOpeners(
    this,
    defaultEditorRepoId: () => _defaultEditorRepoId,
    publishTerminals: _publishTerminals,
  );
  late EditorLayoutController _layout;
  late final ValueNotifier<IdeSidebarView> _sidebarTab;

  /// Terminal claims of the ACTIVE layout (the shells themselves live in the
  /// app-level [terminalRegistryProvider] and survive layout swaps). Pruned
  /// alongside the body host in [_reconcileBodyHost].
  late final IdeTerminalSessions _terminals = IdeTerminalSessions(
    registry: () => ref.read(terminalRegistryProvider.notifier),
    registryState: () => ref.read(terminalRegistryProvider),
  )..addListener(_onTerminalsChanged);

  late final IdeRigHost _rigs = IdeRigHost(layout: () => _layout);
  late final IdeBrowserTabs _browserTabs = IdeBrowserTabs(
    layout: () => _layout,
  );

  /// The open space's conversations as the chat tabs show them, refreshed
  /// every build so a tab's header follows a rename without re-opening it.
  IdeConversationView _conversations = const IdeConversationView();

  /// The space whose conversation set has been mirrored into chat tabs this
  /// open (see [_syncConversationTabs]); reset on space switch so re-opening
  /// a space re-opens its conversations.
  String? _conversationTabsSyncedFor;

  /// Whether the persisted-layout restore for the current space has settled
  /// (applied, or found nothing to apply). Conversation tabs are only
  /// injected AFTER it: a restore replaces the whole tab tree, so tabs added
  /// into the seed beforehand would be silently dropped.
  bool _layoutRestored = false;

  /// Whether the layout on screen may be saved for the current space: it came
  /// from the memo or from a successful server read. A seed shown while the
  /// read is in flight, or after it failed, must never replace the person's
  /// saved layout (and with it the tab they were on).
  bool _canPersist = false;

  /// Bumped on every space entry, so a server read that answers after the
  /// person left (or re-entered) the space is ignored.
  int _entry = 0;

  /// Whether the person changed the layout since entering the space. A newer
  /// server copy found by [_revalidate] then loses: the local change is newer,
  /// and its own save follows.
  bool _editedSinceEntry = false;

  /// True while [_completeRestore] applies the URL and mirrors conversations,
  /// so those changes do not read as the person's own edits.
  bool _settlingRestore = false;

  /// Background tab reconciliation must not publish intermediate URL focus.
  bool _syncingConversationTabs = false;

  /// How many *hidden* webview tabs ([MessagingTabKinds.isWebview]) keep their
  /// live platform view mounted. Hidden webviews beyond the most-recently-visible
  /// cap are suspended ([EditorSuspendedPane]) and rebuilt fresh on reveal.
  /// Code-server tabs are exempt where their worktree's window is shared (the
  /// [_windowPool] bounds those). Chat and terminal tabs are never evicted.
  static const int kMaxHiddenWebviews = 2;

  final EditorBodyHost _bodyHost = EditorBodyHost(
    isWebviewKind: MessagingTabKinds.isWebview,
    maxHiddenWebviews: kMaxHiddenWebviews,
  );

  /// One embedded editor window per worktree, moved between the code-server
  /// tabs of [_layout] as they are selected.
  late final CodeServerWindowPool _windowPool = CodeServerWindowPool(
    targetOf: _codeServerTarget,
    openFile: (worktree, windowId, path, line) => openCodeServerFile(
      ref.read(rpcClientProvider),
      spaceId: worktree.spaceId,
      repoId: worktree.repoId,
      windowId: windowId,
      path: path,
      line: line,
    ),
    closeFile: (worktree, path) => closeCodeServerFile(
      ref.read(rpcClientProvider),
      spaceId: worktree.spaceId,
      repoId: worktree.repoId,
      path: path,
    ),
  );

  String? _defaultEditorRepoId;
  bool _preloadSuppressed = false;

  static CodeServerTarget? _codeServerTarget(EditorTab tab) {
    final spaceId = tab.args['spaceId'];
    if (tab.kind != MessagingTabKinds.codeServer || spaceId is! String) {
      return null;
    }
    return CodeServerTarget(
      spaceId: spaceId,
      repoId: tab.args['repoId'] as String?,
      path: tab.args['path'] as String?,
    );
  }

  double _sidebarWidth = 300;
  static const double _minSidebar = 200;
  static const double _maxSidebar = 560;

  /// Sidebar visibility (ephemeral). Toggled by the panel button (⌘B). The
  /// width is retained so re-showing restores the previous size.
  bool _sidebarVisible = true;

  /// Width of the divider's invisible pointer hit area, centered on the
  /// editor↔sidebar seam. Matches [CcResizable]'s default `dividerHitSize`.
  static const double _dividerHitSize = 8;

  EditorLayoutPersistence? _persistence;
  String? _workspaceId;

  /// Per-file unsaved-changes state (shared with the PR workbench), fed by the
  /// bridge extension via [codeServerDirtyStateProvider]. Keys a code-server
  /// file tab to its dot and gates the Save/Don't-save close prompt. Ephemeral,
  /// cleared on conversation switch.
  final _dirty = EditorDirtyTracker();

  /// Published to the subtree via [EditorTabOpenerScope] so a widget rendered
  /// inside a tab body (a plan bubble in the conversation feed) can open its own
  /// tab here without a callback threaded through the whole feed. Built once —
  /// the closure reads `_layout` at call time, so it survives conversation
  /// switches (which swap the controller).
  late final EditorTabOpener _tabOpener = EditorTabOpener(_open.openFromScope);

  /// What the environment section and ports popover can open here. Built once
  /// so [EnvironmentHostScope] stays an identity check; the closures read the
  /// live layout at call time.
  late final EnvironmentHost _environmentHost = EnvironmentHost(
    openUrl: ({required url, required label}) =>
        _open.openFromScope(MessagingIdeTabs.browserAt(url: url, label: label)),
    openBrowserVm: ({required spaceId}) => _rigs.focusOrOpen(
      AppLocalizations.of(context),
      const RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.chromium,
      ),
    ),
    openLogs: ({required spaceId, required target, required label}) =>
        _open.openFromScope(
          MessagingIdeTabs.environmentLogs(
            workspaceId: _workspaceId,
            spaceId: spaceId,
            target: target,
            label: AppLocalizations.of(context).environmentLogsTab(label),
          ),
        ),
    openProvisioningLogs: ({required spaceId}) => _open.openFromScope(
      MessagingIdeTabs.provisioningLogs(
        workspaceId: _workspaceId,
        spaceId: spaceId,
        label: AppLocalizations.of(context).spaceSetupLogs,
      ),
    ),
    openProcess: ({required spaceId, required sessionId, required label}) =>
        _open.openFromScope(
          MessagingIdeTabs.environmentTerminal(sessionId, label),
        ),
    openSetup: ({required spaceId, required sessionId, required label}) =>
        _open.openFromScope(
          MessagingIdeTabs.environmentTerminal(sessionId, label, setup: true),
        ),
    openViewer: ({required spaceId, required componentId, required label}) =>
        _rigs.focusOrOpen(
          AppLocalizations.of(context),
          RigTabTarget(RigSurface.window.wire, slotId: componentId),
        ),
    openPrefilledTerminal: ({required spaceId, required command}) => _open
        .openFromScope(MessagingIdeTabs.newTerminal(initialInput: command)),
    showsSpace: (spaceId) => mounted && widget.selectedSpaceId == spaceId,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sidebarTab = ValueNotifier<IdeSidebarView>(IdeSidebarView.general);
    _persistence = _newPersistence();
    _workspaceId = ref.read(activeWorkspaceIdProvider);
    final warm = _peekLayout(widget.selectedSpaceId);
    _layout = warm?.layout ?? _seedLayout(widget.selectedSpaceId);
    _canPersist = warm != null;
    _layout.addListener(_onLayoutChanged);
    _windowPool.attach(_layout);
    _wireActions(widget.actions);
    _tabUrl = EditorTabUrlTracker(
      initialKey: widget.focusedTabKey,
      focusKey: _focusTabByKey,
      writeKey: _writeTabKey,
    );
    // Restore this conversation's persisted layout once the first frame (and
    // thus the provider reads in [build]) has run. A layout the memo already
    // held is on screen now; only the tab mirror is left to run.
    final spaceId = widget.selectedSpaceId;
    if (spaceId != null) {
      final entry = _entry;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (warm != null) {
          _completeRestore();
          _revalidate(spaceId, entry);
        } else {
          _restorePersisted(spaceId, entry);
        }
      });
    }
  }

  RouteInformation? _lastRouteInformation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lastRouteInformation ??= GoRouter.maybeOf(
      context,
    )?.routeInformationProvider.value;
  }

  EditorLayoutPersistence _newPersistence() => EditorLayoutPersistence(
    codec: messagingLayoutCodec,
    cache: ref.read(editorLayoutCacheRepositoryProvider),
    cacheKind: editorLayoutCacheKind,
    memo: ref.read(editorLayoutMemoProvider),
  );

  /// The space's layout when this client already knows it, without a
  /// round-trip. Null when it has to be read from the server.
  ({EditorLayoutController? layout})? _peekLayout(String? spaceId) {
    final workspaceId = _workspaceId;
    final persistence = _persistence;
    if (spaceId == null || workspaceId == null || persistence == null) {
      return null;
    }
    return persistence.peek(workspaceId: workspaceId, cacheKey: spaceId);
  }

  /// Wires the external command sink so keyboard shortcuts (⌘T/⌘W/⌘B) can drive
  /// IDE actions without reaching into this private state.
  void _wireActions(MessagingIdeActions actions) {
    actions
      ..openEditor = _open.openEditor
      ..closeActiveTab = closeActiveTab
      ..toggleSidebar = toggleSidebar
      ..quickOpen = _open.quickOpen;
  }

  /// Detaches [actions] so a stale shortcut can't call into a torn-down (or
  /// replaced) state. Silently no-ops when the sink has already been re-wired to
  /// another state.
  void _unwireActions(MessagingIdeActions actions) {
    actions
      ..openEditor = null
      ..closeActiveTab = null
      ..toggleSidebar = null
      ..quickOpen = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unwireActions(widget.actions);
    // Flush the current conversation's layout synchronously before tearing down.
    _persistNow(widget.selectedSpaceId);
    _persistence?.dispose();
    _sidebarTab.dispose();
    _windowPool.dispose();
    _terminals
      ..removeListener(_onTerminalsChanged)
      ..dispose();
    _layout.removeListener(_onLayoutChanged);
    _layout.dispose();
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    // Do not speculate again in this space after the OS asks for memory back.
    _preloadSuppressed = true;
    _windowPool.setPreloadTarget(null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _windowPool.setPreloadTarget(null);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MessagingIdeLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The sink is wired in [initState], so a *replaced* sink would arrive here
    // with every callback null and every shortcut would silently no-op (the
    // binding still matches and consumes the key). The screen keeps one instance
    // for its lifetime, so this is belt-and-braces — but a sink rebuilt in a
    // parent's `build` is exactly how ⌘W broke before.
    if (!identical(oldWidget.actions, widget.actions)) {
      _unwireActions(oldWidget.actions);
      _wireActions(widget.actions);
    }
    final spaceChanged = oldWidget.selectedSpaceId != widget.selectedSpaceId;
    if (spaceChanged) {
      _switchConversation(oldWidget.selectedSpaceId, widget.selectedSpaceId);
    }
    final routeInformation = GoRouter.maybeOf(
      context,
    )?.routeInformationProvider.value;
    // Local tab presses leave GoRouter's key untouched. A fresh navigation
    // to that same key must still reopen/refocus its tab; ordinary provider
    // rebuilds must not reapply the stale route over the user's local focus.
    // Nor must a navigation AWAY: the screen holds this space's key back for
    // a frame while the route already names the next destination, and
    // reapplying it here would refocus the entry tab just before leaving saves
    // the layout, losing the tab the person was on.
    final routePath = routeInformation?.uri.path;
    final explicitTabRequest =
        widget.focusedTabKey != null &&
        oldWidget.focusedTabKey == widget.focusedTabKey &&
        _tabUrl.lastKey != widget.focusedTabKey &&
        !identical(_lastRouteInformation, routeInformation) &&
        routePath != null &&
        spaceIdFromLocation(routePath, _workspaceId) == widget.selectedSpaceId;
    _lastRouteInformation = routeInformation;
    if (!spaceChanged &&
        (oldWidget.focusedTabKey != widget.focusedTabKey ||
            explicitTabRequest)) {
      // Same-space back/forward or deep link: focus after this build.
      // A space switch applies its URL key as part of restore instead;
      // applying a null key again would reset the restored selection.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabUrl.apply(
            _layout,
            widget.focusedTabKey,
            force: explicitTabRequest,
          );
          _syncRestoredTabUrl();
        }
      });
    }
  }

  /// Two-way sync between the focused editor tab and the URL's `?tab=` param:
  /// a tab switch publishes lightweight browser history, while back/forward or
  /// a deep link re-focuses the named tab. The state machine lives in
  /// [EditorTabUrlTracker]; only the focus/write actions are messaging-specific.
  late final EditorTabUrlTracker _tabUrl;

  /// Mirrors focus into browser history without routing the active page again.
  ///
  /// A tab press is local editor state. Sending it through `context.go` rebuilt
  /// the whole messaging route and every visited tab body before the selected
  /// tab could paint.
  void _writeTabKey(String? key) {
    final uri = GoRouterState.of(context).uri;
    unawaited(updateEditorTabRoute(uri, key));
  }

  /// Replaces a space-entry URL with its resolved tab, including in GoRouter's
  /// route state. Wait for conversation tabs before resolving a deep link;
  /// it may name a conversation that was not in the cached layout.
  void _syncRestoredTabUrl() {
    if (widget.selectedSpaceId == null ||
        _conversationTabsSyncedFor != widget.selectedSpaceId) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final uri = GoRouterState.of(context).uri;
    final location = locationWithEditorTab(uri, activeEditorTabKey(_layout));
    if (location == uri.toString()) {
      return;
    }
    _tabUrl.resync(_layout);
    // Resolving saved focus is part of opening the space, not another Back
    // step. Ordinary tab presses still use the lightweight platform writer.
    Router.neglect(context, () => router.go(location));
  }

  /// Focuses the tab a `?tab=` [key] names (see [focusIdeTabByKey]).
  void _focusTabByKey(String key) => focusIdeTabByKey(
    _layout,
    key,
    spaceId: widget.selectedSpaceId,
    view: _conversations,
    openConversation: _open.openConversation,
  );

  /// Toggles the sidebar visibility (⌘B / the panel button). Retains the width
  /// so re-showing restores the previous size.
  void toggleSidebar() {
    setState(() => _sidebarVisible = !_sidebarVisible);
  }

  /// Closes the active leaf's selected tab (⌘W). No-op when the leaf is empty.
  /// Closing the last tab of the only leaf leaves an empty leaf (the tree never
  /// removes its final leaf); closing the last tab of a side pane prunes the
  /// pane — both handled by [EditorLayoutController.closeTab]. A tab with
  /// unsaved changes routes through the same Save/Don't-save/Cancel prompt as
  /// the tab-strip × (see [TabCloseGuard.confirmClose]), then re-locates the tab by
  /// identity (the async prompt can shift the selection).
  Future<void> closeActiveTab() async {
    final leaf = _layout.activeLeaf;
    final controller = leaf.controller;
    if (controller.tabs.isEmpty) {
      return;
    }
    final tab = controller.tabs[controller.selectedIndex];
    if (!await _closeGuard.confirmClose(tab)) {
      return;
    }
    final idx = controller.indexOfIdentity(tab);
    if (idx >= 0) {
      _layout.closeTab(leaf.id, idx);
    }
  }

  /// Seeds a fresh single-leaf layout with the conversation tab alone. A new
  /// space starts slim — Terminal and Browser open on demand from the `[+]`
  /// menu, never by default (a seeded terminal spawns a shell process and a
  /// seeded browser tab holds a webview nobody asked for).
  EditorLayoutController _seedLayout(String? spaceId) {
    final controller = EditorTabGroupController();
    if (spaceId != null) {
      controller.openTab(MessagingIdeTabs.chat(spaceId));
    }
    controller.selectedIndex = 0;
    return EditorLayoutController.single(controller: controller);
  }

  /// Swaps the active [EditorLayoutController], disposing the old one and
  /// reconciling the body host against the new tree.
  void _setLayout(EditorLayoutController next) {
    _layout.removeListener(_onLayoutChanged);
    _windowPool.attach(next);
    _layout.dispose();
    _layout = next;
    _layout.addListener(_onLayoutChanged);
    _reconcileBodyHost();
  }

  /// Persists the outgoing conversation, then loads (or seeds) the incoming
  /// one. Also sweeps cross-conversation session state: the outgoing space's
  /// terminals mirror is emptied (its sessions SURVIVE the swap in the
  /// keep-alive registry — only the sidebar mirror is space-scoped) and
  /// the global thread selection is reset so a thread open in the outgoing
  /// conversation can't leak into the incoming one's pane.
  void _switchConversation(String? from, String? to) {
    _persistNow(from);
    _defaultEditorRepoId = null;
    _preloadSuppressed = false;
    // The incoming space re-runs its restore + conversation-tab mirror.
    _layoutRestored = false;
    _conversationTabsSyncedFor = null;
    // Dirty state is keyed by (repoId, path) without a space; drop it so the
    // incoming conversation can't inherit the outgoing one's unsaved dots.
    _dirty.clear();
    // Keep-decisions belong to tabs that are about to leave the tree with the
    // layout: a swap is not a close, so nothing is waiting to read them.
    _terminals.forgetKeptShells();
    // A space this client has shown before swaps straight to its layout:
    // seeding first and restoring a round-trip later built every tab body
    // twice, and the chat drew a spinner in between.
    final warm = _peekLayout(to);
    setState(() => _setLayout(warm?.layout ?? _seedLayout(to)));
    final entry = ++_entry;
    _canPersist = warm != null;
    _editedSinceEntry = false;
    // This runs from didUpdateWidget (mid-build) and Riverpod 3 forbids
    // modifying a provider during a build pass ("modified a provider while the
    // widget tree was building"). The outgoing conversation's terminals mirror
    // is cleanup, so defer it a frame — the same discipline the restore below
    // (and the rest of this layout) already uses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (from != null) {
        ref
            .read(spaceTerminalsProvider(from).notifier)
            .set(const <TerminalMirror>[]);
        ref
            .read(spaceBrowserTabsProvider(from).notifier)
            .set(const <BrowserTabMirror>[]);
      }
    });
    if (to != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (warm == null) {
          _restorePersisted(to, entry);
        } else if (mounted && _entry == entry) {
          _completeRestore();
          _revalidate(to, entry);
        }
      });
    } else {
      // No restore will run for the empty surface: re-track the seed's focus
      // against the URL tracker immediately (same drift the restore's
      // force-apply resyncs when a conversation IS incoming).
      _tabUrl.resync(_layout);
    }
  }

  Future<void> _restorePersisted(String spaceId, int entry) async {
    final persistence = _persistence;
    final workspaceId = _workspaceId;
    if (persistence == null || workspaceId == null) {
      return;
    }
    final fetched = await persistence.fetch(
      workspaceId: workspaceId,
      cacheKey: spaceId,
    );
    final restored = fetched.layout;
    // Bail if the conversation changed (or we unmounted) while reading.
    if (!mounted || _entry != entry || widget.selectedSpaceId != spaceId) {
      restored?.dispose();
      return;
    }
    // A failed read says nothing about the saved layout: keep the seed on
    // screen, but never save it over the layout the server still holds.
    _canPersist = !fetched.failed;
    // A missing/unrestorable payload keeps the seeded layout; either way the
    // URL's `?tab=` gets the final say on which tab is focused.
    if (restored != null) {
      // The seed's chat tab is usually the restored chat tab too: keep its
      // built feed rather than building it again under the sidebar's reveal.
      _bodyHost.adoptBodies(
        outgoing: _layout.allTabs(),
        incoming: restored.allTabs(),
      );
      setState(() => _setLayout(restored));
    }
    _completeRestore();
  }

  /// The tail every restore shares, whether the layout came from the memo or
  /// the server: the URL's `?tab=` gets the final say, then the space's
  /// conversations are mirrored into chat tabs.
  void _completeRestore() {
    _settlingRestore = true;
    try {
      _tabUrl.apply(_layout, widget.focusedTabKey, force: true);
      _layoutRestored = true;
      // Conversations may already be loaded (provider cache) — mirror them
      // into chat tabs now; otherwise the build watch runs the sync when they
      // arrive.
      _syncConversationTabs();
    } finally {
      _settlingRestore = false;
    }
  }

  /// Re-reads a layout this client restored from its memo.
  ///
  /// The memo is only as fresh as this client's last visit, and the same
  /// person may have moved to another tab on another device since. A newer
  /// server copy replaces the one on screen, unless they already changed
  /// something here.
  Future<void> _revalidate(String spaceId, int entry) async {
    final persistence = _persistence;
    final workspaceId = _workspaceId;
    if (persistence == null || workspaceId == null) {
      return;
    }
    final fetched = await persistence.fetch(
      workspaceId: workspaceId,
      cacheKey: spaceId,
    );
    final fresh = fetched.layout;
    if (!mounted ||
        _entry != entry ||
        widget.selectedSpaceId != spaceId ||
        !fetched.changed ||
        fresh == null ||
        _editedSinceEntry) {
      fresh?.dispose();
      return;
    }
    _bodyHost.adoptBodies(
      outgoing: _layout.allTabs(),
      incoming: fresh.allTabs(),
    );
    setState(() => _setLayout(fresh));
    // The adopted tree replaced the mirrored chat tabs; mirror again.
    _conversationTabsSyncedFor = null;
    _completeRestore();
  }

  /// Mirrors the space's ACTIVE conversations into chat tabs, once per space
  /// open (see [mirrorConversationTabs]). There is no in-pane switcher strip;
  /// the tab strip IS the switcher.
  ///
  /// Runs after the persisted layout settles ([_layoutRestored]) and once the
  /// conversation list + standing id have loaded — whichever comes last —
  /// guarded by [_conversationTabsSyncedFor]. The restored selection (or the
  /// URL's `?tab=`) keeps the final say, re-applied at the end because the URL
  /// may name a chat tab that only now exists.
  void _syncConversationTabs() {
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null ||
        !_layoutRestored ||
        _conversationTabsSyncedFor == spaceId) {
      return;
    }
    final standingId = _conversations.standingId;
    final conversations = ref.read(spaceConversationsProvider(spaceId)).value;
    if (standingId == null || conversations == null) {
      return;
    }
    _conversationTabsSyncedFor = spaceId;
    _syncingConversationTabs = true;
    try {
      mirrorConversationTabs(
        _layout,
        spaceId: spaceId,
        standingId: standingId,
        conversations: conversations,
        view: _conversations,
      );
      _tabUrl.apply(_layout, widget.focusedTabKey, force: true);
    } finally {
      _syncingConversationTabs = false;
    }
    _syncRestoredTabUrl();
  }

  void _onLayoutChanged() {
    if (!mounted) {
      return;
    }
    // A tab leaving the tree from a live-layout change is a USER close (or a
    // drag to another leaf — which keeps the tab live): kill closed shells. A
    // rig tab is NOT one of those — closing it puts away the viewer, not the
    // machine (see [_reconcileBodyHost]).
    _reconcileBodyHost(killOrphanedTerminals: true);
    if (!_syncingConversationTabs && !_settlingRestore) {
      _editedSinceEntry = true;
    }
    // EditorWorkspace already listens to the layout and rebuilds only the
    // workbench. Rebuilding this host too used to rebuild the sidebar and every
    // visited body a second time for each tab press.
    _schedulePersist();
    if (!_syncingConversationTabs) {
      _tabUrl.writeFromLayout(_layout);
    }
    _open.recordRecentFile();
  }

  /// Drops body-host entries for tabs no longer anywhere in the tree. The
  /// shared host prunes its keep-alive/visited/LRU state; the terminal claims
  /// are pruned against the same live set ([IdeTerminalSessions.reconcile]).
  ///
  /// [killOrphanedTerminals] distinguishes WHY a tab left the tree: `true`
  /// (layout change within the live layout — the user closed the tab) kills
  /// the shell; `false` (a seed/switch/restore layout swap) keeps the session
  /// alive in the registry so switching back re-claims it.
  ///
  /// A rig tab is a VIEWER, not the machine: closing it deliberately leaves
  /// the guest running (its pages, session and logged-in state), and the
  /// sidebar's BROWSERS/COMPUTERS row opens the tab again on it. What ends a
  /// machine is an explicit stop or the reaper; tying shutdown to the × made
  /// closing a tab to clear space an irreversible act.
  void _reconcileBodyHost({bool killOrphanedTerminals = false}) {
    final live = Set<EditorTab>.identity()..addAll(_layout.allTabs());
    _bodyHost.reconcile(live);
    _terminals.reconcile(live, killOrphaned: killOrphanedTerminals);
    _publishTerminals();
    _publishBrowserTabs();
  }

  /// A claim landed, a shell retitled or a deferred terminal started: the tab
  /// strip and the sidebar's TERMINALS mirror follow.
  void _onTerminalsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _publishTerminals();
  }

  /// Mirrors the live terminal sessions into [spaceTerminalsProvider] so the
  /// General pane's TERMINALS section can list them (the claims stay the
  /// source of truth; this is a read mirror) — including this space's shells
  /// kept running with NO tab, whose row is the only way back to them. Also
  /// feeds the registry's eviction-protected claim set.
  void _publishTerminals() {
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final sessions = _terminals.mirrorsFor(spaceId);
    // Deferred so it never fires mid-build (the provider is written from build
    // callbacks like a terminal claim's post-frame landing).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(spaceTerminalsProvider(spaceId).notifier).set(sessions);
      ref
          .read(terminalRegistryProvider.notifier)
          .syncClaims(_terminals.claimedSessionIds);
    });
  }

  /// Mirrors the open HOST browser tabs into [spaceBrowserTabsProvider] so the
  /// General pane's BROWSERS section can list them beside the VM rigs — the
  /// tab set stays owned by the layout; this is a read mirror.
  void _publishBrowserTabs() {
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final mirrors = _browserTabs.sync(AppLocalizations.of(context));
    // Deferred so it never fires mid-build: the reconcile can run from
    // didUpdateWidget (a conversation switch) where a provider write throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(spaceBrowserTabsProvider(spaceId).notifier).set(mirrors);
    });
  }

  void _schedulePersist() {
    final spaceId = widget.selectedSpaceId;
    final workspaceId = _workspaceId;
    final persistence = _persistence;
    if (!_canPersist ||
        spaceId == null ||
        workspaceId == null ||
        persistence == null) {
      return;
    }
    persistence.schedule(
      workspaceId: workspaceId,
      cacheKey: spaceId,
      layout: _layout,
    );
  }

  void _persistNow(String? spaceId) {
    final workspaceId = _workspaceId;
    final persistence = _persistence;
    if (!_canPersist ||
        spaceId == null ||
        workspaceId == null ||
        persistence == null) {
      return;
    }
    persistence.flushNow(
      workspaceId: workspaceId,
      cacheKey: spaceId,
      layout: _layout,
    );
  }

  Widget _buildBody(EditorTab tab, bool isVisible) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Keep-alive, lazy build, TickerMode and webview suspension all live in the
    // shared [EditorBodyHost]; the body/suspended widgets stay messaging's.
    return _bodyHost.wrap(
      tab,
      isVisible: isVisible,
      background: t.bgPrimary,
      buildContent: () => MessagingIdeTabBody(
        tab: tab,
        workspaceId: _workspaceId,
        selectedSpaceId: widget.selectedSpaceId,
        isVisible: isVisible,
        windowPool: _windowPool,
        conversationOpenerFor: _open.conversationOpenerFor,
        openSubagentRun: _open.openSubagentRun,
        terminalPane: _buildTerminalPane,
      ),
      buildSuspended: () => EditorSuspendedPane(
        icon: tab.kind == MessagingTabKinds.codeServer
            ? AppIcons.code
            : AppIcons.globe,
      ),
    );
  }

  /// A terminal tab's body; an unclaimed tab claims its session on the next
  /// frame (see [IdeTerminalSessions.completeClaim]).
  Widget _buildTerminalPane(EditorTab tab) {
    if (_terminals.beginClaim(tab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _terminals.completeClaim(
          tab,
          spaceId: widget.selectedSpaceId ?? '',
          workspaceId: ref.read(activeWorkspaceIdProvider) ?? '',
          // The tab may have been closed while the claim was deferred.
          stillOpen: _layout.leafIdContaining(tab) != null,
          onShellExit: _onTerminalShellExit,
        );
      });
    }
    return IdeTerminalPane(
      tab: tab,
      controller: _terminals.controllerFor(tab),
      awaitsStart: _terminals.awaitsStart(tab),
      onStart: () => _terminals.start(tab),
      onOpenFresh: () => _open.openFromScope(MessagingIdeTabs.newTerminal()),
    );
  }

  /// A claimed tab's shell exited: close the tab (post-frame; the callback
  /// fires mid-stream-delivery). When the session id is claimed by no tab —
  /// the space is inactive and the shell exited while hidden — it is killed
  /// in the registry instead (there is no tab to close).
  void _onTerminalShellExit(String sessionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final tab = _terminals.shellExited(sessionId);
      if (tab != null) {
        _layout.closeTabByIdentity(tab);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The layout cache is a stable workspace-scoped provider; build the
    // persistence helper once (the cache repo never changes over the state's
    // life). Keyed by space id under the messaging layout cache kind.
    _persistence ??= _newPersistence();
    _workspaceId = ref.watch(activeWorkspaceIdProvider);
    // Kept warm here so the "+" menu's VM-terminal entry has an answer by the
    // time it opens — the menu itself builds outside this widget's build pass
    // and can only `read`.
    ref.watch(rigCapabilitiesProvider);
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final spaceId = widget.selectedSpaceId;

    _watchCodeServerPreload(spaceId);
    _conversations = _watchConversations(spaceId);

    // Opening a space opens its conversations in the top tab strip. The data
    // above is watched, so whichever of (restore, conversation list, standing
    // id) lands last triggers a rebuild that completes the mirror; the guards
    // inside make the repeats free. Post-frame: opening tabs mutates the
    // layout, which must not happen mid-build.
    if (spaceId != null && _conversationTabsSyncedFor != spaceId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.selectedSpaceId == spaceId) {
          _syncConversationTabs();
        }
      });
    }

    // Archiving does not only happen in this pane. The global sidebar's
    // conversation row archives too, and so can another device — and the mirror
    // above has already fired its once-per-space guard, so neither would close
    // the tab. The conversation would then keep a live stream open in a tab the
    // sidebar has already dropped. Deliberately unguarded and driven by the
    // watched list: it is a no-op on every build where nothing was archived,
    // and closing converges (the next build finds none).
    if (spaceId != null) {
      final orphans = _conversations.archivedTabs(_layout.allTabs());
      if (orphans.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          for (final t in orphans) {
            _layout.closeTabByIdentity(t);
          }
        });
      }
      _listenToCodeServer(spaceId);
    }

    // Wrapped in the opener scope so widgets inside a tab body (the plan bubble
    // in the conversation feed) can open their own tabs here.
    final Widget body = Stack(
      // Fill the parent (the shell body) so the pane row and the overlaid
      // divider both span the full surface, as the top-level Row did before.
      fit: StackFit.expand,
      children: [
        // Boot behind the foreground; park ready windows offstage.
        CodeServerWindowParking(pool: _windowPool),
        // Panes laid out flush, edge-to-edge: the editor fills the remaining
        // width and the sidebar abuts it with no gap. The boundary line is the
        // overlaid divider below, not a border on either pane.
        Row(
          children: [
            Expanded(
              child: EditorWorkspace(
                layout: _layout,
                chrome: _chrome(l10n),
                onResized: _schedulePersist,
                buildBody: (tab, {required isVisible}) =>
                    _buildBody(tab, isVisible),
              ),
            ),
            if (_sidebarVisible)
              SizedBox(width: _sidebarWidth, child: _buildSidebar(l10n)),
          ],
        ),
        // The draggable hairline is overlaid on the editor↔sidebar seam and
        // centered on it, so it consumes no layout width and leaves no gap on
        // either side (the panes meet flush behind it). With the sidebar's own
        // left border removed, this single line is the sole boundary — no
        // doubled edge. Mirrors CcResizable's divider treatment. Hidden when the
        // sidebar is toggled off.
        if (_sidebarVisible)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: _sidebarWidth - _dividerHitSize / 2,
            width: _dividerHitSize,
            child: IdeSidebarDivider(
              hitSize: _dividerHitSize,
              color: t.lineStrong,
              activeColor: t.fgBrandPrimary,
              onDrag: _resizeSidebar,
            ),
          ),
      ],
    );

    return EnvironmentHostScope(
      host: _environmentHost,
      child: EditorTabOpenerScope(opener: _tabOpener, child: body),
    );
  }

  /// Warms only the selected, provisioned space's first repo, never the
  /// workspace's whole repo list. The pool debounces navigation, waits for
  /// scheduler idle and expires an unused window instead of retaining it.
  void _watchCodeServerPreload(String? spaceId) {
    final canPreload =
        CodeServerWindowPool.sharesWindows &&
        spaceId != null &&
        !ref.watch(isDemoServerProvider);
    final worktrees = canPreload
        ? ref
              .watch(
                spaceWorktreesProvider((
                  workspaceId: widget.workspaceId,
                  spaceId: spaceId,
                )),
              )
              .value
        : null;
    _defaultEditorRepoId = worktrees?.firstOrNull?.repoId;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final preload =
        canPreload &&
            _defaultEditorRepoId != null &&
            !_preloadSuppressed &&
            TickerMode.valuesOf(context).enabled &&
            (lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
            ref.watch(spaceProvisioningStatusProvider(spaceId)) ==
                SpaceProvisioningStatus.ready
        ? CodeServerTarget(spaceId: spaceId, repoId: _defaultEditorRepoId)
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.selectedSpaceId != spaceId) {
        return;
      }
      final state = WidgetsBinding.instance.lifecycleState;
      _windowPool.setPreloadTarget(
        !_preloadSuppressed &&
                (state == null || state == AppLifecycleState.resumed)
            ? preload
            : null,
      );
    });
  }

  /// Chat tabs label themselves from the LIVE conversation list rather than
  /// the label frozen into the tab, so a rename lands immediately and a
  /// thread is legible as one. Watched here (not read inside the chrome
  /// callbacks, which run in a descendant's build) so a change actually
  /// rebuilds the tab strip. `spaceConversationsProvider` is already watched
  /// by the switcher, so this shares one subscription.
  IdeConversationView _watchConversations(String? spaceId) {
    if (spaceId == null) {
      return const IdeConversationView();
    }
    final byId = {
      for (final c
          in ref.watch(spaceConversationsProvider(spaceId)).value ??
              const <Conversation>[])
        c.id: c,
    };
    return IdeConversationView(
      byId: byId,
      standingId: ref.watch(standingConversationIdProvider(spaceId)).value,
      titleGeneratingIds:
          ref.watch(spaceTitleGeneratingIdsProvider(spaceId)).value ?? const {},
      busyIds: ref.watch(spaceBusyConversationIdsProvider(spaceId)),
      unreadIds: {
        for (final id in byId.keys)
          if (ref.watch(
            conversationUnreadProvider((spaceId: spaceId, conversationId: id)),
          ))
            id,
      },
    );
  }

  /// The embedded editor's bridge extension, scoped to the open conversation.
  /// Errors (a server without code-server) are ignored.
  void _listenToCodeServer(String spaceId) {
    // In-editor navigation → app tab: a file the user navigated to (cmd-click
    // "go to definition", quick open, …) focuses or opens that file's tab in
    // the pane holding the window that navigated; the tab then takes over the
    // same window, already on the file.
    ref.listen<AsyncValue<CodeServerOpenEvent>>(
      codeServerOpenRequestsProvider(spaceId),
      (previous, next) {
        final evt = next.asData?.value;
        if (evt == null || evt.path.isEmpty) {
          return;
        }
        _windowPool.noteNavigated(evt.windowId, evt.path);
        final owner = _windowPool.ownerOfBridge(evt.windowId);
        _open.openWorktreeFile((
          repoId: evt.repoId,
          path: evt.path,
        ), leafId: owner == null ? null : _layout.leafIdContaining(owner));
      },
    );

    // Unsaved-changes reporting → per-tab dirty dot: each file's dirty↔clean
    // transition, keyed to its path, rebuilds the matching tab's dot.
    ref.listen<AsyncValue<CodeServerDirtyEvent>>(
      codeServerDirtyStateProvider(spaceId),
      (previous, next) {
        final evt = next.asData?.value;
        if (evt == null || evt.path.isEmpty) {
          return;
        }
        if (_dirty.set(path: evt.path, dirty: evt.dirty)) {
          setState(() {});
        }
      },
    );

    // A take-over just began (PRD 16 §8): open the code-server editor tab
    // on this space's worktree the same way ⌘T / a file open would.
    ref.listen<int>(codeServerTabRequestProvider(spaceId), (previous, next) {
      if (previous != null && next != previous) {
        _open.openEditor();
      }
    });
  }

  Widget _buildSidebar(AppLocalizations l10n) => IdeSidebar(
    tabNotifier: _sidebarTab,
    layout: _layout,
    workspaceId: widget.workspaceId,
    spaceId: widget.selectedSpaceId,
    onFocusBrowserTab: (tabId) => _browserTabs.focus(tabId, l10n),
    onCloseBrowserTab: _browserTabs.close,
    // The editor is the default open action (dedup by path).
    onOpenFile: _open.openWorktreeFile,
    // Lightweight read-only fallback (the old default) — available as an
    // explicit "Quick view" so plain-text browsing still works.
    onQuickViewFile: _open.quickViewFile,
    onOpenReview: _open.openReview,
    // Same path the Explorer file-click uses (dedup by path).
    onViewSource: _open.openWorktreeFile,
    onRevertFiles: _open.revertFiles,
    onOpenAgentRun: _open.openAgentRun,
    onOpenAgentShell: _open.openAgentShell,
    onFocusTerminal: _open.focusOrOpenTerminal,
    onKillTerminal: _open.killTerminal,
    // Focusing a machine selects (or opens) ITS tab: the match is surface +
    // engine + slot. This is the way BACK to a machine that is already
    // running — the `[+]` menu is the way to a new one.
    onFocusRig: (target) => _rigs.focusOrOpen(l10n, target),
  );

  void _resizeSidebar(double delta) {
    // The divider reports a physical dx. The sidebar hangs off the trailing
    // edge, so growth is a drag toward the start: negate under RTL, where
    // "toward the start" is a positive dx.
    final logicalDelta = Directionality.of(context) == TextDirection.rtl
        ? -delta
        : delta;
    setState(() {
      _sidebarWidth = (_sidebarWidth - logicalDelta).clamp(
        _minSidebar,
        _maxSidebar,
      );
    });
  }

  /// Whether [tab] is a code-server file tab with unsaved changes (drives the
  /// tab strip's dot). Non-file surfaces (chat/terminal/browser, the ⌘T full
  /// editor with no path) are never dirty.
  ///
  /// Keyed by worktree-relative PATH alone: the dirty subscription is already
  /// scoped to this conversation and the tracker is cleared on conversation
  /// switch and the report's repo id can differ from the tab's (a `⌘T` session
  /// resolves an empty repo id server-side). Two repos in one space sharing a
  /// relative path is rare and only mis-dots a sibling.
  bool _tabDirty(EditorTab tab) =>
      tab.kind == MessagingTabKinds.codeServer &&
      _dirty.isDirty(tab.args['path'] as String?);

  // TabCloseHost: what the close confirmations read.
  @override
  String? get closeGuardWorkspaceId => _workspaceId;

  @override
  String? get closeGuardSpaceId => widget.selectedSpaceId;

  @override
  String? get closeGuardStandingConversationId => _conversations.standingId;

  @override
  bool isTabDirty(EditorTab tab) => _tabDirty(tab);

  @override
  TerminalSessionController? terminalFor(EditorTab tab) =>
      _terminals.controllerFor(tab);

  @override
  void keepShell(EditorTab tab) => _terminals.keepShell(tab);

  @override
  String terminalLabel(EditorTab tab, AppLocalizations l10n) =>
      _terminals.label(tab, l10n);

  @override
  String chatLabel(EditorTab tab, AppLocalizations l10n) =>
      _conversations.chatLabel(tab, l10n);

  // IdeHost: what the tab openers and context-menu actions read.
  @override
  String get hostWorkspaceId => widget.workspaceId;

  @override
  String? get activeWorkspaceId => _workspaceId;

  @override
  String? get selectedSpaceId => widget.selectedSpaceId;

  @override
  IdeConversationView get conversations => _conversations;

  @override
  IdeTerminalSessions get terminals => _terminals;

  @override
  EditorLayoutController get layout => _layout;

  EditorChrome _chrome(AppLocalizations l10n) => messagingIdeChrome(
    l10n: l10n,
    conversations: _conversations,
    terminals: _terminals,
    isDirty: _tabDirty,
    confirmClose: _closeGuard.confirmClose,
    contextMenuExtras: _tabActions.contextMenuExtras,
    onUntitledDraft: _open.openEditor,
    onToggleSidebar: toggleSidebar,
    sidebarVisible: _sidebarVisible,
    newTabMenuItems: (leafId) => messagingNewTabMenu(
      l10n: l10n,
      leafId: leafId,
      spaceId: widget.selectedSpaceId,
      capabilities: IdeRigCapabilities.read(ref),
      rigs: _rigs,
      mounted: () => mounted,
      openNextFrame: _open.openNextFrame,
      onNewConversation: () => unawaited(_open.newConversation(leafId)),
    ),
  );
}
