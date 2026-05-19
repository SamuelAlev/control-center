import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_detail_view.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/browser_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/editor_layout_snapshot.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/file_viewer_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/review_code_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/providers/channel_takeover_provider.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/features/observability/presentation/tool_render/run_activity_opener_scope.dart';
import 'package:control_center/features/plan_studio/presentation/screens/plan_studio_screen.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/features/sandboxing/providers/terminal_registry_provider.dart';
import 'package:control_center/features/sandboxing/providers/terminal_sessions_provider.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// The IDE-style messaging surface: a tiling editor split-tree on the left plus
/// a fixed activity sidebar on the right.
///
/// The editor layout (split tree + per-leaf tab state) is owned by an
/// [EditorLayoutController]; tab *bodies* (chat / terminal / browser / file /
/// diff) are built and **kept alive** here, in one place, under a stable
/// per-tab [GlobalKey] — so a tab dragged between panes is reparented, not
/// rebuilt, keeping its live webview / terminal session intact.
///
/// The layout is persisted **per conversation** (keyed by channel id) in the
/// workspace-scoped cache and restored on restart. Sidebar geometry is
/// ephemeral session state.
/// A small command sink the IDE layout state populates so external callers
/// (keyboard shortcuts) can drive IDE actions (open the code-server editor,
/// close the active tab, toggle the sidebar) without reaching into the private
/// [State].
class MessagingIdeActions {
  /// Opens the code-server editor pane (keyboard-shortcut driven).
  VoidCallback? openEditor;

  /// Closes the currently active editor tab.
  VoidCallback? closeActiveTab;

  /// Toggles the IDE sidebar visibility.
  VoidCallback? toggleSidebar;
}

/// The messaging IDE layout: an editor split tree on the left and a sidebar
/// (General / Explorer / Source Control / Pull Requests) on the right.
class MessagingIdeLayout extends ConsumerStatefulWidget {
  /// Creates the IDE layout.
  const MessagingIdeLayout({
    super.key,
    required this.workspaceId,
    this.selectedChannelId,
    this.focusedTabKey,
    required this.actions,
  });

  /// The active workspace (isolation scope for the sidebar's data + the cache).
  final String workspaceId;

  /// The currently-selected conversation, or null when none is open. Each
  /// conversation owns its own restored editor layout.
  final String? selectedChannelId;

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

class _MessagingIdeLayoutState extends ConsumerState<MessagingIdeLayout> {
  late EditorLayoutController _layout;
  late final ValueNotifier<IdeSidebarView> _sidebarTab;

  // ── Central tab-body host (keep-alive) ───────────────────────────────────
  // Keep-alive / lazy-build / TickerMode / webview-LRU machinery is shared with
  // the PR workbench via [EditorBodyHost]. Feature-specific per-tab resources
  // (terminal session CLAIMS) stay here and are pruned alongside in
  // [_reconcileBodyHost].
  /// Terminal controllers claimed by live tabs of the ACTIVE layout, keyed by
  /// tab identity. The controllers themselves live in the app-level
  /// [terminalRegistryProvider] and SURVIVE layout swaps (channel switches):
  /// dropping a claim detaches the view callbacks but keeps the shell, its
  /// buffer, and its subscriptions alive. A controller dies only on tab close,
  /// shell exit, or the registry's LRU eviction.
  final Map<EditorTab, TerminalSessionController> _terminalSessions = {};
  final Set<EditorTab> _creatingSessions = {};

  /// Live shell titles per terminal tab (OSC 0/2 from the PTY), keyed by tab
  /// identity like [_terminalSessions] and pruned alongside it. Feeds the
  /// chrome's `labelFor`; absent (or cleared on shell restart) falls back to
  /// the tab's own label.
  final Map<EditorTab, String> _terminalTitles = {};

  /// How many *hidden* webview tabs (code-server / browser) keep their live
  /// platform view mounted. Hidden webviews beyond the most-recently-visible
  /// cap are suspended ([EditorSuspendedPane]) and rebuilt fresh on reveal — the
  /// server-side code-server session survives, so the editor reattaches.
  /// Chat and terminal tabs are never evicted.
  static const int kMaxHiddenWebviews = 2;

  final EditorBodyHost _bodyHost = EditorBodyHost(
    isWebviewKind: MessagingTabKinds.isWebview,
    maxHiddenWebviews: kMaxHiddenWebviews,
  );

  // ── Sidebar geometry (ephemeral) ─────────────────────────────────────────
  double _sidebarWidth = 300;
  static const double _minSidebar = 200;
  static const double _maxSidebar = 560;

  /// Sidebar visibility (ephemeral). Toggled by the panel button (⌘B). The
  /// width is retained so re-showing restores the previous size.
  bool _sidebarVisible = true;

  /// Width of the divider's invisible pointer hit area, centered on the
  /// editor↔sidebar seam. Matches [CcResizable]'s default `dividerHitSize`.
  static const double _dividerHitSize = 8;

  // ── Persistence ──────────────────────────────────────────────────────────
  EditorLayoutPersistence? _persistence;
  String? _workspaceId;

  // ── Editor dirty state (unsaved-changes dot) ─────────────────────────────
  /// Per-file unsaved-changes state (shared with the PR workbench), fed by the
  /// bridge extension via [codeServerDirtyStateProvider]. Keys a code-server
  /// file tab to its dot and gates the Save/Don't-save close prompt. Ephemeral,
  /// cleared on conversation switch.
  final _dirty = EditorDirtyTracker();

  // ── Descendant-driven tab opens ───────────────────────────────────────────
  /// Published to the subtree via [EditorTabOpenerScope] so a widget rendered
  /// inside a tab body (a plan bubble in the conversation feed) can open its own
  /// tab here without a callback threaded through the whole feed. Built once —
  /// the closure reads `_layout` at call time, so it survives conversation
  /// switches (which swap the controller).
  late final EditorTabOpener _tabOpener = EditorTabOpener(_openTabFromScope);

  /// The pending run target already claimed by this build, if any — see
  /// [_consumePendingRun].
  String? _claimedPendingRunId;

  @override
  void initState() {
    super.initState();
    _sidebarTab = ValueNotifier<IdeSidebarView>(IdeSidebarView.general);
    _layout = _seedLayout(widget.selectedChannelId);
    _layout.addListener(_onLayoutChanged);
    _wireActions(widget.actions);
    _tabUrl = EditorTabUrlTracker(
      initialKey: widget.focusedTabKey,
      focusKey: (key) => focusEditorTabByKey(_layout, key),
      focusDefault: _focusDefaultTab,
      writeKey: _writeTabKey,
    );
    // Restore this conversation's persisted layout once the first frame (and
    // thus the provider reads in [build]) has run.
    final channelId = widget.selectedChannelId;
    if (channelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restorePersisted(channelId);
      });
    }
  }

  /// Wires the external command sink so keyboard shortcuts (⌘T/⌘W/⌘B) can drive
  /// IDE actions without reaching into this private state.
  void _wireActions(MessagingIdeActions actions) {
    actions
      ..openEditor = openEditor
      ..closeActiveTab = closeActiveTab
      ..toggleSidebar = toggleSidebar;
  }

  /// Detaches [actions] so a stale shortcut can't call into a torn-down (or
  /// replaced) state. Silently no-ops when the sink has already been re-wired to
  /// another state.
  void _unwireActions(MessagingIdeActions actions) {
    actions
      ..openEditor = null
      ..closeActiveTab = null
      ..toggleSidebar = null;
  }

  @override
  void dispose() {
    _unwireActions(widget.actions);
    // Flush the current conversation's layout synchronously before tearing down.
    _persistNow(widget.selectedChannelId);
    _persistence?.dispose();
    _sidebarTab.dispose();
    _layout.removeListener(_onLayoutChanged);
    _layout.dispose();
    super.dispose();
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
    if (oldWidget.selectedChannelId != widget.selectedChannelId) {
      _switchConversation(
        oldWidget.selectedChannelId,
        widget.selectedChannelId,
      );
    }
    if (oldWidget.focusedTabKey != widget.focusedTabKey) {
      // Back/forward or a deep-link changed `?tab=`: apply it a frame later —
      // focusing mutates the layout, which must not happen mid-build. A
      // simultaneous channel switch wins the race: its restore force-applies
      // the URL key against the NEW conversation's tab set afterwards.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabUrl.apply(_layout, widget.focusedTabKey);
        }
      });
    }
  }

  // ── URL tab sync (`?tab=`) ────────────────────────────────────────────────

  /// Two-way sync between the focused editor tab and the URL's `?tab=`
  /// param: a tab switch navigates (joining the back/forward stack and
  /// surviving a refresh), and back/forward or a deep-link re-focuses the
  /// named tab. The state machine lives in [EditorTabUrlTracker]; only the
  /// focus/write actions are messaging-specific.
  late final EditorTabUrlTracker _tabUrl;

  /// Navigates to the current location with `?tab=` set to [key], preserving
  /// every other query param (`?m=` permalinks).
  void _writeTabKey(String? key) {
    final uri = GoRouterState.of(context).uri;
    context.go(locationWithEditorTab(uri, key));
  }

  /// Back/forward to a tab-less location returns to the surface's initial
  /// state: the first tab of the active leaf (the seeded chat tab).
  void _focusDefaultTab() {
    final controller = _layout.activeLeaf.controller;
    if (!controller.isEmpty) {
      controller.selectedIndex = 0;
    }
  }

  // ── Layout lifecycle ──────────────────────────────────────────────────────

  /// Opens (or focuses) the conversation's code-server editor tab on its
  /// isolated worktree — the single place where files are created/saved. Driven
  /// by ⌘T and by double-clicking the tab-strip void. One code-server per
  /// conversation worktree, so a re-open refocuses the running instance rather
  /// than stacking a second tab.
  void openEditor() {
    final channelId = widget.selectedChannelId;
    if (channelId == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    _layout.focusOrOpenInLeaf(
      _layout.activeLeafId,
      (t) =>
          t.kind == MessagingTabKinds.codeServer &&
          t.args['channelId'] == channelId &&
          t.args['path'] == null,
      () => EditorTab(
        kind: MessagingTabKinds.codeServer,
        label: l10n.ideCodeServer,
        icon: MessagingTabKinds.iconFor(MessagingTabKinds.codeServer),
        args: {'channelId': channelId},
      ),
    );
  }

  /// Opens (or refocuses) a tab requested from inside a tab body via
  /// [EditorTabOpenerScope].
  ///
  /// De-dupes across the WHOLE split tree rather than just the active leaf: a
  /// plan already open in a side pane should be brought forward there, not
  /// duplicated next to the chat. Deferred a frame because the caller is
  /// typically mid-gesture (a bubble button) or mid-build (an auto-open on a
  /// freshly-arrived plan), and mutating the tab tree inside either trips the
  /// same mouse-tracker / build assertions [_openTabNextFrame] guards against.
  void _openTabFromScope(EditorTab tab) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final key = tab.dedupKey;
      if (key != null && _layout.focusTab((t) => t.dedupKey == key)) {
        return;
      }
      _layout.openInActiveLeaf(tab);
    });
  }

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
  /// the tab-strip × (see [_confirmCloseTab]), then re-locates the tab by
  /// identity (the async prompt can shift the selection).
  Future<void> closeActiveTab() async {
    final leaf = _layout.activeLeaf;
    final controller = leaf.controller;
    if (controller.tabs.isEmpty) {
      return;
    }
    final tab = controller.tabs[controller.selectedIndex];
    if (!await _confirmCloseTab(tab)) {
      return;
    }
    final idx = controller.indexOfIdentity(tab);
    if (idx >= 0) {
      _layout.closeTab(leaf.id, idx);
    }
  }

  /// Reverts [target]'s files to HEAD server-side, then refreshes the Source
  /// Control panel. Surfaces untracked-skipped files via a toast.
  Future<void> _revertFiles(
    ({String repoId, List<String> paths}) target,
  ) async {
    final channelId = widget.selectedChannelId;
    final workspaceId = _workspaceId;
    if (channelId == null || workspaceId == null) {
      return;
    }
    final result = await revertWorktreeFiles(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      channelId: channelId,
      repoId: target.repoId,
      paths: target.paths,
    );
    if (!mounted) {
      return;
    }
    // Always refresh the changes list so the panel reflects the revert.
    ref.invalidate(
      repoChangesProvider((
        workspaceId: workspaceId,
        repoId: target.repoId,
        channelId: channelId,
      )),
    );
    final l10n = AppLocalizations.of(context);
    if (result == null) {
      _showToast(l10n.ideRevertConfirmTitle, l10n.ideRevertFailed);
    } else if (result.skipped.isNotEmpty) {
      _showToast(
        l10n.ideRevertConfirmTitle,
        l10n.ideRevertSomeSkipped(result.skipped.length),
      );
    }
  }

  void _showToast(String title, String body) {
    final handle = CcToastScope.maybeOf(context);
    if (handle != null) {
      handle.show('$title — $body', variant: CcToastVariant.neutral);
    }
  }

  /// Builds a chat tab for one conversation (stream) inside the channel.
  /// `dedupKey: 'chat:<conversationId>'` makes each conversation unique per
  /// group so re-opening it refocuses the existing tab instead of stacking,
  /// while distinct parentheses each get their own tab. [conversationId] null
  /// ⇒ the channel's `main` conversation (== channel id).
  EditorTab _chatTab(
    String channelId, {
    String? conversationId,
    String? title,
  }) {
    final convId = conversationId ?? channelId;
    return EditorTab(
      kind: MessagingTabKinds.chat,
      label: title ?? 'Chat',
      icon: MessagingTabKinds.iconFor(MessagingTabKinds.chat),
      args: {'channelId': channelId, 'conversationId': convId},
      dedupKey: 'chat:$convId',
    );
  }

  /// Opens the tapped agent run.
  ///
  /// A SUBAGENT run gets its own activity tab: its work never becomes chat
  /// messages, so the conversation cannot show it. A top-level run's activity IS
  /// the conversation (bubbles, composer, steering, follow-mode), so that just
  /// brings the chat forward — reachable the other way via the row's context
  /// menu when the raw timeline is what you want.
  void _openAgentRun(AgentRunTarget target) {
    if (target.isSubAgent) {
      _openAgentActivity(target);
      return;
    }
    final channelId = widget.selectedChannelId;
    if (channelId == null) {
      return;
    }
    // Focus, never re-open: `openTab`'s dedupe REPLACES the tab instance, which
    // would tear down the live chat body.
    if (!_layout.focusTab((t) => t.kind == MessagingTabKinds.chat)) {
      _layout.openInActiveLeaf(_chatTab(channelId));
    }
  }

  /// Claims a run target parked by a surface that cannot open a tab itself (the
  /// global sidebar's channel flyout, which navigates here and leaves the run in
  /// [pendingAgentRunProvider]).
  ///
  /// Claimed synchronously into [_claimedPendingRunId] so a rebuild before the
  /// post-frame callback cannot re-trigger it; the provider itself can only be
  /// cleared off-frame, because this runs from [build] and writing to a provider
  /// during a build throws.
  void _consumePendingRun(PendingAgentRun? pending) {
    if (pending == null ||
        pending.channelId != widget.selectedChannelId ||
        _claimedPendingRunId == pending.runId) {
      return;
    }
    _claimedPendingRunId = pending.runId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(pendingAgentRunProvider)?.runId == pending.runId) {
        ref.read(pendingAgentRunProvider.notifier).set(null);
      }
      // Releasing the claim lets the same run be opened again later instead of
      // being swallowed.
      _claimedPendingRunId = null;
      _openAgentRun((
        agentId: pending.agentId,
        runId: pending.runId,
        label: pending.label,
        isSubAgent: pending.isSubAgent,
      ));
    });
  }

  /// Opens (or refocuses) a run-scoped activity tab.
  ///
  /// `focusTab` first for the same reason as above: a harmless re-tap must not
  /// drop the pane's live subscription and scroll position.
  void _openAgentActivity(AgentRunTarget target) {
    final channelId = widget.selectedChannelId;
    final workspaceId = _workspaceId;
    if (channelId == null || workspaceId == null) {
      return;
    }
    final found = _layout.focusTab(
      (t) =>
          t.kind == MessagingTabKinds.agentActivity &&
          t.args['runId'] == target.runId,
    );
    if (found) {
      return;
    }
    _layout.openInActiveLeaf(
      agentActivityTab(
        workspaceId: workspaceId,
        channelId: channelId,
        runId: target.runId,
        agentId: target.agentId,
        label: target.label,
        fallbackLabel: AppLocalizations.of(context).ideAgentActivity,
      ),
    );
  }

  /// Opens/focuses a conversation's chat tab (the switcher's `onSelect`).
  void _openConversation(String channelId, String conversationId) {
    final found = _layout.focusTab(
      (t) =>
          t.kind == MessagingTabKinds.chat &&
          t.args['conversationId'] == conversationId,
    );
    if (!found) {
      _layout.openInActiveLeaf(
        _chatTab(channelId, conversationId: conversationId),
      );
    }
  }
  /// Seeds a fresh single-leaf layout with the default tabs: Chat (when a
  /// conversation is open), Terminal, Browser.
  EditorLayoutController _seedLayout(String? channelId) {
    final controller = EditorTabGroupController();
    if (channelId != null) {
      controller.openTab(_chatTab(channelId));
    }
    controller.openTab(
      EditorTab(
        kind: MessagingTabKinds.terminal,
        label: 'Terminal',
        icon: MessagingTabKinds.iconFor(MessagingTabKinds.terminal),
        // Stable id so the tab re-claims its kept session from the registry
        // after a channel switch (the arg round-trips through the persisted
        // layout snapshot).
        args: {
          'termSessionId':
              'ide-terminal-${DateTime.now().microsecondsSinceEpoch}',
        },
      ),
    );
    controller.openTab(
      EditorTab(
        kind: MessagingTabKinds.browser,
        label: 'Browser',
        icon: MessagingTabKinds.iconFor(MessagingTabKinds.browser),
      ),
    );
    controller.selectedIndex = 0;
    return EditorLayoutController.single(controller: controller);
  }

  /// Builds a fresh terminal tab.
  EditorTab _newTerminalTab() => EditorTab(
    kind: MessagingTabKinds.terminal,
    label: 'Terminal',
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.terminal),
    // Stable id for the keep-alive registry claim (see _seedLayout).
    args: {
      'termSessionId': 'ide-terminal-${DateTime.now().microsecondsSinceEpoch}',
    },
  );

  /// Swaps the active [EditorLayoutController], disposing the old one and
  /// reconciling the body host against the new tree.
  void _setLayout(EditorLayoutController next) {
    _layout.removeListener(_onLayoutChanged);
    _layout.dispose();
    _layout = next;
    _layout.addListener(_onLayoutChanged);
    _reconcileBodyHost();
  }

  /// Persists the outgoing conversation, then loads (or seeds) the incoming
  /// one. Also sweeps cross-conversation session state: the outgoing channel's
  /// terminals mirror is emptied (its sessions SURVIVE the swap in the
  /// keep-alive registry — only the sidebar mirror is channel-scoped) and
  /// the global thread selection is reset so a thread open in the outgoing
  /// conversation can't leak into the incoming one's pane.
  void _switchConversation(String? from, String? to) {
    _persistNow(from);
    // Dirty state is keyed by (repoId, path) without a channel; drop it so the
    // incoming conversation can't inherit the outgoing one's unsaved dots.
    _dirty.clear();
    setState(() => _setLayout(_seedLayout(to)));
    // This runs from didUpdateWidget (mid-build), and Riverpod 3 forbids
    // modifying a provider during a build pass ("modified a provider while the
    // widget tree was building"). The outgoing conversation's terminals mirror
    // is cleanup, so defer it a frame — the same discipline the restore below
    // (and the rest of this layout) already uses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (from != null) {
        ref.read(channelTerminalsProvider(from).notifier).set(const <TerminalMirror>[]);
      }
    });
    if (to != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restorePersisted(to),
      );
    } else {
      // No restore will run for the empty surface: re-track the seed's focus
      // against the URL tracker immediately (same drift the restore's
      // force-apply resyncs when a conversation IS incoming).
      _tabUrl.resync(_layout);
    }
  }

  Future<void> _restorePersisted(String channelId) async {
    final persistence = _persistence;
    final workspaceId = _workspaceId;
    if (persistence == null || workspaceId == null) {
      return;
    }
    final restored = await persistence.restore(
      workspaceId: workspaceId,
      cacheKey: channelId,
    );
    // Bail if the conversation changed (or we unmounted) while reading.
    if (!mounted || widget.selectedChannelId != channelId) {
      return;
    }
    // A missing/unrestorable payload keeps the seeded layout; either way the
    // URL's `?tab=` gets the final say on which tab is focused.
    if (restored != null) {
      setState(() => _setLayout(restored));
    }
    _tabUrl.apply(_layout, widget.focusedTabKey, force: true);
  }

  void _onLayoutChanged() {
    if (!mounted) {
      return;
    }
    // A tab leaving the tree from a live-layout change is a USER close (or a
    // drag to another leaf — which keeps the tab live): kill closed shells.
    _reconcileBodyHost(killOrphanedTerminals: true);
    setState(() {});
    _schedulePersist();
    _tabUrl.writeFromLayout(_layout);
  }

  /// Drops body-host entries for tabs no longer anywhere in the tree. The
  /// shared host prunes its keep-alive/visited/LRU state; the feature-specific
  /// terminal maps are pruned against the same live set.
  ///
  /// [killOrphanedTerminals] distinguishes WHY a tab left the tree: `true`
  /// (layout change within the live layout — the user closed the tab) kills
  /// the shell via the registry; `false` (a seed/switch/restore layout swap)
  /// detaches the view callbacks and KEEPS the session alive in the registry
  /// so switching back re-claims it with scrollback intact.
  void _reconcileBodyHost({bool killOrphanedTerminals = false}) {
    final live = Set<EditorTab>.identity()..addAll(_layout.allTabs());
    _bodyHost.reconcile(live);
    final registry = ref.read(terminalRegistryProvider.notifier);
    _terminalSessions.removeWhere((tab, controller) {
      if (live.contains(tab)) {
        return false;
      }
      if (killOrphanedTerminals) {
        // The user closed the tab: the shell dies.
        registry.kill(controller.session.sessionId);
      } else {
        // A channel switch swapped the layout out from under the tab: keep the
        // session alive, detached. A shell that exits while its channel is
        // hidden is killed (there is no tab to close).
        controller.onTitleChange = null;
        controller.onShellExit = () {
          ref
              .read(terminalRegistryProvider.notifier)
              .kill(controller.session.sessionId);
        };
      }
      return true;
    });
    _terminalTitles.removeWhere((tab, _) => !live.contains(tab));
    _creatingSessions.removeWhere((tab) => !live.contains(tab));
    _publishTerminals();
  }

  /// Mirrors the live terminal sessions into [channelTerminalsProvider] so the
  /// General pane's TERMINALS section can list them (the map stays the source
  /// of truth; this is a read mirror). Also feeds the registry's
  /// eviction-protected claim set.
  void _publishTerminals() {
    final channelId = widget.selectedChannelId;
    if (channelId == null) {
      return;
    }
    final sessions = _terminalSessions.values
        .where((c) => c.session.channelId == channelId)
        .map((c) => TerminalMirror(session: c.session, title: c.title))
        .toList();
    // Deferred so it never fires mid-build (the provider is written from build
    // callbacks like _buildTerminalPane's post-frame setState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(channelTerminalsProvider(channelId).notifier).set(sessions);
      ref
          .read(terminalRegistryProvider.notifier)
          .syncClaims(
            _terminalSessions.values.map((c) => c.session.sessionId).toSet(),
          );
    });
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  void _schedulePersist() {
    final channelId = widget.selectedChannelId;
    final workspaceId = _workspaceId;
    final persistence = _persistence;
    if (channelId == null || workspaceId == null || persistence == null) {
      return;
    }
    persistence.schedule(
      workspaceId: workspaceId,
      cacheKey: channelId,
      layout: _layout,
    );
  }

  void _persistNow(String? channelId) {
    final workspaceId = _workspaceId;
    final persistence = _persistence;
    if (channelId == null || workspaceId == null || persistence == null) {
      return;
    }
    persistence.flushNow(
      workspaceId: workspaceId,
      cacheKey: channelId,
      layout: _layout,
    );
  }

  // ── Body host (keep-alive build) ───────────────────────────────────────────

  Widget _buildBody(
    EditorTab tab,
    bool isVisible, {
    required AppLocalizations l10n,
    required String? workspaceId,
  }) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Keep-alive, lazy build, TickerMode and webview suspension all live in the
    // shared [EditorBodyHost]; the body/suspended widgets stay messaging's.
    return _bodyHost.wrap(
      tab,
      isVisible: isVisible,
      background: t.bgPrimary,
      buildContent: () =>
          _buildTabContent(tab, l10n: l10n, workspaceId: workspaceId),
      buildSuspended: () => EditorSuspendedPane(
        icon: tab.kind == MessagingTabKinds.codeServer
            ? AppIcons.code
            : AppIcons.globe,
      ),
    );
  }

  Widget _buildTabContent(
    EditorTab tab, {
    required AppLocalizations l10n,
    required String? workspaceId,
  }) {
    switch (tab.kind) {
      case MessagingTabKinds.chat:
        final channelId = tab.args['channelId'] as String;
        final conversationId = tab.args['conversationId'] as String?;
        final pane = ConversationPane(
          channelId: channelId,
          conversationId: conversationId,
          onSelectConversation: (convId) =>
              _openConversation(channelId, convId),
        );
        if (workspaceId == null) {
          return pane;
        }
        // Lets the `task` cell in an agent turn open the subagent it spawned —
        // the transcript renderers take no callbacks, so the opener rides an
        // InheritedWidget instead.
        return RunActivityOpenerScope(
          workspaceId: workspaceId,
          channelId: channelId,
          openRun: ({required runId, required label}) => _openAgentActivity((
            agentId: '',
            runId: runId,
            label: label,
            isSubAgent: true,
          )),
          child: pane,
        );
      case MessagingTabKinds.terminal:
        return _buildTerminalPane(tab);
      case MessagingTabKinds.browser:
        return BrowserPane(initialUrl: tab.args['url'] as String?);
      case MessagingTabKinds.codeServer:
        final channelId = tab.args['channelId'] as String;
        final repoId = tab.args['repoId'] as String?;
        final path = tab.args['path'] as String?;
        return CodeServerPane(channelId: channelId, repoId: repoId, path: path);
      case MessagingTabKinds.file:
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
      case MessagingTabKinds.fileDiff:
        final prFile = tab.args['prFile'] as PrFile;
        // PrDiffView builds a sliver (it's designed to live inside the PR
        // detail screen's CustomScrollView). As a standalone tab body it must be
        // hosted in a viewport, else it's fed to the tab host's ColoredBox (a
        // RenderBox) and crashes ("expected a RenderBox but received a
        // RenderSliverMainAxisGroup").
        return CustomScrollView(
          slivers: [
            PrDiffView(files: [prFile], comments: const []),
          ],
        );
      case MessagingTabKinds.review:
        final repoId = tab.args['repoId'] as String;
        final anchorPath = tab.args['anchorPath'] as String? ?? '';
        if (workspaceId == null) {
          return const SizedBox.shrink();
        }
        return ReviewCodePane(
          workspaceId: workspaceId,
          repoId: repoId,
          anchorPath: anchorPath,
          channelId: tab.args['channelId'] as String?,
        );
      case MessagingTabKinds.plan:
        final planId = tab.args['planId'] as String?;
        if (workspaceId == null || planId == null) {
          return const SizedBox.shrink();
        }
        // Plan Studio hosted as a tab: the tab strip already names it, so the
        // page header is suppressed.
        return PlanStudioScreen(
          workspaceId: workspaceId,
          kind: tab.args['planKind'] as String? ?? 'document',
          id: planId,
          showPageHeader: false,
        );
      case MessagingTabKinds.artifact:
        final tabWorkspaceId = tab.args['workspaceId'] as String?;
        final workProductId = tab.args['workProductId'] as String?;
        // Workspace isolation: a restored layout must never render another
        // tenant's artifact. The layout cache is workspace-scoped so this should
        // be unreachable — deny visibly rather than render.
        if (workProductId == null ||
            workspaceId == null ||
            workspaceId != tabWorkspaceId) {
          return const SizedBox.shrink();
        }
        return ArtifactDetailView(workProductId: workProductId);
      case MessagingTabKinds.agentActivity:
        final tabWorkspaceId = tab.args['workspaceId'] as String?;
        final tabChannelId = tab.args['channelId'] as String?;
        final runId = tab.args['runId'] as String?;
        // Workspace isolation: a restored layout must never render another
        // tenant's run. The layout cache is workspace-scoped so this should be
        // unreachable — deny visibly rather than render.
        if (tabWorkspaceId == null ||
            tabChannelId == null ||
            runId == null ||
            workspaceId == null ||
            workspaceId != tabWorkspaceId) {
          return const AgentActivityPane.unavailable();
        }
        return AgentActivityPane(
          workspaceId: tabWorkspaceId,
          channelId: tabChannelId,
          runId: runId,
          agentId: tab.args['agentId'] as String? ?? '',
          fallbackLabel: tab.args['label'] as String?,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTerminalPane(EditorTab tab) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final claimed = _terminalSessions[tab];
    if (claimed != null) {
      return TerminalSessionView(
        controller: claimed,
        backgroundColor: t.bgPrimary,
      );
    }
    if (_creatingSessions.add(tab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        // The tab carries its session id in args (minted at tab creation and
        // round-tripped through the persisted layout), so a tab restored
        // after a channel switch re-claims its kept session — shell, buffer
        // and subscriptions intact. Legacy snapshots without the arg mint a
        // fresh id (a blank shell, today's behaviour).
        final sessionId =
            tab.args['termSessionId'] as String? ??
            'ide-terminal-${DateTime.now().microsecondsSinceEpoch}';
        // The terminal opens at the conversation root
        // (`conversations/<channelId>`), resolved from the channel id by the
        // view/server (web-safe). The `sessionId` stays unique per tab so
        // each terminal gets its own sandbox session.
        final session = TerminalSession(
          sessionId: sessionId,
          channelId: widget.selectedChannelId ?? '',
          workspaceId: ref.read(activeWorkspaceIdProvider) ?? '',
        );
        final registry = ref.read(terminalRegistryProvider.notifier);
        final controller = registry.obtain(session);
        // The tab may have been closed while the claim was deferred.
        if (_layout.leafIdContaining(tab) == null) {
          registry.kill(session.sessionId);
          _creatingSessions.remove(tab);
          return;
        }
        controller.onTitleChange = (title) => _setTerminalTitle(tab, title);
        controller.onShellExit = () => _onTerminalShellExit(session.sessionId);
        setState(() {
          _terminalSessions[tab] = controller;
          _creatingSessions.remove(tab);
        });
        // Restore the label for a re-claimed kept session.
        _setTerminalTitle(tab, controller.title);
        _publishTerminals();
      });
    }
    return const Center(child: CcSpinner());
  }

  /// A claimed tab's shell exited: close the tab (post-frame; the callback
  /// fires mid-stream-delivery). When the session id is claimed by no tab —
  /// the channel is inactive and the shell exited while hidden — kill it in
  /// the registry instead (there is no tab to close).
  void _onTerminalShellExit(String sessionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final entry in _terminalSessions.entries) {
        if (entry.value.session.sessionId == sessionId) {
          _layout.closeTabByIdentity(entry.key);
          return;
        }
      }
      ref.read(terminalRegistryProvider.notifier).kill(sessionId);
    });
  }

  void _setTerminalTitle(EditorTab tab, String title) {
    if (!mounted) {
      return;
    }
    final next = title.trim();
    final prev = _terminalTitles[tab];
    if (next.isEmpty ? prev == null : prev == next) {
      return;
    }
    setState(() {
      if (next.isEmpty) {
        _terminalTitles.remove(tab);
      } else {
        _terminalTitles[tab] = next;
      }
    });
    // The sidebar TERMINALS mirror carries the live title too — republish so a
    // `claude` / `pnpm dev` retitling shows there as well as in the tab strip.
    _publishTerminals();
  }

  /// The display label for a terminal tab. A CLAIMED tab reads the reactive
  /// per-tab map (fed by title events); an UNCLAIMED tab — a restored layout
  /// whose body hasn't built yet — falls back to the kept controller's last
  /// title in the registry, so the custom name survives navigation even before
  /// the tab is opened again.
  String _terminalLabel(EditorTab tab, AppLocalizations l10n) {
    final live = _terminalTitles[tab];
    if (live != null) {
      return live;
    }
    final sessionId = tab.args['termSessionId'] as String?;
    final kept = sessionId == null
        ? null
        : ref.read(terminalRegistryProvider).controllers[sessionId]?.title;
    // A constant default (NOT tab.label): a persisted snapshot from before
    // the label fix would otherwise leak a stale "New terminal" forever.
    return (kept == null || kept.isEmpty) ? l10n.terminal : kept;
  }


  @override
  Widget build(BuildContext context) {
    // The layout cache is a stable workspace-scoped provider; build the
    // persistence helper once (the cache repo never changes over the state's
    // life). Keyed by channel id under the messaging layout cache kind.
    _persistence ??= EditorLayoutPersistence(
      codec: messagingLayoutCodec,
      cache: ref.read(editorLayoutCacheRepositoryProvider),
      cacheKind: editorLayoutCacheKind,
    );
    _workspaceId = ref.watch(activeWorkspaceIdProvider);
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final channelId = widget.selectedChannelId;

    // A run target parked by the sidebar's channel flyout before it navigated
    // here. Watched (not listened) because the value is usually set BEFORE this
    // layout mounts, so there is no transition for a listener to catch.
    _consumePendingRun(ref.watch(pendingAgentRunProvider));

    // In-editor navigation → app tab: the embedded editor's bridge extension
    // reports a file the user navigated to (cmd-click "go to definition", an
    // Explorer open, …). Open it as its OWN app tab in the active leaf, leaving
    // the source tab pinned on its file. Errors (a server without code-server)
    // are ignored. Scoped to the open conversation.
    if (channelId != null) {
      ref.listen<AsyncValue<CodeServerOpenEvent>>(
        codeServerOpenRequestsProvider(channelId),
        (previous, next) {
          final evt = next.asData?.value;
          if (evt == null || evt.path.isEmpty) {
            return;
          }
          final fileName = evt.path.split('/').last;
          _layout.openInActiveLeaf(
            EditorTab(
              kind: MessagingTabKinds.codeServer,
              label: fileName.isEmpty ? l10n.ideCodeServer : fileName,
              icon: MessagingTabKinds.iconFor(MessagingTabKinds.codeServer),
              args: {
                'channelId': channelId,
                if (evt.repoId.isNotEmpty) 'repoId': evt.repoId,
                'path': evt.path,
              },
            ),
          );
        },
      );

      // Unsaved-changes reporting → per-tab dirty dot. The bridge extension
      // reports each file's dirty↔clean transition; key it to `(repoId, path)`
      // and rebuild so the matching code-server tab shows/hides its dot. Errors
      // (a server without code-server) are ignored.
      ref.listen<AsyncValue<CodeServerDirtyEvent>>(
        codeServerDirtyStateProvider(channelId),
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
      // on this channel's worktree the same way ⌘T / a file open would.
      ref.listen<int>(openCodeServerTabRequestProvider(channelId), (
        previous,
        next,
      ) {
        if (previous != null && next != previous) {
          openEditor();
        }
      });
    }

    // Wrapped in the opener scope so widgets inside a tab body (the plan bubble
    // in the conversation feed) can open their own tabs here.
    final Widget body = Stack(
      // Fill the parent (the shell body) so the pane row and the overlaid
      // divider both span the full surface, as the top-level Row did before.
      fit: StackFit.expand,
      children: [
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
                buildBody: (tab, {required isVisible}) => _buildBody(
                  tab,
                  isVisible,
                  l10n: l10n,
                  workspaceId: _workspaceId,
                ),
              ),
            ),
            if (_sidebarVisible)
              SizedBox(
                width: _sidebarWidth,
                child: IdeSidebar(
                  tabNotifier: _sidebarTab,
                  workspaceId: widget.workspaceId,
                  channelId: widget.selectedChannelId,
                  onOpenFile: (target) {
                    // The editor is the default open action: open (or refocus) a
                    // code-server tab for the clicked file. Each distinct file gets
                    // its own tab — clicking a new file opens a new tab; clicking a
                    // file that's already open refocuses it (dedup by path).
                    final channelId = widget.selectedChannelId;
                    if (channelId == null) {
                      return;
                    }
                    final fileName = target.path.split('/').last;
                    _layout.focusOrOpenInLeaf(
                      _layout.activeLeafId,
                      (t) =>
                          t.kind == MessagingTabKinds.codeServer &&
                          t.args['channelId'] == channelId &&
                          t.args['path'] == target.path,
                      () => EditorTab(
                        kind: MessagingTabKinds.codeServer,
                        // Name the tab after the file the editor was opened with
                        // (the entry file); falls back to the generic label when
                        // there's no path.
                        label: fileName.isEmpty ? l10n.ideCodeServer : fileName,
                        icon: MessagingTabKinds.iconFor(
                          MessagingTabKinds.codeServer,
                        ),
                        args: {
                          'channelId': channelId,
                          'repoId': target.repoId,
                          'path': target.path,
                        },
                      ),
                    );
                  },
                  onQuickViewFile: (target) {
                    // Lightweight read-only fallback (the old default) — available as
                    // an explicit "Quick view" so plain-text browsing still works.
                    _layout.openInActiveLeaf(
                      EditorTab(
                        kind: MessagingTabKinds.file,
                        label: target.path.split('/').last,
                        icon: MessagingTabKinds.iconFor(MessagingTabKinds.file),
                        args: {'repoId': target.repoId, 'path': target.path},
                      ),
                    );
                  },
                  onOpenReview: (target) {
                    final channelId = widget.selectedChannelId;
                    // Open (or refocus) a multi-file "Review code" tab for the
                    // repo, anchored to the clicked file. `dedupKey` keeps one
                    // review tab per (channelId, repoId), so re-clicking another
                    // file in the same repo re-anchors it.
                    _layout.openInActiveLeaf(
                      EditorTab(
                        kind: MessagingTabKinds.review,
                        label: l10n.ideReviewCode,
                        icon: MessagingTabKinds.iconFor(
                          MessagingTabKinds.review,
                        ),
                        dedupKey: 'review:${channelId ?? ''}:${target.repoId}',
                        args: {
                          'channelId': ?channelId,
                          'repoId': target.repoId,
                          'anchorPath': target.file.filename,
                        },
                      ),
                    );
                  },
                  onViewSource: (target) {
                    // Open (or refocus) a code-server tab for the file. Same path
                    // the Explorer file-click uses (dedup by path).
                    final channelId = widget.selectedChannelId;
                    if (channelId == null) {
                      return;
                    }
                    _layout.focusOrOpenInLeaf(
                      _layout.activeLeafId,
                      (t) =>
                          t.kind == MessagingTabKinds.codeServer &&
                          t.args['channelId'] == channelId &&
                          t.args['path'] == target.path,
                      () => EditorTab(
                        kind: MessagingTabKinds.codeServer,
                        label: target.path.split('/').last.isEmpty
                            ? l10n.ideCodeServer
                            : target.path.split('/').last,
                        icon: MessagingTabKinds.iconFor(
                          MessagingTabKinds.codeServer,
                        ),
                        args: {
                          'channelId': channelId,
                          'repoId': target.repoId,
                          'path': target.path,
                        },
                      ),
                    );
                  },
                  onRevertFiles: _revertFiles,
                  onOpenAgentRun: _openAgentRun,
                  // Focusing a terminal selects (or opens) one in the active leaf.
                  onFocusTerminal: (_) => _layout.focusOrOpenInLeaf(
                    _layout.activeLeafId,
                    (t) => t.kind == MessagingTabKinds.terminal,
                    _newTerminalTab,
                  ),
                ),
              ),
          ],
        ),
        // The draggable hairline is overlaid on the editor↔sidebar seam and
        // centered on it, so it consumes no layout width and leaves no gap on
        // either side (the panes meet flush behind it). With the sidebar's own
        // left border removed, this single line is the sole boundary — no
        // doubled edge. Mirrors CcResizable's divider treatment. Hidden when the
        // sidebar is toggled off.
        if (_sidebarVisible)
          Positioned(
            top: 0,
            bottom: 0,
            right: _sidebarWidth - _dividerHitSize / 2,
            width: _dividerHitSize,
            child: _SidebarDivider(
              hitSize: _dividerHitSize,
              color: t.lineStrong,
              activeColor: t.fgBrandPrimary,
              onDrag: (delta) {
                setState(() {
                  _sidebarWidth = (_sidebarWidth - delta).clamp(
                    _minSidebar,
                    _maxSidebar,
                  );
                });
              },
            ),
          ),
      ],
    );

    return EditorTabOpenerScope(opener: _tabOpener, child: body);
  }

  /// The messaging chrome injected into the shared editor: kind icons, the
  /// `[+]` new-tab menu (terminal / browser / open chat), the untitled-draft
  /// action, and the sidebar toggle.
  /// Whether [tab] is a code-server file tab with unsaved changes (drives the
  /// tab strip's dot). Non-file surfaces (chat/terminal/browser, the ⌘T full
  /// editor with no path) are never dirty.
  ///
  /// Keyed by worktree-relative PATH alone: the dirty subscription is already
  /// scoped to this conversation and the tracker is cleared on conversation
  /// switch, and the report's repo id can differ from the tab's (a `⌘T` session
  /// resolves an empty repo id server-side). Two repos in one channel sharing a
  /// relative path is rare and only mis-dots a sibling.
  bool _tabDirty(EditorTab tab) =>
      tab.kind == MessagingTabKinds.codeServer &&
      _dirty.isDirty(tab.args['path'] as String?);

  /// Close interceptor for a code-server tab: clean tabs close immediately; a
  /// dirty one runs the shared Save / Don't save / Cancel prompt, saving via the
  /// embedded editor (the buffer's only holder) on Save.
  Future<bool> _confirmCloseTab(EditorTab tab) {
    if (!_tabDirty(tab)) {
      return Future.value(true);
    }
    final path = tab.args['path'] as String? ?? '';
    return confirmCloseDirtyEditorTab(
      context: context,
      isDirty: true,
      fileName: path.isEmpty ? tab.label : path.split('/').last,
      onSave: () async {
        final channelId = tab.args['channelId'] as String?;
        if (channelId != null && path.isNotEmpty) {
          await saveCodeServerFile(
            ref.read(rpcClientProvider),
            channelId: channelId,
            repoId: tab.args['repoId'] as String?,
            path: path,
          );
        }
      },
    );
  }

  /// Context-menu extras per tab kind: a terminal tab gets "Restart shell";
  /// a code-server (file) tab gets Copy path / Copy relative path. Chat and
  /// browser tabs carry no extras.
  List<CcMenuItem> _tabContextExtras(EditorTab tab) {
    if (tab.kind == MessagingTabKinds.terminal) {
      final l10n = AppLocalizations.of(context);
      final controller = _terminalSessions[tab];
      return [
        CcMenuItem(
          label: l10n.restartShell,
          enabled: controller != null && !controller.booting,
          onSelected: () => unawaited(controller?.restart()),
        ),
      ];
    }
    final relative = tab.args['path'] as String?;
    if (relative == null || relative.isEmpty) {
      return const [];
    }
    final l10n = AppLocalizations.of(context);
    return [
      CcMenuItem(
        label: l10n.copyPath,
        onSelected: () => _copyAbsolutePath(tab, relative),
      ),
      CcMenuItem(
        label: l10n.copyRelativePath,
        onSelected: () => _copyToClipboard(relative),
      ),
    ];
  }

  /// Copies the file's absolute on-disk path — the isolated copy-on-write
  /// worktree the workbench actually edits when the tab is backed by a channel
  /// worktree, else the repo's main working tree.
  Future<void> _copyAbsolutePath(EditorTab tab, String relative) async {
    final worktree = await _worktreeBaseFor(tab);
    if (!mounted) {
      return;
    }
    final base = worktree ?? _mainRepoPath(tab);
    final absolute = base == null
        ? relative
        : (base.endsWith('/') ? '$base$relative' : '$base/$relative');
    _copyToClipboard(absolute);
  }

  /// The isolated worktree root for [tab]'s `(channel, repo)` on the server, or
  /// null when the tab isn't backed by a channel worktree (e.g. a read-only
  /// main-repo file view, which carries no channel id).
  Future<String?> _worktreeBaseFor(EditorTab tab) async {
    final repoId = tab.args['repoId'] as String?;
    final channelId = tab.args['channelId'] as String?;
    if (repoId == null || channelId == null) {
      return null;
    }
    final isolated = await ref
        .read(isolatedRepoRepositoryProvider)
        .forUnitRepo(widget.workspaceId, channelId, repoId);
    return isolated?.path;
  }

  /// The repo's main working-tree path for [tab] — the fallback when there is no
  /// isolated worktree (or the repo can't be resolved).
  String? _mainRepoPath(EditorTab tab) {
    final repoId = tab.args['repoId'] as String?;
    if (repoId == null) {
      return null;
    }
    final repos =
        ref.read(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const [];
    for (final repo in repos) {
      if (repo.id == repoId) {
        return repo.path;
      }
    }
    return null;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      CcToastScope.of(context).show(
        AppLocalizations.of(context).copied,
        variant: CcToastVariant.success,
      );
    }
  }

  /// Opens [tab] in [leafId] on the NEXT frame. The `[+]` menu invokes its
  /// `onSelected` synchronously while its overlay is still dismissing (a live
  /// pointer/mouse-tracker phase); mounting the new tab's platform view
  /// (browser/terminal/editor webview) right then mutates the MouseRegion /
  /// PlatformView tree mid device-update and trips
  /// `mouse_tracker.dart: '!_debugDuringDeviceUpdate'`. Deferring one frame lets
  /// the overlay finish tearing down first. Imperceptible (~1 frame).
  void _openTabNextFrame(String leafId, EditorTab tab) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _layout.setActiveLeaf(leafId);
      _layout.openInActiveLeaf(tab);
    });
  }

  EditorChrome _chrome(AppLocalizations l10n) => EditorChrome(
    iconFor: (tab) => MessagingTabKinds.iconFor(tab.kind),
    // A terminal with a live title — an OSC 0/2 the shell set, or the
    // server-polled foreground process ("pnpm dev serve") — shows that
    // instead of its default label: wezterm/ghostty/iTerm tab behaviour. The
    // live label also falls back to the kept controller's title for a
    // restored-but-unopened tab (see _terminalLabel).
    labelFor: (tab) => tab.kind == MessagingTabKinds.terminal
        ? _terminalLabel(tab, l10n)
        : tab.label,
    dirtyFor: _tabDirty,
    confirmClose: _confirmCloseTab,
    tabContextMenuExtras: _tabContextExtras,
    onUntitledDraft: openEditor,
    onToggleSidebar: toggleSidebar,
    sidebarVisible: _sidebarVisible,
    newTabMenuItems: (leafId) => [
      CcMenuItem(
        label: l10n.ideNewTerminal,
        icon: AppIcons.terminal,
        onSelected: () => _openTabNextFrame(leafId, _newTerminalTab()),
      ),
      CcMenuItem(
        label: _browserLabel(l10n),
        icon: AppIcons.globe,
        onSelected: () => _openTabNextFrame(
          leafId,
          EditorTab(
            kind: MessagingTabKinds.browser,
            label: _browserLabel(l10n),
            icon: MessagingTabKinds.iconFor(MessagingTabKinds.browser),
          ),
        ),
      ),
      CcMenuItem(
        label: l10n.ideOpenChat,
        icon: AppIcons.messageSquareText,
        enabled: widget.selectedChannelId != null,
        onSelected: () {
          final channelId = widget.selectedChannelId;
          if (channelId == null) {
            return;
          }
          _openTabNextFrame(leafId, _chatTab(channelId));
        },
      ),
    ],
  );
}

/// Name for a browser tab + its menu entry. Desktop has a real in-app webview
/// ("Web browser"); web only has a plain iframe ("Simple web browser").
String _browserLabel(AppLocalizations l10n) =>
    kIsWeb ? l10n.ideSimpleWebBrowser : l10n.ideWebBrowser;

/// A thin draggable handle between the editor area and the sidebar.
///
/// A hairline centered in a wider invisible hit area showing a column-resize
/// cursor; dragging reports the horizontal delta so the parent can resize the
/// sidebar. Intended to be overlaid (via [Positioned]) on the seam between the
/// two panes so it consumes no layout width and the hairline lands on the
/// boundary — matching [CcResizable]'s divider treatment.
///
/// The drag uses a [GestureDetector] horizontal-drag gesture (not a raw
/// [Listener]) and, while the gesture is live, pushes a full-IDE
/// [PointerInterceptor] into the root [Overlay]. This is the fix for the web
/// iframe pointer-steal: an `<iframe>` platform view swallows raw pointer events
/// the moment the cursor crosses into it, so the drag would die mid-resize. A
/// Flutter [AbsorbPointer] alone can't stop this — the iframe is a real DOM
/// element outside Flutter's hit-test tree, so the browser keeps routing events
/// to it regardless of what Flutter paints on top. [PointerInterceptor] drops a
/// transparent DOM element above every platform view, so pointer events keep
/// reaching Flutter and the already-captured drag recognizer keeps getting
/// `onHorizontalDragUpdate` no matter where the pointer travels. The overlay is
/// inserted on drag-start (while the pointer is still on the handle) so the
/// shield is already covering the iframe by the time the cursor reaches it.
class _SidebarDivider extends StatefulWidget {
  const _SidebarDivider({
    required this.color,
    required this.activeColor,
    required this.onDrag,
    this.hitSize = 8,
  });

  final Color color;
  final Color activeColor;
  final ValueChanged<double> onDrag;

  /// Width of the invisible pointer hit area centered on the seam.
  final double hitSize;

  @override
  State<_SidebarDivider> createState() => _SidebarDividerState();
}

class _SidebarDividerState extends State<_SidebarDivider> {
  bool _active = false;
  OverlayEntry? _dragOverlay;

  void _setActive(bool value) {
    if (_active != value) {
      setState(() => _active = value);
    }
  }

  /// Pushes a transparent full-screen [PointerInterceptor] over the IDE so the
  /// embedded iframe/code-server can't swallow pointer events during the drag.
  void _beginDragOverlay() {
    if (_dragOverlay != null) {
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    _dragOverlay = OverlayEntry(
      // PointerInterceptor drops a transparent DOM element above every web
      // platform view so the iframe below can't steal the drag's pointer
      // stream. The inner AbsorbPointer/MouseRegion covers desktop native
      // platform views (where PointerInterceptor is a passthrough) and keeps
      // the resize cursor showing across the whole surface while dragging.
      builder: (_) => Positioned.fill(
        child: PointerInterceptor(
          child: const MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            opaque: false,
            child: AbsorbPointer(),
          ),
        ),
      ),
    );
    overlay.insert(_dragOverlay!);
  }

  void _endDragOverlay() {
    _dragOverlay?.remove();
    _dragOverlay = null;
  }

  @override
  void dispose() {
    _endDragOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = AnimatedContainer(
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      width: _active ? 2 : 1,
      color: _active ? widget.activeColor : widget.color,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => _setActive(true),
      onExit: (_) => _setActive(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _setActive(true);
          _beginDragOverlay();
        },
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx != 0) {
            widget.onDrag(details.delta.dx);
          }
        },
        onHorizontalDragEnd: (_) {
          _setActive(false);
          _endDragOverlay();
        },
        onHorizontalDragCancel: () {
          _setActive(false);
          _endDragOverlay();
        },
        child: SizedBox(
          width: widget.hitSize,
          child: Center(
            child: SizedBox(height: double.infinity, child: line),
          ),
        ),
      ),
    );
  }
}
