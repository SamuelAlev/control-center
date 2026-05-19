import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/pr_needs_your_review.dart';

/// One section of the PR inbox, in display order.
///
/// The top sections are reviewer-centric ("what needs me"), the rest are
/// author-centric ("where are my PRs"). Every PR relevant to the operator
/// lands in exactly one section; PRs that neither involve them as reviewer
/// nor author are excluded (the by-repo queue still lists everything).
enum PrInboxSection {
  /// Open, non-draft PRs by others whose review request names the operator
  /// or a team they belong to.
  needsYourReview,

  /// The operator's PRs a reviewer sent back (changes requested) or that CI
  /// failed on — the ball returned to their court.
  returnedToYou,

  /// The operator's PRs that are approved and ready to land.
  approved,

  /// The operator's draft PRs.
  drafts,

  /// The operator's open PRs still waiting on review.
  waitingForReviewers,

  /// The operator's recently merged PRs (within the classifier's window).
  mergingAndMerged,

  /// PRs the operator reviewed that are now waiting on their author.
  waitingForAuthor,
}

/// One classified inbox row: the PR plus the repo it belongs to (needed for
/// navigation and repo-scoped filtering).
class PrInboxItem {
  /// Creates a [PrInboxItem].
  const PrInboxItem({required this.pr, required this.repo});

  /// The pull request.
  final PullRequest pr;

  /// The repo the PR belongs to.
  final Repo repo;

  /// Stable identity: `owner/repo#number`.
  String get key => '${pr.repoFullName}#${pr.number}';

  @override
  bool operator ==(Object other) => other is PrInboxItem && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// The classified inbox: every [PrInboxSection] mapped to its items (present
/// even when empty, so the UI renders a stable section list).
class PrInboxData {
  /// Creates a [PrInboxData].
  PrInboxData({required this.sections}) {
    if (!PrInboxSection.values.every(sections.containsKey)) {
      throw ArgumentError('every section must be present');
    }
  }

  /// An empty inbox (every section present, no items).
  factory PrInboxData.empty() => PrInboxData(
    sections: {for (final s in PrInboxSection.values) s: const <PrInboxItem>[]},
  );

  /// Items per section; every section key is present.
  final Map<PrInboxSection, List<PrInboxItem>> sections;

  /// The items of [section].
  List<PrInboxItem> of(PrInboxSection section) => sections[section]!;

  /// Total item count across all sections.
  int get total => sections.values.fold(0, (sum, v) => sum + v.length);

  /// Whether no section holds any item.
  bool get isEmpty => total == 0;
}

/// Classifies the workspace's PRs into the inbox's sections.
///
/// Pure and synchronous: callers feed it the open-PR snapshot, the operator's
/// recently merged PRs and the reviewed-by-me key set; it never fetches.
class ClassifyPrInboxUseCase {
  /// Creates a [ClassifyPrInboxUseCase].
  const ClassifyPrInboxUseCase();

  /// Default window for [PrInboxSection.mergingAndMerged].
  static const defaultMergedWindow = Duration(days: 7);

  /// Classifies [openByRepo] (the live open-PR snapshot) and [mergedByRepo]
  /// (the operator's merged/closed PR history).
  ///
  /// [viewerLoginByForge] is the operator's account name **per forge**. One
  /// workspace may hold repos on several forges and the same human has a
  /// different login on each, so "is this mine?" is resolved through the forge
  /// of the repo each PR belongs to — never against one global login, which
  /// would silently drop every PR on the other forges.
  ///
  /// [reviewedByMeKeys] holds `"owner/repo#number"` keys of open PRs the
  /// operator has already reviewed (the lazily-fetched overlay) — it drives
  /// [PrInboxSection.waitingForAuthor]. [viewerTeamsByOrg] is the operator's
  /// teams (org → slugs, lower-cased) so a still-pending team request counts as
  /// Needs your review; forges without teams simply contribute nothing to it.
  /// [mergedWindow] bounds how far back [PrInboxSection.mergingAndMerged]
  /// reaches.
  PrInboxData execute({
    required List<RepoPullRequests> openByRepo,
    required Map<ForgeHost, String> viewerLoginByForge,
    List<RepoPullRequests> mergedByRepo = const [],
    Set<String> reviewedByMeKeys = const {},
    Map<String, Set<String>> viewerTeamsByOrg = const {},
    DateTime? now,
    Duration mergedWindow = defaultMergedWindow,
  }) {
    final loginByForge = {
      for (final e in viewerLoginByForge.entries) e.key: e.value.toLowerCase(),
    };
    final effectiveNow = now ?? DateTime.now();
    final sections = {
      for (final s in PrInboxSection.values) s: <PrInboxItem>[],
    };

    if (loginByForge.values.every((l) => l.isEmpty)) {
      return PrInboxData(sections: sections);
    }

    final openKeys = <String>{};
    for (final rp in openByRepo) {
      final me = loginByForge[rp.repo.forge] ?? '';
      if (me.isEmpty) {
        continue;
      }
      for (final pr in rp.prs) {
        if (!pr.isOpen) {
          continue;
        }
        final item = PrInboxItem(pr: pr, repo: rp.repo);
        openKeys.add(item.key);
        final section = _classifyOpen(
          pr,
          me: me,
          reviewedByMe: pr.reviewedByMe || reviewedByMeKeys.contains(item.key),
          viewerTeamsByOrg: viewerTeamsByOrg,
        );
        if (section != null) {
          sections[section]!.add(item);
        }
      }
    }

    for (final rp in mergedByRepo) {
      final me = loginByForge[rp.repo.forge] ?? '';
      if (me.isEmpty) {
        continue;
      }
      for (final pr in rp.prs) {
        if (!pr.isMerged || pr.author?.login.toLowerCase() != me) {
          continue;
        }
        final mergedAt = pr.mergedAt;
        if (mergedAt == null ||
            effectiveNow.difference(mergedAt) > mergedWindow) {
          continue;
        }
        final item = PrInboxItem(pr: pr, repo: rp.repo);
        // The merged feed can lag the open snapshot; never double-list.
        if (openKeys.contains(item.key)) {
          continue;
        }
        sections[PrInboxSection.mergingAndMerged]!.add(item);
      }
    }

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    for (final entry in sections.entries) {
      if (entry.key == PrInboxSection.mergingAndMerged) {
        entry.value.sort(
          (a, b) => (b.pr.mergedAt ?? epoch).compareTo(a.pr.mergedAt ?? epoch),
        );
      } else {
        entry.value.sort(
          (a, b) =>
              (b.pr.updatedAt ?? epoch).compareTo(a.pr.updatedAt ?? epoch),
        );
      }
    }

    return PrInboxData(sections: sections);
  }

  /// Places one open PR, or returns null when the inbox excludes it (someone
  /// else's PR that neither requests the operator nor was reviewed by them).
  PrInboxSection? _classifyOpen(
    PullRequest pr, {
    required String me,
    required bool reviewedByMe,
    required Map<String, Set<String>> viewerTeamsByOrg,
  }) {
    final mine = pr.author?.login.toLowerCase() == me;

    if (mine) {
      if (pr.isDraft) {
        return PrInboxSection.drafts;
      }
      if (pr.reviewDecision == PrReviewDecision.changesRequested ||
          pr.checksStatus == PrChecksStatus.failing) {
        return PrInboxSection.returnedToYou;
      }
      if (pr.reviewDecision == PrReviewDecision.approved) {
        return PrInboxSection.approved;
      }
      return PrInboxSection.waitingForReviewers;
    }

    // GitHub drops the operator (or their team) from reviewRequests once
    // they review, so an open request is by definition still awaiting them.
    // Drafts are not reviewable yet — they surface once marked ready.
    if (prNeedsYourReview(
      isDraft: pr.isDraft,
      authorLogin: pr.author?.login,
      viewerLogin: me,
      requestedUserLogins: pr.requestedReviewers.map((r) => r.login),
      requestedTeamSlugs: pr.requestedTeamSlugs,
      repoFullName: pr.repoFullName,
      viewerTeamsByOrg: viewerTeamsByOrg,
    )) {
      return PrInboxSection.needsYourReview;
    }
    if (reviewedByMe) {
      return PrInboxSection.waitingForAuthor;
    }
    return null;
  }
}
