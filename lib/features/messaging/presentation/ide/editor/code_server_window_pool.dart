import 'dart:async';

import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// What a code-server tab shows: a worktree (the window key) and a file in it.
@immutable
class CodeServerTarget {
  /// Creates a [CodeServerTarget].
  const CodeServerTarget({
    required this.spaceId,
    this.repoId,
    this.path,
    this.line,
  });

  /// The conversation whose isolated worktree the editor opens.
  final String spaceId;

  /// The repo whose worktree to open (null lets the server pick the first).
  final String? repoId;

  /// The worktree-relative file to show, or null for the bare editor.
  final String? path;

  /// The 1-based line to reveal in [path] (best-effort).
  final int? line;

  /// Tabs with equal keys share one editor window.
  String get worktreeKey => '$spaceId\x1f${repoId ?? ''}';
}

/// Asks the bridge in editor window [windowId] to show [path].
typedef CodeServerOpenFile =
    Future<void> Function(
      CodeServerTarget worktree,
      String windowId,
      String path,
      int? line,
    );

/// Closes [path] in the worktree's editor windows after its last tab closed.
typedef CodeServerCloseFile =
    Future<void> Function(CodeServerTarget worktree, String path);

/// One embedded VS Code window, shared by the code-server tabs of a worktree.
///
/// Its live webview sits under [key] and is reparented (never rebuilt) between
/// the tab that shows it and the pool's offstage parking slot.
class CodeServerWindow {
  CodeServerWindow._(this.boot) : shownPath = boot.path;

  /// Keeps the window's element, and so its platform view, across moves.
  final GlobalKey key = GlobalKey();

  /// The target the window was minted for: its session request and the file
  /// its URL opens at boot.
  final CodeServerTarget boot;

  /// The session request the window's view resolves (stable for its life).
  CodeServerSessionRequest get request => CodeServerSessionRequest(
    spaceId: boot.spaceId,
    repoId: boot.repoId,
    path: boot.path,
    line: boot.line,
  );

  /// The bridge extension's id for this window, once it has activated.
  String? bridgeId;

  /// The worktree-relative file the window shows.
  String? shownPath;

  /// The visible tab showing this window, or null while it is parked.
  EditorTab? owner;

  String? _leafId;
  int _lastUsed = 0;
  ({String path, int? line})? _pendingOpen;
}

/// Shares one code-server window per worktree across an editor layout's tabs.
///
/// Every code-server tab used to boot its own VS Code window: a workbench load
/// plus a fresh extension host (and its language servers) per tab. Now each
/// selected code-server tab borrows a window of its worktree. A tab switch moves
/// the window to the newly selected tab and asks its bridge extension to show
/// that tab's file; a window no visible tab needs waits in [parked]. A worktree
/// only gets a second window while two of its tabs are visible side by side.
///
/// Assignments change only in [reconcile], which runs from layout notifications
/// (outside build) and notifies every pane plus the parking slot at once, so a
/// window's [GlobalKey] leaves its old place and lands in its new one within
/// the same frame.
class CodeServerWindowPool extends ChangeNotifier {
  /// Creates a pool. [targetOf] maps a tab to what it shows (null for other
  /// kinds); [openFile] and [closeFile] reach the bridge through the server.
  CodeServerWindowPool({
    required this.targetOf,
    required this.openFile,
    required this.closeFile,
  });

  /// Whether this platform shares windows. Sharing moves a native webview
  /// between tabs; a web iframe reloads when moved and its console (the bridge
  /// window id) is unreadable, and Linux has no embedded editor at all, so
  /// there every pane keeps its own window.
  static bool get sharesWindows =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// What a tab shows, or null when it is not a code-server tab (or not
  /// resolvable yet, e.g. a PR worktree still provisioning).
  final CodeServerTarget? Function(EditorTab tab) targetOf;

  /// Sends an `open` to a window's bridge.
  final CodeServerOpenFile openFile;

  /// Closes a file whose last tab closed.
  final CodeServerCloseFile closeFile;

  EditorLayoutController? _layout;
  final List<CodeServerWindow> _windows = [];
  Map<EditorTab, CodeServerTarget> _liveTargets = Map.identity();
  int _clock = 0;
  bool _reconcileScheduled = false;

  /// The window [tab] shows, or null when it holds none.
  CodeServerWindow? windowOf(EditorTab tab) {
    for (final w in _windows) {
      if (identical(w.owner, tab)) {
        return w;
      }
    }
    return null;
  }

  /// Windows no visible tab shows, kept mounted offstage.
  List<CodeServerWindow> get parked => [
    for (final w in _windows)
      if (w.owner == null) w,
  ];

  /// The tab showing the window whose bridge id is [bridgeId], if any.
  EditorTab? ownerOfBridge(String? bridgeId) {
    if (bridgeId == null) {
      return null;
    }
    for (final w in _windows) {
      if (w.bridgeId == bridgeId) {
        return w.owner;
      }
    }
    return null;
  }

  /// Follows [layout] (replacing any previous one) and reconciles.
  void attach(EditorLayoutController layout) {
    if (identical(_layout, layout)) {
      return;
    }
    _layout?.removeListener(_onLayoutChanged);
    _layout = layout;
    // A swapped layout is another conversation: its tabs never closed, so no
    // file is closed for them.
    _liveTargets = Map.identity();
    layout.addListener(_onLayoutChanged);
    _onLayoutChanged();
  }

  /// Records the bridge id [id] the window's webview logged, then sends any
  /// file switch that was waiting for it.
  void bridgeReady(CodeServerWindow window, String id) {
    window.bridgeId = id;
    _flush(window);
  }

  /// A fresh view of [window] is booting (first mount, or remounted after its
  /// element was lost): it opens the boot file again under a new bridge, so
  /// its owner's file is re-requested once that bridge is up.
  void windowBooting(CodeServerWindow window) {
    window
      ..bridgeId = null
      ..shownPath = window.boot.path
      .._pendingOpen = null;
    final owner = window.owner;
    final target = owner == null ? null : _liveTargets[owner];
    if (target != null) {
      _want(window, target);
    }
  }

  /// The window [bridgeId] navigated itself to [path] (go to definition,
  /// quick open), so switching to that file's tab needs no `open`.
  void noteNavigated(String? bridgeId, String path) {
    for (final w in _windows) {
      if (bridgeId != null && w.bridgeId == bridgeId) {
        w.shownPath = path;
      }
    }
  }

  /// Reconciles after the current frame (safe to call from build).
  void requestReconcile() {
    if (_reconcileScheduled) {
      return;
    }
    _reconcileScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _reconcileScheduled = false;
      reconcile();
    });
  }

  void _onLayoutChanged() {
    // Mid-build, panes must not be told to rebuild; move windows next frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      requestReconcile();
    } else {
      reconcile();
    }
  }

  /// Moves windows to the code-server tabs now visible, parks the rest, closes
  /// files whose last tab closed and drops windows no tab can use.
  void reconcile() {
    final layout = _layout;
    if (layout == null) {
      return;
    }
    final live = <EditorTab, CodeServerTarget>{};
    final visible =
        <({EditorTab tab, String leafId, CodeServerTarget target})>[];
    void walk(EditorNode node) {
      if (node is EditorLeafNode) {
        final tabs = node.controller.tabs;
        for (var i = 0; i < tabs.length; i++) {
          final target = targetOf(tabs[i]);
          if (target == null) {
            continue;
          }
          live[tabs[i]] = target;
          if (i == node.controller.selectedIndex) {
            visible.add((tab: tabs[i], leafId: node.id, target: target));
          }
        }
      } else if (node is EditorSplitNode) {
        node.children.forEach(walk);
      }
    }

    walk(layout.root);
    final liveTargets = Map<EditorTab, CodeServerTarget>.identity()
      ..addAll(live);
    _closeRemovedFiles(liveTargets);
    _liveTargets = liveTargets;

    var changed = false;
    final visibleTabs = Set<EditorTab>.identity()
      ..addAll(visible.map((v) => v.tab));
    for (final w in _windows) {
      if (w.owner != null && !visibleTabs.contains(w.owner)) {
        w.owner = null;
        changed = true;
      }
    }
    for (final v in visible) {
      if (windowOf(v.tab) != null) {
        continue;
      }
      final window = _pick(v.target, v.leafId) ?? _create(v.target);
      window
        ..owner = v.tab
        .._leafId = v.leafId
        .._lastUsed = ++_clock;
      _want(window, v.target);
      changed = true;
    }
    if (_pruneParked(liveTargets.values)) {
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void _closeRemovedFiles(Map<EditorTab, CodeServerTarget> live) {
    final stillShown = {
      for (final t in live.values)
        if (t.path != null) '${t.worktreeKey}\x1f${t.path}',
    };
    for (final entry in _liveTargets.entries) {
      final path = entry.value.path;
      if (live.containsKey(entry.key) || path == null) {
        continue;
      }
      if (stillShown.add('${entry.value.worktreeKey}\x1f$path')) {
        unawaited(closeFile(entry.value, path));
      }
    }
  }

  /// The parked window of [target]'s worktree to reuse: the one last shown in
  /// [leafId] (a tab switch in the same pane), else one already showing the
  /// file, else the most recently used.
  CodeServerWindow? _pick(CodeServerTarget target, String leafId) {
    final free = [
      for (final w in _windows)
        if (w.owner == null && w.boot.worktreeKey == target.worktreeKey) w,
    ];
    if (free.isEmpty) {
      return null;
    }
    for (final w in free) {
      if (w._leafId == leafId) {
        return w;
      }
    }
    for (final w in free) {
      if (target.path != null && w.shownPath == target.path) {
        return w;
      }
    }
    free.sort((a, b) => b._lastUsed.compareTo(a._lastUsed));
    return free.first;
  }

  CodeServerWindow _create(CodeServerTarget target) {
    final window = CodeServerWindow._(target);
    _windows.add(window);
    return window;
  }

  /// Keeps one parked window per worktree that still has a tab, so the next
  /// switch to it is instant; drops the rest.
  bool _pruneParked(Iterable<CodeServerTarget> live) {
    final liveKeys = {for (final t in live) t.worktreeKey};
    final kept = <String>{};
    final byRecency = [..._windows]
      ..sort((a, b) => b._lastUsed.compareTo(a._lastUsed));
    final drop = <CodeServerWindow>[];
    for (final w in byRecency) {
      if (w.owner != null) {
        continue;
      }
      final key = w.boot.worktreeKey;
      if (!liveKeys.contains(key) || !kept.add(key)) {
        drop.add(w);
      }
    }
    _windows.removeWhere(drop.contains);
    return drop.isNotEmpty;
  }

  void _want(CodeServerWindow window, CodeServerTarget target) {
    final path = target.path;
    if (path == null || window.shownPath == path) {
      window._pendingOpen = null;
      return;
    }
    window._pendingOpen = (path: path, line: target.line);
    _flush(window);
  }

  void _flush(CodeServerWindow window) {
    final pending = window._pendingOpen;
    final bridgeId = window.bridgeId;
    if (pending == null || bridgeId == null) {
      return;
    }
    window
      .._pendingOpen = null
      ..shownPath = pending.path;
    unawaited(openFile(window.boot, bridgeId, pending.path, pending.line));
  }

  @override
  void dispose() {
    _layout?.removeListener(_onLayoutChanged);
    _layout = null;
    super.dispose();
  }
}
