import 'dart:async';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_detail_view.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/browser_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/code_server_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/conversation_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/editor_layout_snapshot.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/file_viewer_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/review_code_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/agent_run_target.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/create_untitled_conversation.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_changes_provider.dart';
import 'package:control_center/features/messaging/providers/space_browser_tabs_provider.dart';
import 'package:control_center/features/messaging/providers/space_takeover_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/features/observability/presentation/tool_render/run_activity_opener_scope.dart';
import 'package:control_center/features/plan_studio/presentation/screens/plan_studio_screen.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/rigs/presentation/browser_engine_logo.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_pane.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/sandboxing/presentation/enclosed_terminal_start.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/features/sandboxing/providers/terminal_registry_provider.dart';
import 'package:control_center/features/sandboxing/providers/terminal_sessions_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_dirty_support.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_live_close.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:control_center/shared/editor/host/editor_body_host.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:control_center/shared/editor/host/editor_layout_persistence.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart';
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
/// The layout is persisted **per conversation** (keyed by space id) in the
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
  /// [terminalRegistryProvider] and SURVIVE layout swaps (space switches):
  /// dropping a claim detaches the view callbacks but keeps the shell, its
  /// buffer and its subscriptions alive. A controller dies only on tab close,
  /// shell exit, or the registry's LRU eviction.
  final Map<EditorTab, TerminalSessionController> _terminalSessions = {};
  final Set<EditorTab> _creatingSessions = {};

  /// Terminal tabs whose shell the user chose to KEEP when closing them (the
  /// prompt only appears while a command is running). Read — and cleared — by
  /// the reconcile that follows the close, which then detaches the session
  /// instead of killing it. Keyed by tab identity like [_terminalSessions].
  final Set<EditorTab> _keptShells = Set<EditorTab>.identity();

  /// Restored enclosed-VM terminal tabs the user has since pressed Start on.
  ///
  /// Session-lived on purpose: the deferral is a property of the RESTORE, so
  /// the next launch must defer again rather than remember a press from
  /// yesterday. Keyed by tab identity like [_terminalSessions].
  final Set<EditorTab> _startedDeferred = {};

  /// Live shell titles per terminal tab (OSC 0/2 from the PTY), keyed by tab
  /// identity like [_terminalSessions] and pruned alongside it. Feeds the
  /// chrome's `labelFor`; absent (or cleared on shell restart) falls back to
  /// the tab's own label.
  final Map<EditorTab, String> _terminalTitles = {};

  /// Stable per-session ids for the open HOST browser tabs (the in-app
  /// webview kind), keyed by tab identity like [_terminalSessions] and pruned
  /// alongside it. The sidebar's BROWSERS rows address a tab through its id;
  /// minting the id here (rather than in the tab's args) keeps restored
  /// layouts — which never carried one — addressable too.
  final Map<EditorTab, String> _browserTabIds = {};
  int _browserTabIdSeq = 0;

  /// The open space's conversations by id, refreshed every build so a chat
  /// tab's header follows a rename (and a thread keeps its badge) without the
  /// tab having to be re-opened. Empty until the space's list arrives.
  Map<String, Conversation> _conversationsById = const {};

  /// The open space's standing conversation id, so the seeded chat tab — which
  /// deliberately carries no conversation arg — can still name what it shows.
  String? _standingConversationId;

  /// The space whose conversation set has been mirrored into chat tabs this
  /// open (see [_syncConversationTabs]); reset on space switch so re-opening
  /// a space re-opens its conversations.
  String? _conversationTabsSyncedFor;

  /// Whether the persisted-layout restore for the current space has settled
  /// (applied, or found nothing to apply). Conversation tabs are only
  /// injected AFTER it: a restore replaces the whole tab tree, so tabs added
  /// into the seed beforehand would be silently dropped.
  bool _layoutRestored = false;

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
    _layout = _seedLayout(widget.selectedSpaceId);
    _layout.addListener(_onLayoutChanged);
    _wireActions(widget.actions);
    _tabUrl = EditorTabUrlTracker(
      initialKey: widget.focusedTabKey,
      focusKey: _focusTabByKey,
      focusDefault: _focusDefaultTab,
      writeKey: _writeTabKey,
    );
    // Restore this conversation's persisted layout once the first frame (and
    // thus the provider reads in [build]) has run.
    final spaceId = widget.selectedSpaceId;
    if (spaceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restorePersisted(spaceId);
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
    _persistNow(widget.selectedSpaceId);
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
    if (oldWidget.selectedSpaceId != widget.selectedSpaceId) {
      _switchConversation(oldWidget.selectedSpaceId, widget.selectedSpaceId);
    }
    if (oldWidget.focusedTabKey != widget.focusedTabKey) {
      // Back/forward or a deep-link changed `?tab=`: apply it a frame later —
      // focusing mutates the layout, which must not happen mid-build. A
      // simultaneous space switch wins the race: its restore force-applies
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
  /// surviving a refresh) and back/forward or a deep-link re-focuses the
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

  /// Focuses the tab a `?tab=` [key] names, mapping across the standing
  /// conversation's two identities: the seeded chat tab carries the space key
  /// ([MessagingTabKinds.chatSpaceTabKey]) while a deep link (the sidebar's
  /// conversation rows) names the conversation id — both mean the same
  /// stream, so a miss on one is retried as the other.
  ///
  /// A chat key with no open tab at all re-OPENS it: the sidebar's
  /// conversation rows must keep working after the user closed that
  /// conversation's tab. Guarded to conversations that exist in this space
  /// and aren't archived; any other stale key keeps the current selection.
  void _focusTabByKey(String key) {
    if (focusEditorTabByKey(_layout, key)) {
      return;
    }
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final standingId = _standingConversationId;
    final spaceKey = MessagingTabKinds.chatSpaceTabKey(spaceId);
    if (standingId != null &&
        key == spaceKey &&
        focusEditorTabByKey(
          _layout,
          MessagingTabKinds.chatTabKey(standingId),
        )) {
      return;
    }
    if (standingId != null &&
        key == MessagingTabKinds.chatTabKey(standingId) &&
        focusEditorTabByKey(_layout, spaceKey)) {
      return;
    }
    if (key == spaceKey) {
      _layout.openInActiveLeaf(_chatTab(spaceId));
      return;
    }
    final conversationId = MessagingTabKinds.conversationIdFromChatTabKey(key);
    final conv = conversationId == null
        ? null
        : _conversationsById[conversationId];
    if (conv == null || conv.isArchived) {
      return;
    }
    _openConversation(spaceId, conv.id);
  }

  // ── Layout lifecycle ──────────────────────────────────────────────────────

  /// Opens (or focuses) the conversation's code-server editor tab on its
  /// isolated worktree — the single place where files are created/saved. Driven
  /// by ⌘T and by double-clicking the tab-strip void. One code-server per
  /// conversation worktree, so a re-open refocuses the running instance rather
  /// than stacking a second tab.
  void openEditor() {
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    _layout.focusOrOpenInLeaf(
      _layout.activeLeafId,
      (t) =>
          t.kind == MessagingTabKinds.codeServer &&
          t.args['spaceId'] == spaceId &&
          t.args['path'] == null,
      () => EditorTab(
        kind: MessagingTabKinds.codeServer,
        label: l10n.ideCodeServer,
        icon: MessagingTabKinds.iconFor(MessagingTabKinds.codeServer),
        args: {'spaceId': spaceId},
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
  /// freshly-arrived plan) and mutating the tab tree inside either trips the
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
    final spaceId = widget.selectedSpaceId;
    final workspaceId = _workspaceId;
    if (spaceId == null || workspaceId == null) {
      return;
    }
    final result = await revertWorktreeFiles(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: target.repoId,
      paths: target.paths,
    );
    if (!mounted) {
      return;
    }
    // Always refresh the changes lists so the panel reflects the revert — both
    // the flat diff (the review tab) and the staged/unstaged split the Source
    // Control panel renders.
    final args = (
      workspaceId: workspaceId,
      repoId: target.repoId,
      spaceId: spaceId,
    );
    ref
      ..invalidate(repoChangesProvider(args))
      ..invalidate(repoChangesGroupedProvider(args));
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

  /// Builds a chat tab for one conversation (stream) inside the space.
  /// `dedupKey: 'chat:<conversationId>'` makes each conversation unique per
  /// group so re-opening it refocuses the existing tab instead of stacking,
  /// while distinct conversations each get their own tab.
  ///
  /// [conversationId] null means "the space's standing conversation" and the
  /// tab carries NO conversation arg — the pane resolves it. It is never
  /// substituted with the space id: that value names no conversation row.
  EditorTab _chatTab(String spaceId, {String? conversationId, String? title}) {
    return EditorTab(
      kind: MessagingTabKinds.chat,
      label: title ?? 'Chat',
      icon: MessagingTabKinds.iconFor(MessagingTabKinds.chat),
      args: {'spaceId': spaceId, 'conversationId': ?conversationId},
      dedupKey: conversationId == null
          ? MessagingTabKinds.chatSpaceTabKey(spaceId)
          : MessagingTabKinds.chatTabKey(conversationId),
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
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    // Focus, never re-open: `openTab`'s dedupe REPLACES the tab instance, which
    // would tear down the live chat body.
    if (!_layout.focusTab((t) => t.kind == MessagingTabKinds.chat)) {
      _layout.openInActiveLeaf(_chatTab(spaceId));
    }
  }

  /// Claims a run target parked by a surface that cannot open a tab itself (the
  /// global sidebar's space flyout, which navigates here and leaves the run in
  /// [pendingAgentRunProvider]).
  ///
  /// Claimed synchronously into [_claimedPendingRunId] so a rebuild before the
  /// post-frame callback cannot re-trigger it; the provider itself can only be
  /// cleared off-frame, because this runs from [build] and writing to a provider
  /// during a build throws.
  void _consumePendingRun(PendingAgentRun? pending) {
    if (pending == null ||
        pending.spaceId != widget.selectedSpaceId ||
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
    final spaceId = widget.selectedSpaceId;
    final workspaceId = _workspaceId;
    if (spaceId == null || workspaceId == null) {
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
        spaceId: spaceId,
        runId: target.runId,
        agentId: target.agentId,
        label: target.label,
        fallbackLabel: AppLocalizations.of(context).ideAgentActivity,
      ),
    );
  }

  /// Opens/focuses a conversation's chat tab (the pane's
  /// `onSelectConversation`: opening a thread, starting one).
  ///
  /// The seeded chat tab carries no conversation arg (it renders whatever the
  /// space's standing conversation resolves to), so selecting THAT
  /// conversation must focus it rather than open a second tab onto the same
  /// stream. The standing id is already resolved by the pane that is asking,
  /// so reading the provider here is a cache hit.
  void _openConversation(String spaceId, String conversationId) {
    final standingId = ref.read(standingConversationIdProvider(spaceId)).value;
    final found = _layout.focusTab(
      (t) =>
          t.kind == MessagingTabKinds.chat &&
          (t.args['conversationId'] == conversationId ||
              (t.args['conversationId'] == null &&
                  t.args['spaceId'] == spaceId &&
                  conversationId == standingId)),
    );
    if (!found) {
      _layout.openInActiveLeaf(
        _chatTab(spaceId, conversationId: conversationId),
      );
    }
  }

  /// Seeds a fresh single-leaf layout with the conversation tab alone. A new
  /// space starts slim — Terminal and Browser open on demand from the `[+]`
  /// menu, never by default (a seeded terminal spawns a shell process and a
  /// seeded browser tab holds a webview nobody asked for).
  EditorLayoutController _seedLayout(String? spaceId) {
    final controller = EditorTabGroupController();
    if (spaceId != null) {
      controller.openTab(_chatTab(spaceId));
    }
    controller.selectedIndex = 0;
    return EditorLayoutController.single(controller: controller);
  }

  /// Builds a fresh terminal tab. With [backend] `'microvm'` the shell opens
  /// inside the conversation's enclosed VM instead of on the host.
  EditorTab _newTerminalTab({String? backend}) => EditorTab(
    kind: MessagingTabKinds.terminal,
    label: 'Terminal',
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.terminal),
    // Stable id so the tab re-claims its kept session from the registry
    // after a space switch (the arg round-trips through the persisted
    // layout snapshot). The backend rides in args so a restored layout
    // reopens the shell where it was, not silently on the host.
    args: {
      'termSessionId': 'ide-terminal-${DateTime.now().microsecondsSinceEpoch}',
      'backend': ?backend,
    },
  );

  /// Builds the rig tab for [target] — the one construction shared by the
  /// `[+]` menu and the General panel's BROWSERS/COMPUTERS rows, so a tab and
  /// its sidebar row can never disagree about args or identity.
  EditorTab _rigTab(AppLocalizations l10n, RigTabTarget target) => EditorTab(
    kind: MessagingTabKinds.rig,
    label: RigTabSurfaces.labelFor(
      l10n,
      target.surface,
      engine: target.engine,
      slotId: target.slotId,
    ),
    icon: RigTabSurfaces.iconFor(target.surface),
    args: target.args,
    // One tab per MACHINE per conversation: a second tab on the same machine
    // would show it twice, while a "Firefox (VM)" beside a "Chromium (VM)" —
    // or a second WebKit machine beside the first — is two machines on
    // purpose, and the slot in the key is what says which.
    dedupKey: '${MessagingTabKinds.rig}:${target.dedupKey}',
  );

  /// The `[+]` menu's target for [kind]: the lowest-numbered machine of that
  /// surface and engine that has no tab yet.
  ///
  /// `[+]` means "one I do not have open" — that is what a new-tab button
  /// means everywhere else in the strip, and re-picking an entry only to be
  /// walked back to the tab already on screen tells a person nothing.
  ///
  /// Keyed on the open TABS, not on the running machines, and that distinction
  /// is the whole design:
  ///
  ///  * The first press takes the conversation's DEFAULT machine — the one an
  ///    agent's `*_use` calls drive. So a person opening "the browser" while an
  ///    agent is already using one lands on THAT machine and can watch it work,
  ///    rather than booting a second browser beside it.
  ///  * A press while that tab is open takes the next slot: a real second VM,
  ///    which is what someone comparing two builds asked for.
  ///  * A press when a machine of that kind is running with no tab lands back
  ///    on it — closing a rig tab puts the viewer away and leaves the guest
  ///    running, so this is the common case. Re-attaching to a machine that is
  ///    already up is free; booting another beside it is gigabytes.
  ///
  /// The phone is the exception and always addresses the one device — see
  /// [RigTabSurfaces.nextTarget], which owns both rules.
  RigTabTarget _nextRigTarget(RigTabTarget kind) =>
      RigTabSurfaces.nextTarget(kind, [
        for (final tab in _layout.allTabs())
          if (tab.kind == MessagingTabKinds.rig) tab.args,
      ]);

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
  /// one. Also sweeps cross-conversation session state: the outgoing space's
  /// terminals mirror is emptied (its sessions SURVIVE the swap in the
  /// keep-alive registry — only the sidebar mirror is space-scoped) and
  /// the global thread selection is reset so a thread open in the outgoing
  /// conversation can't leak into the incoming one's pane.
  void _switchConversation(String? from, String? to) {
    _persistNow(from);
    // The incoming space re-runs its restore + conversation-tab mirror.
    _layoutRestored = false;
    _conversationTabsSyncedFor = null;
    // Dirty state is keyed by (repoId, path) without a space; drop it so the
    // incoming conversation can't inherit the outgoing one's unsaved dots.
    _dirty.clear();
    // Keep-decisions belong to tabs that are about to leave the tree with the
    // layout: a swap is not a close, so nothing is waiting to read them.
    _keptShells.clear();
    setState(() => _setLayout(_seedLayout(to)));
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

  Future<void> _restorePersisted(String spaceId) async {
    final persistence = _persistence;
    final workspaceId = _workspaceId;
    if (persistence == null || workspaceId == null) {
      return;
    }
    final restored = await persistence.restore(
      workspaceId: workspaceId,
      cacheKey: spaceId,
    );
    // Bail if the conversation changed (or we unmounted) while reading.
    if (!mounted || widget.selectedSpaceId != spaceId) {
      return;
    }
    // A missing/unrestorable payload keeps the seeded layout; either way the
    // URL's `?tab=` gets the final say on which tab is focused.
    if (restored != null) {
      setState(() => _setLayout(restored));
    }
    _tabUrl.apply(_layout, widget.focusedTabKey, force: true);
    _layoutRestored = true;
    // Conversations may already be loaded (provider cache) — mirror them into
    // chat tabs now; otherwise the build watch runs the sync when they arrive.
    _syncConversationTabs();
  }

  /// Mirrors the space's ACTIVE conversations into chat tabs, once per space
  /// open: opening a space opens its conversations in the top tab strip.
  /// (There is no in-pane switcher strip; the tab strip IS the switcher.)
  ///
  /// Runs after the persisted layout settles ([_layoutRestored]) and once the
  /// conversation list + standing id have loaded — whichever comes last —
  /// guarded by [_conversationTabsSyncedFor]. Tabs are added WITHOUT stealing
  /// focus ([EditorLayoutController.ensureBackgroundTab]): the restored
  /// selection (or the URL's `?tab=`) keeps the final say, re-applied at the
  /// end because the URL may name a chat tab that only now exists.
  void _syncConversationTabs() {
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null ||
        !_layoutRestored ||
        _conversationTabsSyncedFor == spaceId) {
      return;
    }
    final standingId = _standingConversationId;
    final conversations = ref.read(spaceConversationsProvider(spaceId)).value;
    if (standingId == null || conversations == null) {
      return;
    }
    _conversationTabsSyncedFor = spaceId;
    final active = conversations
        .where((c) => !c.isArchived)
        .toList(growable: false);
    final open = _layout
        .allTabs()
        .where((t) => t.kind == MessagingTabKinds.chat)
        .toList(growable: false);
    // A persisted layout can still carry a conversation archived in a
    // previous session (or from another device): its tab closes rather than
    // resurrecting an archived stream.
    for (final t in open) {
      final id = t.args['conversationId'] as String?;
      final conv = id == null ? null : _conversationsById[id];
      if (conv != null && conv.isArchived) {
        _layout.closeTabByIdentity(t);
      }
    }
    // A conversation already shown by some chat tab is left alone — including
    // the standing one shown by the no-arg seeded tab.
    bool covered(Conversation c) => open.any(
      (t) =>
          t.args['conversationId'] == c.id ||
          (t.args['conversationId'] == null &&
              t.args['spaceId'] == spaceId &&
              c.id == standingId),
    );
    // The standing conversation goes first (as the no-arg tab, like the seed)
    // so the reversed walk below can insert every other conversation right
    // after the first chat tab and come out in list order.
    final standing = _conversationsById[standingId];
    if (standing != null && !standing.isArchived && !covered(standing)) {
      _layout.ensureBackgroundTab(
        _chatTab(spaceId, title: standing.title),
        afterKind: MessagingTabKinds.chat,
      );
    }
    for (final c in active.reversed) {
      if (c.id == standingId || covered(c)) {
        continue;
      }
      _layout.ensureBackgroundTab(
        _chatTab(spaceId, conversationId: c.id, title: c.title),
        afterKind: MessagingTabKinds.chat,
      );
    }
    _tabUrl.apply(_layout, widget.focusedTabKey, force: true);
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
    // A rig tab is a VIEWER, not the machine. Closing it deliberately leaves
    // the guest running: the browser you were driving keeps its pages, its
    // session and its logged-in state, and the sidebar's BROWSERS/COMPUTERS
    // row opens the tab again on it. What ends a machine is either an explicit
    // stop or the reaper — idle past its window it parks (free, the next
    // action wakes it) and past twice that it closes and says so
    // ("Enclosure reclaimed"). Tying shutdown to the × made closing a tab to
    // clear space an irreversible act that read like tidying up.
    final registry = ref.read(terminalRegistryProvider.notifier);
    _terminalSessions.removeWhere((tab, controller) {
      if (live.contains(tab)) {
        return false;
      }
      if (killOrphanedTerminals && !_keptShells.remove(tab)) {
        // The user closed the tab: the shell dies. Unless they were asked
        // (a command was running) and chose to keep it — then it takes the
        // detached path below and stays claimable from the TERMINALS list.
        registry.kill(controller.session.sessionId);
      } else {
        // A space switch swapped the layout out from under the tab: keep the
        // session alive, detached. A shell that exits while its space is
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
    _startedDeferred.removeWhere((tab) => !live.contains(tab));
    _publishTerminals();
    _publishBrowserTabs();
  }

  /// Mirrors the live terminal sessions into [spaceTerminalsProvider] so the
  /// General pane's TERMINALS section can list them (the map stays the source
  /// of truth; this is a read mirror). Also feeds the registry's
  /// eviction-protected claim set.
  ///
  /// Lists the shells of this space with NO tab too — the ones kept running
  /// when their tab was closed. That row is the only way back to them, and a
  /// shell that keeps working while vanishing from the UI is worse than one
  /// that was killed: the person meant to leave it running, not to lose it.
  void _publishTerminals() {
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final claimed = {
      for (final c in _terminalSessions.values) c.session.sessionId,
    };
    final registry = ref.read(terminalRegistryProvider);
    final sessions = [
      for (final c in _terminalSessions.values)
        if (c.session.spaceId == spaceId)
          TerminalMirror(session: c.session, title: c.title),
      for (final c in registry.controllers.values)
        if (c.session.spaceId == spaceId &&
            !claimed.contains(c.session.sessionId))
          TerminalMirror(session: c.session, title: c.title),
    ];
    // Deferred so it never fires mid-build (the provider is written from build
    // callbacks like _buildTerminalPane's post-frame setState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(spaceTerminalsProvider(spaceId).notifier).set(sessions);
      ref
          .read(terminalRegistryProvider.notifier)
          .syncClaims(
            _terminalSessions.values.map((c) => c.session.sessionId).toSet(),
          );
    });
  }

  /// Mirrors the open HOST browser tabs (the in-app webview) into
  /// [spaceBrowserTabsProvider] so the General pane's BROWSERS section can
  /// list them beside the VM rigs — the tab set stays owned by the layout;
  /// this is a read mirror (the same discipline as [_publishTerminals]).
  void _publishBrowserTabs() {
    final spaceId = widget.selectedSpaceId;
    if (spaceId == null) {
      return;
    }
    final live = Set<EditorTab>.identity()..addAll(_layout.allTabs());
    _browserTabIds.removeWhere((tab, _) => !live.contains(tab));
    final tabs = [
      for (final tab in _layout.allTabs())
        if (tab.kind == MessagingTabKinds.browser) tab,
    ];
    for (final tab in tabs) {
      _browserTabIds.putIfAbsent(
        tab,
        () => 'ide-browser-${_browserTabIdSeq++}',
      );
    }
    final l10n = AppLocalizations.of(context);
    final mirrors = [
      for (var i = 0; i < tabs.length; i++)
        BrowserTabMirror(
          tabId: _browserTabIds[tabs[i]]!,
          // A second host webview reads the same words as the first; the
          // number is the only thing telling the rows — and their × — apart.
          label: i == 0
              ? tabs[i].label
              : l10n.rigLabelNumbered(tabs[i].label, '${i + 1}'),
        ),
    ];
    // Deferred so it never fires mid-build: the reconcile can run from
    // didUpdateWidget (a conversation switch) where a provider write throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(spaceBrowserTabsProvider(spaceId).notifier).set(mirrors);
    });
  }

  // ── Host browser tabs (sidebar BROWSERS rows) ──────────────────────────────

  /// Focuses a HOST browser tab by its mirror id — a BROWSERS row's tap.
  void _focusBrowserTab(String tabId) {
    final found = _layout.focusTab(
      (t) => t.kind == MessagingTabKinds.browser && _browserTabIds[t] == tabId,
    );
    if (found) {
      return;
    }
    // The row's tab is already gone (a stale mirror); a fresh one is the
    // closest thing to what the tap asked for.
    final l10n = AppLocalizations.of(context);
    _layout.openInActiveLeaf(
      EditorTab(
        kind: MessagingTabKinds.browser,
        label: _browserLabel(l10n),
        icon: MessagingTabKinds.iconFor(MessagingTabKinds.browser),
      ),
    );
  }

  /// Closes a HOST browser tab by its mirror id — a BROWSERS row's hover ×.
  /// A host webview holds no machine and no unsaved work, so the close is
  /// immediate (no close-confirmation round-trip).
  void _closeBrowserTab(String tabId) {
    for (final entry in _browserTabIds.entries) {
      if (entry.value == tabId) {
        _layout.closeTabByIdentity(entry.key);
        return;
      }
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  void _schedulePersist() {
    final spaceId = widget.selectedSpaceId;
    final workspaceId = _workspaceId;
    final persistence = _persistence;
    if (spaceId == null || workspaceId == null || persistence == null) {
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
    if (spaceId == null || workspaceId == null || persistence == null) {
      return;
    }
    persistence.flushNow(
      workspaceId: workspaceId,
      cacheKey: spaceId,
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
      buildContent: () => _buildTabContent(
        tab,
        l10n: l10n,
        workspaceId: workspaceId,
        isVisible: isVisible,
      ),
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
    bool isVisible = true,
  }) {
    switch (tab.kind) {
      case MessagingTabKinds.chat:
        final spaceId = tab.args['spaceId'] as String;
        final conversationId = tab.args['conversationId'] as String?;
        final pane = ConversationPane(
          spaceId: spaceId,
          conversationId: conversationId,
          onSelectConversation: (convId) => _openConversation(spaceId, convId),
        );
        if (workspaceId == null) {
          return pane;
        }
        // Lets the `task` cell in an agent turn open the subagent it spawned —
        // the transcript renderers take no callbacks, so the opener rides an
        // InheritedWidget instead.
        return RunActivityOpenerScope(
          workspaceId: workspaceId,
          spaceId: spaceId,
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
      case MessagingTabKinds.rig:
        return RigTabPane(
          surface: tab.args['surface'] as String? ?? RigTabSurfaces.computer,
          engine: RigTabSurfaces.engineFromArgs(tab.args),
          slotId: RigTabSurfaces.slotFromArgs(tab.args),
          conversationId: widget.selectedSpaceId,
          // A hidden rig tab stops streaming: the guest keeps encoding and the
          // link keeps carrying frames otherwise, for a picture on no screen.
          isVisible: isVisible,
        );
      case MessagingTabKinds.codeServer:
        final spaceId = tab.args['spaceId'] as String;
        final repoId = tab.args['repoId'] as String?;
        final path = tab.args['path'] as String?;
        return CodeServerPane(spaceId: spaceId, repoId: repoId, path: path);
      case MessagingTabKinds.attachment:
        return AttachmentPreviewPane(
          attachmentId: tab.args[kAttachmentPreviewIdArg] as String? ?? '',
          label: tab.args['label'] as String?,
        );
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
          spaceId: tab.args['spaceId'] as String?,
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
          spaceId: tab.args['spaceId'] as String?,
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
      case MessagingTabKinds.contextExplorer:
        final explorerWorkspaceId = tab.args['workspaceId'] as String?;
        final explorerSpaceId = tab.args['spaceId'] as String?;
        final explorerAgentId = tab.args['agentId'] as String?;
        // Workspace isolation: a restored layout must never render another
        // tenant's context breakdown. The layout cache is workspace-scoped so
        // this should be unreachable — deny visibly rather than render.
        if (explorerWorkspaceId == null ||
            explorerSpaceId == null ||
            explorerAgentId == null ||
            workspaceId == null ||
            workspaceId != explorerWorkspaceId) {
          return const SizedBox.shrink();
        }
        return ContextExplorerPane(
          workspaceId: explorerWorkspaceId,
          spaceId: explorerSpaceId,
          agentId: explorerAgentId,
        );
      case MessagingTabKinds.agentActivity:
        final tabWorkspaceId = tab.args['workspaceId'] as String?;
        final tabSpaceId = tab.args['spaceId'] as String?;
        final runId = tab.args['runId'] as String?;
        // Workspace isolation: a restored layout must never render another
        // tenant's run. The layout cache is workspace-scoped so this should be
        // unreachable — deny visibly rather than render.
        if (tabWorkspaceId == null ||
            tabSpaceId == null ||
            runId == null ||
            workspaceId == null ||
            workspaceId != tabWorkspaceId) {
          return const AgentActivityPane.unavailable();
        }
        return AgentActivityPane(
          workspaceId: tabWorkspaceId,
          spaceId: tabSpaceId,
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
    // A RESTORED enclosed terminal boots a VM the moment it attaches, so it
    // waits for a press — the same rule the rig tabs follow, reached through
    // the adjacent terminal path. `_startedDeferred` is state of this session
    // only: after a restart the tab defers again.
    if (tab.args[EditorLayoutCodec.deferStartArg] == true &&
        !_startedDeferred.contains(tab)) {
      return EnclosedTerminalStart(
        onStart: () => setState(() => _startedDeferred.add(tab)),
      );
    }
    if (_creatingSessions.add(tab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        // The tab carries its session id in args (minted at tab creation and
        // round-tripped through the persisted layout), so a tab restored
        // after a space switch re-claims its kept session — shell, buffer
        // and subscriptions intact. Legacy snapshots without the arg mint a
        // fresh id (a blank shell, today's behaviour).
        final sessionId =
            tab.args['termSessionId'] as String? ??
            'ide-terminal-${DateTime.now().microsecondsSinceEpoch}';
        // The terminal opens at the conversation root
        // (`conversations/<spaceId>`), resolved from the space id by the
        // view/server (web-safe). The `sessionId` stays unique per tab so
        // each terminal gets its own sandbox session.
        final session = TerminalSession(
          sessionId: sessionId,
          spaceId: widget.selectedSpaceId ?? '',
          workspaceId: ref.read(activeWorkspaceIdProvider) ?? '',
          backend: tab.args['backend'] as String?,
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
  /// the space is inactive and the shell exited while hidden — kill it in
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
    // life). Keyed by space id under the messaging layout cache kind.
    _persistence ??= EditorLayoutPersistence(
      codec: messagingLayoutCodec,
      cache: ref.read(editorLayoutCacheRepositoryProvider),
      cacheKind: editorLayoutCacheKind,
    );
    _workspaceId = ref.watch(activeWorkspaceIdProvider);
    // Kept warm here so the "+" menu's VM-terminal entry has an answer by the
    // time it opens — the menu itself builds outside this widget's build pass
    // and can only `read`.
    ref.watch(rigCapabilitiesProvider);
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final spaceId = widget.selectedSpaceId;

    // Chat tabs label themselves from the LIVE conversation list rather than
    // the label frozen into the tab, so a rename lands immediately and a
    // thread is legible as one. Watched here (not read inside the chrome
    // callback, which runs in a descendant's build) so a change actually
    // rebuilds the tab strip. `spaceConversationsProvider` is already watched
    // by the switcher, so this shares one subscription.
    _conversationsById = spaceId == null
        ? const {}
        : {
            for (final c
                in ref.watch(spaceConversationsProvider(spaceId)).value ??
                    const <Conversation>[])
              c.id: c,
          };
    _standingConversationId = spaceId == null
        ? null
        : ref.watch(standingConversationIdProvider(spaceId)).value;

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
      final orphans = [
        for (final t in _layout.allTabs())
          if (t.kind == MessagingTabKinds.chat &&
              (_conversationsById[t.args['conversationId']]?.isArchived ??
                  false))
            t,
      ];
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
    }

    // A run target parked by the sidebar's space flyout before it navigated
    // here. Watched (not listened) because the value is usually set BEFORE this
    // layout mounts, so there is no transition for a listener to catch.
    _consumePendingRun(ref.watch(pendingAgentRunProvider));

    // In-editor navigation → app tab: the embedded editor's bridge extension
    // reports a file the user navigated to (cmd-click "go to definition", an
    // Explorer open, …). Open it as its OWN app tab in the active leaf, leaving
    // the source tab pinned on its file. Errors (a server without code-server)
    // are ignored. Scoped to the open conversation.
    if (spaceId != null) {
      ref.listen<AsyncValue<CodeServerOpenEvent>>(
        codeServerOpenRequestsProvider(spaceId),
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
                'spaceId': spaceId,
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
      ref.listen<int>(openCodeServerTabRequestProvider(spaceId), (
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
                  spaceId: widget.selectedSpaceId,
                  onFocusBrowserTab: _focusBrowserTab,
                  onCloseBrowserTab: _closeBrowserTab,
                  onOpenFile: (target) {
                    // The editor is the default open action: open (or refocus) a
                    // code-server tab for the clicked file. Each distinct file gets
                    // its own tab — clicking a new file opens a new tab; clicking a
                    // file that's already open refocuses it (dedup by path).
                    final spaceId = widget.selectedSpaceId;
                    if (spaceId == null) {
                      return;
                    }
                    final fileName = target.path.split('/').last;
                    _layout.focusOrOpenInLeaf(
                      _layout.activeLeafId,
                      (t) =>
                          t.kind == MessagingTabKinds.codeServer &&
                          t.args['spaceId'] == spaceId &&
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
                          'spaceId': spaceId,
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
                        args: {
                          'repoId': target.repoId,
                          'path': target.path,
                          // The quick view reads the conversation's own
                          // worktree — the copy the Explorer listed.
                          'spaceId': ?widget.selectedSpaceId,
                        },
                      ),
                    );
                  },
                  onOpenReview: (target) {
                    final spaceId = widget.selectedSpaceId;
                    // Open (or refocus) a multi-file "Review code" tab for the
                    // repo, anchored to the clicked file. `dedupKey` keeps one
                    // review tab per (spaceId, repoId), so re-clicking another
                    // file in the same repo re-anchors it.
                    _layout.openInActiveLeaf(
                      EditorTab(
                        kind: MessagingTabKinds.review,
                        label: l10n.ideReviewCode,
                        icon: MessagingTabKinds.iconFor(
                          MessagingTabKinds.review,
                        ),
                        dedupKey: 'review:${spaceId ?? ''}:${target.repoId}',
                        args: {
                          'spaceId': ?spaceId,
                          'repoId': target.repoId,
                          'anchorPath': target.file.filename,
                        },
                      ),
                    );
                  },
                  onViewSource: (target) {
                    // Open (or refocus) a code-server tab for the file. Same path
                    // the Explorer file-click uses (dedup by path).
                    final spaceId = widget.selectedSpaceId;
                    if (spaceId == null) {
                      return;
                    }
                    _layout.focusOrOpenInLeaf(
                      _layout.activeLeafId,
                      (t) =>
                          t.kind == MessagingTabKinds.codeServer &&
                          t.args['spaceId'] == spaceId &&
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
                          'spaceId': spaceId,
                          'repoId': target.repoId,
                          'path': target.path,
                        },
                      ),
                    );
                  },
                  onRevertFiles: _revertFiles,
                  onOpenAgentRun: _openAgentRun,
                  onFocusTerminal: _focusOrOpenTerminal,
                  // Focusing a machine selects (or opens) ITS tab: the match is
                  // surface + engine + slot, so "Firefox (VM)" never focuses
                  // the Chromium tab beside it and the second WebKit machine
                  // never focuses the first one's tab. This is the way BACK to
                  // a machine that is already running — the `[+]` menu is the
                  // way to a new one.
                  onFocusRig: (target) => _focusOrOpenRig(l10n, target),
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
  /// action and the sidebar toggle.
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

  /// Close interceptor for a code-server tab: clean tabs close immediately; a
  /// dirty one runs the shared Save / Don't save / Cancel prompt, saving via the
  /// embedded editor (the buffer's only holder) on Save.
  Future<bool> _confirmCloseTab(EditorTab tab) async {
    if (!await _confirmCloseLiveWork(tab)) {
      return false;
    }
    // The first prompt is async, so this state can be gone by now — and an
    // unmounted layout has no tab left to close.
    if (!mounted || !_tabDirty(tab)) {
      return mounted;
    }
    final path = tab.args['path'] as String? ?? '';
    return confirmCloseDirtyEditorTab(
      context: context,
      isDirty: true,
      fileName: path.isEmpty ? tab.label : path.split('/').last,
      onSave: () async {
        final spaceId = tab.args['spaceId'] as String?;
        if (spaceId != null && path.isNotEmpty) {
          await saveCodeServerFile(
            ref.read(rpcClientProvider),
            spaceId: spaceId,
            repoId: tab.args['repoId'] as String?,
            path: path,
          );
        }
      },
    );
  }

  /// Asks what to do with the live work behind [tab] before it closes, and
  /// carries out the answer. Returns whether the close may proceed.
  ///
  /// Only tabs that are ACTUALLY busy prompt — a machine that is up, a shell
  /// with a command in the foreground, a conversation an agent is working in.
  /// A rig tab nobody started, a shell at its prompt and a quiet conversation
  /// close the way they always have, because a confirmation that fires on
  /// every close is one people learn to dismiss without reading, and it would
  /// fire on the ones that cost nothing.
  Future<bool> _confirmCloseLiveWork(EditorTab tab) async {
    final l10n = AppLocalizations.of(context);
    return switch (tab.kind) {
      MessagingTabKinds.rig => _confirmCloseRig(tab, l10n),
      MessagingTabKinds.terminal => _confirmCloseTerminal(tab, l10n),
      MessagingTabKinds.chat => _confirmCloseConversation(tab, l10n),
      _ => Future.value(true),
    };
  }

  /// The rig tab's machine: keep it running (reopen from the sidebar) or shut
  /// it down now. Nothing booted → nothing to ask about.
  Future<bool> _confirmCloseRig(EditorTab tab, AppLocalizations l10n) async {
    final workspaceId = _workspaceId;
    final spaceId = widget.selectedSpaceId;
    if (workspaceId == null || spaceId == null) {
      return true;
    }
    final key = (
      workspaceId: workspaceId,
      conversationId: spaceId,
      surface: tab.args['surface'] as String? ?? RigTabSurfaces.computer,
      engine: RigTabSurfaces.browserEngineOf(tab.args),
      slotId: RigTabSurfaces.slotFromArgs(tab.args),
    );
    // A rig that is still BOOTING counts: it already owns a machine, and a
    // boot abandoned halfway is the most expensive thing to leave behind.
    final rig =
        ref.read(conversationRigProvider(key)) ??
        ref.read(conversationPendingRigProvider(key));
    if (rig == null) {
      return true;
    }
    final choice = await confirmCloseLiveTab(
      context: context,
      title: l10n.ideCloseKeepTitle(tab.label),
      body: l10n.ideCloseKeepBodyMachine,
      shutDownLabel: l10n.ideCloseShutDownMachine,
    );
    switch (choice) {
      case LiveTabCloseChoice.cancel:
        return false;
      case LiveTabCloseChoice.keepRunning:
        return true;
      case LiveTabCloseChoice.shutDown:
        await _destroyRig(workspaceId, rig.id);
        return true;
    }
  }

  Future<void> _destroyRig(String workspaceId, String rigId) async {
    try {
      await ref.read(rigRepositoryProvider).destroy(workspaceId, rigId);
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }

  /// The terminal tab's shell: asked about only while a command holds the
  /// foreground. A shell at its prompt is closed and killed exactly as before
  /// — keeping every idle shell alive would fill the registry's six slots with
  /// prompts nobody is coming back to.
  Future<bool> _confirmCloseTerminal(
    EditorTab tab,
    AppLocalizations l10n,
  ) async {
    final controller = _terminalSessions[tab];
    if (controller == null || !controller.isRunningCommand) {
      return true;
    }
    final choice = await confirmCloseLiveTab(
      context: context,
      title: l10n.ideCloseKeepTitle(_terminalLabel(tab, l10n)),
      body: l10n.ideCloseKeepBodyShell,
      shutDownLabel: l10n.ideCloseEndShell,
    );
    switch (choice) {
      case LiveTabCloseChoice.cancel:
        return false;
      case LiveTabCloseChoice.keepRunning:
        // The reconcile that follows the close reads this and detaches the
        // session instead of killing it; the TERMINALS list keeps showing it.
        _keptShells.add(tab);
        return true;
      case LiveTabCloseChoice.shutDown:
        return true;
    }
  }

  /// The chat tab's agents: closing the tab never stopped a run, so "keep
  /// running" is the status quo — what is new is being told, and being offered
  /// the stop that was otherwise only reachable from the composer of a tab you
  /// were about to close.
  Future<bool> _confirmCloseConversation(
    EditorTab tab,
    AppLocalizations l10n,
  ) async {
    final workspaceId = _workspaceId;
    final conversationId =
        tab.args['conversationId'] as String? ?? _standingConversationId;
    if (workspaceId == null || conversationId == null) {
      return true;
    }
    final runs =
        ref
            .read(
              conversationActiveRunsProvider((
                workspaceId: workspaceId,
                conversationId: conversationId,
              )),
            )
            .asData
            ?.value ??
        const [];
    if (runs.isEmpty) {
      return true;
    }
    final choice = await confirmCloseLiveTab(
      context: context,
      title: l10n.ideCloseKeepTitle(_chatLabel(tab, l10n)),
      body: l10n.ideCloseKeepBodyAgent,
      shutDownLabel: l10n.ideCloseStopAgent,
    );
    switch (choice) {
      case LiveTabCloseChoice.cancel:
        return false;
      case LiveTabCloseChoice.keepRunning:
        return true;
      case LiveTabCloseChoice.shutDown:
        // Every run in THIS conversation — a multi-agent room can have
        // several, and stopping one of them is not what "stop" reads as.
        final messaging = ref.read(messagingServiceProvider);
        for (final run in runs) {
          await messaging.stopRun(workspaceId, run.id);
        }
        return true;
    }
  }

  /// Context-menu extras per tab kind: a chat tab gets "Archive
  /// conversation"; a terminal tab gets "Restart shell"; a code-server (file)
  /// tab gets Copy path / Copy relative path. Browser tabs carry no extras.
  List<CcMenuItem> _tabContextExtras(EditorTab tab) {
    if (tab.kind == MessagingTabKinds.chat) {
      final l10n = AppLocalizations.of(context);
      final conv = _tabConversation(tab);
      final activeCount = _conversationsById.values
          .where((c) => !c.isArchived)
          .length;
      return [
        CcMenuItem(
          label: l10n.archiveConversation,
          // The last active conversation stays: a space always keeps one live
          // stream (archiving it would just mint a fresh standing one).
          enabled: conv != null && !conv.isArchived && activeCount > 1,
          onSelected: () => unawaited(_archiveConversation(tab)),
        ),
      ];
    }
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

  /// Archives the conversation a chat [tab] shows and closes the tab: the
  /// conversation leaves the global sidebar's rows and the space's tab strip
  /// (both filter to active conversations), and the space-open tab mirror
  /// never re-opens it.
  Future<void> _archiveConversation(EditorTab tab) async {
    final workspaceId = _workspaceId;
    final conv = _tabConversation(tab);
    if (workspaceId == null || conv == null) {
      return;
    }
    await ref
        .read(conversationRepositoryProvider)
        .setStatus(
          workspaceId: workspaceId,
          conversationId: conv.id,
          status: ConversationStatus.archived,
        );
    if (mounted) {
      _layout.closeTabByIdentity(tab);
    }
  }

  /// Copies the file's absolute on-disk path — the isolated copy-on-write
  /// worktree the workbench actually edits when the tab is backed by a space
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

  /// The isolated worktree root for [tab]'s `(space, repo)` on the server, or
  /// null when the tab isn't backed by a space worktree (e.g. a read-only
  /// main-repo file view, which carries no space id).
  Future<String?> _worktreeBaseFor(EditorTab tab) async {
    final repoId = tab.args['repoId'] as String?;
    final spaceId = tab.args['spaceId'] as String?;
    if (repoId == null || spaceId == null) {
      return null;
    }
    final isolated = await ref
        .read(isolatedRepoRepositoryProvider)
        .forUnitRepo(widget.workspaceId, spaceId, repoId);
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

  /// The browsers the connected server can boot.
  ///
  /// Empty when the capability probe has not answered yet or the server is
  /// too old to report engines; [RigTabSurfaces.targets] reads that as
  /// Chromium, which is what such a server runs.
  Set<RigBrowserEngine> get _serverBrowserEngines => ref
      .read(rigCapabilitiesProvider)
      .maybeWhen(
        data: (backends) => {
          for (final b in backends)
            if (b.hostsBrowser) ...b.browserEngines,
        },
        orElse: () => const <RigBrowserEngine>{},
      );

  /// Whether the connected server can host a terminal inside an enclosed VM
  /// right now (QEMU present + the exec image downloaded).
  bool get _serverHostsVmTerminals => ref
      .read(rigCapabilitiesProvider)
      .maybeWhen(
        data: (backends) => backends.any((b) => b.available && b.terminals),
        orElse: () => false,
      );

  /// The conversation a chat [tab] renders, or null while it is still
  /// resolving. A tab with no `conversationId` arg shows the space's standing
  /// conversation — the one place the two are allowed to differ.
  Conversation? _tabConversation(EditorTab tab) {
    if (tab.kind != MessagingTabKinds.chat) {
      return null;
    }
    final id = tab.args['conversationId'] as String? ?? _standingConversationId;
    return id == null ? null : _conversationsById[id];
  }

  /// A chat tab's header: the conversation's own title. A thread is prefixed
  /// so it can never be mistaken for the stream it was branched from — two
  /// tabs of the same space otherwise read identically.
  String _chatLabel(EditorTab tab, AppLocalizations l10n) {
    final conversation = _tabConversation(tab);
    if (conversation == null) {
      return tab.label;
    }
    final name = conversationDisplayName(conversation, l10n);
    return conversation.isThread ? l10n.threadTabTitle(name) : name;
  }

  /// Shows the shell [sessionId]: its tab if one is open anywhere in the tree,
  /// otherwise a tab that re-claims that very session.
  ///
  /// The id matters. A row in the TERMINALS list can name a shell whose tab
  /// was closed while a command kept running, and the tab this opens carries
  /// its session id — so the pane re-claims the live controller from the
  /// registry, scrollback and all, instead of spawning a blank shell beside
  /// the one still working.
  void _focusOrOpenTerminal(String sessionId) {
    bool showsSession(EditorTab t) =>
        t.kind == MessagingTabKinds.terminal &&
        t.args['termSessionId'] == sessionId;
    if (_layout.focusTab(showsSession)) {
      return;
    }
    final kept = ref
        .read(terminalRegistryProvider)
        .controllers[sessionId]
        ?.session;
    _layout.openInActiveLeaf(
      kept == null
          ? _newTerminalTab()
          : EditorTab(
              kind: MessagingTabKinds.terminal,
              label: 'Terminal',
              icon: MessagingTabKinds.iconFor(MessagingTabKinds.terminal),
              args: {'termSessionId': sessionId, 'backend': ?kept.backend},
            ),
    );
  }

  /// Shows [target]'s machine: its tab if one is open anywhere in the tree,
  /// otherwise a new tab on it in the active leaf.
  ///
  /// This is the way BACK to a machine — the General panel's BROWSERS and
  /// COMPUTERS rows — and closing a rig tab leaves its machine running, so a
  /// row here is routinely a machine with no tab at all. The match is surface +
  /// engine + SLOT, so a row never opens the tab beside its own.
  ///
  /// De-duped across the WHOLE tree rather than the active leaf: a machine
  /// already visible in a side pane should be brought forward there, not
  /// mirrored into a second tab whose × the user will read as closing it.
  void _focusOrOpenRig(AppLocalizations l10n, RigTabTarget target) {
    bool showsTarget(EditorTab t) =>
        t.kind == MessagingTabKinds.rig &&
        t.args['surface'] == target.surface &&
        RigTabSurfaces.browserEngineOf(t.args) ==
            RigTabSurfaces.browserEngineOf(target.args) &&
        RigTabSurfaces.slotFromArgs(t.args) == target.slotId;
    if (_layout.focusTab(showsTarget)) {
      return;
    }
    _layout.openInActiveLeaf(_rigTab(l10n, target));
  }

  /// One `[+]` entry for a kind of machine — a surface, and one per browser
  /// engine, because a rig runs exactly one engine for its whole life so which
  /// browser is a choice made here or not at all.
  ///
  /// The entry keeps the kind's plain name; WHICH machine it opens is resolved
  /// on press, and the number lands on the tab it creates. Deciding the slot
  /// while the menu is built would fix it too early — the tab set can change
  /// underneath an open menu, and a stale slot hands a second press the first
  /// press's machine.
  CcMenuItem _rigMenuItem(
    AppLocalizations l10n,
    String leafId,
    RigTabTarget kind,
  ) => CcMenuItem(
    label: RigTabSurfaces.menuLabelFor(l10n, kind),
    icon: RigTabSurfaces.iconFor(kind.surface),
    searchText: RigTabSurfaces.menuSearchKeywords(l10n),
    // A browser entry leads with its engine's logo — the whole reason to open
    // a second browser rig is to tell the engines apart.
    leading: kind.engine == null
        ? null
        : (color) =>
              BrowserEngineLogo(engine: kind.engine!, size: 16, color: color),
    enabled: widget.selectedSpaceId != null,
    onSelected: () => WidgetsBinding.instance.addPostFrameCallback((_) {
      // Deferred a frame for the same reason as [_openTabNextFrame]: the menu
      // is still tearing its overlay down, and mounting a rig's platform view
      // inside that pointer phase trips the mouse tracker.
      if (!mounted) {
        return;
      }
      _layout.setActiveLeaf(leafId);
      // Focus-or-open rather than open: on the phone surface every press
      // names the one device, so a second press must show that tab instead of
      // stacking a duplicate view of it.
      _focusOrOpenRig(l10n, _nextRigTarget(kind));
    }),
  );

  EditorChrome _chrome(AppLocalizations l10n) => EditorChrome(
    // A thread's chat tab gets the branch glyph the conversation switcher
    // uses, so the badge reads the same in both places.
    iconFor: (tab) => _tabConversation(tab)?.isThread ?? false
        ? AppIcons.gitBranch
        : MessagingTabKinds.iconFor(tab.kind),
    // A browser-rig tab leads with its engine's monochrome logo (an SVG the
    // icon font has no glyph for), so "Firefox (VM)" and "Chromium (VM)"
    // are told apart at a glance — the job the generic globe could not do.
    leadingFor: (tab) =>
        tab.kind == MessagingTabKinds.rig &&
            tab.args['surface'] == RigTabSurfaces.browser
        ? (color) => BrowserEngineLogo(
            engine:
                RigTabSurfaces.browserEngineOf(tab.args) ??
                RigBrowserEngine.fallback,
            color: color,
          )
        : null,
    // A terminal with a live title — an OSC 0/2 the shell set, or the
    // server-polled foreground process ("pnpm dev serve") — shows that
    // instead of its default label: wezterm/ghostty/iTerm tab behaviour. The
    // live label also falls back to the kept controller's title for a
    // restored-but-unopened tab (see _terminalLabel).
    labelFor: (tab) => switch (tab.kind) {
      MessagingTabKinds.terminal => _terminalLabel(tab, l10n),
      MessagingTabKinds.chat => _chatLabel(tab, l10n),
      _ => tab.label,
    },
    dirtyFor: _tabDirty,
    confirmClose: _confirmCloseTab,
    tabContextMenuExtras: _tabContextExtras,
    onUntitledDraft: openEditor,
    onToggleSidebar: toggleSidebar,
    sidebarVisible: _sidebarVisible,
    newTabMenuItems: (leafId) => [
      // Conversations are tabs and every one of them opens with the space, so
      // there is no "Open chat" entry — only the affordance to create the next
      // conversation. First in the menu: the conversation is the surface every
      // other entry opens something beside.
      CcMenuItem(
        label: l10n.newConversation,
        icon: AppIcons.messagesSquare,
        enabled: widget.selectedSpaceId != null,
        onSelected: () async {
          final spaceId = widget.selectedSpaceId;
          if (spaceId == null) {
            return;
          }
          // No name prompt: the conversation starts untitled and the
          // workspace's title model names it after its first message.
          final id = await createUntitledConversation(ref, spaceId);
          if (id == null || !mounted) {
            return;
          }
          _openTabNextFrame(leafId, _chatTab(spaceId, conversationId: id));
        },
      ),
      // Deliberately ABOVE the first heading rather than inside a group of its
      // own: it is the one row that makes the thing the others open something
      // beside, and a one-row section would be a heading pretending to
      // organize.
      CcMenuItem.section(l10n.ideMenuSectionTools),
      CcMenuItem(
        label: l10n.terminal,
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
      const CcMenuItem.divider(),
      // The heading is what lets every row under it drop the "(VM)" its label
      // used to carry, and it puts the in-app webview (above) and a browser
      // rig in visibly different groups — the confusion that suffix existed to
      // prevent, now handled structurally instead of by making the reader
      // parse to the end of each line.
      CcMenuItem.section(l10n.ideMenuSectionVirtualMachine),
      // A shell inside the conversation's enclosed VM. Offered only when the
      // connected server can actually host one (QEMU + the exec image);
      // otherwise the entry would be a button whose only outcome is an error
      // three minutes later.
      if (_serverHostsVmTerminals)
        CcMenuItem(
          label: l10n.terminal,
          icon: AppIcons.terminal,
          searchText: RigTabSurfaces.menuSearchKeywords(l10n),
          enabled: widget.selectedSpaceId != null,
          onSelected: () =>
              _openTabNextFrame(leafId, _newTerminalTab(backend: 'microvm')),
        ),
      // One entry per machine an agent can drive, and one per BROWSER: a rig
      // runs exactly one engine for its whole life, so which browser is a
      // choice made here or not at all. Scoped to this conversation, so the
      // tab and the agent's `computer_use`/`browser_use`/`mobile_use` calls
      // address the SAME machine rather than copies of it.
      for (final kind in RigTabSurfaces.targets(_serverBrowserEngines))
        _rigMenuItem(l10n, leafId, kind),
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
