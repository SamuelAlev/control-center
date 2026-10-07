import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';

/// Blocks until the (event-driven, idempotent) provisioner has finished a PR
/// space's checkout at the PR head.
///
/// An already-ready space returns on the first poll. Throws rather than
/// returning on failure or timeout: a caller that continued would hand an
/// agent, or an editor, an empty `repos/` and call it a review.
Future<void> awaitPrSpaceProvisioning({
  required MessagingRepository messaging,
  required String workspaceId,
  required String spaceId,
  required int prNumber,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 120));
  while (true) {
    final ch = await messaging.getSpaceById(workspaceId, spaceId);
    final status = ch?.provisioningStatus ?? SpaceProvisioningStatus.ready;
    if (status == SpaceProvisioningStatus.ready) {
      return;
    }
    if (status == SpaceProvisioningStatus.failed) {
      throw StateError('PR worktree provisioning failed for #$prNumber');
    }
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('PR worktree provisioning timed out for #$prNumber');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

/// The association backing pull request `repoFullName#prNumber`, or null when
/// it has none yet.
///
/// The forge id is the fast key, but repo + number is the identity: a PR's
/// space is checked out at `refs/pull/<number>/head` of that repo, so reusing a
/// row for any other PR would hand this one another PR's tree. A by-id hit that
/// names a different PR is ignored, and an empty id (a forge payload without a
/// node id, or a row written before ids were read) is never looked up at all —
/// every such row shares the key ''. Repo + number then finds the row whatever
/// id it was written under.
Future<ReviewSpaceAssociation?> findPrSpaceAssociation(
  ReviewSpaceRepository associations, {
  required String workspaceId,
  required String repoFullName,
  required int prNumber,
  required String prExternalId,
}) async {
  bool isThisPr(ReviewSpaceAssociation a) =>
      a.repoFullName == repoFullName && a.prNumber == prNumber;
  if (prExternalId.isNotEmpty) {
    final byId = await associations.watchByPr(workspaceId, prExternalId).first;
    if (byId != null && isThisPr(byId)) {
      return byId;
    }
  }
  // Newest first, so a PR associated more than once resolves to its latest.
  final all = await associations.watchByWorkspace(workspaceId).first;
  for (final a in all) {
    if (isThisPr(a)) {
      return a;
    }
  }
  return null;
}
