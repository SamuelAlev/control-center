part of 'pr_diff_tab.dart';

/// [PrDiffTab]'s comment-permalink reveal loop, driven by
/// [_PrDiffTabState._maybeRevealPendingComment].
extension _PrDiffTabCommentReveal on _PrDiffTabState {
  void _scheduleReveal(
    int commentId, {
    required int attempts,
    required DateTime loadDeadline,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.pendingCommentAnchor?.value != commentId) {
        return;
      }
      // Until the patch stream lands the diff shows the patch-free file index,
      // which has no rows for a thread to sit on. Revealing then would find
      // nothing and bounce to the timeline, so wait for the patches (and the
      // comments) on a clock rather than the frame budget: they are network
      // loads, and a large PR's diff takes far longer than 30 frames.
      final patches = _listenForPatches
          ? ref.read(prFilesProvider(widget.prRef))
          : const AsyncLoading<List<PrFile>>();
      if (patches.hasError) {
        _abandonReveal(commentId);
        return;
      }
      final comments = ref.read(prReviewCommentsProvider(widget.prRef)).value;
      if (comments == null || !patches.hasValue) {
        if (DateTime.now().isBefore(loadDeadline)) {
          _scheduleReveal(
            commentId,
            attempts: attempts,
            loadDeadline: loadDeadline,
          );
        } else {
          _abandonReveal(commentId);
        }
        return;
      }
      final diff = _diffKey.currentState;
      if (diff == null) {
        if (attempts > 0) {
          _scheduleReveal(
            commentId,
            attempts: attempts - 1,
            loadDeadline: loadDeadline,
          );
        } else {
          _abandonReveal(commentId);
        }
        return;
      }

      final threads = groupServerReviewThreads(comments);
      ServerReviewThread? thread;
      for (final t in threads) {
        if (t.comments.any((c) => c.id == commentId)) {
          thread = t;
          break;
        }
      }
      // Unknown comment (deleted, or an issue comment that never lived in the
      // diff), or an outdated thread whose anchor line is gone from the
      // current diff: there is no row to scroll to, so hand it back rather
      // than scrolling nowhere.
      if (thread == null || thread.isOutdated) {
        _abandonReveal(commentId);
        return;
      }
      final fileIndex = diff.filesIndexOf(thread.path);
      if (fileIndex < 0) {
        // The file is outside the diff's current scope (a commit range, or a
        // filter). Clear the scope once and retry; if it still is not there,
        // the conversation belongs on the timeline.
        if (attempts > 0 && _clearScopeForReveal()) {
          _scheduleReveal(
            commentId,
            attempts: attempts - 1,
            loadDeadline: loadDeadline,
          );
        } else {
          _abandonReveal(commentId);
        }
        return;
      }

      widget.pendingCommentAnchor?.value = null;
      // The diff resolves the thread's row itself: its line is a file line on
      // one side, not a row index, and the file may not be parsed yet.
      final revealed = await diff.revealThread(thread.id, fileIndex: fileIndex);
      if (!revealed && mounted) {
        widget.onCommentNotInDiff?.call(commentId);
      }
    });
  }

  /// Widens the diff back to the whole pull request so a permalinked file can
  /// be found. Returns whether anything actually changed — false stops the
  /// retry loop rather than spinning on an unchanged scope.
  bool _clearScopeForReveal() {
    if (!ref.read(prDiffScopeProvider).isScoped) {
      return false;
    }
    ref.read(prDiffScopeProvider.notifier).updateSelection(const {});
    return true;
  }

  void _abandonReveal(int commentId) {
    if (widget.pendingCommentAnchor?.value == commentId) {
      widget.pendingCommentAnchor!.value = null;
    }
    widget.onCommentNotInDiff?.call(commentId);
  }
}
