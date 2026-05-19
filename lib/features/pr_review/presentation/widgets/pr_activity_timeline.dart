import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/utils/pr_activity_entries.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/server_review_threads.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/outdated_comments.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_thread_widget.dart';
import 'package:control_center/features/pr_review/presentation/widgets/reaction_bar.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/reaction_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:control_center/shared/widgets/github_user_mention.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Overview tab's conversation feed, rendered under the PR description:
/// a chronological timeline of the opened event, review requests, submitted
/// reviews (verdict rows, or comment cards when the reviewer wrote a summary),
/// top-level conversation comments (bots included) and pushed commits.
///
/// Inline code comments deliberately do NOT appear here — they stay anchored
/// to their diff lines in the Diff tab.
class PrActivityTimeline extends ConsumerStatefulWidget {
  /// Creates a [PrActivityTimeline].
  const PrActivityTimeline({
    super.key,
    required this.pr,
    required this.prRef,
    this.onOpenFileInDiff,
  });

  /// The pull request whose activity is shown.
  final PullRequest pr;

  /// The PR number (data lookups).
  final PrRef prRef;

  /// Called with a changed file's tree-order index when a conversation's
  /// "view in diff" action is pressed, so the detail screen can focus the
  /// Diff tab and jump to that file.
  final ValueChanged<int>? onOpenFileInDiff;

  @override
  ConsumerState<PrActivityTimeline> createState() => _PrActivityTimelineState();
}

class _PrActivityTimelineState extends ConsumerState<PrActivityTimeline> {
  /// Per-conversation open/closed presses, keyed by thread id. The DEFAULT is
  /// derived (`open == !resolved`), matching the diff.
  ///
  /// Held HERE rather than per review entry: a reply can be submitted with a
  /// later review than the conversation it answers, so following it means
  /// opening a thread that lives under a different entry entirely.
  final Map<String, bool> _open = {};

  /// Optimistic resolve state, dropped once the comment stream agrees.
  final Map<String, bool> _resolvedOverride = {};
  final Set<String> _resolveInFlight = {};

  /// Render keys per conversation, so following a reply can scroll to the one
  /// it answers.
  final Map<String, GlobalKey> _threadKeys = {};

  /// The conversation just jumped to, drawn with an accent border so the eye
  /// lands on it after the scroll.
  String? _focusedThreadId;

  GlobalKey _keyFor(String threadId) =>
      _threadKeys.putIfAbsent(threadId, GlobalKey.new);

  bool _isResolved(ServerReviewThread t) =>
      _resolvedOverride[t.id] ?? t.isResolved;

  bool _isOpen(ServerReviewThread t) => _open[t.id] ?? !_isResolved(t);

  /// Reveals the conversation a reply answers: expands it if it was collapsed
  /// (a resolved one arrives collapsed) and scrolls it into view.
  Future<void> _revealThread(String threadId) async {
    setState(() {
      _open[threadId] = true;
      _focusedThreadId = threadId;
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

  Future<void> _setResolved(ServerReviewThread thread, bool resolved) async {
    final forgeThreadId = thread.threadId;
    if (forgeThreadId == null || _resolveInFlight.contains(thread.id)) {
      return;
    }
    final ctl = ref.read(
      prInlineCommentsControllerProvider(widget.prRef).notifier,
    );
    setState(() {
      _resolveInFlight.add(thread.id);
      _resolvedOverride[thread.id] = resolved;
      _open[thread.id] = !resolved;
    });
    try {
      await ctl.setServerThreadResolved(
        threadId: forgeThreadId,
        resolved: resolved,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resolvedOverride.remove(thread.id);
        _open.remove(thread.id);
      });
      CcToastScope.of(context).show(
        AppLocalizations.of(context).failedToResolveConversation('$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _resolveInFlight.remove(thread.id));
      }
    }
  }

  /// Focuses the Diff tab on the file a conversation is anchored in.
  ///
  /// Falls back to the top of the diff when the file is no longer in it.
  /// [orderedFiles] is the tree-order file list the Diff tab's jump indices
  /// are defined over.
  void _openThreadInDiff(List<PrFile> orderedFiles, ServerReviewThread thread) {
    final i = orderedFiles.indexWhere((f) => f.filename == thread.path);
    widget.onOpenFileInDiff?.call(i >= 0 ? i : 0);
  }

  /// The conversations a review started, or null when it started none.
  Widget? _threadsHost(
    List<ServerReviewThread> threads,
    List<PrFile> orderedFiles,
  ) {
    if (threads.isEmpty) {
      return null;
    }
    return _ReviewCodeThreads(
      threads: threads,
      controller: ref.watch(
        prInlineCommentsControllerProvider(widget.prRef).notifier,
      ),
      isOpen: _isOpen,
      isResolved: _isResolved,
      isResolveBusy: (t) => _resolveInFlight.contains(t.id),
      focusedThreadId: _focusedThreadId,
      keyFor: _keyFor,
      onToggleCollapsed: (t) => setState(() => _open[t.id] = !_isOpen(t)),
      onSetResolved: _setResolved,
      onOpenInDiff: (t) => _openThreadInDiff(orderedFiles, t),
    );
  }

  /// The replies a review posted into conversations it did not start, or null.
  Widget? _repliesHost(List<ServerReviewReply> replies, PullRequest pr) {
    if (replies.isEmpty) {
      return null;
    }
    return _ReviewReplyRefs(
      replies: replies,
      repoFullName: pr.repoFullName,
      onFollow: (reply) => _revealThread(reply.thread.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.pr;
    final prRef = widget.prRef;
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    final reviews =
        ref.watch(prReviewsProvider(prRef)).value ??
        const <PrReviewSubmission>[];
    final comments =
        ref.watch(prIssueCommentsProvider(prRef)).value ??
        const <IssueComment>[];
    final commits =
        ref.watch(prCommitsProvider(prRef)).value ?? const <PrCommit>[];
    final events =
        ref.watch(prTimelineEventsProvider(prRef)).value ?? const [];
    final codeComments =
        ref.watch(prReviewCommentsProvider(prRef)).value ??
        const <PrCodeReviewComment>[];
    final orderedFiles = sortFilesByTreeOrder(
      ref.watch(prFilesProvider(prRef)).value ?? const <PrFile>[],
    );

    // Conversations, keyed by the review that STARTED each one.
    //
    // Keyed by the root's review id, not by every comment's: a reply is
    // submitted with its own later review, so bucketing per comment would
    // scatter one discussion across several timeline entries and show the
    // reply detached from what it answers.
    final allThreads = groupServerReviewThreads(codeComments);
    final threadsByReview = <int, List<ServerReviewThread>>{};
    for (final thread in allThreads) {
      final reviewId = thread.reviewId;
      if (reviewId != null) {
        threadsByReview.putIfAbsent(reviewId, () => []).add(thread);
      }
    }
    // A review that only REPLIED to earlier conversations owns no thread of its
    // own, so its entry would render as a bare "reviewed · 3 hours ago" with
    // the words nowhere in sight. Surface the replies there, pointing back.
    final repliesByReview = serverReviewRepliesByReview(allThreads);

    final entries = buildPrActivityEntries(
      pr: pr,
      reviews: reviews,
      comments: comments,
      commits: commits,
      events: events,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            l10n.activity,
            style: CcTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ),
        for (final (i, entry) in entries.indexed)
          _TimelineTile(
            isLast: i == entries.length - 1,
            leading: _leadingFor(entry),
            child: switch (entry) {
              PrOpenedEntry() => _OpenedRow(entry: entry),
              PrReviewRequestEntry() => _ReviewRequestRow(entry: entry),
              PrCommitEntry() => _CommitRow(entry: entry),
              PrCommitGroupEntry() => _CommitGroupRow(entry: entry),
              PrReviewEntry() when entry.review.body.trim().isEmpty =>
                _ReviewVerdictRow(
                  entry: entry,
                  threads: _threadsHost(
                    threadsByReview[entry.review.id] ?? const [],
                    orderedFiles,
                  ),
                  replies: _repliesHost(
                    repliesByReview[entry.review.id] ?? const [],
                    pr,
                  ),
                ),
              PrReviewEntry() => _ReviewCard(
                prRef: prRef,
                entry: entry,
                pr: pr,
                threads: _threadsHost(
                  threadsByReview[entry.review.id] ?? const [],
                  orderedFiles,
                ),
                replies: _repliesHost(
                  repliesByReview[entry.review.id] ?? const [],
                  pr,
                ),
              ),
              PrCommentEntry() => _CommentCard(
                entry: entry,
                pr: pr,
                prRef: prRef,
              ),
            },
          ),
      ],
    );
  }

  Widget _leadingFor(PrActivityEntry entry) {
    switch (entry) {
      case PrOpenedEntry():
        return const _GutterIcon(
          icon: AppIcons.gitPullRequest,
          color: ReviewStatusColors.success,
        );
      case PrReviewRequestEntry():
        return const _GutterIcon(icon: AppIcons.eye);
      case PrCommitEntry():
      case PrCommitGroupEntry():
        return const _GutterIcon(icon: AppIcons.gitCommitHorizontal);
      case PrReviewEntry(:final review):
        if (review.body.trim().isEmpty) {
          final (icon, color) = switch (review.state) {
            PrReviewSubmissionState.approved => (
              AppIcons.circleCheck,
              ReviewStatusColors.success,
            ),
            PrReviewSubmissionState.changesRequested => (
              AppIcons.circleX,
              ReviewStatusColors.failure,
            ),
            _ => (AppIcons.messageSquare, null),
          };
          return _GutterIcon(icon: icon, color: color);
        }
        return _Avatar(user: review.author);
      case PrCommentEntry(:final comment):
        return _Avatar(user: comment.user);
    }
  }
}

/// The avatar bubble used when a card row anchors the connector.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final PrUser? user;

  @override
  Widget build(BuildContext context) {
    final login = user?.login ?? '';
    if (login.isEmpty) {
      return const _GutterIcon(icon: AppIcons.messageSquare);
    }
    return GitHubUserAvatar(
      login: login,
      avatarUrl: user?.avatarUrl ?? '',
      size: 24,
    );
  }
}

/// One gutter-plus-content row: the 24px [leading] bubble sits on a
/// continuous vertical connector; the entry's content renders to its right.
///
/// The connector is a `Positioned` line in a [Stack] sized by the content row
/// — NOT an `IntrinsicHeight` column. Intrinsic sizing dry-lays-out the whole
/// row and the markdown bodies inside comment cards contain `LayoutBuilder`s,
/// which cannot compute a dry layout (throws at runtime).
class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.isLast,
    required this.leading,
    required this.child,
  });

  final bool isLast;
  final Widget leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      children: [
        // Connector line, centered under the 24px bubble, spanning from the
        // bubble's bottom to the tile's bottom (where the next bubble starts).
        if (!isLast)
          Positioned(
            left: 24 / 2 - 0.75,
            top: 24,
            bottom: 0,
            child: Container(width: 1.5, color: t.borderSecondary),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                // 3px optically centers a single bodySmall line (~18px)
                // against the 24px bubble; 16px separates entries on the
                // connector.
                padding: const EdgeInsets.only(top: 3, bottom: 16),
                child: child,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The 24px icon bubble that anchors a row onto the connector line.
class _GutterIcon extends StatelessWidget {
  const _GutterIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: t.bgSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Icon(icon, size: 13, color: color ?? t.fgTertiary),
    );
  }
}

/// A compact event sentence with an inline "· 3h ago" suffix that reveals the
/// absolute instant via the shared [AppTimestamp] hover card.
class _EventSentence extends StatelessWidget {
  const _EventSentence({required this.spans, required this.timestamp});

  /// The pre-styled sentence spans.
  final List<InlineSpan> spans;

  /// When it happened.
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final base = CcTypography.caption.copyWith(color: t.textTertiary);
    final rel = formatRelativeTime(context, timestamp);
    final relStyle = base.copyWith(color: t.textTertiary);
    return Text.rich(
      TextSpan(
        style: base.copyWith(color: t.textSecondary, height: 1.5),
        children: [
          ...spans,
          if (rel.isNotEmpty && timestamp != null)
            // The hover card anchors to just the "· 3h ago" suffix, not the
            // full-width sentence — otherwise it would centre under the row's
            // midpoint, far to the right of the timestamp.
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: AppTimestamp(
                dateTime: timestamp!,
                child: Text(' · $rel', style: relStyle),
              ),
            )
          else if (rel.isNotEmpty)
            TextSpan(text: ' · $rel', style: relStyle),
        ],
      ),
    );
  }
}

/// Splits a localized [sentence] into spans, emphasising each occurrence of
/// the given names — i18n-safe because names are verbatim substrings of the
/// translated template output.
List<InlineSpan> _emphasized(
  BuildContext context,
  String sentence,
  List<String> emphasis,
) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final strong = TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary);
  var spans = <InlineSpan>[TextSpan(text: sentence)];
  for (final name in emphasis) {
    if (name.isEmpty) {
      continue;
    }
    final next = <InlineSpan>[];
    for (final span in spans) {
      final s = span as TextSpan;
      // Only unstyled spans are split; already-emphasised ones stay intact.
      if (s.style != null || s.text == null || !s.text!.contains(name)) {
        next.add(span);
        continue;
      }
      final parts = s.text!.split(name);
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          next.add(TextSpan(text: parts[i]));
        }
        if (i < parts.length - 1) {
          next.add(TextSpan(text: name, style: strong));
        }
      }
    }
    spans = next;
  }
  return spans;
}

class _NamedMention {
  const _NamedMention({
    required this.placeholder,
    required this.login,
    this.avatarUrl = '',
    this.isTeam = false,
  });

  factory _NamedMention.user(PrUser user, String placeholder) => _NamedMention(
    placeholder: placeholder,
    login: user.login,
    avatarUrl: user.avatarUrl,
  );

  factory _NamedMention.maybeUser(PrUser? user, String placeholder) {
    if (user != null && user.login.isNotEmpty) {
      return _NamedMention.user(user, placeholder);
    }
    return _NamedMention(placeholder: placeholder, login: '');
  }

  factory _NamedMention.reviewer(PrReviewerMention mention) => _NamedMention(
    placeholder: mention.name,
    login: mention.name,
    avatarUrl: mention.avatarUrl,
    isTeam: mention.isTeam,
  );

  /// Substring in the localized sentence this mention replaces.
  final String placeholder;

  /// GitHub login (or team name).
  final String login;

  final String avatarUrl;
  final bool isTeam;
}

List<InlineSpan> _eventSpans(
  BuildContext context,
  String sentence,
  List<_NamedMention> mentions,
) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final style = CcTypography.caption.copyWith(
    fontWeight: FontWeight.w600,
    color: t.textPrimary,
    height: 1,
  );
  final builders = <String, InlineSpan Function()>{};
  for (final m in mentions) {
    if (m.placeholder.isEmpty || (!m.isTeam && m.login.isEmpty)) {
      continue;
    }
    builders.putIfAbsent(
      m.placeholder,
      () =>
          () => WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GitHubUserMention(
              login: m.login,
              avatarUrl: m.avatarUrl,
              isTeam: m.isTeam,
              style: style,
            ),
          ),
    );
  }
  if (builders.isEmpty) {
    return _emphasized(context, sentence, [
      for (final m in mentions) m.placeholder,
    ]);
  }

  final keys = builders.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  var spans = <InlineSpan>[TextSpan(text: sentence)];
  for (final key in keys) {
    final build = builders[key]!;
    final next = <InlineSpan>[];
    for (final span in spans) {
      if (span is! TextSpan ||
          span.style != null ||
          span.text == null ||
          !span.text!.contains(key)) {
        next.add(span);
        continue;
      }
      final parts = span.text!.split(key);
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          next.add(TextSpan(text: parts[i]));
        }
        if (i < parts.length - 1) {
          next.add(build());
        }
      }
    }
    spans = next;
  }
  return spans;
}

class _OpenedRow extends StatelessWidget {
  const _OpenedRow({required this.entry});

  final PrOpenedEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final author = _displayLogin(entry.author, l10n);
    final sentence = entry.commitsCount > 0
        ? l10n.prTimelineOpenedWithCommits(author, entry.commitsCount)
        : l10n.prTimelineOpened(author);
    final mentions = [_NamedMention.maybeUser(entry.author, author)];
    return _EventSentence(
      spans: _eventSpans(context, sentence, mentions),
      timestamp: entry.timestamp,
    );
  }
}

class _ReviewRequestRow extends StatelessWidget {
  const _ReviewRequestRow({required this.entry});

  final PrReviewRequestEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actor = _displayLogin(entry.actor, l10n);
    final requested = entry.requestedNames.join(', ');
    final removed = entry.removedNames.join(', ');
    final sentence = switch ((
      entry.requested.isNotEmpty,
      entry.removed.isNotEmpty,
    )) {
      (true, true) => l10n.prTimelineRequestedAndRemovedReview(
        actor,
        requested,
        removed,
      ),
      (false, true) => l10n.prTimelineRemovedReviewRequest(actor, removed),
      _ => l10n.prTimelineRequestedReview(actor, requested),
    };
    return _EventSentence(
      spans: _eventSpans(context, sentence, [
        _NamedMention.maybeUser(entry.actor, actor),
        for (final m in entry.requested) _NamedMention.reviewer(m),
        for (final m in entry.removed) _NamedMention.reviewer(m),
      ]),
      timestamp: entry.timestamp,
    );
  }
}

class _CommitRow extends ConsumerWidget {
  const _CommitRow({required this.entry});

  final PrCommitEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final base = CcTypography.caption.copyWith(color: t.textTertiary);
    final author = _displayLogin(entry.commit.author, l10n);
    final sentence = l10n.prTimelineCommitted(author);
    final mentions = [_NamedMention.maybeUser(entry.commit.author, author)];
    return _EventSentence(
      spans: [
        ..._eventSpans(context, sentence, mentions),
        TextSpan(
          text: ' ${entry.commit.shortSha}',
          style: base.copyWith(
            fontFamily: ref.watch(codeFontFamilyProvider),
            color: t.textSecondary,
          ),
        ),
        TextSpan(
          text: ' ${entry.commit.title}',
          style: base.copyWith(color: t.textTertiary),
        ),
      ],
      timestamp: entry.timestamp,
    );
  }
}

/// A contiguous run of same-author commits, compacted to one
/// "{author} pushed N commits" accordion row. Clicking the sentence toggles
/// the individual commits open underneath (chevron pairs with the state, per
/// the never-color-alone rule).
class _CommitGroupRow extends ConsumerStatefulWidget {
  const _CommitGroupRow({required this.entry});

  final PrCommitGroupEntry entry;

  @override
  ConsumerState<_CommitGroupRow> createState() => _CommitGroupRowState();
}

class _CommitGroupRowState extends ConsumerState<_CommitGroupRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final base = CcTypography.caption.copyWith(color: t.textTertiary);
    final entry = widget.entry;
    final author = _displayLogin(entry.author, l10n);
    final sentence = l10n.prTimelinePushedCommits(author, entry.commits.length);
    final mentions = [_NamedMention.maybeUser(entry.author, author)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTappable(
          onPressed: () => setState(() => _expanded = !_expanded),
          borderRadius: AppRadii.brSm,
          builder: (context, states) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _EventSentence(
                  spans: _eventSpans(context, sentence, mentions),
                  timestamp: entry.timestamp,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                size: 14,
                color: states.contains(WidgetState.hovered)
                    ? t.fgTertiary
                    : t.fgQuaternary,
              ),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, c) in entry.commits.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                    child: Row(
                      // Centre the 13px commit icon against the single-line
                      // hash + title; `start` pins it to the top of the taller
                      // line box (height 1.5) and it floats above the text.
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.gitCommitHorizontal,
                          size: 13,
                          color: t.fgQuaternary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _EventSentence(
                            spans: [
                              TextSpan(
                                text: c.shortSha,
                                style: base.copyWith(
                                  fontFamily: ref.watch(codeFontFamilyProvider),
                                  color: t.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: ' ${c.title}',
                                style: base.copyWith(color: t.textTertiary),
                              ),
                            ],
                            timestamp: c.date,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A submitted review with no summary text: one verdict sentence, colored by
/// state and paired with a shape (the gutter icon) per the status rule.
class _ReviewVerdictRow extends StatelessWidget {
  const _ReviewVerdictRow({
    required this.entry,
    required this.threads,
    required this.replies,
  });

  final PrReviewEntry entry;

  /// The conversations this review started, already built. Null when none.
  final Widget? threads;

  /// The replies it posted into conversations it did not start. Null when none.
  final Widget? replies;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final author = _displayLogin(entry.review.author, l10n);
    final sentence = switch (entry.review.state) {
      PrReviewSubmissionState.approved => l10n.prTimelineApproved(author),
      PrReviewSubmissionState.changesRequested =>
        l10n.prTimelineChangesRequested(author),
      _ => l10n.prTimelineReviewed(author),
    };
    final mentions = [_NamedMention.maybeUser(entry.review.author, author)];
    final row = _EventSentence(
      spans: _eventSpans(context, sentence, mentions),
      timestamp: entry.review.submittedAt,
    );
    if (threads == null && replies == null) {
      return row;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [row, ?replies, ?threads],
    );
  }
}

/// A review's inline conversations, rendered under its timeline row.
///
/// This used to be a bare "N code comments" button that jumped to the Diff
/// tab. That is not enough: a comment whose line no longer exists is
/// **outdated**, cannot be anchored to a diff row and so is unreachable from
/// the Diff tab at all — the timeline is the only place it can still be read.
/// So each conversation renders here in full: what it was left against, the
/// whole reply chain, a reply box and resolve, exactly as in the diff.
class _ReviewCodeThreads extends StatelessWidget {
  const _ReviewCodeThreads({
    required this.threads,
    required this.controller,
    required this.isOpen,
    required this.isResolved,
    required this.isResolveBusy,
    required this.focusedThreadId,
    required this.keyFor,
    required this.onToggleCollapsed,
    required this.onSetResolved,
    required this.onOpenInDiff,
  });

  /// Conversations started by this review, oldest first.
  final List<ServerReviewThread> threads;
  final PrInlineCommentsController controller;

  // State lives on the timeline, not here: following a reply has to open a
  // conversation that may sit under a different review entry.
  final bool Function(ServerReviewThread) isOpen;
  final bool Function(ServerReviewThread) isResolved;
  final bool Function(ServerReviewThread) isResolveBusy;
  final String? focusedThreadId;
  final GlobalKey Function(String threadId) keyFor;
  final ValueChanged<ServerReviewThread> onToggleCollapsed;
  final Future<void> Function(ServerReviewThread, bool) onSetResolved;

  /// Jumps the Diff tab to a conversation's file. Not offered for an outdated
  /// one — there is no row left to jump to.
  final ValueChanged<ServerReviewThread> onOpenInDiff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(
              l10n.prTimelineCodeComments(threads.length),
              style: CcTypography.caption.copyWith(
                color: context.ds.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final thread in threads)
            _TimelineThreadCard(
              key: keyFor(thread.id),
              thread: thread,
              controller: controller,
              collapsed: !isOpen(thread),
              resolved: isResolved(thread),
              resolveBusy: isResolveBusy(thread),
              focused: focusedThreadId == thread.id,
              onToggleCollapsed: () => onToggleCollapsed(thread),
              onSetResolved: (v) => onSetResolved(thread, v),
              onOpenInDiff: thread.isOutdated
                  ? null
                  : () => onOpenInDiff(thread),
            ),
        ],
      ),
    );
  }
}

/// The replies a review posted into conversations it did NOT start.
///
/// Without these the entry renders as a bare "reviewed · 3 hours ago": the
/// person answered someone, and their words live in a thread anchored under an
/// earlier entry. Each row shows what they said and follows back to the
/// discussion — opening it if it was collapsed or resolved, and scrolling to it.
class _ReviewReplyRefs extends ConsumerWidget {
  const _ReviewReplyRefs({
    required this.replies,
    required this.repoFullName,
    required this.onFollow,
  });

  final List<ServerReviewReply> replies;
  final String repoFullName;
  final ValueChanged<ServerReviewReply> onFollow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final reply in replies)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: t.bgPrimary,
                border: Border.all(color: t.borderSecondary),
                borderRadius: AppRadii.brMd,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CcTappable(
                    onPressed: () => onFollow(reply),
                    semanticLabel: l10n.inReplyTo(reply.thread.path),
                    builder: (context, states) => Container(
                      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                      color: states.contains(WidgetState.hovered)
                          ? t.bgPrimaryHover
                          : t.bgSecondary,
                      child: Row(
                        children: [
                          Icon(AppIcons.reply, size: 13, color: t.textTertiary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.inReplyTo(reply.thread.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CcTypography.caption.copyWith(
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            AppIcons.arrowUp,
                            size: 12,
                            color: t.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: GitHubMarkdownBody(
                      data: reply.comment.body,
                      repoOwner: repoFullName.split('/').firstOrNull,
                      repoName: repoFullName.split('/').lastOrNull,
                      compact: true,
                      codeFontFamily: ref.watch(codeFontFamilyProvider),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One conversation in the timeline: what it was left against, then the
/// discussion itself.
class _TimelineThreadCard extends StatelessWidget {
  const _TimelineThreadCard({
    super.key,
    required this.thread,
    required this.controller,
    required this.collapsed,
    required this.resolved,
    required this.resolveBusy,
    required this.focused,
    required this.onToggleCollapsed,
    required this.onSetResolved,
    required this.onOpenInDiff,
  });

  final ServerReviewThread thread;
  final PrInlineCommentsController controller;
  final bool collapsed;
  final bool resolved;
  final bool resolveBusy;

  /// Whether this is the conversation just jumped to, drawn with an accent
  /// border so the eye lands on it after the scroll.
  final bool focused;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<bool> onSetResolved;
  final VoidCallback? onOpenInDiff;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final inline = inlineThreadFromServerThread(
      thread,
      unknownAuthorLabel: l10n.unknownAuthor,
      resolved: resolved,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.bgPrimary,
        border: Border.all(color: focused ? t.accent : t.borderSecondary),
        borderRadius: AppRadii.brMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThreadFileHeader(thread: thread, onOpenInDiff: onOpenInDiff),
          // The forge's own hunk, not the live diff: for an outdated
          // conversation this is the only surviving picture of the code it was
          // about, and for a current one it saves a trip to the Diff tab.
          if (thread.root.diffHunk.trim().isNotEmpty && !collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: ReviewDiffHunkSnippet(
                hunk: thread.root.diffHunk,
                path: thread.path,
              ),
            ),
          PrInlineThreadBlock(
            thread: inline,
            controller: controller,
            collapsed: collapsed,
            resolveBusy: resolveBusy,
            canResolve: thread.threadId != null,
            onToggleCollapsed: onToggleCollapsed,
            onSetResolved: onSetResolved,
          ),
        ],
      ),
    );
  }
}

/// The file a conversation was left on, with its line range, an outdated badge
/// when the line is gone, and a jump to the Diff tab when it is not.
class _ThreadFileHeader extends StatelessWidget {
  const _ThreadFileHeader({required this.thread, required this.onOpenInDiff});

  final ServerReviewThread thread;
  final VoidCallback? onOpenInDiff;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final start = thread.startLine;
    final end = thread.endLine;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        border: Border(bottom: BorderSide(color: t.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.fileCode, size: 13, color: t.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              thread.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: t.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (start != null && end != null) ...[
            const SizedBox(width: 8),
            Text(
              thread.isMultiLine
                  ? l10n.commentOnLinesRange(start, end)
                  : l10n.commentOnLine(end),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
          if (thread.isOutdated) ...[
            const SizedBox(width: 8),
            CcBadge(
              label: l10n.outdated,
              variant: CcBadgeVariant.warning,
              icon: AppIcons.clock,
            ),
          ],
          if (onOpenInDiff != null) ...[
            const SizedBox(width: 4),
            CcIconButton(
              onPressed: onOpenInDiff,
              icon: AppIcons.arrowRight,
              tooltip: l10n.viewInDiff,
            ),
          ],
        ],
      ),
    );
  }
}

/// A submitted review with a summary: a comment card carrying the verdict
/// chip in its header, with the code-comments jump row underneath.
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.entry,
    required this.pr,
    required this.prRef,
    required this.threads,
    required this.replies,
  });

  final PrReviewEntry entry;
  final PullRequest pr;
  final PrRef prRef;

  /// The conversations this review started, already built. Null when none.
  final Widget? threads;

  /// The replies it posted into conversations it did not start. Null when none.
  final Widget? replies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final review = entry.review;
    final (chipLabel, chipIcon, chipColor) = switch (review.state) {
      PrReviewSubmissionState.approved => (
        l10n.approved,
        AppIcons.check,
        ReviewStatusColors.success,
      ),
      PrReviewSubmissionState.changesRequested => (
        l10n.changesRequested,
        AppIcons.circleX,
        ReviewStatusColors.failure,
      ),
      _ => (l10n.commented, AppIcons.messageSquare, null),
    };
    final card = _ActivityCard(
      author: review.author,
      createdAt: review.submittedAt,
      body: review.body,
      repoFullName: pr.repoFullName,
      chip: _VerdictChip(label: chipLabel, icon: chipIcon, color: chipColor),
      footer: ReactionBar(
        reactions: review.reactions,
        onToggle: (content, {required add}) => toggleReaction(
          ref,
          ReactionTarget.review,
          reviewId: review.id,
          pr: prRef,
          content: content,
          add: add,
        ),
      ),
    );
    if (threads == null && replies == null) {
      return card;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [card, ?replies, ?threads],
    );
  }
}

/// A top-level conversation comment (human or bot) with its reaction bar.
/// The bar always renders: with no existing reactions it shows only the
/// add-reaction popover chip, which is the only way to react to a comment.
class _CommentCard extends ConsumerWidget {
  const _CommentCard({
    required this.entry,
    required this.pr,
    required this.prRef,
  });

  final PrCommentEntry entry;
  final PullRequest pr;
  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comment = entry.comment;
    return _ActivityCard(
      author: comment.user,
      createdAt: comment.createdAt,
      body: comment.body,
      repoFullName: pr.repoFullName,
      footer: ReactionBar(
        reactions: comment.reactions,
        onToggle: (content, {required add}) => toggleReaction(
          ref,
          ReactionTarget.issueComment,
          commentId: comment.id,
          pr: prRef,
          content: content,
          add: add,
        ),
      ),
    );
  }
}

/// The shared comment-card chrome: a header row (author, optional bot badge,
/// relative time, optional verdict chip) over a markdown body.
class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({
    required this.author,
    required this.createdAt,
    required this.body,
    required this.repoFullName,
    this.chip,
    this.footer,
  });

  final PrUser? author;
  final DateTime? createdAt;
  final String body;
  final String repoFullName;
  final Widget? chip;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final login = author?.login ?? '';
    final isBot = isGitHubBotLogin(login);
    final displayLogin = isBot
        ? login.substring(0, login.length - '[bot]'.length)
        : login;

    return Container(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: t.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                // The whole left cluster shares one Expanded so the trailing
                // chip is pushed flush right (a Flexible sibling next to a
                // Spacer would keep half the free space and strand the chip
                // mid-row).
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: _ClickableAuthorName(
                          login: login,
                          displayLogin: displayLogin.isEmpty
                              ? l10n.prTimelineSomeone
                              : displayLogin,
                          isBot: isBot,
                        ),
                      ),
                      if (isBot) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: t.borderSecondary),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            l10n.prTimelineBotBadge,
                            style: CcTypography.caption.copyWith(
                              color: t.textTertiary,
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                      if (createdAt != null) ...[
                        const SizedBox(width: 8),
                        AppTimestamp(
                          dateTime: createdAt!,
                          child: Text(
                            formatRelativeTime(context, createdAt),
                            style: CcTypography.caption.copyWith(
                              color: t.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (chip != null) ...[const SizedBox(width: 8), chip!],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: PrBodyMarkdown(body: body, repoFullName: repoFullName),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(alignment: Alignment.centerLeft, child: footer),
            ),
        ],
      ),
    );
  }
}

/// The review-verdict pill: color + icon + label, never color alone.
class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.label, required this.icon, this.color});

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = color ?? t.textSecondary;
    final bg = (color ?? t.fgTertiary).withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: CcTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clickable author login in a comment/review card header. The timeline
/// gutter already holds the avatar, so this is the name only.
class _ClickableAuthorName extends StatelessWidget {
  const _ClickableAuthorName({
    required this.login,
    required this.displayLogin,
    required this.isBot,
  });

  final String login;
  final String displayLogin;
  final bool isBot;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final name = Text(
      displayLogin,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CcTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: t.textPrimary,
      ),
    );
    if (login.isEmpty || isBot) {
      return name;
    }
    return GitHubUserHoverTarget(
      login: login,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final workspaceId = context.currentWorkspaceId;
            if (workspaceId == null) {
              return;
            }
            GoRouter.of(context).go(userProfileRoute(workspaceId, login));
          },
          behavior: HitTestBehavior.opaque,
          child: Semantics(button: true, label: displayLogin, child: name),
        ),
      ),
    );
  }
}

String _displayLogin(PrUser? user, AppLocalizations l10n) {
  final login = user?.login ?? '';
  if (login.isEmpty) {
    return l10n.prTimelineSomeone;
  }
  return isGitHubBotLogin(login)
      ? login.substring(0, login.length - '[bot]'.length)
      : login;
}
