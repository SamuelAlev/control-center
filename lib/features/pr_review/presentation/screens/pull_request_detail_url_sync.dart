part of 'pull_request_detail_screen.dart';

/// URL, history, and comment-permalink synchronization for [_PrDetailBodyState].
extension _PrDetailUrlSync on _PrDetailBodyState {
  /// Updates the URL when the focused workbench tab changes.
  void _writeTabKey(String? key) => _scheduleUrlSync();

  /// Copies [shas] into the diff scope when it differs from what is showing.
  void _applyCommits(Set<String> shas) {
    if (setEquals(ref.read(prDiffScopeProvider).selectedShas, shas)) {
      return;
    }
    _applyingCommits = true;
    try {
      ref.read(prDiffScopeProvider.notifier).updateSelection(shas);
    } finally {
      _applyingCommits = false;
    }
  }

  void _scheduleApplyCommits(Set<String> shas) {
    final first = _pendingCommitApply == null;
    _pendingCommitApply = Set<String>.of(shas);
    if (!first) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = _pendingCommitApply;
      _pendingCommitApply = null;
      if (!mounted || pending == null) {
        return;
      }
      if (!setEquals(widget.scopedCommits, pending)) {
        return;
      }
      _applyCommits(pending);
      final tab = widget.focusedTabKey;
      if (pending.isNotEmpty && (tab == null || tab == PrTabKinds.diff)) {
        _focusKind(PrTabKinds.diff);
      }
    });
  }

  /// Coalesces tab-focus and commit-scope writes within one frame into a
  /// single [GoRouter.go] transition.
  void _scheduleUrlSync() {
    if (_urlSyncScheduled) {
      return;
    }
    _urlSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlSyncScheduled = false;
      if (!mounted) {
        return;
      }
      _publishScopeAndTab();
    });
  }

  String _resolvedLocation(
    Uri current, {
    required bool preserveIncomingComment,
  }) {
    var base = current;
    final activeComment =
        _pendingCommentId.value ?? _pendingOverviewCommentId.value;
    if (activeComment != null) {
      final params = Map<String, String>.of(base.queryParameters)
        ..['comment'] = '$activeComment';
      base = base.replace(queryParameters: params);
    } else if (!preserveIncomingComment) {
      base = uriWithoutQueryParam(base, 'comment');
    }
    final withCommits = Uri.parse(
      locationWithPrCommits(base, ref.read(prDiffScopeProvider).selectedShas),
    );
    return locationWithEditorTab(withCommits, activeEditorTabKey(_layout));
  }

  /// Reflects the active tab, commit scope, and pending comment into the
  /// GoRouter URL so back/forward steps through workbench state.
  void _publishScopeAndTab() {
    if (!mounted) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final current = GoRouterState.of(context).uri;
    final location = _resolvedLocation(current, preserveIncomingComment: false);
    if (location == current.toString()) {
      return;
    }
    final next = Uri.parse(location);
    if (current.path == next.path &&
        mapEquals(current.queryParameters, next.queryParameters)) {
      return;
    }
    final replace = !_restoredLayout || _replaceNextUrlSync;
    _replaceNextUrlSync = false;
    if (replace) {
      if (!ref.read(navigationHistoryProvider.notifier).replace(location)) {
        Router.neglect(context, () => router.go(location));
      }
      return;
    }
    router.go(location);
  }

  /// Replaces a bare PR-entry URL with its resolved tab in place so Back skips
  /// the transient entry.
  void _syncRestoredTabUrl() {
    if (!mounted) {
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    final current = GoRouterState.of(context).uri;
    final location = _resolvedLocation(current, preserveIncomingComment: true);
    if (location == current.toString()) {
      return;
    }
    _tabUrl.resync(_layout);
    if (!ref.read(navigationHistoryProvider.notifier).replace(location)) {
      Router.neglect(context, () => router.go(location));
    }
  }

  /// Handles route-driven `?tab=`, `?comment=`, and `?commits=` updates.
  void _didUpdateRoute(_PrDetailBody oldWidget) {
    final routeInformation = GoRouter.maybeOf(
      context,
    )?.routeInformationProvider.value;
    final routeChanged = !identical(_lastRouteInformation, routeInformation);
    _lastRouteInformation = routeInformation;

    final tabChanged =
        oldWidget.focusedTabKey != widget.focusedTabKey ||
        (widget.focusedTabKey != null &&
            routeChanged &&
            _tabUrl.lastKey != widget.focusedTabKey);
    final commentArrived =
        widget.pendingCommentId != null &&
        (oldWidget.pendingCommentId != widget.pendingCommentId || routeChanged);

    if (tabChanged || commentArrived) {
      // Focus the target tab before arming the comment anchor so an offstage
      // target tab waits for visibility instead of consuming the anchor early.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (tabChanged) {
          _tabUrl.apply(_layout, widget.focusedTabKey);
        }
        if (commentArrived) {
          _armCommentReveal(
            widget.pendingCommentId!,
            overview: widget.focusedTabKey == PrTabKinds.overview,
          );
        }
      });
    }
    if (!setEquals(oldWidget.scopedCommits, widget.scopedCommits)) {
      // Back/forward changed `?commits=`. Applying it now would write the
      // provider while this element is still updating — the failure that
      // paints the error widget over the workbench.
      _scheduleApplyCommits(widget.scopedCommits);
    }
  }

  void _armCommentReveal(int commentId, {required bool overview}) {
    final target = overview ? _pendingOverviewCommentId : _pendingCommentId;
    final other = overview ? _pendingCommentId : _pendingOverviewCommentId;
    other.value = null;
    if (target.value == commentId) {
      target.value = null;
    }
    target.value = commentId;
  }

  /// The activity timeline asked to open a review conversation: focus the Diff
  /// tab and hand it the comment to reveal, the same path a permalink takes.
  void _openCommentInDiff(int commentId) {
    _armCommentReveal(commentId, overview: false);
    _focusKind(PrTabKinds.diff);
    _scheduleUrlSync();
  }

  /// Fallback for a permalinked comment the diff cannot anchor: an outdated
  /// thread (its line is gone), a file outside the diff's scope, or a
  /// top-level conversation comment.
  void _revealCommentOnOverview(int commentId) {
    if (!mounted) {
      return;
    }
    _armCommentReveal(commentId, overview: true);
    _replaceNextUrlSync = true;
    _focusKind(PrTabKinds.overview);
    _scheduleUrlSync();
  }
}
