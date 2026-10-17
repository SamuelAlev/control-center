part of 'pr_review_threads.dart';

class _ReviewThreadCard extends ConsumerStatefulWidget {
  const _ReviewThreadCard({
    super.key,
    required this.coords,
    required this.comments,
    required this.canReply,
    required this.canResolve,
    required this.permissionKnown,
  });
  final PrCoords coords;
  final List<PrCodeReviewComment> comments;
  final bool canReply;
  final bool canResolve;
  final bool permissionKnown;

  @override
  ConsumerState<_ReviewThreadCard> createState() => _ReviewThreadCardState();
}

class _ReviewThreadCardState extends ConsumerState<_ReviewThreadCard> {
  final _reply = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _act(
    Future<void> Function() action, {
    bool clearReply = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (clearReply) _reply.clear();
      ref.invalidate(prThreadCommentsProvider(widget.coords));
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final comments = widget.comments;
    final root = comments.firstWhere(
      (c) => c.inReplyToId == null,
      orElse: () => comments.first,
    );
    final threadId = comments
        .map((comment) => comment.threadId)
        .whereType<String>()
        .firstOrNull;
    final resolved = comments.any((comment) => comment.isResolved);
    final line = root.anchorLine;
    final number = line == null
        ? ''
        : NumberFormat.decimalPattern(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(line);
    final repository = ref.watch(prReviewRepositoryProvider(widget.coords));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border.all(color: t.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              root.path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
            if (line != null)
              Text(
                l10n.mobilePrThreadLine(
                  root.side == 'LEFT'
                      ? l10n.mobilePrOriginalSide
                      : l10n.mobilePrUpdatedSide,
                  number,
                ),
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            if (resolved)
              Text(
                l10n.mobilePrThreadResolved,
                style: TextStyle(fontSize: 12, color: t.textSuccessPrimary),
              ),
            const SizedBox(height: 10),
            for (final comment in comments) ...[
              PrBubble(
                author: comment.user,
                at: comment.createdAt,
                child: PhoneMarkdown(data: comment.body),
              ),
              const SizedBox(height: 12),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: t.textErrorPrimary),
                ),
              ),
            if (widget.canReply && repository != null) ...[
              CcTextArea(
                controller: _reply,
                minLines: 1,
                maxLines: 4,
                enabled: !_busy,
                hintText: l10n.mobilePrReplyHint,
              ),
              const SizedBox(height: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                loading: _busy,
                onPressed: _busy
                    ? null
                    : () {
                        final body = _reply.text.trim();
                        if (body.isEmpty) {
                          setState(() => _error = l10n.mobilePrCommentRequired);
                          return;
                        }
                        _act(
                          () => repository.replyToReviewComment(
                            prNumber: widget.coords.number,
                            parentCommentId: root.id,
                            body: body,
                          ),
                          clearReply: true,
                        );
                      },
                child: Text(l10n.mobilePrReply),
              ),
            ],
            if (widget.canResolve &&
                threadId != null &&
                repository != null) ...[
              const SizedBox(height: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _busy
                    ? null
                    : () => _act(
                        () => repository.setReviewThreadResolved(
                          prNumber: widget.coords.number,
                          threadId: threadId,
                          resolved: !resolved,
                        ),
                      ),
                child: Text(
                  resolved
                      ? l10n.mobilePrReopenThread
                      : l10n.mobilePrResolveThread,
                ),
              ),
            ],
            if (widget.permissionKnown &&
                !widget.canResolve &&
                threadId != null)
              Text(
                l10n.mobilePrResolvePermissionDenied,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
