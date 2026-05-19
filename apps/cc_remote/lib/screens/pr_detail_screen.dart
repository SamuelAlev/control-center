import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/widgets/diff_view.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_remote/widgets/workspace_avatar.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The detail screen's three reads.
enum _PrTab {
  /// Description, reviews and comments, plus the composer.
  conversation,

  /// The changed files, each expanding to its unified diff.
  files,

  /// CI check runs for the head commit.
  checks,
}

/// `/pr/:repoId/:number` — one pull request: the description, the review
/// history and conversation, the changed files WITH their diffs, the CI checks,
/// and the review actions.
///
/// The diff is UNIFIED, never side-by-side, and its file sections start
/// collapsed. That is the phone's shape of the same read, not a lesser one: a
/// 44-character column cannot hold two columns of code, and a PR touching
/// twenty files would otherwise build every one of their diffs before the
/// reader has looked at anything. What the phone still leaves to the desk is
/// INLINE commenting — anchoring a thread to a line needs a target you can hit
/// precisely and a composer that does not cover the code it is about.
///
/// Every mutation rides the operator's own forge credential server-side, so an
/// approval from the phone is authored by them, not by the app.
class PrDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [PrDetailScreen].
  const PrDetailScreen({super.key, required this.repoId, required this.number});

  /// The repo the PR belongs to (a PR number is unique only within a repo).
  final String repoId;

  /// The PR number.
  final int number;

  @override
  ConsumerState<PrDetailScreen> createState() => _PrDetailScreenState();
}

class _PrDetailScreenState extends ConsumerState<PrDetailScreen> {
  final TextEditingController _comment = TextEditingController();
  _PrTab _tab = _PrTab.conversation;
  bool _acting = false;
  String? _error;
  String? _notice;

  PrCoords get _coords => (repoId: widget.repoId, number: widget.number);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  /// Runs a forge mutation, surfacing its outcome inline.
  ///
  /// A phone has no toast host above this screen and a failed approval must
  /// not look like a successful one, so the result lands in the sheet the
  /// operator is already looking at.
  Future<void> _run(String success, Future<void> Function() action) async {
    setState(() {
      _acting = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() => _notice = success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _acting = false);
      }
    }
  }

  Future<void> _submitReview(String event, String success) async {
    final repository = ref.read(prReviewRepositoryProvider(_coords));
    if (repository == null) {
      return;
    }
    final body = _comment.text.trim();
    // GitHub rejects a REQUEST_CHANGES review with no body; say so here rather
    // than letting the API round-trip return an opaque 422.
    if (event == 'REQUEST_CHANGES' && body.isEmpty) {
      setState(() => _error = 'Add a comment explaining what needs changing.');
      return;
    }
    await _run(success, () async {
      await repository.submitReview(
        prNumber: widget.number,
        event: event,
        body: body.isEmpty ? null : body,
      );
      _comment.clear();
    });
  }

  Future<void> _merge(PullRequest pr) async {
    final repository = ref.read(prReviewRepositoryProvider(_coords));
    if (repository == null) {
      return;
    }
    await _run('Merged', () async {
      await repository.mergePullRequest(
        prNumber: widget.number,
        mergeMethod: 'squash',
        // One logical intent, one key: a double-tap on a phone, or a retry
        // after the socket drops mid-merge, must collapse to a single merge
        // rather than racing GitHub for the second one to 405.
        idempotencyKey: 'phone-merge:${widget.repoId}:${widget.number}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(prDetailProvider(_coords));
    final repo = ref.watch(prRepoProvider(_coords));
    final pr = async.value;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(t, repo?.fullName ?? 'Pull request', pr),
            if (pr == null)
              Expanded(
                child: async.hasError
                    ? CcEmptyState(
                        icon: AppIcons.triangleAlert,
                        message: "Couldn't load this pull request",
                        description: '${async.error}',
                      )
                    : const Center(child: CcSpinner(size: 24)),
              )
            else ...[
              Expanded(child: _body(t, pr)),
              _actions(t, pr),
            ],
          ],
        ),
      ),
    );
  }

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
              semanticLabel: 'Back',
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
                semanticLabel: 'Open on the forge',
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        _summary(t, pr),
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

  Widget _summary(DesignSystemTokens t, PullRequest pr) {
    final reviewers = ref.watch(prReviewersProvider(_coords)).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pr.title,
          style: TextStyle(
            fontSize: 19,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(prLifecycleIcon(pr), size: 16, color: prLifecycleColor(t, pr)),
            const SizedBox(width: 6),
            Text(
              prLifecycleLabel(pr),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: prLifecycleColor(t, pr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${pr.headRef} → ${pr.baseRef}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CcBadge(
              label: '${pr.changedFiles} files',
              variant: CcBadgeVariant.neutral,
            ),
            if (churn(pr.additions, pr.deletions).isNotEmpty)
              CcBadge(
                label: churn(pr.additions, pr.deletions),
                variant: CcBadgeVariant.neutral,
              ),
            CcBadge(
              label: '${pr.commitsCount} commits',
              variant: CcBadgeVariant.neutral,
            ),
            if (pr.mergeableState == PrMergeableState.dirty)
              const CcBadge(label: 'Conflicts', variant: CcBadgeVariant.danger),
          ],
        ),
        if (reviewers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Reviewers(reviewers: reviewers),
        ],
      ],
    );
  }

  Widget _tabBar(DesignSystemTokens t) {
    final files = ref.watch(prFilesProvider(_coords)).value?.length;
    final checks = ref.watch(prCheckRunsProvider(_coords)).value?.length;
    String withCount(String label, int? count) =>
        count == null || count == 0 ? label : '$label ($count)';
    return Row(
      children: [
        for (final tab in _PrTab.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CcChip(
              label: switch (tab) {
                _PrTab.conversation => 'Conversation',
                _PrTab.files => withCount('Files', files),
                _PrTab.checks => withCount('Checks', checks),
              },
              selected: _tab == tab,
              onPressed: () => setState(() => _tab = tab),
            ),
          ),
      ],
    );
  }

  List<Widget> _conversation(DesignSystemTokens t, PullRequest pr) {
    final reviews = ref.watch(prReviewsProvider(_coords)).value ?? const [];
    final comments =
        ref.watch(prIssueCommentsProvider(_coords)).value ?? const [];

    // One timeline, not two lists: a review and a comment are the same kind of
    // event to a reader, and interleaving them by time is what makes the
    // conversation legible.
    final entries =
        <_TimelineEntry>[
          for (final r in reviews)
            if (r.state != PrReviewSubmissionState.pending &&
                (r.body.isNotEmpty ||
                    r.state != PrReviewSubmissionState.commented))
              _TimelineEntry(
                author: r.author,
                body: r.body,
                at: r.submittedAt,
                review: r.state,
              ),
          for (final c in comments)
            _TimelineEntry(author: c.user, body: c.body, at: c.createdAt),
        ]..sort((a, b) {
          final epoch = DateTime.fromMillisecondsSinceEpoch(0);
          return (a.at ?? epoch).compareTo(b.at ?? epoch);
        });

    return [
      if (pr.body.trim().isNotEmpty) ...[
        _Bubble(
          author: pr.author,
          at: pr.createdAt,
          child: PhoneMarkdown(data: pr.body),
        ),
        const SizedBox(height: 12),
      ],
      for (final e in entries) ...[
        _Bubble(
          author: e.author,
          at: e.at,
          review: e.review,
          child: e.body.trim().isEmpty
              ? const SizedBox.shrink()
              : PhoneMarkdown(data: e.body),
        ),
        const SizedBox(height: 12),
      ],
      if (entries.isEmpty && pr.body.trim().isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No description and no comments yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.textTertiary),
          ),
        ),
    ];
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
            'No changed files.',
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
          // Keyed by filename so a file's open/expanded state follows the FILE
          // across a stream update, not the index it happened to sit at.
          child: _FileDiffTile(key: ValueKey(f.filename), file: f),
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
            'No checks reported for the head commit.',
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
          child: _CheckRow(run: run),
        ),
    ];
  }

  Widget _actions(DesignSystemTokens t, PullRequest pr) {
    final canAct = pr.isOpen && !_acting;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              _Notice(text: _error!, danger: true),
              const SizedBox(height: 8),
            ] else if (_notice != null) ...[
              _Notice(text: _notice!, danger: false),
              const SizedBox(height: 8),
            ],
            if (pr.isOpen) ...[
              CcTextArea(
                controller: _comment,
                minLines: 1,
                maxLines: 4,
                hintText: 'Leave a review comment…',
                enabled: !_acting,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      icon: AppIcons.messageSquare,
                      onPressed: canAct
                          ? () => _submitReview('COMMENT', 'Comment posted')
                          : null,
                      child: const Text('Comment'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      icon: AppIcons.circleX,
                      onPressed: canAct
                          ? () => _submitReview(
                              'REQUEST_CHANGES',
                              'Changes requested',
                            )
                          : null,
                      child: const Text('Request'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CcButton(
                      size: CcButtonSize.sm,
                      icon: AppIcons.check,
                      loading: _acting,
                      onPressed: canAct
                          ? () => _submitReview('APPROVE', 'Approved')
                          : null,
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
              if (pr.canMerge) ...[
                const SizedBox(height: 8),
                CcButton(
                  fullWidth: true,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.gitMerge,
                  onPressed: canAct ? () => _merge(pr) : null,
                  child: const Text('Squash and merge'),
                ),
              ],
            ] else
              Text(
                '${prLifecycleLabel(pr)} — no actions available.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

/// One conversation entry: a review submission or a plain comment.
class _TimelineEntry {
  _TimelineEntry({
    required this.author,
    required this.body,
    required this.at,
    this.review,
  });

  final PrUser? author;
  final String body;
  final DateTime? at;
  final PrReviewSubmissionState? review;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.author,
    required this.at,
    required this.child,
    this.review,
  });

  final PrUser? author;
  final DateTime? at;
  final Widget child;
  final PrReviewSubmissionState? review;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RemoteAvatar(
              url: author?.avatarUrl,
              fallbackLabel: author?.login ?? '',
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                author?.login ?? 'unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            if (review != null) ...[
              const SizedBox(width: 6),
              CcBadge(
                label: switch (review!) {
                  PrReviewSubmissionState.approved => 'approved',
                  PrReviewSubmissionState.changesRequested =>
                    'requested changes',
                  PrReviewSubmissionState.commented => 'reviewed',
                  PrReviewSubmissionState.pending => 'pending',
                },
                variant: switch (review!) {
                  PrReviewSubmissionState.approved => CcBadgeVariant.success,
                  PrReviewSubmissionState.changesRequested =>
                    CcBadgeVariant.danger,
                  _ => CcBadgeVariant.neutral,
                },
              ),
            ],
            const Spacer(),
            Text(
              shortAgo(at),
              style: TextStyle(fontSize: 11, color: t.textTertiary),
            ),
          ],
        ),
        Padding(padding: const EdgeInsets.only(left: 28, top: 4), child: child),
      ],
    );
  }
}

/// A reviewer is a person OR a team — a sealed union, so each side is named
/// rather than reached through a lowest-common-denominator field.
String _nameOf(PrReviewer r) => switch (r) {
  PrUserReviewer(:final user) => user.login,
  PrTeamReviewer(:final name, :final slug) => name.isEmpty ? slug : name,
};

String? _avatarOf(PrReviewer r) => switch (r) {
  PrUserReviewer(:final user) => user.avatarUrl,
  PrTeamReviewer(:final avatarUrl) => avatarUrl,
};

class _Reviewers extends StatelessWidget {
  const _Reviewers({required this.reviewers});

  final List<PrReviewer> reviewers;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Reviewers',
          style: TextStyle(fontSize: 12, color: t.textTertiary),
        ),
        for (final r in reviewers)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RemoteAvatar(
                url: _avatarOf(r),
                fallbackLabel: _nameOf(r),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                _nameOf(r),
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
              const SizedBox(width: 3),
              Icon(
                switch (r.state) {
                  PrReviewSubmissionState.approved => AppIcons.circleCheck,
                  PrReviewSubmissionState.changesRequested => AppIcons.circleX,
                  PrReviewSubmissionState.commented => AppIcons.messageSquare,
                  PrReviewSubmissionState.pending => AppIcons.clock,
                },
                size: 12,
                color: switch (r.state) {
                  PrReviewSubmissionState.approved => t.textSuccessPrimary,
                  PrReviewSubmissionState.changesRequested =>
                    t.textErrorPrimary,
                  _ => t.fgTertiary,
                },
              ),
            ],
          ),
      ],
    );
  }
}

/// One changed file: a tappable header carrying its path and churn, expanding
/// to the file's unified diff.
///
/// Collapsed by default, and that is the point rather than a compromise. The
/// header row is the scan — twenty files, what changed and by how much — and
/// expanding every one of them on open would build thousands of rows inside
/// the PR screen's own scroll view before the reader has looked at anything.
class _FileDiffTile extends StatefulWidget {
  const _FileDiffTile({super.key, required this.file});

  final PrFile file;

  @override
  State<_FileDiffTile> createState() => _FileDiffTileState();
}

class _FileDiffTileState extends State<_FileDiffTile> {
  bool _open = false;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final file = widget.file;
    final slash = file.filename.lastIndexOf('/');
    final dir = slash <= 0 ? '' : file.filename.substring(0, slash + 1);
    final name = slash < 0 ? file.filename : file.filename.substring(slash + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcTappable(
          onPressed: () => setState(() => _open = !_open),
          semanticLabel: _open
              ? 'Hide the diff for ${file.filename}'
              : 'Show the diff for ${file.filename}',
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          builder: (context, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    _open ? AppIcons.chevronDown : AppIcons.chevronRight,
                    size: 14,
                    color: t.fgTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    switch (file.status) {
                      PrFileStatus.added => AppIcons.circleCheck,
                      PrFileStatus.removed => AppIcons.minus,
                      PrFileStatus.renamed => AppIcons.arrowRight,
                      _ => AppIcons.fileText,
                    },
                    size: 14,
                    color: t.fgTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (dir.isNotEmpty)
                          TextSpan(
                            text: dir,
                            style: TextStyle(color: t.textTertiary),
                          ),
                        TextSpan(
                          text: name,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CcFonts.code(
                      textStyle: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  churn(file.additions, file.deletions),
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12, top: 2),
            child: DiffView(
              patch: file.patch,
              expanded: _showAll,
              onExpand: () => setState(() => _showAll = true),
            ),
          ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.run});

  final CheckRun run;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final (icon, color, label) = _state(t);
    final elapsed = run.startedAt == null
        ? null
        : (run.completedAt ?? DateTime.now()).difference(run.startedAt!);
    return CcTappable(
      onPressed: run.htmlUrl.isEmpty ? null : () => openExternal(run.htmlUrl),
      semanticLabel: '${run.name}, $label',
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textPrimary),
                  ),
                  if (run.workflowName != null &&
                      run.workflowName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      run.workflowName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              elapsed == null ? label : '$label · ${shortDuration(elapsed)}',
              style: TextStyle(fontSize: 11, color: t.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  /// The glyph, colour and WORD for this run — never colour alone, which is
  /// the one signal a red/green-blind operator cannot read.
  (IconData, Color, String) _state(DesignSystemTokens t) {
    if (run.status != CheckRunStatus.completed) {
      return (AppIcons.clock, t.textWarningPrimary, 'running');
    }
    return switch (run.conclusion) {
      CheckRunConclusion.success => (
        AppIcons.circleCheck,
        t.textSuccessPrimary,
        'passed',
      ),
      CheckRunConclusion.failure ||
      CheckRunConclusion.timedOut ||
      CheckRunConclusion.actionRequired => (
        AppIcons.circleX,
        t.textErrorPrimary,
        'failed',
      ),
      CheckRunConclusion.cancelled || CheckRunConclusion.stale => (
        AppIcons.circleSlash,
        t.fgTertiary,
        'cancelled',
      ),
      _ => (AppIcons.circleDot, t.fgTertiary, 'skipped'),
    };
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.danger});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger ? t.dangerSoft : t.successSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              danger ? AppIcons.triangleAlert : AppIcons.circleCheck,
              size: 14,
              color: danger ? t.textErrorPrimary : t.textSuccessPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: t.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
