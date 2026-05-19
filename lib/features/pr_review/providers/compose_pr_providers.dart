import 'package:control_center/core/network/github_graphql_client.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/data/mappers/pr_review_mapper.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Branch names available on the active repo's remote — the candidate set for
/// both the head and base of a new PR. Empty when no GitHub-linked repo is
/// active.
///
/// Ordered for the compose pickers: the current user's branches first (by most
/// recent commit), then everyone else's (also most-recent first). Branches with
/// unknown commit dates sort last within their group.
final repoBranchesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repo = ref.watch(activeRepoProvider);
  if (repo == null || !repo.hasGitHubRemote) {
    return const <String>[];
  }
  final currentLogin = ref.watch(currentUserLoginProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  final branches = await ref
      .read(githubApiClientProvider)
      .graphql
      .listBranchesWithActivity(
        repo.githubOwner,
        repo.githubRepoName,
        cancelToken: cancelToken,
      );

  int byRecencyDesc(GitHubBranchActivity a, GitHubBranchActivity b) {
    final da = a.committedDate;
    final db = b.committedDate;
    if (da == null && db == null) {
      return 0;
    }
    if (da == null) {
      return 1;
    }
    if (db == null) {
      return -1;
    }
    return db.compareTo(da);
  }

  final sorted = branches.toList()..sort(byRecencyDesc);
  final mine = <String>[];
  final others = <String>[];
  for (final b in sorted) {
    if (currentLogin.isNotEmpty &&
        b.authorLogin?.toLowerCase() == currentLogin) {
      mine.add(b.name);
    } else {
      others.add(b.name);
    }
  }
  return [...mine, ...others];
});

/// The active repo's default branch (e.g. `main`) — the convenience default for
/// a new PR's base. Empty when no GitHub-linked repo is active.
final defaultBranchProvider = FutureProvider.autoDispose<String>((ref) {
  final repo = ref.watch(activeRepoProvider);
  if (repo == null || !repo.hasGitHubRemote) {
    return Future.value('');
  }
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(githubApiClientProvider)
      .pr
      .getDefaultBranch(
        repo.githubOwner,
        repo.githubRepoName,
        cancelToken: cancelToken,
      );
});

/// A pull-request template offered on the compose screen: a display `name`
/// (empty when `isDefault`), the markdown `body` it seeds, and whether it's the
/// repo's single default template (the UI localises that label).
typedef PrTemplateOption = ({String name, String body, bool isDefault});

/// The active repo's pull-request template(s), discovered from the conventional
/// GitHub locations (`pull_request_template.md` in root/`docs`/`.github`, plus
/// any named templates under a `PULL_REQUEST_TEMPLATE/` directory). Empty when
/// the repo has no template or no GitHub-linked repo is active — the compose
/// body then stays blank. Re-fetches when the active repo changes.
final prTemplatesProvider = FutureProvider.autoDispose<List<PrTemplateOption>>((
  ref,
) async {
  final repo = ref.watch(activeRepoProvider);
  if (repo == null || !repo.hasGitHubRemote) {
    return const <PrTemplateOption>[];
  }
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  final templates = await ref
      .read(githubApiClientProvider)
      .graphql
      .fetchPullRequestTemplates(
        repo.githubOwner,
        repo.githubRepoName,
        cancelToken: cancelToken,
      );
  return [
    for (final t in templates)
      (name: t.name, body: t.body, isDefault: t.isDefault),
  ];
});

/// Key for [branchComparisonProvider]: the base and head branch to diff.
typedef CompareKey = ({String base, String head});

/// The diff of `base...head` on the active repo: the changed files (ready for
/// the diff viewer) plus summary totals. Re-fetches whenever the base or head
/// changes. Returns null when either branch is empty (nothing to compare yet).
typedef ComposeDiff = ({
  List<PrFile> files,
  List<PrCommit> commits,
  int additions,
  int deletions,
  int totalCommits,
});

/// Compares `key.base`...`key.head` on the active repo.
final branchComparisonProvider = FutureProvider.autoDispose
    .family<ComposeDiff?, CompareKey>((ref, key) async {
      final repo = ref.watch(activeRepoProvider);
      if (repo == null ||
          !repo.hasGitHubRemote ||
          key.base.isEmpty ||
          key.head.isEmpty ||
          key.base == key.head) {
        return null;
      }
      final cancelToken = CancelToken();
      ref.onDispose(cancelToken.cancel);
      final comparison = await ref
          .read(githubApiClientProvider)
          .pr
          .compareBranches(
            repo.githubOwner,
            repo.githubRepoName,
            base: key.base,
            head: key.head,
            cancelToken: cancelToken,
          );
      return (
        files: comparison.files.map(prFileFromGitHub).toList(growable: false),
        commits: comparison.commits
            .map(prCommitFromGitHub)
            .toList(growable: false),
        additions: comparison.additions,
        deletions: comparison.deletions,
        totalCommits: comparison.totalCommits,
      );
    });

/// Form state for composing a new pull request. Selections are staged here and
/// only committed to GitHub on [ComposePrNotifier.submit].
class ComposePrState {
  /// Creates a [ComposePrState].
  const ComposePrState({
    this.base = '',
    this.head = '',
    this.title = '',
    this.body = '',
    this.assignees = const [],
    this.reviewers = const [],
    this.submitting = false,
    this.error,
  });

  /// Base branch the PR will merge into.
  final String base;

  /// Head branch carrying the changes.
  final String head;

  /// PR title.
  final String title;

  /// PR description (markdown).
  final String body;

  /// Staged assignees.
  final List<PrUser> assignees;

  /// Staged reviewers (users and teams).
  final List<PrReviewerCandidate> reviewers;

  /// Whether a create call is in flight.
  final bool submitting;

  /// The last submit error, if any.
  final String? error;

  /// Whether the form has the minimum needed to open a PR.
  bool get canSubmit =>
      !submitting &&
      base.isNotEmpty &&
      head.isNotEmpty &&
      base != head &&
      title.trim().isNotEmpty;

  /// Returns a copy with the given fields replaced. Pass [clearError] to drop
  /// a stale error.
  ComposePrState copyWith({
    String? base,
    String? head,
    String? title,
    String? body,
    List<PrUser>? assignees,
    List<PrReviewerCandidate>? reviewers,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) {
    return ComposePrState(
      base: base ?? this.base,
      head: head ?? this.head,
      title: title ?? this.title,
      body: body ?? this.body,
      assignees: assignees ?? this.assignees,
      reviewers: reviewers ?? this.reviewers,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the compose-PR form and the create-on-GitHub commit.
class ComposePrNotifier extends Notifier<ComposePrState> {
  @override
  ComposePrState build() => const ComposePrState();

  /// Clears the staged base/head branches. Called when the active repo changes:
  /// the previously-staged branches belong to the old repo and don't exist on
  /// the new one, so comparing or opening a PR against them would fail (and the
  /// branch pickers would hold a value absent from their replaced item list).
  /// The base re-defaults to the new repo's default branch via the screen's
  /// [defaultBranchProvider] listener once it resolves.
  void resetBranches() {
    if (state.base.isNotEmpty || state.head.isNotEmpty) {
      state = state.copyWith(base: '', head: '');
    }
  }

  /// Sets the base branch.
  void setBase(String branch) => state = state.copyWith(base: branch);

  /// Sets the head branch.
  void setHead(String branch) => state = state.copyWith(head: branch);

  /// Sets the title.
  void setTitle(String title) => state = state.copyWith(title: title);

  /// Sets the body markdown.
  void setBody(String body) => state = state.copyWith(body: body);

  /// Replaces the staged assignees.
  void setAssignees(List<PrUser> assignees) =>
      state = state.copyWith(assignees: List.unmodifiable(assignees));

  /// Replaces the staged reviewers.
  void setReviewers(List<PrReviewerCandidate> reviewers) =>
      state = state.copyWith(reviewers: List.unmodifiable(reviewers));

  /// Removes a staged assignee by login.
  void removeAssignee(String login) => state = state.copyWith(
    assignees: List.unmodifiable(
      state.assignees.where((a) => a.login != login),
    ),
  );

  /// Removes a staged reviewer by selection key.
  void removeReviewer(String selectionKey) => state = state.copyWith(
    reviewers: List.unmodifiable(
      state.reviewers.where((r) => r.selectionKey != selectionKey),
    ),
  );

  /// Creates the PR on GitHub (as a draft when [asDraft]). Returns the new PR
  /// number on success, or null on failure (with [ComposePrState.error] set).
  Future<int?> submit({required bool asDraft}) async {
    if (!state.canSubmit) {
      return null;
    }
    final repo = ref.read(activeRepoProvider);
    if (repo == null || !repo.hasGitHubRemote) {
      state = state.copyWith(error: 'No GitHub repository is selected.');
      return null;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      state = state.copyWith(error: 'No active workspace.');
      return null;
    }

    state = state.copyWith(submitting: true, clearError: true);
    final lifecycle = ref.read(prLifecycleRepositoryProvider);
    try {
      final prId = await lifecycle.createDraft(
        workspaceId: workspaceId,
        title: state.title.trim(),
        body: state.body,
      );
      final reviewerUsers = [
        for (final r in state.reviewers)
          if (r.kind == ReviewerKind.user) r.key,
      ];
      final reviewerTeams = [
        for (final r in state.reviewers)
          if (r.kind == ReviewerKind.team) r.key,
      ];
      final result = await lifecycle.createOnGitHub(
        prId: prId,
        owner: repo.githubOwner,
        repo: repo.githubRepoName,
        title: state.title.trim(),
        body: state.body,
        head: state.head,
        base: state.base,
        draft: asDraft,
        assignees: [for (final a in state.assignees) a.login],
        reviewerUsers: reviewerUsers,
        reviewerTeams: reviewerTeams,
      );
      final number = result['number'] as int?;
      if (number == null) {
        // The draft row exists but GitHub didn't return a PR — surface it
        // rather than navigating to a non-existent PR.
        await lifecycle.delete(prId);
        state = state.copyWith(
          submitting: false,
          error: 'GitHub did not return a pull request.',
        );
        return null;
      }
      state = state.copyWith(submitting: false);
      return number;
    } catch (e) {
      state = state.copyWith(submitting: false, error: '$e');
      return null;
    }
  }
}

/// The compose-PR form notifier. Auto-disposes so each visit to the compose
/// screen starts from a clean form.
final composePrProvider =
    NotifierProvider.autoDispose<ComposePrNotifier, ComposePrState>(
      ComposePrNotifier.new,
    );
