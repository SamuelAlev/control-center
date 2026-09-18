import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-flight edit state for a single PR's title/body/assignees/reviewers.
///
/// Keeps the "saving" flags and the optimistic in-flight sets in one place so
/// each editing widget (title field, body editor, sidebar rows/pickers) stays
/// a dumb view that just reflects this state.
class PrEditState {
  /// Creates a [PrEditState].
  const PrEditState({
    this.savingTitle = false,
    this.savingBody = false,
    this.optimisticBody,
    this.optimisticComments = const {},
    this.savingCommentIds = const {},
    this.pendingAssignees = const {},
    this.pendingReviewers = const {},
  });

  /// Whether a title save is in flight.
  final bool savingTitle;

  /// Whether a body save is in flight.
  final bool savingBody;

  /// Markdown body shown while a checkbox toggle (or other body save) is in
  /// flight, so the box does not snap back until the detail stream catches up.
  final String? optimisticBody;

  /// Per-comment markdown shown while a checkbox toggle is in flight.
  final Map<int, String> optimisticComments;

  /// Comment ids whose body save is in flight.
  final Set<int> savingCommentIds;

  /// User logins (lowercased) whose assignee add/remove is in flight.
  final Set<String> pendingAssignees;

  /// Reviewer selection keys (`user:<login>` / `team:<slug>`) whose change is
  /// in flight.
  final Set<String> pendingReviewers;

  /// Returns a copy with the given fields replaced.
  PrEditState copyWith({
    bool? savingTitle,
    bool? savingBody,
    String? optimisticBody,
    bool clearOptimisticBody = false,
    Map<int, String>? optimisticComments,
    Set<int>? savingCommentIds,
    Set<String>? pendingAssignees,
    Set<String>? pendingReviewers,
  }) {
    return PrEditState(
      savingTitle: savingTitle ?? this.savingTitle,
      savingBody: savingBody ?? this.savingBody,
      optimisticBody: clearOptimisticBody
          ? null
          : (optimisticBody ?? this.optimisticBody),
      optimisticComments: optimisticComments ?? this.optimisticComments,
      savingCommentIds: savingCommentIds ?? this.savingCommentIds,
      pendingAssignees: pendingAssignees ?? this.pendingAssignees,
      pendingReviewers: pendingReviewers ?? this.pendingReviewers,
    );
  }
}

/// Drives PR metadata edits: calls the repository, flips loading/optimistic
/// flags and invalidates the relevant providers so the streams re-fetch. Each
/// mutating method returns `null` on success or an error message on failure
/// (the caller surfaces it via a snackbar — the notifier has no context).
class PrEditNotifier extends Notifier<PrEditState> {
  /// Creates a [PrEditNotifier] for [pr].
  PrEditNotifier(this.pr);

  /// The PR this notifier manages: repo coords + number, so every edit lands
  /// on the PR's OWN repo — a number alone is ambiguous across repos.
  final PrRef pr;

  @override
  PrEditState build() {
    ref.listen(prDetailProvider(pr), (previous, next) {
      final body = next.asData?.value?.body;
      if (body != null && state.optimisticBody == body) {
        state = state.copyWith(clearOptimisticBody: true);
      }
    });
    ref.listen(prIssueCommentsProvider(pr), (previous, next) {
      final comments = next.asData?.value;
      if (comments == null || state.optimisticComments.isEmpty) {
        return;
      }
      final remaining = Map<int, String>.of(state.optimisticComments);
      var changed = false;
      for (final comment in comments) {
        if (remaining[comment.id] == comment.body) {
          remaining.remove(comment.id);
          changed = true;
        }
      }
      if (changed) {
        state = state.copyWith(optimisticComments: remaining);
      }
    });
    return const PrEditState();
  }

  /// The PR number this notifier edits, sourced from [pr].
  int get prNumber => pr.number;

  PrReviewRepository? get _repo => ref.read(prRepositoryProvider(pr));

  void _refreshDetail() => ref.invalidate(prDetailProvider(pr));

  void _refreshReviewers() {
    ref.invalidate(prReviewersProvider(pr));
    ref.invalidate(prDetailProvider(pr));
  }

  static String _msg(Object e) => e is AppException ? e.message : e.toString();

  /// Saves the PR [title]. Returns null on success, else an error message.
  Future<String?> saveTitle(String title) async {
    final repo = _repo;
    if (repo == null) {
      return null;
    }
    state = state.copyWith(savingTitle: true);
    try {
      await repo.updatePullRequest(prNumber: prNumber, title: title);
      _refreshDetail();
      return null;
    } catch (e) {
      return _msg(e);
    } finally {
      state = state.copyWith(savingTitle: false);
    }
  }

  /// Saves the PR [body] (markdown). Returns null on success, else an error.
  Future<String?> saveBody(String body) async {
    final repo = _repo;
    if (repo == null) {
      return null;
    }
    state = state.copyWith(savingBody: true, optimisticBody: body);
    try {
      await repo.updatePullRequest(prNumber: prNumber, body: body);
      _refreshDetail();
      return null;
    } catch (e) {
      state = state.copyWith(clearOptimisticBody: true);
      return _msg(e);
    } finally {
      state = state.copyWith(savingBody: false);
    }
  }

  /// Ticks or unticks the [index]-th GFM task-list checkbox in [currentBody]
  /// and PATCHes the PR. Returns null on success, else an error message.
  Future<String?> toggleTaskListItem({
    required String currentBody,
    required int index,
  }) async {
    if (state.savingBody) {
      return null;
    }
    final source = state.optimisticBody ?? currentBody;
    final next = toggleMarkdownTaskListItem(source, index);
    if (next == null || next == source) {
      return null;
    }
    return saveBody(next);
  }

  /// Ticks or unticks the [index]-th GFM task-list checkbox in a conversation
  /// comment and PATCHes it. Returns null on success, else an error message.
  Future<String?> toggleCommentTaskListItem({
    required int commentId,
    required String currentBody,
    required int index,
  }) async {
    if (state.savingCommentIds.contains(commentId)) {
      return null;
    }
    final source = state.optimisticComments[commentId] ?? currentBody;
    final next = toggleMarkdownTaskListItem(source, index);
    if (next == null || next == source) {
      return null;
    }
    return saveIssueComment(commentId: commentId, body: next);
  }

  /// Saves a conversation comment's [body]. Returns null on success, else an
  /// error message.
  Future<String?> saveIssueComment({
    required int commentId,
    required String body,
  }) async {
    final repo = _repo;
    if (repo == null) {
      return null;
    }
    state = state.copyWith(
      savingCommentIds: {...state.savingCommentIds, commentId},
      optimisticComments: {...state.optimisticComments, commentId: body},
    );
    try {
      await repo.updateIssueComment(
        prNumber: prNumber,
        commentId: commentId,
        body: body,
      );
      ref.invalidate(prIssueCommentsProvider(pr));
      return null;
    } catch (e) {
      final remaining = Map<int, String>.of(state.optimisticComments)
        ..remove(commentId);
      state = state.copyWith(optimisticComments: remaining);
      return _msg(e);
    } finally {
      state = state.copyWith(
        savingCommentIds: state.savingCommentIds.difference({commentId}),
      );
    }
  }

  /// Applies an assignee diff in one shot (used by the picker's Save).
  Future<String?> applyAssigneeChanges({
    List<String> add = const [],
    List<String> remove = const [],
  }) async {
    if (add.isEmpty && remove.isEmpty) {
      return null;
    }
    final repo = _repo;
    if (repo == null) {
      return null;
    }
    final keys = {...add, ...remove}.map((l) => l.toLowerCase()).toSet();
    state = state.copyWith(
      pendingAssignees: {...state.pendingAssignees, ...keys},
    );
    try {
      if (add.isNotEmpty) {
        await repo.addAssignees(prNumber: prNumber, logins: add);
      }
      if (remove.isNotEmpty) {
        await repo.removeAssignees(prNumber: prNumber, logins: remove);
      }
      _refreshDetail();
      return null;
    } catch (e) {
      return _msg(e);
    } finally {
      state = state.copyWith(
        pendingAssignees: state.pendingAssignees.difference(keys),
      );
    }
  }

  /// Removes a single assignee (used by the inline remove affordance).
  Future<String?> removeAssignee(String login) =>
      applyAssigneeChanges(remove: [login]);

  /// Applies a reviewer diff in one shot (used by the picker's Save).
  Future<String?> applyReviewerChanges({
    List<String> addUsers = const [],
    List<String> addTeams = const [],
    List<String> removeUsers = const [],
    List<String> removeTeams = const [],
  }) async {
    if (addUsers.isEmpty &&
        addTeams.isEmpty &&
        removeUsers.isEmpty &&
        removeTeams.isEmpty) {
      return null;
    }
    final repo = _repo;
    if (repo == null) {
      return null;
    }
    try {
      if (addUsers.isNotEmpty || addTeams.isNotEmpty) {
        await repo.requestReviewers(
          prNumber: prNumber,
          userLogins: addUsers,
          teamSlugs: addTeams,
        );
      }
      if (removeUsers.isNotEmpty || removeTeams.isNotEmpty) {
        await repo.removeRequestedReviewers(
          prNumber: prNumber,
          userLogins: removeUsers,
          teamSlugs: removeTeams,
        );
      }
      _refreshReviewers();
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// Removes a single requested reviewer (user or team) via the inline remove.
  Future<String?> removeReviewer({String? userLogin, String? teamSlug}) async {
    final key = userLogin != null
        ? 'user:${userLogin.toLowerCase()}'
        : 'team:${teamSlug!.toLowerCase()}';
    final repo = _repo;
    if (repo == null) {
      return null;
    }
    state = state.copyWith(pendingReviewers: {...state.pendingReviewers, key});
    try {
      await repo.removeRequestedReviewers(
        prNumber: prNumber,
        userLogins: userLogin != null ? [userLogin] : const [],
        teamSlugs: teamSlug != null ? [teamSlug] : const [],
      );
      _refreshReviewers();
      return null;
    } catch (e) {
      return _msg(e);
    } finally {
      state = state.copyWith(
        pendingReviewers: state.pendingReviewers.difference({key}),
      );
    }
  }
}

/// Per-PR edit-state notifier. Lives as long as an editing widget watches it;
/// auto-disposes when the detail screen leaves.
final prEditProvider = NotifierProvider.family
    .autoDispose<PrEditNotifier, PrEditState, PrRef>(PrEditNotifier.new);
