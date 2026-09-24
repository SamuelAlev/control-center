import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException;
import 'package:cc_domain/core/domain/entities/message.dart'
    show MessageType, SenderType;
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart'
    show DefaultAnswererResolver, EnsurePrReviewSpace;

/// The head and base of a pull request, as the forge currently reports them.
typedef PrMergeRefs = ({String title, String baseRef, String headRef});

/// Reads a pull request's refs from the forge, or null when it does not exist.
typedef PrMergeRefsLookup =
    Future<PrMergeRefs?> Function(String owner, String repo, int prNumber);

/// Computes the files that conflict when the PR's head is merged into
/// [baseRef], acting as [userId] (whose credential reaches the repo).
typedef PrConflictFilesLookup =
    Future<List<String>> Function({
      required String workspaceId,
      required String owner,
      required String repo,
      required int prNumber,
      required String baseRef,
      required String? userId,
    });

/// What a PR that will not merge conflicts on.
class PrMergeConflicts {
  /// Creates a [PrMergeConflicts].
  const PrMergeConflicts({
    required this.files,
    required this.baseRef,
    required this.headRef,
  });

  /// The conflicting paths, in git's order. Empty when the merge is clean.
  final List<String> files;

  /// The branch the PR merges into.
  final String baseRef;

  /// The PR's own branch.
  final String headRef;

  /// Wire shape for `pr_review.mergeConflicts`.
  Map<String, dynamic> toWire() => {
    'files': files,
    'base_ref': baseRef,
    'head_ref': headRef,
  };
}

/// Lists a pull request's merge conflicts and hands them to an agent.
///
/// GitHub says only THAT a branch conflicts (`mergeable_state: dirty`, or a
/// `405` on merge), never which files, so the list is computed here with
/// `git merge-tree` on the server's PR clone — the same three-way merge the
/// forge runs. The fix runs in the PR's own space, whose checkout is already
/// the PR head, so the agent's push lands on the branch the PR shows.
class PrMergeConflictService {
  /// Creates a [PrMergeConflictService].
  PrMergeConflictService({
    required this._refs,
    required this._conflictFiles,
    required this._ensureSpace,
    required this._defaultAgent,
    required this._conversations,
    required this._messaging,
    required this._messagingRepository,
    this._onWarning,
  });

  final PrMergeRefsLookup _refs;
  final PrConflictFilesLookup _conflictFiles;
  final EnsurePrReviewSpace _ensureSpace;
  final DefaultAnswererResolver _defaultAgent;
  final ConversationRepository _conversations;
  final MessagingPort _messaging;
  final MessagingRepository _messagingRepository;
  final void Function(String message)? _onWarning;

  /// The files PR #[prNumber] conflicts on against its base.
  Future<PrMergeConflicts> conflicts({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    String? userId,
  }) async {
    final refs = await _requireRefs(owner, repo, prNumber);
    final files = await _conflictFiles(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
      baseRef: refs.baseRef,
      userId: userId,
    );
    return PrMergeConflicts(
      files: files,
      baseRef: refs.baseRef,
      headRef: refs.headRef,
    );
  }

  /// Starts an agent resolving PR #[prNumber]'s conflicts in a new
  /// conversation of the PR's space, on behalf of [userId].
  ///
  /// Returns the space, conversation and agent it started, so the client can
  /// take the operator straight to it.
  Future<Map<String, dynamic>> fixConflicts({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    String? userId,
  }) async {
    final refs = await _requireRefs(owner, repo, prNumber);
    // Best-effort: the list focuses the agent, but the merge it runs finds
    // the same files, so a failed probe must not stop the fix.
    var files = const <String>[];
    try {
      files = await _conflictFiles(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        prNumber: prNumber,
        baseRef: refs.baseRef,
        userId: userId,
      );
    } on Object catch (e) {
      _onWarning?.call(
        'pr_merge_conflicts: listing $owner/$repo#$prNumber failed: $e',
      );
    }

    final spaceId = await _ensureSpace(
      workspaceId: workspaceId,
      repoFullName: '$owner/$repo',
      prNumber: prNumber,
      title: refs.title,
    );
    if (spaceId == null || spaceId.isEmpty) {
      throw StateError('Could not prepare the pull request\'s workspace.');
    }
    final agentId = await _resolveAgent(workspaceId, spaceId);
    if (agentId == null) {
      throw const ValidationException(
        'This workspace has no agent to resolve the conflicts.',
      );
    }

    final conversation = await _conversations.create(
      workspaceId: workspaceId,
      spaceId: spaceId,
      title: 'Resolve merge conflicts',
      createdByPrincipalId: userId,
    );
    final prompt = buildMergeConflictPrompt(
      prNumber: prNumber,
      baseRef: refs.baseRef,
      headRef: refs.headRef,
      files: files,
    );
    await _messaging.sendUserMessage(
      workspaceId,
      spaceId,
      prompt,
      senderUserId: userId,
      conversationId: conversation.id,
    );
    final runId = await _messaging.dispatchAgent(
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      prompt: prompt,
      requestedByUserId: userId,
      conversationId: conversation.id,
    );
    if (runId == null || runId.isEmpty) {
      throw StateError('The agent could not be started.');
    }
    return {
      'space_id': spaceId,
      'conversation_id': conversation.id,
      'agent_id': agentId,
      'run_id': runId,
    };
  }

  Future<PrMergeRefs> _requireRefs(String owner, String repo, int n) async {
    final refs = await _refs(owner, repo, n);
    if (refs == null || refs.baseRef.isEmpty) {
      throw NotFoundException('Pull request $owner/$repo#$n was not found.');
    }
    return refs;
  }

  /// The agent that last spoke in the space (it already knows this PR), else
  /// the workspace default, added to the roster so it can post there.
  Future<String?> _resolveAgent(String workspaceId, String spaceId) async {
    final messages = await _messagingRepository.getSpaceMessages(
      workspaceId,
      spaceId,
    );
    for (final message in messages.reversed) {
      if (message.senderType == SenderType.agent &&
          (message.messageType == MessageType.text ||
              message.messageType == MessageType.agentTurn)) {
        return message.senderId;
      }
    }
    final fallback = await _defaultAgent(workspaceId);
    if (fallback == null || fallback.isEmpty) {
      return null;
    }
    final participants = await _messagingRepository.getParticipants(
      workspaceId,
      spaceId,
    );
    if (!participants.any((p) => p.principalId == fallback)) {
      await _messaging.addAgentToSpace(
        workspaceId,
        spaceId,
        fallback,
        renameForGroup: false,
      );
    }
    return fallback;
  }
}

/// The instruction an agent gets to resolve a PR's conflicts.
///
/// A merge of the base INTO the branch, never a rebase: the branch is
/// published and other people may have it checked out, and a rebase would make
/// every one of them force-pull.
String buildMergeConflictPrompt({
  required int prNumber,
  required String baseRef,
  required String headRef,
  required List<String> files,
}) {
  final fileList = files.isEmpty
      ? 'GitHub did not say which files conflict; the merge below will.'
      : 'These files conflict:\n${[for (final f in files) '- `$f`'].join('\n')}';
  return 'Pull request #$prNumber (`$headRef` into `$baseRef`) cannot be '
      'merged: it conflicts with `$baseRef`.\n\n'
      '$fileList\n\n'
      'This worktree is already checked out on the pull request branch. '
      'Resolve the conflicts:\n'
      '1. Fetch the latest `$baseRef` from `origin` and merge it into this '
      'branch. Do NOT rebase and do NOT force-push — the branch is published.\n'
      '2. Resolve every conflict, keeping the intent of both sides. Read the '
      'commits on each side when the intent is not obvious from the code.\n'
      '3. Build the project and run the tests that cover the files you touched.\n'
      '4. Commit the merge and push it to `$headRef` (do NOT create a new '
      'branch or open another pull request).\n'
      '5. Reply with each file you resolved and how, and name any conflict '
      'where you had to choose one side over the other.\n\n'
      'If a conflict cannot be resolved without a decision only the author can '
      'make, stop before committing and ask.';
}
