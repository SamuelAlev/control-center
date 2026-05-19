import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// One row of the Overview activity feed, in display order. Pure data — the
/// widget layer decides how each variant renders (compact event row vs.
/// comment card).
sealed class PrActivityEntry {
  const PrActivityEntry();

  /// When the entry happened; null sorts to the top (unknown legacy data).
  DateTime? get timestamp;
}

/// "{author} opened this pull request with N commits" — always first.
class PrOpenedEntry extends PrActivityEntry {
  /// PrOpenedEntry.
  const PrOpenedEntry({
    required this.author,
    required this.commitsCount,
    required this.timestamp,
  });

  /// PR author (null when the forge omitted it).
  final PrUser? author;

  /// Number of commits on the PR at load time.
  final int commitsCount;

  @override
  final DateTime? timestamp;
}

/// A reviewer named in a [PrReviewRequestEntry] burst.
class PrReviewerMention {
  /// PrReviewerMention.
  const PrReviewerMention({
    required this.name,
    this.isTeam = false,
    this.avatarUrl = '',
  });

  /// User login or team name.
  final String name;

  /// Whether [name] is a team.
  final bool isTeam;

  /// Avatar URL for a user reviewer or team logo. Empty when unknown.
  final String avatarUrl;
}

/// "{actor} requested review from A, B and removed the review request for C".
/// Consecutive per-reviewer forge events by the same actor within a short
/// window collapse into one row, mixing requests and removals (see
/// [buildPrActivityEntries]). Names are the net of the burst: a reviewer
/// requested then dropped in the same burst lands only in [removed].
class PrReviewRequestEntry extends PrActivityEntry {
  /// PrReviewRequestEntry.
  const PrReviewRequestEntry({
    required this.actor,
    this.requested = const [],
    this.removed = const [],
    required this.timestamp,
  });

  /// Who (re-)requested or withdrew the review.
  final PrUser? actor;

  /// Reviewers still requested at the end of the burst, in first-seen order.
  final List<PrReviewerMention> requested;

  /// Reviewers whose request was withdrawn by the end of the burst, in
  /// first-seen order.
  final List<PrReviewerMention> removed;

  /// Logins / team names in [requested], for copy and tests.
  List<String> get requestedNames => [for (final m in requested) m.name];

  /// Logins / team names in [removed], for copy and tests.
  List<String> get removedNames => [for (final m in removed) m.name];

  @override
  final DateTime? timestamp;
}

/// A submitted review — a compact verdict row when [PrReviewSubmission.body]
/// is empty, a comment card with a verdict chip otherwise.
class PrReviewEntry extends PrActivityEntry {
  /// PrReviewEntry.
  const PrReviewEntry({required this.review});

  /// The review submission.
  final PrReviewSubmission review;

  @override
  DateTime? get timestamp => review.submittedAt;
}

/// A top-level conversation comment (humans and bots alike).
class PrCommentEntry extends PrActivityEntry {
  /// PrCommentEntry.
  const PrCommentEntry({required this.comment});

  /// The issue comment.
  final IssueComment comment;

  @override
  DateTime? get timestamp => comment.createdAt;
}

/// "{author} committed {sha} {message}".
class PrCommitEntry extends PrActivityEntry {
  /// PrCommitEntry.
  const PrCommitEntry({required this.commit});

  /// The commit.
  final PrCommit commit;

  @override
  DateTime? get timestamp => commit.date;
}

/// "{author} pushed N commits" — a collapsed accordion over a contiguous run
/// of 2+ commits by the same author (no other activity in between). Expanding
/// it reveals the individual commits.
class PrCommitGroupEntry extends PrActivityEntry {
  /// PrCommitGroupEntry.
  const PrCommitGroupEntry({required this.commits});

  /// The run's commits, in feed order. Always 2+ and single-authored.
  final List<PrCommit> commits;

  /// The run's author (they all share one).
  PrUser? get author => commits.first.author;

  @override
  DateTime? get timestamp => commits.first.date;
}

/// Merges the PR's conversation streams into one chronological activity feed:
/// the opened event, grouped review-request/remove events, submitted reviews,
/// issue comments and commits — ascending by time (nulls first, insertion
/// order as the tie-break). Inline code comments deliberately stay out: they
/// render in the diff.
List<PrActivityEntry> buildPrActivityEntries({
  required PullRequest pr,
  required List<PrReviewSubmission> reviews,
  required List<IssueComment> comments,
  required List<PrCommit> commits,
  required List<PrTimelineEvent> events,
}) {
  /// GitHub emits one event per reviewer for a single "request review from
  /// A, B, C" action and a person tweaking the list (add, drop, add) lands
  /// as a run of mixed request/remove events. Same-actor events collapse
  /// while each is within this window of the previous one.
  const requestGroupWindow = Duration(hours: 1);

  final entries = <PrActivityEntry>[
    PrOpenedEntry(
      author: pr.author,
      commitsCount: pr.commitsCount,
      timestamp: pr.createdAt,
    ),
  ];

  var burstOpen = false;
  PrUser? burstActor;
  DateTime? burstStartedAt;
  DateTime? burstLastAt;
  final burstRequested = <PrReviewerMention>[];
  final burstRemoved = <PrReviewerMention>[];

  void applyToBurst(PrTimelineEvent e) {
    final name = e.reviewerName;
    if (name.isEmpty) {
      return;
    }
    final mention = PrReviewerMention(
      name: name,
      isTeam: e.reviewerIsTeam,
      avatarUrl: e.reviewerAvatarUrl,
    );
    if (e.kind == PrTimelineEventKind.reviewRequestRemoved) {
      burstRequested.removeWhere((m) => m.name == name);
      if (!burstRemoved.any((m) => m.name == name)) {
        burstRemoved.add(mention);
      }
    } else {
      burstRemoved.removeWhere((m) => m.name == name);
      if (!burstRequested.any((m) => m.name == name)) {
        burstRequested.add(mention);
      }
    }
  }

  void flushBurst() {
    if (!burstOpen) {
      return;
    }
    if (burstRequested.isNotEmpty || burstRemoved.isNotEmpty) {
      entries.add(
        PrReviewRequestEntry(
          actor: burstActor,
          requested: List<PrReviewerMention>.unmodifiable(
            List.of(burstRequested),
          ),
          removed: List<PrReviewerMention>.unmodifiable(List.of(burstRemoved)),
          timestamp: burstStartedAt,
        ),
      );
    }
    burstOpen = false;
    burstActor = null;
    burstStartedAt = null;
    burstLastAt = null;
    burstRequested.clear();
    burstRemoved.clear();
  }

  for (final e in events) {
    final prev = burstLastAt;
    final at = e.createdAt;
    final sameBurst =
        burstOpen &&
        burstActor?.login == e.actor?.login &&
        prev != null &&
        at != null &&
        at.difference(prev).abs() <= requestGroupWindow;
    if (sameBurst) {
      applyToBurst(e);
      burstLastAt = at;
    } else {
      flushBurst();
      burstOpen = true;
      burstActor = e.actor;
      burstStartedAt = e.createdAt;
      burstLastAt = e.createdAt;
      applyToBurst(e);
    }
  }
  flushBurst();

  entries.addAll([
    // Pending = a draft the reviewer hasn't submitted; not activity yet.
    for (final r in reviews)
      if (r.state != PrReviewSubmissionState.pending) PrReviewEntry(review: r),
    for (final c in comments) PrCommentEntry(comment: c),
    for (final c in commits) PrCommitEntry(commit: c),
  ]);

  // Ascending by time with insertion order as the tie-break (List.sort is not
  // stable); null timestamps first, keeping their relative order.
  final indexed = entries.indexed.toList()
    ..sort((a, b) {
      final ta = a.$2.timestamp;
      final tb = b.$2.timestamp;
      if (ta == null || tb == null) {
        if (ta == null && tb == null) {
          return a.$1.compareTo(b.$1);
        }
        return ta == null ? -1 : 1;
      }
      final byTime = ta.compareTo(tb);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return _groupCommitRuns([for (final (_, e) in indexed) e]);
}

/// Collapses contiguous runs of 2+ [PrCommitEntry]s by the same (known)
/// author into one [PrCommitGroupEntry]. Runs after sorting, so any other
/// entry landing between two commits breaks the run — "pushed N commits"
/// only compacts genuinely back-to-back pushes.
List<PrActivityEntry> _groupCommitRuns(List<PrActivityEntry> sorted) {
  final out = <PrActivityEntry>[];
  final run = <PrCommit>[];

  void flush() {
    if (run.length >= 2) {
      out.add(PrCommitGroupEntry(commits: List.unmodifiable(run)));
    } else {
      out.addAll(run.map((c) => PrCommitEntry(commit: c)));
    }
    run.clear();
  }

  for (final e in sorted) {
    final login = e is PrCommitEntry ? (e.commit.author?.login ?? '') : '';
    if (e is PrCommitEntry && login.isNotEmpty) {
      if (run.isNotEmpty && run.first.author?.login != login) {
        flush();
      }
      run.add(e.commit);
    } else {
      flush();
      out.add(e);
    }
  }
  flush();
  return out;
}
