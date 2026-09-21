import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_harness/cc_harness.dart';
import 'package:cc_host/cc_host.dart';

import 'package:cc_server_core/src/catalog/catalog_wire.dart';

/// Builds the `pr_review.*` RepoOps (review CRUD, stacks, previews).
///
/// Every op carries `owner`/`repo` and resolves the repository via the
/// workspace-linked repo gate. The builder accepts the closures that the
/// catalog's `buildRemoteRpcCatalog` defines locally.
List<RepoOp> buildPrReviewOps({
  required Future<PrReviewRepository> Function(
    String workspaceId,
    String owner,
    String repo, {
    required String userId,
    bool asApp,
  }) resolvePrReviewRepository,
  required ({String owner, String repo}) Function(Map<String, dynamic> args) requireRepoCoords,
  required Future<Map<String, dynamic>?> Function({
    required String workspaceId,
    required String kind,
    required String key,
    required Future<Map<String, dynamic>?> Function() fetch,
  }) previewSwr,
  required Future<void> Function(String workspaceId, String spaceId) assertSpaceOwned,
  required MessagingRepository messagingRepository,
  PrPreviewFetcher? fetchPrPreview,
  CommitPreviewFetcher? fetchCommitPreview,
  UserRepository? userRepository,
  ReviewFindingStatusPort? reviewFindingStatus,
}) => [
    RepoOp(
      name: 'pr_review.getDraft',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final draft = await repo.getDraft(
          (ctx.args['pr_number'] as num).toInt(),
        );
        return {'draft': draft};
      },
    ),
    RepoOp(
      name: 'pr_review.upsertDraft',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'text'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.upsertDraft(
          (ctx.args['pr_number'] as num).toInt(),
          ctx.args['text'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.clearDraft',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.clearDraft((ctx.args['pr_number'] as num).toInt());
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.listAssignableUsers',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final users = await repo.listAssignableUsers();
        return {'users': users.map(prUserToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pr_review.listRequestableReviewers',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final candidates = await repo.listRequestableReviewers();
        return {
          'candidates': candidates.map(prReviewerCandidateToWire).toList(),
        };
      },
    ),
    RepoOp(
      name: 'pr_review.suggestedReviewers',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final users = await repo.listSuggestedReviewers(
          (ctx.args['pr_number'] as num).toInt(),
        );
        return {'users': users.map(prUserToWire).toList()};
      },
    ),
    RepoOp(
      name: 'pr_review.getJobRunDetail',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'job_id'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final job = await repo.getJobRunDetail(
          (ctx.args['job_id'] as num).toInt(),
        );
        return {'job': ?(job == null ? null : jobRunDetailToWire(job))};
      },
    ),
    RepoOp(
      name: 'pr_review.getWorkflowGraph',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'run_id'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final graph = await repo.getWorkflowGraph(
          (ctx.args['run_id'] as num).toInt(),
        );
        return {'graph': ?(graph == null ? null : workflowGraphToWire(graph))};
      },
    ),
    RepoOp(
      name: 'pr_review.resolveImageDiff',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'path', 'base_ref', 'head_ref', 'status'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final previous = ctx.args['previous_path'];
        final result = await repo.resolveImageDiff(
          path: ctx.args['path'] as String,
          previousPath: previous is String && previous.isNotEmpty
              ? previous
              : null,
          baseRef: ctx.args['base_ref'] as String,
          headRef: ctx.args['head_ref'] as String,
          status: PrFileStatusExtension.fromString(
            ctx.args['status'] as String? ?? 'modified',
          ),
        );
        return result.toJson();
      },
    ),
    RepoOp(
      name: 'pr_review.invalidatePullRequest',
      kind: RepoOpKind.mutate,
      // Cache-bust, not a state change — the next read refetches.
      audited: false,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.invalidatePullRequest(
          (ctx.args['pr_number'] as num).toInt(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.invalidateDiff',
      kind: RepoOpKind.mutate,
      // Cache-bust, not a state change — the next read refetches.
      audited: false,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.invalidateDiff((ctx.args['pr_number'] as num).toInt());
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.markFileAsViewed',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'external_id',
        'path',
        'viewed',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.markFileAsViewed(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          externalId: ctx.args['external_id'] as String,
          path: ctx.args['path'] as String,
          viewed: ctx.args['viewed'] as bool,
        );
        return {'ok': true};
      },
    ),
    // Posts review findings as inline PR comments under the server's app
    // identity. Bodies read from stored `review_node` messages (not the
    // client) so attribution is honest. `pr_review.postReviewComment` stays
    // on the caller's account (human-typed body).
    //
    // Unanchored findings counted, never dropped. Anchors outside the diff
    // get their own bucket (GitHub 422; not retryable as `failed`).
    // Classified from GitHub's post verdict — no pre-fetch of the PR file list.
    RepoOp(
      name: 'pr_review.commentFindings',
      kind: RepoOpKind.mutate,
      actionClasses: const {ActionClass.prPublish},
      requiredArgs: [
        'workspace_id',
        'space_id',
        'owner',
        'repo',
        'pr_number',
        'commit_sha',
        'message_ids',
      ],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(workspaceId, spaceId);
        final c = requireRepoCoords(ctx.args);
        final prNumber = (ctx.args['pr_number'] as num).toInt();
        final wanted = <String>{
          for (final id in (ctx.args['message_ids'] as List? ?? const []))
            if (id is String && id.isNotEmpty) id,
        };
        if (wanted.isEmpty) {
          return {'posted': 0, 'skipped': 0, 'outOfDiff': 0, 'failed': 0};
        }

        // Space-wide, NOT the standing conversation: each reviewer files its
        // findings into its own stream, so gathering from one conversation
        // matched none of the selected ids and reported "posted 0, skipped 0,
        // failed 0" — a silent no-op that looked like a successful post of
        // nothing. Same rule the GitHub publisher already follows.
        final messages = await messagingRepository.getSpaceMessages(
          workspaceId,
          spaceId,
        );
        final repository = await resolvePrReviewRepository(
          workspaceId,
          c.owner,
          c.repo,
          userId: ctx.userId,
          asApp: true,
        );

        var posted = 0;
        var skipped = 0;
        var outOfDiff = 0;
        final outOfDiffPaths = <String>{};
        final errors = <String>[];
        for (final m in messages) {
          if (m.messageType != MessageType.reviewNode ||
              !wanted.contains(m.id)) {
            continue;
          }
          final payload = ReviewNodePayload.fromMetadata(m.metadata);
          final path = payload?.anchor.filePath;
          final line = payload?.anchor.lineNumber;
          if (payload == null || path == null || line == null) {
            skipped++;
            continue;
          }
          try {
            await repository.postReviewComment(
              prNumber: prNumber,
              commitSha: ctx.args['commit_sha'] as String,
              path: path,
              line: payload.anchor.lineEnd ?? line,
              side: 'RIGHT',
              body: m.content,
              startLine: payload.anchor.lineEnd != null ? line : null,
            );
            posted++;
          } on Object catch (e) {
            if (isOutOfDiffAnchorRejection(e)) {
              outOfDiff++;
              outOfDiffPaths.add(path);
            } else {
              errors.add('$e');
            }
          }
        }
        return {
          'posted': posted,
          'skipped': skipped,
          'outOfDiff': outOfDiff,
          'failed': errors.length,
          if (outOfDiffPaths.isNotEmpty)
            'outOfDiffPaths': outOfDiffPaths.toList(),
          if (errors.isNotEmpty) 'errors': errors,
        };
      },
    ),
    RepoOp(
      name: 'pr_review.postReviewComment',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'commit_sha',
        'path',
        'line',
        'side',
        'body',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final result = await repo.postReviewComment(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          commitSha: ctx.args['commit_sha'] as String,
          path: ctx.args['path'] as String,
          line: (ctx.args['line'] as num).toInt(),
          side: ctx.args['side'] as String,
          body: ctx.args['body'] as String,
          startLine: (ctx.args['start_line'] as num?)?.toInt(),
          startSide: ctx.args['start_side'] as String?,
        );
        return {'result': result};
      },
    ),
    RepoOp(
      name: 'pr_review.replyToReviewComment',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'parent_comment_id', 'body'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.replyToReviewComment(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          parentCommentId: (ctx.args['parent_comment_id'] as num).toInt(),
          body: ctx.args['body'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.uploadContent',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'path', 'base64_content', 'message'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final url = await repo.uploadContent(
          ctx.args['path'] as String,
          ctx.args['base64_content'] as String,
          ctx.args['message'] as String,
        );
        return {'url': url};
      },
    ),
    RepoOp(
      name: 'pr_review.toggleReviewCommentReaction',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'comment_id',
        'content',
        'add',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.toggleReviewCommentReaction(
          commentId: (ctx.args['comment_id'] as num).toInt(),
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          content: ctx.args['content'] as String,
          add: ctx.args['add'] as bool,
          currentUserLogin: ctx.args['current_user_login'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.toggleIssueCommentReaction',
      kind: RepoOpKind.mutate,
      // Emoji reaction on a conversation comment — high-frequency and
      // low-stakes, noise in the audit trail.
      audited: false,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'comment_id',
        'content',
        'add',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.toggleIssueCommentReaction(
          commentId: (ctx.args['comment_id'] as num).toInt(),
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          content: ctx.args['content'] as String,
          add: ctx.args['add'] as bool,
          currentUserLogin: ctx.args['current_user_login'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.togglePullRequestReaction',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'content', 'add'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.togglePullRequestReaction(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          content: ctx.args['content'] as String,
          add: ctx.args['add'] as bool,
          currentUserLogin: ctx.args['current_user_login'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.toggleReviewReaction',
      kind: RepoOpKind.mutate,
      requiredArgs: [
        'owner',
        'repo',
        'pr_number',
        'review_id',
        'content',
        'add',
      ],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.toggleReviewReaction(
          reviewId: (ctx.args['review_id'] as num).toInt(),
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          content: ctx.args['content'] as String,
          add: ctx.args['add'] as bool,
          currentUserLogin: ctx.args['current_user_login'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.submitReview',
      kind: RepoOpKind.mutate,
      // Irreversible: publishes a review to GitHub (external side effect).
      undoClass: UndoClass.irreversible,
      requiredArgs: ['owner', 'repo', 'pr_number', 'event'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.submitReview(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          event: ctx.args['event'] as String,
          body: ctx.args['body'] as String?,
          comments: [
            for (final c in (ctx.args['comments'] as List? ?? const []))
              if (c is Map)
                PendingReviewComment.fromJson(c.cast<String, dynamic>()),
          ],
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      // Moves ONE of our own review findings between statuses — fixed,
      // dismissed, or back to open. Distinct from
      // `pr_review.setReviewThreadResolved` next door, which resolves a thread
      // on GitHub; this is the state of a finding in our review.
      //
      // A dedicated op rather than a generic metadata write, for three
      // reasons: the status is validated against the enum instead of pasted in
      // as a string, the change is written through the typed payload so it
      // always parses back, and a dismissal records the suppression fact that
      // stops the same finding returning on the next pull request.
      name: 'pr_review.setFindingStatus',
      kind: RepoOpKind.mutate,
      // Reversible: reopening is a first-class move, so this belongs in the
      // undo journal rather than being a one-way door.
      undoClass: UndoClass.reversible,
      requiredArgs: ['workspace_id', 'space_id', 'node_message_id', 'status'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final spaceId = ctx.args['space_id'] as String;
        await assertSpaceOwned(workspaceId, spaceId);

        final rawStatus = ctx.args['status'];
        final status = rawStatus is String
            ? ReviewNodeStatus.fromName(rawStatus)
            : null;
        if (status == null) {
          throw ValidationException(
            'Unknown finding status: $rawStatus. Expected one of '
            '${ReviewNodeStatus.values.map((s) => s.wireName).join(', ')}.',
          );
        }

        // Attributed to the person who pressed it, by name. A status change
        // signed "system" tells a later reader nothing about who decided.
        var actor = ctx.userId;
        if (userRepository != null) {
          actor =
              (await userRepository.getById(ctx.userId))?.displayName ??
              ctx.userId;
        }

        final rawReason = ctx.args['reason'];
        try {
          final change = await reviewFindingStatus!.setStatus(
            workspaceId: workspaceId,
            spaceId: spaceId,
            nodeMessageId: ctx.args['node_message_id'] as String,
            status: status,
            actorLabel: actor,
            reason: rawReason is String ? rawReason : null,
          );
          return {
            'node_message_id': change.nodeMessageId,
            'status': change.status.wireName,
            'previous_status': change.previousStatus.wireName,
            'suppression_recorded': change.suppressionRecorded,
          };
        } on ReviewFindingNotFound catch (e) {
          throw NotFoundException(e.toString());
        }
      },
    ),
    RepoOp(
      name: 'pr_review.setReviewThreadResolved',
      kind: RepoOpKind.mutate,
      // Irreversible in the undo sense: it writes a conversation state to the
      // forge that other reviewers see. Reopening is a fresh call, not an undo.
      undoClass: UndoClass.irreversible,
      requiredArgs: ['owner', 'repo', 'pr_number', 'thread_id', 'resolved'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.setReviewThreadResolved(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          threadId: ctx.args['thread_id'] as String,
          resolved: ctx.args['resolved'] as bool,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.mergePullRequest',
      kind: RepoOpKind.mutate,
      // Irreversible: merging lands commits on GitHub — an external side effect
      // that no inverse op can undo. It gets preview/confirm (below) instead
      // and never enters the undo stack (PRD 19 §4/§5).
      undoClass: UndoClass.irreversible,
      requiredArgs: ['owner', 'repo', 'pr_number', 'merge_method'],
      preview: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final n = (ctx.args['pr_number'] as num?)?.toInt();
        final method = ctx.args['merge_method'] as String? ?? 'merge';
        return ActionPreview(
          summary: 'Merge ${c.owner}/${c.repo} #$n via $method',
          warnings: const [
            'Merging pushes commits to GitHub and cannot be undone from here.',
          ],
        );
      },
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final result = await repo.mergePullRequest(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          mergeMethod: ctx.args['merge_method'] as String,
          commitTitle: ctx.args['commit_title'] as String?,
          commitMessage: ctx.args['commit_message'] as String?,
        );
        return {'result': result};
      },
    ),
    RepoOp(
      name: 'pr_review.closePullRequest',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.closePullRequest(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.setPullRequestDraft',
      kind: RepoOpKind.mutate,
      // Taking a draft out of draft notifies every requested reviewer on the
      // forge — the same outward-facing effect as publishing a review. The
      // reverse direction is declared with it because one op serves both and a
      // policy that forbids writing a PR's published state forbids both ways.
      actionClasses: const {ActionClass.prPublish},
      requiredArgs: ['owner', 'repo', 'pr_number', 'draft'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.setPullRequestDraft(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          draft: ctx.args['draft'] as bool,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.listStacks',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final stacks = await repo.listStacks(
          prNumber: (ctx.args['pr_number'] as num?)?.toInt(),
        );
        return {
          'stacks': [for (final s in stacks) prStackToWire(s)],
        };
      },
    ),
    RepoOp(
      name: 'pr_review.createStack',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pull_requests'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final prNumbers = [
          for (final n in (ctx.args['pull_requests'] as List?) ?? const [])
            (n as num).toInt(),
        ];
        if (prNumbers.length < 2) {
          throw ArgumentError('A stack needs at least two pull requests');
        }
        final stack = await repo.createStack(prNumbers: prNumbers);
        return {'stack': prStackToWire(stack)};
      },
    ),
    RepoOp(
      name: 'pr_review.addToStack',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'stack_number', 'pull_requests'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final prNumbers = [
          for (final n in (ctx.args['pull_requests'] as List?) ?? const [])
            (n as num).toInt(),
        ];
        if (prNumbers.isEmpty) {
          throw ArgumentError('pull_requests must not be empty');
        }
        final stack = await repo.addToStack(
          stackNumber: (ctx.args['stack_number'] as num).toInt(),
          prNumbers: prNumbers,
        );
        return {'stack': stack == null ? null : prStackToWire(stack)};
      },
    ),
    RepoOp(
      name: 'pr_review.unstack',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'stack_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        final stack = await repo.unstack(
          stackNumber: (ctx.args['stack_number'] as num).toInt(),
        );
        // Null stack = every entry was removed and the stack dissolved (GitHub
        // answered 204).
        return {'stack': stack == null ? null : prStackToWire(stack)};
      },
    ),
    RepoOp(
      name: 'pr_review.updatePullRequest',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.updatePullRequest(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          title: ctx.args['title'] as String?,
          body: ctx.args['body'] as String?,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.updateIssueComment',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'comment_id', 'body'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.updateIssueComment(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          commentId: (ctx.args['comment_id'] as num).toInt(),
          body: ctx.args['body'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.addAssignees',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'logins'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.addAssignees(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          logins: ((ctx.args['logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.removeAssignees',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number', 'logins'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.removeAssignees(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          logins: ((ctx.args['logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.requestReviewers',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.requestReviewers(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          userLogins: ((ctx.args['user_logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
          teamSlugs: ((ctx.args['team_slugs'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'pr_review.removeRequestedReviewers',
      kind: RepoOpKind.mutate,
      requiredArgs: ['owner', 'repo', 'pr_number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        final repo = await resolvePrReviewRepository(
          ctx.workspaceId!,
          c.owner,
          c.repo,
          userId: ctx.userId,
        );
        await repo.removeRequestedReviewers(
          prNumber: (ctx.args['pr_number'] as num).toInt(),
          userLogins: ((ctx.args['user_logins'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
          teamSlugs: ((ctx.args['team_slugs'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
        return {'ok': true};
      },
    ),
    // The host fetches via the GitHub client (the desktop holds the token) and
    // SWR-caches the lightweight preview against the workspace's cache. Returns
    // `null` when the ref can't be resolved (the chip falls back to a link).
    RepoOp(
      name: 'pr_review.prPreview',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'number'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        if (fetchPrPreview == null) {
          return {'preview': null};
        }
        final number = (ctx.args['number'] as num).toInt();
        final preview = await previewSwr(
          workspaceId: ctx.workspaceId!,
          kind: 'prPreview',
          key: '${c.owner}/${c.repo}#$number',
          fetch: () => fetchPrPreview(c.owner, c.repo, number),
        );
        return {'preview': preview};
      },
    ),
    RepoOp(
      name: 'pr_review.commitPreview',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'sha'],
      handler: (ctx) async {
        final c = requireRepoCoords(ctx.args);
        if (fetchCommitPreview == null) {
          return {'preview': null};
        }
        final sha = ctx.args['sha'] as String;
        final preview = await previewSwr(
          workspaceId: ctx.workspaceId!,
          kind: 'commitPreview',
          key: '${c.owner}/${c.repo}@$sha',
          fetch: () => fetchCommitPreview(c.owner, c.repo, sha),
        );
        return {'preview': preview};
      },
    ),
];
