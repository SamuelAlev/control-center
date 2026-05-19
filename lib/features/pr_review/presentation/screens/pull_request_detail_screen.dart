import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/deployment_preview.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/browser_pane.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_chat_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_checks_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_code_server_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_diff_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_file_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_layout_codec.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_overview_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_review_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_rig_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_source_control_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_kinds.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_terminal_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_mention_avatar_scope.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_timer_banner.dart';
import 'package:control_center/features/pr_review/providers/pr_channel_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_preview_deployments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/sandboxing/presentation/enclosed_terminal_start.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/editor/editor_dirty_support.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:control_center/shared/editor/host/editor_body_host.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:control_center/shared/editor/host/editor_layout_persistence.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pull request detail screen.
class PullRequestDetailScreen extends ConsumerStatefulWidget {
  /// PullRequestDetailScreen({super.key,.
  const PullRequestDetailScreen({
    super.key,
    required this.owner,
    required this.repo,
    required this.prNumber,
    this.focusedTabKey,
  });

  /// Repo owner from the route parameters (the PR's repo, `owner/repo`).
  final String owner;

  /// Repo name from the route parameters.
  final String repo;

  /// PR number from the route parameters.
  final int prNumber;

  /// The focused workbench tab's key from the URL's `?tab=` param, or null
  /// when the URL names no tab (the seeded/restored selection then stands).
  final String? focusedTabKey;

  @override
  ConsumerState<PullRequestDetailScreen> createState() =>
      _PullRequestDetailScreenState();
}

class _PullRequestDetailScreenState
    extends ConsumerState<PullRequestDetailScreen> {
  // The PR-review surface's repo scope is driven from the URL by
  // `prDetailRouteScopeSyncProvider` (kept alive in `ControlCenterApp`), not
  // pinned here. go_router reuses this State across PR→PR hops (the page key is
  // the route *pattern*, not the resolved params), so an `initState`/`dispose`
  // pin would go stale on a cross-repo hop — see [prDetailRepoScopeProvider].

  @override
  Widget build(BuildContext context) {
    final prNumber = widget.prNumber;
    final prAsync = ref.watch(prDetailProvider(prNumber));
    // Stamp freshness on every successful (re)load — initial fetch and each
    // poll/manual refresh — so the title row can report "Checked {time}".
    ref.listen(prDetailProvider(prNumber), (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp('pr-detail:$prNumber');
      }
    });
    return prAsync.when(
      data: (pr) {
        if (pr == null) {
          return PageWrapper(child: _NotFound(prNumber: prNumber));
        }
        // The PR title + actions now live inside the Overview tab (not a page
        // header above the tabs), so the wrapper carries only the body. The
        // shell title bar still renders the route breadcrumb + back nav.
        return PageWrapper(
          // Key by PR number so navigating between PRs gets a fresh
          // [_PrDetailBodyState] — without this, the diff view's
          // [GlobalKey]s for individual files (keyed by path) leak across
          // PRs, causing e.g. PR1's `package.json` content to bleed into
          // PR2's `package.json` view because the old [PrFileDiffState]
          // (with its cached `_fileLinesFuture`) gets reused.
          child: PrMentionAvatarScope(
            prNumber: prNumber,
            owner: widget.owner,
            child: _PrDetailBody(
              key: ValueKey('pr-detail-$prNumber'),
              pr: pr,
              prNumber: prNumber,
              focusedTabKey: widget.focusedTabKey,
            ),
          ),
        );
      },
      loading: () => const PageWrapper(child: _PrDetailLoadingBody()),
      error: (e, _) => PageWrapper(
        child: _ErrorState(prNumber: prNumber, error: e),
      ),
    );
  }
}

class _PrDetailBody extends ConsumerStatefulWidget {
  const _PrDetailBody({
    super.key,
    required this.pr,
    required this.prNumber,
    this.focusedTabKey,
  });
  final PullRequest pr;
  final int prNumber;

  /// The focused tab's key from the URL's `?tab=` param, or null.
  final String? focusedTabKey;
  @override
  ConsumerState<_PrDetailBody> createState() => _PrDetailBodyState();
}

class _PrDetailBodyState extends ConsumerState<_PrDetailBody> {
  /// The editor split-tree that hosts the PR tabs — the same surface the
  /// messaging IDE uses, so tabs can be split into panes and dragged between
  /// them.
  ///
  /// Deliberately `late`, NOT `late final`: [_setLayout] replaces it (persisted
  /// restore, the N9 review-split preset). A `late final` reassignment throws
  /// AFTER the old controller was disposed, stranding the workbench on a dead
  /// controller ("used after being disposed" on every tab tap).
  late EditorLayoutController _layout;

  /// A cross-tab signal the Overview sidebar sets (a tree-order file index) and
  /// the Diff tab consumes to jump to that file.
  final ValueNotifier<int?> _pendingFileJump = ValueNotifier<int?>(null);

  /// Shared keep-alive / lazy-build / TickerMode / webview-LRU host — the same
  /// machinery the messaging IDE uses, so a hidden terminal/code-server tab
  /// isn't spawned until first seen and heavyweight webviews are LRU-suspended.
  final EditorBodyHost _bodyHost = EditorBodyHost(
    isWebviewKind: PrTabKinds.isWebview,
  );

  /// Debounced, workspace-scoped layout persistence, keyed per PR
  /// (`owner/repo#number`) so this PR's workbench panes/sizes restore on reopen.
  EditorLayoutPersistence? _persistence;
  String? _workspaceId;

  /// The active workspace's repo id for this PR (`owner/repo`), resolved in
  /// [build] and read when opening a file in a code-server tab so the server
  /// resolves the right isolated worktree.
  String? _prRepoId;

  /// Per-file unsaved-changes state (shared with the messaging IDE), fed by the
  /// bridge extension via [codeServerDirtyStateProvider]. Drives the per-tab
  /// dirty dot and gates the Save/Don't-save close prompt for code-server tabs.
  final _dirty = EditorDirtyTracker();

  /// Dedup keys of deploy-preview tabs already injected this session. Lets a
  /// re-detection refresh an *open* preview tab in place while never re-adding
  /// one the user deliberately closed.
  final Set<String> _injectedPreviewKeys = {};

  /// Live shell titles per terminal tab (OSC 0/2 from the PTY, or the
  /// server-polled foreground process), keyed by tab identity — the tab
  /// instance keys the live PTY, so the title override lives beside it rather
  /// than replacing it. Feeds [EditorChrome.labelFor]; absent (or cleared on
  /// shell restart) falls back to the tab's own label.
  final Map<EditorTab, String> _terminalTitles = {};

  /// Restored enclosed-VM terminal tabs the user has since pressed Start on.
  ///
  /// Session-lived on purpose: the deferral is a property of the RESTORE, so
  /// reopening the page must defer again rather than remember an old press.
  final Set<EditorTab> _startedDeferred = {};

  /// The PR's stable layout-cache key: `owner/repo#number`.
  String get _layoutKey => '${widget.pr.repoFullName}#${widget.prNumber}';

  /// The default PR tabs, in display order.
  static const List<String> _kinds = [
    PrTabKinds.overview,
    PrTabKinds.diff,
    PrTabKinds.sourceControl,
    PrTabKinds.chat,
    PrTabKinds.actions,
    PrTabKinds.review,
  ];

  @override
  void initState() {
    super.initState();
    _layout = _seedLayout();
    _layout.addListener(_onLayoutChanged);
    _tabUrl = EditorTabUrlTracker(
      initialKey: widget.focusedTabKey,
      focusKey: _focusUrlTarget,
      focusDefault: () => _focusKind(PrTabKinds.overview),
      writeKey: _writeTabKey,
    );
    // Restore this PR's persisted workbench once the first frame (and thus the
    // provider reads in [build]) has run.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restorePersisted());
  }

  @override
  void didUpdateWidget(covariant _PrDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedTabKey != widget.focusedTabKey) {
      // Back/forward or a deep-link changed `?tab=`: apply it a frame later —
      // focusing mutates the layout, which must not happen mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabUrl.apply(_layout, widget.focusedTabKey);
        }
      });
    }
  }

  // ── URL tab sync (`?tab=`) ────────────────────────────────────────────────

  /// Two-way sync between the focused workbench tab and the URL's `?tab=`
  /// param: a tab switch navigates (joining the back/forward stack and
  /// surviving a refresh) and back/forward or a deep-link re-focuses the
  /// named tab. The state machine lives in [EditorTabUrlTracker]; only the
  /// focus/write actions are PR-specific.
  late final EditorTabUrlTracker _tabUrl;

  /// Navigates to the current location with `?tab=` set to [key].
  void _writeTabKey(String? key) {
    final uri = GoRouterState.of(context).uri;
    context.go(locationWithEditorTab(uri, key));
  }

  /// Focuses the tab of [key] wherever it lives in the split tree. A key that
  /// names one of the fixed single-instance PR tabs is opened when closed
  /// (the tab must exist for the URL to make sense); any other stale key
  /// (a closed preview / file tab) leaves the current selection.
  void _focusUrlTarget(String key) {
    if (!focusEditorTabByKey(_layout, key) && _kinds.contains(key)) {
      _focusKind(key);
    }
  }

  static EditorLayoutController _seedLayout() {
    final group = EditorTabGroupController();
    for (final kind in _kinds) {
      group.openTab(
        EditorTab(
          kind: kind,
          label: _fallbackLabel(kind),
          icon: PrTabKinds.iconFor(kind),
          dedupKey: kind,
        ),
      );
    }
    group.selectedIndex = 0;
    return EditorLayoutController.single(controller: group);
  }

  @override
  void dispose() {
    _persistNow();
    _persistence?.dispose();
    _layout.removeListener(_onLayoutChanged);
    _layout.dispose();
    _pendingFileJump.dispose();
    super.dispose();
  }

  void _onLayoutChanged() {
    if (!mounted) {
      return;
    }
    _bodyHost.reconcile(_layout.allTabs());
    _pruneTerminalTitles();
    setState(() {});
    _persistNow(debounced: true);
    _tabUrl.writeFromLayout(_layout);
  }

  void _setLayout(EditorLayoutController next) {
    _layout.removeListener(_onLayoutChanged);
    _layout.dispose();
    _layout = next;
    _layout.addListener(_onLayoutChanged);
    _bodyHost.reconcile(_layout.allTabs());
    _pruneTerminalTitles();
  }

  /// Drops per-tab terminal state for tabs no longer anywhere in the tree.
  void _pruneTerminalTitles() {
    final live = Set<EditorTab>.identity()..addAll(_layout.allTabs());
    _terminalTitles.removeWhere((tab, _) => !live.contains(tab));
    _startedDeferred.removeWhere((tab) => !live.contains(tab));
  }

  /// Records the shell title the PTY of [tab] reported (empty clears it back
  /// to the default label) and refreshes the tab strip.
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
  }

  void _persistNow({bool debounced = false}) {
    final workspaceId = _workspaceId;
    final persistence = _persistence;
    if (workspaceId == null || persistence == null) {
      return;
    }
    if (debounced) {
      persistence.schedule(
        workspaceId: workspaceId,
        cacheKey: _layoutKey,
        layout: _layout,
      );
    } else {
      persistence.flushNow(
        workspaceId: workspaceId,
        cacheKey: _layoutKey,
        layout: _layout,
      );
    }
  }

  Future<void> _restorePersisted() async {
    final persistence = _persistence;
    final workspaceId = _workspaceId;
    if (persistence == null || workspaceId == null) {
      return;
    }
    final restored = await persistence.restore(
      workspaceId: workspaceId,
      cacheKey: _layoutKey,
    );
    if (!mounted) {
      return;
    }
    // A missing/unrestorable payload keeps the seeded layout; either way the
    // URL's `?tab=` gets the final say on which tab is focused.
    if (restored != null) {
      setState(() => _setLayout(restored));
    }
    _tabUrl.apply(_layout, widget.focusedTabKey, force: true);
  }

  /// English fallback label; the localized label is resolved per-build by the
  /// chrome's [EditorChrome.labelFor].
  static String _fallbackLabel(String kind) => switch (kind) {
    PrTabKinds.overview => 'Overview',
    PrTabKinds.diff => 'Diff',
    PrTabKinds.sourceControl => 'Source control',
    PrTabKinds.chat => 'Chat',
    PrTabKinds.actions => 'Actions',
    _ => 'Review',
  };

  static String _label(String kind, AppLocalizations l10n) => switch (kind) {
    PrTabKinds.overview => l10n.overview,
    PrTabKinds.diff => l10n.diff,
    PrTabKinds.sourceControl => l10n.sourceControl,
    PrTabKinds.chat => l10n.chat,
    PrTabKinds.actions => l10n.actions,
    _ => l10n.review,
  };

  /// Focuses the tab of [kind] wherever it lives in the split tree (opening it
  /// in the active leaf if it was closed).
  void _focusKind(String kind) {
    final found = _layout.focusTab((t) => t.kind == kind);
    if (!found) {
      _layout.openInActiveLeaf(
        EditorTab(
          kind: kind,
          label: _fallbackLabel(kind),
          icon: PrTabKinds.iconFor(kind),
          dedupKey: kind,
        ),
      );
    }
  }

  /// A `+`-menu row that reopens (or refocuses) a single-instance PR tab of
  /// [kind] in the clicked leaf — so a closed Overview/Diff/Actions/Review tab
  /// can be brought back.
  CcMenuItem _reopenTabItem(String leafId, String kind, String label) =>
      CcMenuItem(
        label: label,
        icon: PrTabKinds.iconFor(kind),
        onSelected: () {
          _layout.setActiveLeaf(leafId);
          _focusKind(kind);
        },
      );

  /// Stable dedup key for a preview's tab — one per site (or per URL when the
  /// site can't be derived).
  static String _previewDedupKey(DeploymentPreview p) =>
      'pr.preview:${p.siteName.isNotEmpty ? p.siteName : p.url}';

  /// Reconciles the auto-detected deploy-preview tabs against [previews]. Adds a
  /// tab (just after Diff, without stealing focus) the first time a preview is
  /// seen; refreshes an already-open one in place if its URL changed; never
  /// re-adds one the user has closed.
  void _reconcilePreviewTabs(List<DeploymentPreview> previews) {
    if (!mounted || previews.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final openKeys = {
      for (final t in _layout.allTabs())
        if (t.kind == PrTabKinds.preview) t.dedupKey,
    };
    for (final p in previews) {
      final key = _previewDedupKey(p);
      final firstTime = _injectedPreviewKeys.add(key);
      // Add on first sighting; otherwise only touch it while it is still open.
      if (!firstTime && !openKeys.contains(key)) {
        continue;
      }
      _layout.ensureBackgroundTab(
        EditorTab(
          kind: PrTabKinds.preview,
          label: p.siteName.isNotEmpty
              ? l10n.previewDeploymentTab(p.siteName)
              : l10n.previewDeployment,
          icon: PrTabKinds.iconFor(PrTabKinds.preview),
          args: {'url': p.url, if (p.siteName.isNotEmpty) 'site': p.siteName},
          dedupKey: key,
        ),
        afterKind: PrTabKinds.diff,
      );
    }
  }

  /// The Overview sidebar asked to open a changed file: focus the Diff tab and
  /// hand it the file index to jump to.
  void _openFileInDiff(int index) {
    _pendingFileJump.value = index;
    _focusKind(PrTabKinds.diff);
  }

  /// Opens (or focuses) an editable code-server tab at [path] on the PR
  /// worktree — full VS Code on the isolated CoW checkout, so edits land beside
  /// any agent edits and surface in Source Control. Deduped by path so
  /// re-opening the same file refocuses; [line] (1-based) deep-links a location
  /// (best-effort). Replaces the former plain-text quick editor; the legacy
  /// `pr.file` kind stays decodable for old persisted layouts.
  void _openFileInEditor(String path, {int? line}) {
    final slash = path.lastIndexOf('/');
    final basename = slash >= 0 ? path.substring(slash + 1) : path;
    _layout.focusOrOpenInLeaf(
      _layout.activeLeafId,
      (t) => t.kind == PrTabKinds.codeServer && t.args['path'] == path,
      () => EditorTab(
        kind: PrTabKinds.codeServer,
        label: basename,
        icon: PrTabKinds.iconFor(PrTabKinds.codeServer),
        args: {
          'path': path,
          if (_prRepoId != null) 'repoId': _prRepoId,
          if (line != null && line > 0) 'line': line,
        },
        dedupKey: 'pr.codeServer:$path',
      ),
    );
  }

  /// Whether [tab] is a code-server file tab with unsaved changes (drives the
  /// tab strip's dot). The bare ⌘-editor tab with no `path` is never dirty.
  bool _tabDirty(EditorTab tab) =>
      tab.kind == PrTabKinds.codeServer &&
      _dirty.isDirty(tab.args['path'] as String?);

  /// Close interceptor for a code-server tab: clean tabs close immediately; a
  /// dirty one runs the shared Save / Don't save / Cancel prompt, saving via the
  /// embedded editor on Save. Non-code-server tabs never prompt.
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
        final channelId = ref.read(prChannelProvider(widget.pr)).value;
        if (channelId != null && path.isNotEmpty) {
          await saveCodeServerFile(
            ref.read(rpcClientProvider),
            channelId: channelId,
            repoId: tab.args['repoId'] as String? ?? _prRepoId,
            path: path,
          );
        }
      },
    );
  }

  /// Closes the active leaf's selected tab (⌘W), routing a dirty code-server
  /// tab through the same Save / Don't save / Cancel prompt as the tab-strip ×
  /// (an async prompt can shift the selection, so the tab is re-located by
  /// identity before closing). Mirrors the messaging IDE's `closeActiveTab`.
  Future<void> _closeActiveTab() async {
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

  /// Copy path / Copy relative path rows for a code-server (file) tab. The
  /// fixed PR tabs (overview / diff / …) and tool tabs carry no path.
  List<CcMenuItem> _tabContextExtras(EditorTab tab) {
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

  /// Copies the file's absolute on-disk path — the PR's isolated copy-on-write
  /// worktree (the SAME checkout the workbench edits), not the repo's main
  /// working tree. Falls back to the main tree only if the worktree can't be
  /// resolved.
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

  /// The PR channel's isolated worktree root for [tab]'s repo on the server, or
  /// null when it can't be resolved (no repo/workspace/channel yet).
  Future<String?> _worktreeBaseFor(EditorTab tab) async {
    final workspaceId = _workspaceId;
    final repoId = tab.args['repoId'] as String? ?? _prRepoId;
    if (workspaceId == null || repoId == null) {
      return null;
    }
    final channelId = ref.read(prChannelProvider(widget.pr)).value;
    if (channelId == null) {
      return null;
    }
    final isolated = await ref
        .read(isolatedRepoRepositoryProvider)
        .forUnitRepo(workspaceId, channelId, repoId);
    return isolated?.path;
  }

  /// The repo's main working-tree path for [tab] — the fallback when the PR
  /// worktree can't be resolved.
  String? _mainRepoPath(EditorTab tab) {
    final workspaceId = _workspaceId;
    final repoId = tab.args['repoId'] as String? ?? _prRepoId;
    if (workspaceId == null || repoId == null) {
      return null;
    }
    final repos =
        ref.read(reposForWorkspaceProvider(workspaceId)).value ?? const [];
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

  Widget _buildBody(
    EditorTab tab, {
    required bool isVisible,
    required PrDetailRefreshState pollingState,
  }) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return _bodyHost.wrap(
      tab,
      isVisible: isVisible,
      background: t.bgPrimary,
      buildContent: () => _tabContent(tab, pollingState, isVisible: isVisible),
      buildSuspended: () => EditorSuspendedPane(
        icon: tab.kind == PrTabKinds.codeServer
            ? AppIcons.code
            : AppIcons.globe,
      ),
    );
  }

  Widget _tabContent(
    EditorTab tab,
    PrDetailRefreshState pollingState, {
    bool isVisible = true,
  }) {
    switch (tab.kind) {
      case PrTabKinds.overview:
        return PrOverviewTab(
          pr: widget.pr,
          prNumber: widget.prNumber,
          onOpenFileInDiff: _openFileInDiff,
        );
      case PrTabKinds.diff:
        return PrDiffTab(
          pr: widget.pr,
          pendingFileJump: _pendingFileJump,
          hasDiffUpdate: pollingState.hasDiffUpdate,
          onRefreshDiff: () => unawaited(
            ref
                .read(prDetailPollingProvider(widget.prNumber).notifier)
                .refreshDiff(),
          ),
          onOpenFileInEditor: _openFileInEditor,
        );
      case PrTabKinds.actions:
        final checksAsync = ref.watch(prCheckRunsProvider(widget.prNumber));
        return SingleChildScrollView(
          child: ChecksTab(
            checks: checksAsync.value ?? const [],
            isLoading: checksAsync.isLoading,
            error: checksAsync.hasError ? checksAsync.error : null,
          ),
        );
      case PrTabKinds.sourceControl:
        return PrSourceControlTab(
          pr: widget.pr,
          onOpenInEditor: _openFileInEditor,
        );
      case PrTabKinds.chat:
        return PrChatTab(pr: widget.pr);
      case PrTabKinds.terminal:
        // A RESTORED enclosed terminal boots a VM the moment it attaches, so
        // it waits for a press — the same rule the rig tabs follow.
        if (tab.args[EditorLayoutCodec.deferStartArg] == true &&
            !_startedDeferred.contains(tab)) {
          return EnclosedTerminalStart(
            onStart: () => setState(() => _startedDeferred.add(tab)),
          );
        }
        return PrTerminalTab(
          pr: widget.pr,
          backend: tab.args['backend'] as String?,
          onTitleChange: (title) => _setTerminalTitle(tab, title),
        );
      case PrTabKinds.file:
        return PrFileTab(
          pr: widget.pr,
          path: tab.args['path'] as String? ?? '',
        );
      case PrTabKinds.codeServer:
        final lineArg = tab.args['line'];
        return PrCodeServerTab(
          pr: widget.pr,
          path: tab.args['path'] as String?,
          repoId: tab.args['repoId'] as String?,
          line: lineArg is int
              ? lineArg
              : lineArg is num
              ? lineArg.toInt()
              : null,
        );
      case PrTabKinds.browser:
      case PrTabKinds.preview:
        return BrowserPane(initialUrl: tab.args['url'] as String?);
      case PrTabKinds.rig:
        // Scoped to the PR's own channel, the same one the terminal tab uses,
        // so the machine sits on the prepared PR worktree and the agents in
        // this PR's conversation drive the one the reviewer is watching.
        return PrRigTab(
          pr: widget.pr,
          surface: tab.args['surface'] as String? ?? RigTabSurfaces.computer,
          isVisible: isVisible,
        );
      case PrTabKinds.review:
      // Legacy kinds fold into the unified review tab (decode-compat).
      case PrTabKinds.aiReview:
      case PrTabKinds.reviewStudio:
        return PrReviewTab(pr: widget.pr);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Whether the connected server can host a terminal inside an enclosed VM
  /// right now (QEMU present + the exec image downloaded).
  bool get _serverHostsVmTerminals => ref
      .read(rigCapabilitiesProvider)
      .maybeWhen(
        data: (backends) => backends.any((b) => b.available && b.terminals),
        orElse: () => false,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The layout cache is a stable workspace-scoped provider; build the
    // persistence helper once, keyed per PR under the PR layout cache kind.
    _persistence ??= EditorLayoutPersistence(
      codec: prLayoutCodec,
      cache: ref.read(editorLayoutCacheRepositoryProvider),
      cacheKind: prEditorLayoutCacheKind,
    );
    _workspaceId = ref.watch(activeWorkspaceIdProvider);
    _prRepoId = prRepoIdFor(ref, widget.pr);
    // Kept warm so the "+" menu's VM-terminal entry has an answer by the time
    // it opens — the menu builds outside this build pass and can only read.
    ref.watch(rigCapabilitiesProvider);
    final pollingState = ref.watch(prDetailPollingProvider(widget.prNumber));

    // The checks summary (and other surfaces) request the Actions tab via
    // [prChecksUiProvider]; the sentinel index maps to focusing that tab.
    ref.listen<PrChecksUiState>(prChecksUiProvider, (prev, next) {
      final requested = next.requestedTabIndex;
      if (requested == null) {
        return;
      }
      if (requested == kPrActionsTabIndex) {
        _focusKind(PrTabKinds.actions);
      }
      ref.read(prChecksUiProvider.notifier).consumeTabRequest();
    });

    // Auto-detected deploy previews → one "Preview" tab per site, injected
    // after Diff (without stealing focus). The listener fires when the derived
    // preview set changes (a status/comment arrives, a redeploy lands); the
    // callback runs post-build, so mutating the layout here is safe.
    ref.listen(prPreviewDeploymentsProvider(widget.prNumber), (_, next) {
      _reconcilePreviewTabs(next);
    });

    ref.listen(prDetailProvider(widget.prNumber), (prev, next) {
      final prevSha = prev?.value?.headSha;
      final nextSha = next.value?.headSha;
      if (prevSha != null &&
          nextSha != null &&
          prevSha.isNotEmpty &&
          nextSha.isNotEmpty &&
          prevSha != nextSha) {
        ref
            .read(prDetailPollingProvider(widget.prNumber).notifier)
            .notifyDiffStale();
      }
    });

    // In-editor navigation → app tab. When a code-server tab is open, the
    // embedded editor's bridge extension reports files the user navigated to
    // (cmd-click "go to definition", an Explorer open); open each as its own
    // code-server tab so the source tab stays pinned on its file. Gated on an
    // existing code-server tab so merely viewing a PR never provisions the
    // worktree (watching prChannelProvider ensures the channel).
    final hasCodeServerTab = _layout.allTabs().any(
      (t) => t.kind == PrTabKinds.codeServer,
    );
    if (hasCodeServerTab) {
      final channelId = ref.watch(prChannelProvider(widget.pr)).value;
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
                kind: PrTabKinds.codeServer,
                label: fileName.isEmpty ? l10n.ideCodeServer : fileName,
                icon: PrTabKinds.iconFor(PrTabKinds.codeServer),
                args: {
                  'path': evt.path,
                  if (evt.repoId.isNotEmpty) 'repoId': evt.repoId,
                  // The bridge reports a 0-based line; the URL builder wants
                  // 1-based.
                  if (evt.line != null) 'line': evt.line! + 1,
                },
              ),
            );
          },
        );

        // Unsaved-changes reporting → per-tab dirty dot. Toggles the matching
        // code-server tab's dot. Errors (no code-server) are ignored.
        ref.listen<AsyncValue<CodeServerDirtyEvent>>(
          codeServerDirtyStateProvider(channelId),
          (previous, next) {
            final evt = next.asData?.value;
            if (evt == null) {
              return;
            }
            if (_dirty.set(path: evt.path, dirty: evt.dirty)) {
              setState(() {});
            }
          },
        );
      }
    }

    return ScopedShortcuts(
      scope: '/pull-requests/',
      bindings: {
        'pr.detail-tab-conv': () => _focusKind(PrTabKinds.overview),
        'pr.detail-tab-files': () => _focusKind(PrTabKinds.diff),
        'pr.detail-tab-review': () => _focusKind(PrTabKinds.review),
        'pr.detail-refresh': () => unawaited(
          ref
              .read(prDetailPollingProvider(widget.prNumber).notifier)
              .refreshAll(),
        ),
        'pr.detail-close-tab': () => unawaited(_closeActiveTab()),
      },
      child: Column(
        children: [
          ReviewTimerBanner(prNumber: widget.prNumber),
          Expanded(
            child: EditorWorkspace(
              layout: _layout,
              chrome: EditorChrome(
                iconFor: (tab) => PrTabKinds.iconFor(tab.kind),
                dirtyFor: _tabDirty,
                confirmClose: _confirmCloseTab,
                tabContextMenuExtras: _tabContextExtras,
                // Dynamic tabs (terminal, opened file, code-server) carry their
                // own label (e.g. the filename, or "Code server" for the bare
                // editor); the fixed tabs are localized by kind. A terminal
                // whose shell set a title (OSC 0/2) shows that instead.
                labelFor: (tab) => switch (tab.kind) {
                  PrTabKinds.terminal => _terminalTitles[tab] ?? tab.label,
                  PrTabKinds.rig => tab.label,
                  PrTabKinds.file ||
                  PrTabKinds.codeServer ||
                  PrTabKinds.preview => tab.label,
                  _ => _label(tab.kind, l10n),
                },
                newTabMenuItems: (leafId) => [
                  // The primary PR tabs — reopenable after being closed.
                  _reopenTabItem(leafId, PrTabKinds.overview, l10n.overview),
                  _reopenTabItem(leafId, PrTabKinds.diff, l10n.diff),
                  _reopenTabItem(leafId, PrTabKinds.actions, l10n.actions),
                  _reopenTabItem(leafId, PrTabKinds.review, l10n.review),
                  _reopenTabItem(
                    leafId,
                    PrTabKinds.sourceControl,
                    l10n.sourceControl,
                  ),
                  _reopenTabItem(leafId, PrTabKinds.chat, l10n.chat),
                  // Tool tabs.
                  CcMenuItem(
                    label: l10n.ideNewTerminal,
                    icon: PrTabKinds.iconFor(PrTabKinds.terminal),
                    onSelected: () {
                      _layout.setActiveLeaf(leafId);
                      // A fresh terminal each time (no dedupKey) — multiple
                      // shells on the same PR worktree are useful.
                      _layout.openInActiveLeaf(
                        EditorTab(
                          kind: PrTabKinds.terminal,
                          label: l10n.terminal,
                          icon: PrTabKinds.iconFor(PrTabKinds.terminal),
                        ),
                      );
                    },
                  ),
                  // A shell inside the PR conversation's enclosed VM. Only
                  // when the server can actually host one — otherwise the
                  // entry is a button whose sole outcome is a delayed error.
                  if (_serverHostsVmTerminals)
                    CcMenuItem(
                      label: l10n.ideNewVmTerminal,
                      icon: PrTabKinds.iconFor(PrTabKinds.terminal),
                      onSelected: () {
                        _layout.setActiveLeaf(leafId);
                        _layout.openInActiveLeaf(
                          EditorTab(
                            kind: PrTabKinds.terminal,
                            label: l10n.terminal,
                            icon: PrTabKinds.iconFor(PrTabKinds.terminal),
                            args: const {'backend': 'microvm'},
                          ),
                        );
                      },
                    ),
                  CcMenuItem(
                    label: l10n.ideCodeServer,
                    icon: PrTabKinds.iconFor(PrTabKinds.codeServer),
                    onSelected: () {
                      _layout.setActiveLeaf(leafId);
                      _layout.focusOrOpenInLeaf(
                        leafId,
                        (t) => t.kind == PrTabKinds.codeServer,
                        () => EditorTab(
                          kind: PrTabKinds.codeServer,
                          label: l10n.ideCodeServer,
                          icon: PrTabKinds.iconFor(PrTabKinds.codeServer),
                          dedupKey: PrTabKinds.codeServer,
                        ),
                      );
                    },
                  ),
                  // One entry per machine an agent can drive on this PR.
                  for (final surface in RigTabSurfaces.all)
                    CcMenuItem(
                      label: _rigTabLabel(l10n, surface),
                      icon: RigTabSurfaces.iconFor(surface),
                      onSelected: () {
                        _layout.setActiveLeaf(leafId);
                        _layout.focusOrOpenInLeaf(
                          leafId,
                          (t) =>
                              t.kind == PrTabKinds.rig &&
                              t.args['surface'] == surface,
                          () => EditorTab(
                            kind: PrTabKinds.rig,
                            label: RigTabSurfaces.labelFor(l10n, surface),
                            icon: RigTabSurfaces.iconFor(surface),
                            args: {'surface': surface},
                            // One tab per surface: a second "Browser (VM)"
                            // would show the same machine twice.
                            dedupKey: '${PrTabKinds.rig}:$surface',
                          ),
                        );
                      },
                    ),
                  CcMenuItem(
                    label: l10n.ideWebBrowser,
                    icon: PrTabKinds.iconFor(PrTabKinds.browser),
                    onSelected: () {
                      _layout.setActiveLeaf(leafId);
                      _layout.openInActiveLeaf(
                        EditorTab(
                          kind: PrTabKinds.browser,
                          label: l10n.ideWebBrowser,
                          icon: PrTabKinds.iconFor(PrTabKinds.browser),
                        ),
                      );
                    },
                  ),
                ],
              ),
              buildBody: (tab, {required isVisible}) => _buildBody(
                tab,
                isVisible: isVisible,
                pollingState: pollingState,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The loading state: the real workbench chrome with the default tab set, each
/// body a tab-shaped skeleton. Rendering the true tab strip (not a faux one)
/// means nothing reflows when the PR arrives — the chrome stays put and only
/// the tab bodies swap from placeholder to content.
class _PrDetailLoadingBody extends StatefulWidget {
  const _PrDetailLoadingBody();

  @override
  State<_PrDetailLoadingBody> createState() => _PrDetailLoadingBodyState();
}

class _PrDetailLoadingBodyState extends State<_PrDetailLoadingBody> {
  late final EditorLayoutController _layout;

  @override
  void initState() {
    super.initState();
    _layout = _PrDetailBodyState._seedLayout();
    // Tabs stay switchable while the PR loads (each shows its own skeleton).
    _layout.addListener(_onLayoutChanged);
  }

  void _onLayoutChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _layout.removeListener(_onLayoutChanged);
    _layout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EditorWorkspace(
      layout: _layout,
      chrome: EditorChrome(
        iconFor: (tab) => PrTabKinds.iconFor(tab.kind),
        labelFor: (tab) => _PrDetailBodyState._label(tab.kind, l10n),
      ),
      buildBody: (tab, {required isVisible}) => switch (tab.kind) {
        PrTabKinds.overview => const PrOverviewSkeleton(),
        PrTabKinds.diff => const PrDiffTabSkeleton(),
        _ => const PrPanelSkeleton(),
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.prNumber});
  final int prNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.fileQuestion, size: 48, color: t.textTertiary),
          const SizedBox(height: 16),
          Text(
            l10n.pullRequestNotFound,
            style: CcTypography.title.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pullRequestNotFoundBody,
            textAlign: TextAlign.center,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: 20),
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () =>
                context.go(pullRequestsRoute(context.currentWorkspaceId!)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.arrowLeft, size: 16),
                const SizedBox(width: 8),
                Text(l10n.backToPullRequests),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends ConsumerStatefulWidget {
  const _ErrorState({required this.prNumber, required this.error});
  final int prNumber;
  final Object error;

  @override
  ConsumerState<_ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends ConsumerState<_ErrorState> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.triangleAlert, size: 48, color: t.textErrorPrimary),
              const SizedBox(height: 16),
              Text(
                l10n.couldntLoadPullRequest,
                textAlign: TextAlign.center,
                style: CcTypography.title.copyWith(color: t.textPrimary),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  CcButton(
                    onPressed: () =>
                        ref.invalidate(prDetailProvider(widget.prNumber)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.refreshCw, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.retry),
                      ],
                    ),
                  ),
                  CcButton(
                    variant: CcButtonVariant.secondary,
                    onPressed: () =>
                        setState(() => _showDetails = !_showDetails),
                    child: Text(l10n.showDetails),
                  ),
                ],
              ),
              if (_showDetails) ...[
                const SizedBox(height: 16),
                SelectableText(
                  widget.error.toString(),
                  textAlign: TextAlign.center,
                  style: CcTypography.caption.copyWith(
                    color: t.textTertiary,
                    fontFamily: CcFonts.codeFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu label for a rig tab. Says "(VM)" so it is never confused with the
/// in-app webview and the deploy-preview tabs sitting beside it in the same
/// menu — those are pages in this app, this is a machine somewhere else.
String _rigTabLabel(AppLocalizations l10n, String surface) => switch (surface) {
  RigTabSurfaces.browser => l10n.rigTabBrowser,
  RigTabSurfaces.mobile => l10n.rigTabMobile,
  _ => l10n.rigTabComputer,
};
