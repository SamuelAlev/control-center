part of 'pr_activity_timeline.dart';

/// [_PrActivityTimelineState]'s feed rows and tree-ordered files, memoized
/// across builds.
mixin _FeedRowsMemo {
  // Memoized feed derivation. A rebuild for a press (expanding a thread, a
  // resolve in flight) or an unrelated watch used to re-group every review
  // thread, re-sort the file tree and rebuild the entry list from scratch.
  // Inputs are compared by identity: each is a provider snapshot that is only
  // replaced when the data actually changed.
  List<PrFile>? _filesIn;
  List<PrFile> _filesOut = const [];
  List<_FeedRow> _rowsOut = const [];
  PullRequest? _rowsPr;
  List<PrReviewSubmission>? _rowsReviews;
  List<IssueComment>? _rowsComments;
  List<PrCommit>? _rowsCommits;
  List<PrTimelineEvent>? _rowsEvents;
  List<PrCodeReviewComment>? _rowsCodeComments;

  List<PrFile> _orderedFilesFor(List<PrFile> files) {
    if (!identical(files, _filesIn)) {
      _filesIn = files;
      _filesOut = sortFilesByTreeOrder(files);
    }
    return _filesOut;
  }

  List<_FeedRow> _rowsFor({
    required PullRequest pr,
    required List<PrReviewSubmission> reviews,
    required List<IssueComment> comments,
    required List<PrCommit> commits,
    required List<PrTimelineEvent> events,
    required List<PrCodeReviewComment> codeComments,
  }) {
    if (identical(pr, _rowsPr) &&
        identical(reviews, _rowsReviews) &&
        identical(comments, _rowsComments) &&
        identical(commits, _rowsCommits) &&
        identical(events, _rowsEvents) &&
        identical(codeComments, _rowsCodeComments)) {
      return _rowsOut;
    }
    _rowsPr = pr;
    _rowsReviews = reviews;
    _rowsComments = comments;
    _rowsCommits = commits;
    _rowsEvents = events;
    _rowsCodeComments = codeComments;
    return _rowsOut = _buildRows(
      pr: pr,
      reviews: reviews,
      comments: comments,
      commits: commits,
      events: events,
      codeComments: codeComments,
    );
  }

  static List<_FeedRow> _buildRows({
    required PullRequest pr,
    required List<PrReviewSubmission> reviews,
    required List<IssueComment> comments,
    required List<PrCommit> commits,
    required List<PrTimelineEvent> events,
    required List<PrCodeReviewComment> codeComments,
  }) {
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

    // One sliver child per conversation so a review that started twenty
    // threads does not build (and markdown-parse) all twenty the moment
    // its verdict row enters the cache extent.
    final rows = <_FeedRow>[];
    for (final entry in entries) {
      if (entry is PrReviewEntry) {
        final threads = threadsByReview[entry.review.id] ?? const [];
        final replies = repliesByReview[entry.review.id] ?? const [];
        rows.add(_EntryRow(entry));
        if (replies.isNotEmpty) {
          rows.add(_RepliesRow(replies));
        }
        if (threads.isNotEmpty) {
          rows.add(_ThreadsIntroRow(entry.review.id, threads.length));
          for (final thread in threads) {
            rows.add(_ThreadRow(thread));
          }
        }
      } else {
        rows.add(_EntryRow(entry));
      }
    }
    return rows;
  }
}

/// One virtualised sliver child in the activity feed. A review's
/// conversations are unbundled so only on-screen cards build.
sealed class _FeedRow {
  const _FeedRow();
}

class _EntryRow extends _FeedRow {
  const _EntryRow(this.entry);
  final PrActivityEntry entry;
}

class _RepliesRow extends _FeedRow {
  const _RepliesRow(this.replies);
  final List<ServerReviewReply> replies;
}

class _ThreadsIntroRow extends _FeedRow {
  const _ThreadsIntroRow(this.reviewId, this.count);
  final int reviewId;
  final int count;
}

class _ThreadRow extends _FeedRow {
  const _ThreadRow(this.thread);
  final ServerReviewThread thread;
}
