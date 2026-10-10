part of 'pr_diff_tab.dart';

/// [PrDiffTab]'s comment-permalink reveal loop, driven by
/// [_PrDiffTabState._maybeRevealPendingComment].
extension _PrDiffTabCommentReveal on _PrDiffTabState {
  void _scheduleReveal(int commentId, {required int attempts}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.pendingCommentAnchor?.value != commentId) {
        return;
      }
      final comments = ref.read(prReviewCommentsProvider(widget.prRef)).value;
      final diff = _diffKey.currentState;
      if (comments == null || diff == null) {
        if (attempts > 0) {
          _scheduleReveal(commentId, attempts: attempts - 1);
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
      final line = thread?.endLine;
      if (thread == null || line == null) {
        _abandonReveal(commentId);
        return;
      }
      final fileIndex = diff.filesIndexOf(thread.path);
      if (fileIndex < 0) {
        // The file is outside the diff's current scope (a commit range, or a
        // filter). Clear the scope once and retry; if it still is not there,
        // the conversation belongs on the timeline.
        if (attempts > 0 && _clearScopeForReveal()) {
          _scheduleReveal(commentId, attempts: attempts - 1);
        } else {
          _abandonReveal(commentId);
        }
        return;
      }

      widget.pendingCommentAnchor?.value = null;
      await diff.jumpToFile(fileIndex);
      if (!mounted) {
        return;
      }
      await diff.revealThread(
        thread.id,
        fileIndex: fileIndex,
        displayLine: line,
      );
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
