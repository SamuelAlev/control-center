import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
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
    this.pendingAssignees = const {},
    this.pendingReviewers = const {},
  });

  /// Whether a title save is in flight.
  final bool savingTitle;

  /// Whether a body save is in flight.
  final bool savingBody;

  /// User logins (lowercased) whose assignee add/remove is in flight.
  final Set<String> pendingAssignees;

  /// Reviewer selection keys (`user:<login>` / `team:<slug>`) whose change is
  /// in flight.
  final Set<String> pendingReviewers;

  /// Returns a copy with the given fields replaced.
  PrEditState copyWith({
    bool? savingTitle,
    bool? savingBody,
    Set<String>? pendingAssignees,
    Set<String>? pendingReviewers,
  }) {
    return PrEditState(
      savingTitle: savingTitle ?? this.savingTitle,
      savingBody: savingBody ?? this.savingBody,
      pendingAssignees: pendingAssignees ?? this.pendingAssignees,
      pendingReviewers: pendingReviewers ?? this.pendingReviewers,
    );
  }
}

/// Drives PR metadata edits: calls the repository, flips loading/optimistic
/// flags, and invalidates the relevant providers so the streams re-fetch. Each
/// mutating method returns `null` on success or an error message on failure
/// (the caller surfaces it via a snackbar — the notifier has no context).
class PrEditNotifier extends Notifier<PrEditState> {
  /// Creates a [PrEditNotifier] for [prNumber].
  PrEditNotifier(this.prNumber);

  /// PR number this notifier manages.
  final int prNumber;

  @override
  PrEditState build() => const PrEditState();

  PrReviewRepository get _repo => ref.read(prReviewRepositoryProvider);

  void _refreshDetail() => ref.invalidate(prDetailProvider(prNumber));

  void _refreshReviewers() {
    ref.invalidate(prReviewersProvider(prNumber));
    ref.invalidate(prDetailProvider(prNumber));
  }

  static String _msg(Object e) => e is AppException ? e.message : e.toString();

  /// Saves the PR [title]. Returns null on success, else an error message.
  Future<String?> saveTitle(String title) async {
    state = state.copyWith(savingTitle: true);
    try {
      await _repo.updatePullRequest(prNumber: prNumber, title: title);
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
    state = state.copyWith(savingBody: true);
    try {
      await _repo.updatePullRequest(prNumber: prNumber, body: body);
      _refreshDetail();
      return null;
    } catch (e) {
      return _msg(e);
    } finally {
      state = state.copyWith(savingBody: false);
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
    final keys = {...add, ...remove}.map((l) => l.toLowerCase()).toSet();
    state = state.copyWith(
      pendingAssignees: {...state.pendingAssignees, ...keys},
    );
    try {
      if (add.isNotEmpty) {
        await _repo.addAssignees(prNumber: prNumber, logins: add);
      }
      if (remove.isNotEmpty) {
        await _repo.removeAssignees(prNumber: prNumber, logins: remove);
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
    try {
      if (addUsers.isNotEmpty || addTeams.isNotEmpty) {
        await _repo.requestReviewers(
          prNumber: prNumber,
          userLogins: addUsers,
          teamSlugs: addTeams,
        );
      }
      if (removeUsers.isNotEmpty || removeTeams.isNotEmpty) {
        await _repo.removeRequestedReviewers(
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
    state = state.copyWith(pendingReviewers: {...state.pendingReviewers, key});
    try {
      await _repo.removeRequestedReviewers(
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
    .autoDispose<PrEditNotifier, PrEditState, int>(PrEditNotifier.new);
