part of 'pr_activity_timeline.dart';

/// Comment-permalink and reply-follow scrolling for [_PrActivityTimelineState].
extension _PrActivityTimelineCommentReveal on _PrActivityTimelineState {
  static const Duration _revealLoadTimeout = Duration(seconds: 20);

  void _maybeRevealPendingComment() {
    final commentId = widget.pendingCommentAnchor?.value;
    if (commentId == null || !mounted || !widget.isVisible) {
      return;
    }
    _scheduleCommentReveal(
      commentId,
      loadDeadline: DateTime.now().add(_revealLoadTimeout),
    );
  }

  void _scheduleCommentReveal(
    int commentId, {
    required DateTime loadDeadline,
    bool refreshed = false,
    int missingRetries = 3,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          !widget.isVisible ||
          widget.pendingCommentAnchor?.value != commentId) {
        return;
      }

      int? foundIndex;
      _FeedRow? foundRow;
      for (var i = 0; i < _rowsOut.length; i++) {
        final row = _rowsOut[i];
        switch (row) {
          case _EntryRow(entry: PrCommentEntry(:final comment))
              when comment.id == commentId:
            foundIndex = i;
            foundRow = row;
          case _ThreadRow(:final thread)
              when thread.comments.any((c) => c.id == commentId):
            foundIndex = i;
            foundRow = row;
          default:
            break;
        }
        if (foundIndex != null) {
          break;
        }
      }

      if (foundIndex == null || foundRow == null) {
        final issueAsync = ref.read(prIssueCommentsProvider(widget.prRef));
        final codeAsync = ref.read(prReviewCommentIndexProvider(widget.prRef));
        if ((issueAsync.isLoading || codeAsync.isLoading) &&
            DateTime.now().isBefore(loadDeadline)) {
          _scheduleCommentReveal(
            commentId,
            loadDeadline: loadDeadline,
            refreshed: refreshed,
            missingRetries: missingRetries,
          );
          return;
        }
        if (!refreshed) {
          ref.invalidate(prIssueCommentsProvider(widget.prRef));
          ref.invalidate(prReviewCommentIndexProvider(widget.prRef));
          _scheduleCommentReveal(
            commentId,
            loadDeadline: loadDeadline,
            refreshed: true,
            missingRetries: 3,
          );
          return;
        }
        if (missingRetries > 0) {
          _scheduleCommentReveal(
            commentId,
            loadDeadline: loadDeadline,
            refreshed: true,
            missingRetries: missingRetries - 1,
          );
          return;
        }
        if (widget.pendingCommentAnchor?.value == commentId) {
          widget.pendingCommentAnchor!.value = null;
        }
        return;
      }

      if (widget.pendingCommentAnchor?.value == commentId) {
        widget.pendingCommentAnchor!.value = null;
      }

      String? focusedThreadId;
      int? focusedCommentId;
      _updateState(() {
        switch (foundRow) {
          case _ThreadRow(:final thread):
            _open[thread.id] = true;
            _focusedThreadId = thread.id;
            _focusedCommentId = null;
            focusedThreadId = thread.id;
          case _EntryRow():
            _focusedCommentId = commentId;
            _focusedThreadId = null;
            focusedCommentId = commentId;
          default:
            break;
        }
      });

      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }

      final sc = widget.scrollController;
      if (_listController.isAttached && sc != null && sc.hasClients) {
        _listController.animateToItem(
          index: foundIndex + 1,
          scrollController: sc,
          alignment: 0.15,
          duration: (_) => const Duration(milliseconds: 260),
          curve: (_) => Curves.easeOutCubic,
        );
      } else if (focusedThreadId != null) {
        final target = _threadKeys[focusedThreadId]?.currentContext;
        if (target != null && target.mounted) {
          await Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: 0.15,
          );
        }
      }

      if (!mounted) {
        return;
      }
      _focusFade?.cancel();
      _focusFade = Timer(const Duration(seconds: 3), () {
        if (!mounted) {
          return;
        }
        if ((focusedThreadId != null && _focusedThreadId == focusedThreadId) ||
            (focusedCommentId != null &&
                _focusedCommentId == focusedCommentId)) {
          _updateState(() {
            if (focusedThreadId != null &&
                _focusedThreadId == focusedThreadId) {
              _focusedThreadId = null;
            }
            if (focusedCommentId != null &&
                _focusedCommentId == focusedCommentId) {
              _focusedCommentId = null;
            }
          });
        }
      });
    });
  }

  /// Reveals the conversation a reply answers: expands it if it was collapsed
  /// (a resolved one arrives collapsed) and scrolls it into view.
  Future<void> _revealThread(String threadId) async {
    _updateState(() {
      _open[threadId] = true;
      _focusedThreadId = threadId;
      _focusedCommentId = null;
    });
    // Expanding changes the card's height, so the scroll has to wait for the
    // layout it is scrolling to.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final target = _threadKeys[threadId]?.currentContext;
    // The card's own context, not this State's: it may have been rebuilt (or
    // never mounted, if the conversation scrolled out of a lazy list) while the
    // frame settled.
    if (target == null || !target.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  }
}

/// Top-level conversation comment card in the activity timeline.
class _CommentCard extends ConsumerWidget {
  const _CommentCard({
    required this.entry,
    required this.pr,
    required this.prRef,
    this.focused = false,
  });

  final PrCommentEntry entry;
  final PullRequest pr;
  final PrRef prRef;
  final bool focused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comment = entry.comment;
    final edit = ref.watch(prEditProvider(prRef));
    final displayBody = edit.optimisticComments[comment.id] ?? comment.body;
    final login = ref.watch(currentUserLoginForPrProvider(prRef)).toLowerCase();
    final isAuthor =
        login.isNotEmpty && comment.user?.login.toLowerCase() == login;
    final canToggleTasks =
        isAuthor || ref.watch(prRepoWriteAccessProvider(prRef));
    final parts = pr.repoFullName.split('/');
    final reactions = comment.reactions;
    return EditableCommentSlot(
      initialBody: displayBody,
      owner: parts.isNotEmpty ? parts.first : '',
      repo: parts.length > 1 ? parts[1] : '',
      onSave: (body) => ref
          .read(prEditProvider(prRef).notifier)
          .saveIssueComment(commentId: comment.id, body: body),
      builder: (context, editor, startEdit) => PrCommentActions(
        prRef: prRef,
        body: displayBody,
        authorLogin: comment.user?.login ?? '',
        commentId: comment.id,
        onEdit: startEdit,
        onToggleReaction: (content, {required add}) => toggleReaction(
          ref,
          ReactionTarget.issueComment,
          commentId: comment.id,
          pr: prRef,
          content: content,
          add: add,
        ),
        child: _ActivityCard(
          author: comment.user,
          createdAt: comment.createdAt,
          body: displayBody,
          repoFullName: pr.repoFullName,
          bodyEditor: editor,
          focused: focused,
          onTaskCheckboxChanged: canToggleTasks
              ? (index, _) {
                  final l10n = AppLocalizations.of(context);
                  final toaster = CcToastScope.of(context);
                  ref
                      .read(prEditProvider(prRef).notifier)
                      .toggleCommentTaskListItem(
                        commentId: comment.id,
                        currentBody: displayBody,
                        index: index,
                      )
                      .then((error) {
                        if (error != null && context.mounted) {
                          toaster.show(
                            l10n.saveFailed,
                            variant: CcToastVariant.danger,
                          );
                        }
                      });
                }
              : null,
          footer: reactions.isEmpty
              ? null
              : ReactionBar(
                  reactions: reactions,
                  showAdder: false,
                  onToggle: (content, {required add}) => toggleReaction(
                    ref,
                    ReactionTarget.issueComment,
                    commentId: comment.id,
                    pr: prRef,
                    content: content,
                    add: add,
                  ),
                ),
        ),
      ),
    );
  }
}
