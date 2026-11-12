import 'package:cc_domain/cc_domain.dart'
    show NeedsSignInException, NetworkException, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/cc_infra.dart'
    show kNeedsSignInCode, mapHttpException, needsSignInLaneOf;
import 'package:cc_server_core/src/pr_review/agent_pr_marker.dart';
import 'package:cc_server_core/src/pr_review/agent_pr_requesters.dart';
import 'package:cc_server_core/src/pr_review/agent_run_pull_request_scope.dart';
import 'package:rhttp/rhttp.dart' show RhttpException;

/// The forge client a pull request is opened with: [actingUserId]'s own
/// one-repository token when [viaPerson], else the workspace's automation.
typedef AgentPrClientFor =
    ForgePrClient Function(
      Repo repo, {
      required String workspaceId,
      String? actingUserId,
      bool viaPerson,
    });

/// Everyone who armed the trigger whose pipeline started the active runs of
/// [conversationId] (empty: no armed trigger did, or it recorded nobody).
typedef AgentRunsArmedBy =
    Future<Set<String>> Function(String workspaceId, String conversationId);

/// Opens pull requests for agent runs, and edits their own
/// ([AgentPullRequestPort]).
///
/// Who: the person who requested the run, on their own one-repository token,
/// so the forge's own "an author cannot approve their own pull request" rule
/// applies and the requester is recorded ([AgentPrRequesters]) for the
/// server's self-approval refusal on every forge. A run nobody requested
/// (schedule, webhook) opens it as the Control Center bot, and records the
/// admin who armed the trigger that started it instead. The person's token
/// never enters the sandbox: it is used here, on the server. The body ends
/// with [agentPullRequestMarker], naming who asked.
///
/// What: only a repository linked to the run's workspace that the requester
/// may read there (admin or read grant), and only from a branch that is the
/// run's own (it pushed it through the gateway, or it is the run's space
/// branch for that repository), as [AgentRunPullRequestScope] holds them.
///
/// An edit of a title or description goes out as the same actor, only on
/// the run's own pull request ([AgentRunPullRequestScope.ownPullRequest])
/// while it is open, and the new description ends with the marker again.
///
/// A description keeps its @-mentions, opened or edited: bringing people in
/// is part of a pull request. What the bot posts in the conversation has
/// them made inert (`AgentPullRequestCommentService`).
class AgentPullRequestService implements AgentPullRequestPort {
  /// Creates the service.
  AgentPullRequestService({
    required this._scope,
    required this._clientFor,
    required this._requesters,
    required this._viewerLogin,
    required this._armedBy,
  });

  static const String _opening = 'open a pull request';
  static const String _editing = 'edit its pull request';

  final AgentRunPullRequestScope _scope;
  final AgentPrClientFor _clientFor;
  final AgentPrRequesters _requesters;
  final ForgeViewerLogin _viewerLogin;
  final AgentRunsArmedBy _armedBy;

  @override
  Future<String?> requesterOf({
    required String workspaceId,
    required String conversationId,
  }) async => (await _scope.runsOf(
    workspaceId,
    conversationId,
    doing: _opening,
  )).requester;

  @override
  Future<Set<String>> approvalOwnersOf({
    required String workspaceId,
    required String conversationId,
  }) async {
    final requester = await requesterOf(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    return requester != null
        ? {requester}
        : await _armedBy(workspaceId, conversationId);
  }

  @override
  Future<List<AgentCommitIdentity>> commitIdentitiesOf({
    required String workspaceId,
    required String conversationId,
  }) async => {
    for (final run in (await _scope.runsOf(
      workspaceId,
      conversationId,
      doing: _opening,
    )).runs)
      ?run.grant.identity,
  }.toList();

  @override
  Future<AgentPullRequestResult> open(AgentPullRequestDraft draft) async {
    final workspaceId = draft.workspaceId;
    final runs = await _scope.runsOf(
      workspaceId,
      draft.conversationId,
      doing: _opening,
    );
    final requester = runs.requester;
    final repo = await _scope.repoFor(
      workspaceId,
      draft.repo,
      runs,
      doing: _opening,
    );
    _requireBranch(draft.head, 'head');
    _requireBranch(draft.base, 'base');
    if (draft.head == draft.base) {
      throw const ValidationException(
        'The head and base branches are the same.',
      );
    }
    if (!await _scope.isRunBranch(workspaceId, runs.runs, repo, draft.head)) {
      throw ValidationException(
        '${draft.head} is not this run\'s branch. Open a pull request from a '
        'branch this run pushed, or from its space\'s own branch.',
      );
    }
    final client = _clientOf(repo, workspaceId, requester);
    final requesterLogin = await _loginOf(repo, workspaceId, requester);
    // Who may not approve it: the requester, or for a run nobody requested
    // everyone who armed its trigger. Recorded before the forge is asked
    // (a failure aborts the open), so no failure leaves it unguarded.
    final approvalOwners = requester != null
        ? {requester}
        : await _armedBy(workspaceId, draft.conversationId);
    final int number;
    final String url;
    try {
      final pr = await _requesters.open(
        repo: repo,
        head: draft.head,
        approvalOwnerUserIds: approvalOwners,
        create: () => client.createPullRequest(
          title: draft.title,
          body: withAgentPullRequestMarker(
            draft.body,
            requesterLogin: requesterLogin,
          ),
          headBranch: draft.head,
          baseBranch: draft.base,
          draft: draft.draft,
        ),
      );
      number = pr.number;
      url = pr.htmlUrl;
    } on RhttpException catch (e) {
      throw _refusal(mapHttpException(e), repo, _opening);
    } on NetworkException catch (e) {
      throw _refusal(e, repo, _opening);
    }
    return AgentPullRequestResult(
      repoFullName: repo.fullName,
      number: number,
      url: url,
      author: requester != null
          ? AgentPullRequestAuthor.requester
          : AgentPullRequestAuthor.bot,
    );
  }

  @override
  Future<AgentPullRequestEditResult> update(AgentPullRequestEdit edit) async {
    const maxTitle = AgentPullRequestEdit.maxTitleLength;
    const maxBody = AgentPullRequestEdit.maxBodyLength;
    if (edit.number <= 0) {
      throw const ValidationException('Name the pull request by its number.');
    }
    final title = edit.title?.trim();
    final body = edit.body?.trim();
    if (title == null && body == null) {
      throw const ValidationException(
        'Give a new title, a new description, or both.',
      );
    }
    if (title != null && title.isEmpty) {
      throw const ValidationException('The title is empty.');
    }
    if (title != null && title.length > maxTitle) {
      throw const ValidationException(
        'The title is longer than $maxTitle characters.',
      );
    }
    if (body != null && body.length > maxBody) {
      throw const ValidationException(
        'The description is longer than $maxBody characters.',
      );
    }
    final workspaceId = edit.workspaceId;
    final runs = await _scope.runsOf(
      workspaceId,
      edit.conversationId,
      doing: _editing,
    );
    final requester = runs.requester;
    final repo = await _scope.repoFor(
      workspaceId,
      edit.repo,
      runs,
      doing: _editing,
    );
    final client = _clientOf(repo, workspaceId, requester);
    try {
      final pr = await _scope.ownPullRequest(
        client,
        workspaceId: workspaceId,
        runs: runs.runs,
        repo: repo,
        number: edit.number,
      );
      if (!pr.isOpen) {
        throw ValidationException(
          '${repo.fullName}#${edit.number} is '
          '${pr.isMerged ? 'merged' : 'closed'}: only an open pull request '
          'can be edited.',
        );
      }
      String? nextBody;
      if (body != null) {
        // A body an agent opened ends with the "Opened by" marker, and keeps
        // it; one a person opened says an agent edited it.
        nextBody = withAgentPullRequestMarker(
          body,
          requesterLogin: await _loginOf(repo, workspaceId, requester),
          edited: !hasAgentOpenedMarker(pr.body),
        );
        if (nextBody.length > maxBody) {
          throw const ValidationException(
            'The description is longer than $maxBody characters once the '
            'line naming who asked is added.',
          );
        }
      }
      await client.updatePullRequest(
        prNumber: edit.number,
        title: title,
        body: nextBody,
      );
      return AgentPullRequestEditResult(
        repoFullName: repo.fullName,
        number: edit.number,
        url: pr.htmlUrl,
      );
    } on RhttpException catch (e) {
      throw _refusal(mapHttpException(e), repo, _editing);
    } on NetworkException catch (e) {
      throw _refusal(e, repo, _editing);
    }
  }

  /// The forge client the runs' work is published with: the requester's own
  /// one-repository token, or the bot when nobody requested them.
  ForgePrClient _clientOf(Repo repo, String workspaceId, String? requester) =>
      _clientFor(
        repo,
        workspaceId: workspaceId,
        actingUserId: requester,
        viaPerson: requester != null,
      );

  /// [requester]'s login on [repo]'s forge, for the marker; null when nobody
  /// requested the run or it cannot be read (the marker then names nobody).
  Future<String?> _loginOf(
    Repo repo,
    String workspaceId,
    String? requester,
  ) async {
    if (requester == null) {
      return null;
    }
    try {
      return await _viewerLogin(repo.forge, requester, workspaceId);
    } on Object catch (_) {
      return null;
    }
  }

  /// A plain branch name: no fork prefix (`owner:branch`), no option-like or
  /// path-escaping shape.
  static void _requireBranch(String branch, String which) {
    final ok =
        branch.length <= 255 &&
        RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(branch) &&
        !branch.startsWith('-') &&
        !branch.startsWith('/') &&
        !branch.endsWith('/') &&
        !branch.endsWith('.lock') &&
        !branch.contains('..') &&
        !branch.contains('//');
    if (!ok) {
      throw ValidationException('"$branch" is not a valid $which branch.');
    }
  }

  /// The forge's refusal, as the agent should read it: a missing sign-in of
  /// the requester names the lane to sign in to.
  static Exception _refusal(NetworkException e, Repo repo, String doing) {
    if (e.code == kNeedsSignInCode) {
      final lane = needsSignInLaneOf(e.responseBody) ?? repo.forge.wire;
      return NeedsSignInException(
        lane,
        'The person who asked for this run has to sign in to '
        '${repo.forge.displayName} before an agent can $doing as them.',
      );
    }
    return e;
  }
}
