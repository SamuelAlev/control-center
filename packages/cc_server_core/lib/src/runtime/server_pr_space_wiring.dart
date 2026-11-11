part of '../cc_server_runtime.dart';

/// The PR workbench's `ensurePrSpace`: idempotently ensures a PR has a
/// backing space (mode review), linked via the review-space association, and
/// kicks off provisioning of its repo worktree at the PR head. Reused by the
/// chat, terminal and file surfaces so the whole PR page hangs off one space.
/// Returns `{space_id, provisioning_status}`.
Future<Map<String, dynamic>> Function({
  required String workspaceId,
  required String repoFullName,
  required int prNumber,
  required String prExternalId,
  String? createdByUserId,
  String title,
})
_prSpaceEnsurer({
  required DaoReviewSpaceRepository reviewSpaceRepository,
  required DaoMessagingRepository messagingRepository,
  required WorkspaceDatabaseManager workspaceDbs,
  required SpaceProvisioningService spaceProvisioningService,
  required DomainEventBus eventBus,
}) =>
    ({
      required String workspaceId,
      required String repoFullName,
      required int prNumber,
      required String prExternalId,
      String? createdByUserId,
      String title = '',
    }) async {
      final existing = await findPrSpaceAssociation(
        reviewSpaceRepository,
        workspaceId: workspaceId,
        repoFullName: repoFullName,
        prNumber: prNumber,
        prExternalId: prExternalId,
      );
      if (existing != null &&
          await messagingRepository.spaceExists(
            workspaceId,
            existing.spaceId,
          )) {
        final ch = await messagingRepository.getSpaceById(
          workspaceId,
          existing.spaceId,
        );
        var status = ch?.provisioningStatus ?? SpaceProvisioningStatus.ready;
        // A space whose last provision ended badly is re-provisioned, not
        // reported. `SpaceCreated` fires once, at creation, so a space that
        // reached `failed` (or was stopped) had nothing left that would ever try
        // again: every later "Ask AI" on that pull request read the stale row and
        // threw `PR worktree provisioning failed` for ever, with the only escape
        // being to delete the space by hand. `provision` is idempotent and is the
        // same call the space banner's Retry makes — the failure is usually a
        // leftover the attempt itself cleans up, so the retry is what heals it.
        if (status.isStopped) {
          // Flip the row FIRST. `provision` sets `provisioning` itself, but it
          // runs unawaited and `awaitPrProvisioning` starts polling the moment
          // this returns — losing that race would read the old `failed` and
          // throw before the retry had begun.
          await workspaceDbs
              .of(workspaceId)
              .messagingDao
              .updateSpaceProvisioningStatus(
                existing.spaceId,
                SpaceProvisioningStatus.provisioning.toDbValue(),
              );
          CcHostLog.info(
            'PR space ${existing.spaceId} was ${status.toDbValue()}; '
            're-provisioning for #$prNumber',
          );
          unawaited(
            spaceProvisioningService
                .provision(workspaceId: workspaceId, spaceId: existing.spaceId)
                .catchError((Object err, StackTrace st) {
                  CcHostLog.error(
                    're-provisioning failed for ${existing.spaceId}: $err',
                    err,
                    st,
                  );
                }),
          );
          status = SpaceProvisioningStatus.provisioning;
        }
        return {
          'space_id': existing.spaceId,
          'provisioning_status': status.toDbValue(),
        };
      }
      final name = reviewSpaceName(prNumber, title);
      // Through [SpaceFactory] — the same chokepoint every other creation path
      // uses — so the row and its `SpaceCreated` cannot come apart. The
      // association is written in `beforeAnnounce` rather than after the call
      // because it is what the PR-aware provisioner reads to resolve the head ref
      // it checks out; announcing first races it into the default branch.
      final space =
          await SpaceFactory(
            repository: messagingRepository,
            eventBus: eventBus,
          ).create(
            workspaceId,
            name,
            const <String>[],
            mode: Mode.review,
            createdByUserId: createdByUserId,
            // Workbench spaces stay out of the sidebar until someone actually
            // messages in them — opening a PR must not mint visible spaces.
            kind: SpaceKind.pr,
            beforeAnnounce: (space) => reviewSpaceRepository.create(
              spaceId: space.id,
              workspaceId: workspaceId,
              prExternalId: prExternalId,
              prNumber: prNumber,
              repoFullName: repoFullName,
            ),
          );
      return {
        'space_id': space.id,
        'provisioning_status': SpaceProvisioningStatus.provisioning.toDbValue(),
      };
    };
