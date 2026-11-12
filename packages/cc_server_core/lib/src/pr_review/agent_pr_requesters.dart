import 'package:cc_domain/cc_domain.dart'
    show NetworkException, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/agent_pull_request_requester_repository.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart' show kNeedsSignInCode, mapHttpException;
import 'package:rhttp/rhttp.dart' show RhttpException;

/// The caller's own login on a forge in a workspace ('' when unknown).
typedef ForgeViewerLogin =
    Future<String> Function(ForgeHost forge, String userId, String workspaceId);

/// The caller's own account on a forge in a workspace: the login a pull
/// request author is shown by and the forge's durable account id (GitHub and
/// GitLab numeric id, Bitbucket `account_id`; '' when unknown). Null when they
/// hold no usable credential there.
typedef ForgeViewerAccount =
    Future<({String login, String id})?> Function(
      ForgeHost forge,
      String userId,
      String workspaceId,
    );

/// Who asked an agent for each pull request it opened, and the one check
/// every approval on every forge passes ([guardFor]).
///
/// An agent opens a pull request for a person on that person's own
/// downscoped token, which makes GitHub's own "an author cannot approve
/// their own pull request" rule apply there. GitLab and Bitbucket enforce no
/// such rule by default, and an approval is only worth anything when someone
/// other than the requester looked at the agent's work, so the server
/// refuses it itself on every forge: the person who asked for the change is
/// its author in every sense that matters for review. A run nobody asked for
/// records everyone who armed the trigger that started it.
///
/// Recorded server-wide ([AgentPullRequestRequesterRepository]: a table of
/// its own in the global database, never pruned, unreachable by clients)
/// keyed by the forge's durable repository id, so a rename or a transfer does
/// not lose them. A record names no workspace: the same forge repository
/// linked in another workspace is the same pull request, and must not be a
/// way around the refusal, nor may deleting or restoring the workspace it was
/// written through.
///
/// Recording is not best effort: a pending row is written before the forge is
/// asked to open the pull request ([recordPending]; a failure aborts the
/// open), and is matched by head branch until [recordOpened] has written the
/// number. A pending row left behind by an open whose outcome was unclear (a
/// timeout, a 5xx) is settled by [reconcile] from the open-PR poller and by
/// the approval check itself: promoted to a numbered record once an open pull
/// request carries its head branch, dropped after [pendingMaxAge] without one.
class AgentPrRequesters {
  /// Creates the store over [_records], the server-wide records.
  AgentPrRequesters({required this._records, required this._viewer});

  final AgentPullRequestRequesterRepository _records;
  final ForgeViewerAccount _viewer;

  /// How long a pending row waits for an open pull request to carry its head
  /// branch before [reconcile] drops it as one the forge never opened.
  static const pendingMaxAge = Duration(days: 7);

  static String _forgeOf(Repo repo) =>
      '${repo.forge.wire}|${repo.forge.gitHost}|';

  static String _openedKey(Repo repo, String repoId, int number) =>
      '${_forgeOf(repo)}id:$repoId#$number'.toLowerCase();

  static String _pendingPrefix(Repo repo) =>
      '${_forgeOf(repo)}${repo.remoteOwner}/${repo.remoteName}@'.toLowerCase();

  static String _pendingKey(Repo repo, String head) =>
      '${_pendingPrefix(repo)}$head';

  static Set<String> _owners(Iterable<String> ids) => {
    for (final id in ids)
      if (id.trim().isNotEmpty) id.trim(),
  };

  /// Records, before the forge is asked, that an agent is opening a pull
  /// request from [head] on [repo] that [requesterUserIds] may not approve.
  /// Throws when it cannot be written: the pull request must then not be
  /// opened.
  Future<void> recordPending(
    Repo repo, {
    required String head,
    required Set<String> requesterUserIds,
  }) async {
    final owners = _owners(requesterUserIds);
    if (owners.isEmpty || head.isEmpty) {
      throw ArgumentError(
        'A pending agent pull request needs a requester and '
        'a head branch.',
      );
    }
    await _records.add(
      AgentPullRequestRecordState.pending,
      _pendingKey(repo, head),
      owners,
    );
  }

  /// Records that the pull request from [head] is [pr] (its number, on the
  /// repository with its durable id), then drops the pending row. Throws,
  /// leaving the pending row, when [pr] names no repository id or the row
  /// cannot be written: the refusal then still finds it by head branch.
  Future<void> recordOpened(
    Repo repo, {
    required String head,
    required PullRequest pr,
    required Set<String> requesterUserIds,
  }) async {
    if (pr.baseRepoId.isEmpty) {
      throw StateError(
        '${repo.forge.displayName} did not say which repository '
        '${repo.fullName}#${pr.number} is in.',
      );
    }
    await _records.add(
      AgentPullRequestRecordState.opened,
      _openedKey(repo, pr.baseRepoId, pr.number),
      _owners(requesterUserIds),
    );
    await _records.remove(
      AgentPullRequestRecordState.pending,
      _pendingKey(repo, head),
    );
  }

  /// Opens a pull request from [head] on [repo] through [create], recording
  /// [approvalOwnerUserIds] (when there are any) as who may not approve it:
  /// pending before [create] runs (a failure there aborts the open), then by
  /// the number and repository id of the pull request it returns. A pull
  /// request the forge definitely did not open drops the pending row; one it
  /// may still have opened (a timeout, a 5xx) keeps it, matched by head
  /// branch.
  Future<PullRequest> open({
    required Repo repo,
    required String head,
    required Set<String> approvalOwnerUserIds,
    required Future<PullRequest> Function() create,
  }) async {
    final owners = _owners(approvalOwnerUserIds);
    if (owners.isEmpty) {
      return create();
    }
    await recordPending(repo, head: head, requesterUserIds: owners);
    final PullRequest pr;
    try {
      pr = await create();
    } on Object catch (e) {
      if (_definitelyRefused(e)) {
        try {
          await abandonPending(repo, head: head);
        } on Object catch (_) {
          // A stale pending row only refuses its owners' own approval.
        }
      }
      rethrow;
    }
    try {
      await recordOpened(repo, head: head, pr: pr, requesterUserIds: owners);
    } on Object catch (e) {
      CcHostLog.warning(
        'agent pr: could not record ${repo.fullName}#${pr.number} by number '
        '(its head branch still guards it): $e',
      );
    }
    return pr;
  }

  /// Whether the forge refused to open the pull request outright, so it was
  /// not opened.
  static bool _definitelyRefused(Object error) {
    final mapped = switch (error) {
      final NetworkException e => e,
      final RhttpException e => mapHttpException(e),
      _ => null,
    };
    if (mapped == null) {
      return false;
    }
    final status = mapped.statusCode;
    return mapped.code == kNeedsSignInCode ||
        (status != null &&
            status >= 400 &&
            status < 500 &&
            status != 408 &&
            status != 429);
  }

  /// Drops the pending row of a pull request the forge refused to open.
  Future<void> abandonPending(Repo repo, {required String head}) => _records
      .remove(AgentPullRequestRecordState.pending, _pendingKey(repo, head));

  /// Settles the pending rows on [repo] against [openPrs], the open pull
  /// requests the forge just listed for it.
  ///
  /// A pending row whose head branch an open pull request carries becomes
  /// that pull request's numbered record (every one, should two open pull
  /// requests share the branch); one listed without a repository id keeps
  /// the row. A row older than [pendingMaxAge] that matched none is dropped,
  /// but only when [complete]: the list then held every open pull request, so
  /// the forge never opened it or it has closed since. A partial list (more
  /// pages than were read) drops nothing.
  Future<void> reconcile(
    Repo repo,
    List<PullRequest> openPrs, {
    required bool complete,
    DateTime? now,
  }) async {
    final prefix = _pendingPrefix(repo);
    final pending = [
      for (final row in await _records.pendingWithPrefix(prefix))
        if (row.key.startsWith(prefix)) row,
    ];
    if (pending.isEmpty) {
      return;
    }
    final cutoff = (now ?? DateTime.now()).subtract(pendingMaxAge);
    for (final row in pending) {
      final head = row.key.substring(prefix.length);
      final matching = [
        for (final pr in openPrs)
          if (pr.state == PrState.open && pr.headRef == head) pr,
      ];
      if (matching.isEmpty) {
        if (complete && row.recordedAt.isBefore(cutoff)) {
          await abandonPending(repo, head: head);
        }
        continue;
      }
      if (matching.any((pr) => pr.baseRepoId.isEmpty)) {
        continue;
      }
      for (final pr in matching) {
        await _records.add(
          AgentPullRequestRecordState.opened,
          _openedKey(repo, pr.baseRepoId, pr.number),
          row.userIds,
        );
      }
      await abandonPending(repo, head: head);
    }
  }

  /// Promotes the pending row an open [pr] on [repo] carries the head branch
  /// of to its numbered record.
  Future<void> _promoteFor(Repo repo, PullRequest pr) async {
    if (pr.state != PrState.open ||
        pr.headRef.isEmpty ||
        pr.baseRepoId.isEmpty) {
      return;
    }
    await _records.promote(
      _pendingKey(repo, pr.headRef),
      _openedKey(repo, pr.baseRepoId, pr.number),
    );
  }

  /// Everyone who may not approve pull request [number] of the forge
  /// repository [repoId] (the forge's durable id, '' when unknown) that
  /// [repo] links, or a pull request still pending from [headBranch],
  /// whichever workspace recorded it. Throws when the records could not be
  /// read: an unknown answer must not read as "nobody".
  Future<Set<String>> requestersOf(
    Repo repo,
    int number, {
    required String repoId,
    String? headBranch,
  }) async {
    try {
      return await _records.requesters(
        openedKey: repoId.isEmpty ? null : _openedKey(repo, repoId, number),
        pendingKey: headBranch == null || headBranch.isEmpty
            ? null
            : _pendingKey(repo, headBranch),
      );
    } on Object catch (e) {
      CcHostLog.warning('agent pr: could not read who asked for it: $e');
      throw const ValidationException(
        'Control Center could not check who asked for this pull request, so '
        'it cannot be approved from here right now. Try again shortly.',
      );
    }
  }

  /// The approval check for clients acting as [actingUserId] on [repo] in
  /// [workspaceId]: the one place every approval passes, whichever surface
  /// asked for it (a submitted review, a published review, any forge).
  ///
  /// Refused: an approval with no person behind it; anyone recorded as not
  /// allowed to approve this pull request (whichever workspace recorded it);
  /// the pull request's own author ([isAuthor]). Fails closed: a pull request
  /// that cannot be read, names no repository id or no author, or a caller
  /// whose own forge account cannot be confirmed, is refused with a message to
  /// try again.
  ForgeApprovalGuard guardFor(
    Repo repo, {
    required String workspaceId,
    String? actingUserId,
  }) =>
      (client, prNumber) => _refuse(
        repo,
        prNumber,
        client: client,
        workspaceId: workspaceId,
        actingUserId: actingUserId,
      );

  Future<void> _refuse(
    Repo repo,
    int prNumber, {
    required ForgePrClient client,
    required String workspaceId,
    required String? actingUserId,
  }) async {
    if (actingUserId == null || actingUserId.isEmpty) {
      throw const ValidationException(
        'Only a person can approve a pull request; Control Center automation '
        'never does.',
      );
    }
    final forge = repo.forge.displayName;
    final pr = await client.getPullRequest(prNumber);
    if (pr == null || pr.baseRepoId.isEmpty) {
      throw ValidationException(
        "Couldn't confirm this pull request on $forge, so it cannot be "
        'approved from here right now. Try again.',
      );
    }
    final requesters = await requestersOf(
      repo,
      prNumber,
      repoId: pr.baseRepoId,
      headBranch: pr.headRef,
    );
    try {
      await _promoteFor(repo, pr);
    } on Object catch (e) {
      // The head branch keeps guarding it until a later read promotes it.
      CcHostLog.warning(
        'agent pr: could not record ${repo.fullName}#${pr.number} by '
        'number: $e',
      );
    }
    if (requesters.contains(actingUserId)) {
      throw const ValidationException(
        'An agent opened this pull request at your request, so you are its '
        'author for review: another reviewer has to approve it.',
      );
    }
    final author = pr.author;
    if (author == null ||
        (author.login.trim().isEmpty && author.accountId.trim().isEmpty)) {
      throw ValidationException(
        "Couldn't confirm who opened this pull request on $forge. Try again.",
      );
    }
    final viewer = await _viewer(repo.forge, actingUserId, workspaceId);
    if (viewer == null ||
        (viewer.login.trim().isEmpty && viewer.id.trim().isEmpty)) {
      throw ValidationException(
        "Couldn't confirm your $forge account. Try again.",
      );
    }
    if (isAuthor(author, viewer)) {
      throw const ValidationException(
        'You opened this pull request, so you cannot approve it: another '
        'reviewer has to.',
      );
    }
  }

  /// Whether [viewer] is the account that authored a pull request by
  /// [author]. The forge's durable account id decides when both sides carry
  /// one (GitHub and GitLab numeric ids, Bitbucket `account_id`: a login can
  /// be renamed and, on Bitbucket, a nickname is neither stable nor unique);
  /// otherwise the logins are compared case-insensitively. An empty side
  /// matches nothing.
  static bool isAuthor(PrUser author, ({String login, String id}) viewer) {
    final authorId = author.accountId.trim();
    final viewerId = viewer.id.trim();
    if (authorId.isNotEmpty && viewerId.isNotEmpty) {
      return authorId == viewerId;
    }
    final authorLogin = author.login.trim().toLowerCase();
    return authorLogin.isNotEmpty &&
        authorLogin == viewer.login.trim().toLowerCase();
  }
}
