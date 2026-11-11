/// Review-space associations (a pull request tied to the space reviewing
/// it): the create/update ops and the live watches.
///
/// A review space names a pull request and its repository, so every op and
/// watch here answers only for a pull request the caller may see (PR
/// visibility: grant AND their own forge sign-in, [PrRepoVisibility]).
library;

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show reviewSpaceToWire;
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';

/// `review_space.create` / `review_space.updateStatus`. [requirePrRepo]
/// refuses a repository (`owner/name`) the caller may not see.
List<RepoOp> buildReviewSpaceOps({
  required ReviewSpaceRepository reviewSpaces,
  required Future<Repo> Function(
    String workspaceId,
    String repoFullName, {
    required String userId,
  })
  requirePrRepo,
}) => [
  RepoOp(
    name: 'review_space.create',
    kind: RepoOpKind.mutate,
    requiredArgs: ['space_id', 'pr_external_id', 'pr_number', 'repo_full_name'],
    handler: (ctx) async {
      // The association is stamped with the bound session workspace — a
      // client can't create one in a foreign workspace (isolation invariant)
      // — and only for a pull request the caller may see.
      await requirePrRepo(
        ctx.workspaceId!,
        ctx.args['repo_full_name'] as String,
        userId: ctx.userId,
      );
      final association = await reviewSpaces.create(
        spaceId: ctx.args['space_id'] as String,
        workspaceId: ctx.workspaceId!,
        prExternalId: ctx.args['pr_external_id'] as String,
        prNumber: (ctx.args['pr_number'] as num).toInt(),
        repoFullName: ctx.args['repo_full_name'] as String,
      );
      return {'association': reviewSpaceToWire(association)};
    },
  ),
  RepoOp(
    name: 'review_space.updateStatus',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id', 'status'],
    handler: (ctx) async {
      final id = ctx.args['id'] as String;
      // Verify ownership before mutating (ID-only lookup is not a boundary):
      // the association must already be visible in the bound workspace.
      final owned = await reviewSpaces.watchByWorkspace(ctx.workspaceId!).first;
      final association = owned.where((a) => a.id == id).firstOrNull;
      if (association == null) {
        throw const WorkspaceMismatchException(
          'Review space association belongs to a different workspace',
        );
      }
      await requirePrRepo(
        ctx.workspaceId!,
        association.repoFullName,
        userId: ctx.userId,
      );
      final status = ReviewSpaceStatus.values.asNameMap()[ctx.args['status']];
      if (status == null) {
        throw const NotFoundException('Unknown review space status');
      }
      await reviewSpaces.updateStatus(ctx.workspaceId!, id, status);
      return {'ok': true};
    },
  ),
];

/// The `review_space.watch*` queries, re-filtered live by
/// [watchPrVisibility].
List<WatchQuery> buildReviewSpaceWatchQueries({
  required ReviewSpaceRepository reviewSpaces,
  required Stream<RepoVisibility> Function(String workspaceId, String userId)
  watchPrVisibility,
}) => [
  // Review spaces name a pull request and its repository, so each one is
  // shown only to a caller who may see that repo's pull requests (PR
  // visibility: grant AND their own forge sign-in), re-filtered live.
  WatchQuery(
    name: 'review_space.watchByWorkspace',
    handler: (ctx) => combineWithVisibility(
      reviewSpaces
          .watchByWorkspace(ctx.workspaceId!)
          .map((list) => {'rows': list}),
      watchPrVisibility(ctx.workspaceId!, ctx.userId),
      (frame, visibility) => {
        'associations': [
          for (final a in frame['rows'] as List<ReviewSpaceAssociation>)
            if (visibility.canSeeFullName(a.repoFullName)) reviewSpaceToWire(a),
        ],
      },
    ),
  ),
  WatchQuery(
    name: 'review_space.watchByPr',
    handler: (ctx) {
      final prExternalId = ctx.args['pr_external_id'] as String?;
      if (prExternalId == null) {
        throw const NotFoundException('Missing pr_external_id');
      }
      // PR node ids are global; scope to the bound workspace server-side.
      return combineWithVisibility(
        reviewSpaces
            .watchByPr(ctx.workspaceId!, prExternalId)
            .map((a) => {'row': a}),
        watchPrVisibility(ctx.workspaceId!, ctx.userId),
        (frame, visibility) {
          final a = frame['row'] as ReviewSpaceAssociation?;
          return {
            'association':
                a == null || !visibility.canSeeFullName(a.repoFullName)
                ? null
                : reviewSpaceToWire(a),
          };
        },
      );
    },
  ),
  WatchQuery(
    name: 'review_space.watchBySpace',
    handler: (ctx) {
      final spaceId = ctx.args['space_id'] as String?;
      if (spaceId == null) {
        throw const NotFoundException('Missing space_id');
      }
      // The interface keys by space_id alone; enforce ownership on the
      // emitted row — a foreign-workspace association is filtered to null so
      // an ID-only lookup can't leak across workspaces (isolation invariant).
      return combineWithVisibility(
        reviewSpaces
            .watchBySpace(ctx.workspaceId!, spaceId)
            .map((a) => {'row': a}),
        watchPrVisibility(ctx.workspaceId!, ctx.userId),
        (frame, visibility) {
          final a = frame['row'] as ReviewSpaceAssociation?;
          return {
            'association':
                a == null ||
                    a.workspaceId != ctx.workspaceId ||
                    !visibility.canSeeFullName(a.repoFullName)
                ? null
                : reviewSpaceToWire(a),
          };
        },
      );
    },
  ),
  WatchQuery(
    name: 'review_space.watchAllBySpace',
    handler: (ctx) {
      final spaceId = ctx.args['space_id'] as String?;
      if (spaceId == null) {
        throw const NotFoundException('Missing space_id');
      }
      // Workspace-scoped at the query level (the bound workspace), so a
      // foreign-workspace association is never emitted (isolation invariant).
      return combineWithVisibility(
        reviewSpaces
            .watchAllBySpace(ctx.workspaceId!, spaceId)
            .map((list) => {'rows': list}),
        watchPrVisibility(ctx.workspaceId!, ctx.userId),
        (frame, visibility) => {
          'associations': [
            for (final a in frame['rows'] as List<ReviewSpaceAssociation>)
              if (visibility.canSeeFullName(a.repoFullName))
                reviewSpaceToWire(a),
          ],
        },
      );
    },
  ),
];
