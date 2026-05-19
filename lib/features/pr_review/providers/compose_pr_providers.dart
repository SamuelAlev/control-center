import 'package:cc_data/cc_data.dart'
    show prCommitFromWireDto, prFileFromWireDto;
import 'package:cc_domain/cc_domain.dart' show PrCommitDto, PrFileDto;
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Branch names available on the active repo's remote — the candidate set for
/// both the head and base of a new PR. Empty when no GitHub-linked repo is
/// active.
///
/// Fetched SERVER-SIDE over RPC (the thin client holds no GitHub token): the
/// host runs the gh query and orders the result for the compose pickers (the
/// server user's branches first, each group most-recent-commit first).
final repoBranchesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repo = ref.watch(activeRepoProvider);
  if (repo == null || !repo.hasGitHubRemote) {
    return const <String>[];
  }
  final data = await ref.watch(rpcClientProvider).call('github.repoBranches', {
    'owner': repo.githubOwner,
    'repo': repo.githubRepoName,
  });
  return [
    for (final b in (data['branches'] as List? ?? const [])) b as String,
  ];
});

/// The active repo's default branch (e.g. `main`) — the convenience default for
/// a new PR's base. Empty when no GitHub-linked repo is active. Resolved
/// SERVER-SIDE over RPC.
final defaultBranchProvider = FutureProvider.autoDispose<String>((ref) async {
  final repo = ref.watch(activeRepoProvider);
  if (repo == null || !repo.hasGitHubRemote) {
    return '';
  }
  final data = await ref.watch(rpcClientProvider).call('github.defaultBranch', {
    'owner': repo.githubOwner,
    'repo': repo.githubRepoName,
  });
  return data['branch'] as String? ?? '';
});

/// A pull-request template offered on the compose screen: a display `name`
/// (empty when `isDefault`), the markdown `body` it seeds, and whether it's the
/// repo's single default template (the UI localises that label).
typedef PrTemplateOption = ({String name, String body, bool isDefault});

/// The active repo's pull-request template(s), discovered SERVER-SIDE over RPC
/// from the conventional GitHub locations. Empty when the repo has no template
/// or no GitHub-linked repo is active. Re-fetches when the active repo changes.
final prTemplatesProvider = FutureProvider.autoDispose<List<PrTemplateOption>>((
  ref,
) async {
  final repo = ref.watch(activeRepoProvider);
  if (repo == null || !repo.hasGitHubRemote) {
    return const <PrTemplateOption>[];
  }
  final data = await ref.watch(rpcClientProvider).call('github.prTemplates', {
    'owner': repo.githubOwner,
    'repo': repo.githubRepoName,
  });
  return [
    for (final t in (data['templates'] as List? ?? const []))
      (
        name: (t as Map)['name'] as String? ?? '',
        body: t['body'] as String? ?? '',
        isDefault: t['is_default'] as bool? ?? false,
      ),
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

/// Compares `key.base`...`key.head` on the active repo, SERVER-SIDE over RPC.
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
      final data = await ref
          .watch(rpcClientProvider)
          .call('github.compareBranches', {
            'owner': repo.githubOwner,
            'repo': repo.githubRepoName,
            'base': key.base,
            'head': key.head,
          });
      final c = data['comparison'];
      if (c is! Map) {
        return null;
      }
      final m = c.cast<String, dynamic>();
      return (
        files: [
          for (final f in (m['files'] as List? ?? const []))
            prFileFromWireDto(
              PrFileDto.fromJson((f as Map).cast<String, dynamic>()),
            ),
        ],
        commits: [
          for (final cm in (m['commits'] as List? ?? const []))
            prCommitFromWireDto(
              PrCommitDto.fromJson((cm as Map).cast<String, dynamic>()),
            ),
        ],
        additions: (m['additions'] as num?)?.toInt() ?? 0,
        deletions: (m['deletions'] as num?)?.toInt() ?? 0,
        totalCommits: (m['total_commits'] as num?)?.toInt() ?? 0,
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
