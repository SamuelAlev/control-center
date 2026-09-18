part of 'pr_detail_screen.dart';

extension _PrDetailBody on _PrDetailScreenState {
  Widget _header(DesignSystemTokens t, String title, PullRequest? pr) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            PhoneIconButton(
              icon: AppIcons.arrowLeft,
              semanticLabel: AppLocalizations.of(context).back,
              onPressed: () => context.pop(),
              color: t.fgSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$title #${widget.number}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            if (pr != null && pr.htmlUrl.isNotEmpty)
              PhoneIconButton(
                icon: AppIcons.externalLink,
                semanticLabel: AppLocalizations.of(context).openOnForge,
                onPressed: () => openExternal(pr.htmlUrl),
                color: t.fgSecondary,
                iconSize: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(DesignSystemTokens t, PullRequest pr) {
    final reviewers = ref.watch(prReviewersProvider(_coords)).value ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        PrSummary(pr: pr, reviewers: reviewers),
        const SizedBox(height: 16),
        _tabBar(t),
        const SizedBox(height: 12),
        ...switch (_tab) {
          _PrTab.conversation => _conversation(t, pr),
          _PrTab.files => _files(t),
          _PrTab.checks => _checks(t),
        },
      ],
    );
  }

  Widget _tabBar(DesignSystemTokens t) {
    final l10n = AppLocalizations.of(context);
    final files = ref.watch(prFilesProvider(_coords)).value?.length;
    final checks = ref.watch(prCheckRunsProvider(_coords)).value?.length;
    String withCount(String label, int? count) =>
        count == null || count == 0 ? label : l10n.labelWithCount(label, count);
    return Row(
      children: [
        for (final tab in _PrTab.values)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: CcChip(
              label: switch (tab) {
                _PrTab.conversation => l10n.conversation,
                _PrTab.files => withCount(l10n.files, files),
                _PrTab.checks => withCount(l10n.checks, checks),
              },
              selected: _tab == tab,
              onPressed: () => _set(() => _tab = tab),
            ),
          ),
      ],
    );
  }

  List<Widget> _conversation(DesignSystemTokens t, PullRequest pr) {
    ref.watch(prRepoPermissionProvider(_coords));
    ref.watch(viewerLoginsProvider);
    final reviews = ref.watch(prReviewsProvider(_coords)).value ?? const [];
    final comments =
        ref.watch(prIssueCommentsProvider(_coords)).value ?? const [];
    final entries =
        <PrTimelineEntry>[
          for (final r in reviews)
            if (r.state != PrReviewSubmissionState.pending &&
                (r.body.isNotEmpty ||
                    r.state != PrReviewSubmissionState.commented))
              PrTimelineEntry(
                author: r.author,
                body: r.body,
                at: r.submittedAt,
                review: r.state,
              ),
          for (final c in comments)
            PrTimelineEntry(
              author: c.user,
              body: _optimisticComments[c.id] ?? c.body,
              at: c.createdAt,
              commentId: c.id,
              canEditComment: _canEditComment(c.user),
            ),
        ]..sort((a, b) {
          final epoch = DateTime.fromMillisecondsSinceEpoch(0);
          return (a.at ?? epoch).compareTo(b.at ?? epoch);
        });
    return buildConversationTimeline(
      context: context,
      t: t,
      prBody: _optimisticPrBody ?? pr.body,
      prAuthor: pr.author,
      prCreatedAt: pr.createdAt,
      entries: entries,
      onPrBodyCheckboxChanged: _canEditPrBody(pr)
          ? (index, _) => _togglePrBodyCheckbox(pr, index)
          : null,
      onCommentCheckboxChanged: (commentId, index, _) {
        final entry = entries
            .where((e) => e.commentId == commentId)
            .firstOrNull;
        if (entry == null || !entry.canEditComment) {
          return;
        }
        _toggleCommentCheckbox(
          commentId: commentId,
          currentBody: entry.body,
          index: index,
        );
      },
    );
  }

  List<Widget> _files(DesignSystemTokens t) {
    final async = ref.watch(prFilesProvider(_coords));
    final files = async.value ?? const <PrFile>[];
    if (async.isLoading && files.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CcSpinner(size: 20)),
        ),
      ];
    }
    if (files.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            AppLocalizations.of(context).noChangedFiles,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.textTertiary),
          ),
        ),
      ];
    }
    return [
      for (final f in files)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: FileDiffTile(key: ValueKey(f.filename), file: f),
        ),
    ];
  }

  List<Widget> _checks(DesignSystemTokens t) {
    final async = ref.watch(prCheckRunsProvider(_coords));
    final runs = async.value ?? const <CheckRun>[];
    if (async.isLoading && runs.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CcSpinner(size: 20)),
        ),
      ];
    }
    if (runs.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            AppLocalizations.of(context).noChecksReported,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.textTertiary),
          ),
        ),
      ];
    }
    return [
      for (final run in runs)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CheckRow(run: run),
        ),
    ];
  }
}
