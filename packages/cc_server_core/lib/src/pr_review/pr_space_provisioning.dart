import 'dart:async';

import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';

/// Blocks until the (event-driven, idempotent) provisioner has finished a PR
/// space's checkout at the PR head.
///
/// An already-ready space returns at once; otherwise this waits on the
/// workspace's space stream (no polling) for the row to settle. Throws rather
/// than returning on failure, timeout or a space that does not exist: a caller
/// that continued would hand an agent, or an editor, an empty `repos/` and
/// call it a review. The [timeout] runs on the zone's timers, so a test drives
/// it with a fake clock.
Future<void> awaitPrSpaceProvisioning({
  required MessagingRepository messaging,
  required String workspaceId,
  required String spaceId,
  required int prNumber,
  Duration timeout = const Duration(seconds: 120),
}) async {
  // True once [space] says the wait is over; throws when it is over badly.
  bool settled(Space? space) {
    if (space == null) {
      throw StateError('PR space $spaceId for #$prNumber does not exist');
    }
    final status = space.provisioningStatus;
    if (status == SpaceProvisioningStatus.failed) {
      throw StateError('PR worktree provisioning failed for #$prNumber');
    }
    return status == SpaceProvisioningStatus.ready;
  }

  if (settled(await messaging.getSpaceById(workspaceId, spaceId))) {
    return;
  }
  final Space? last;
  try {
    last = await messaging
        .watchSpacesByWorkspace(workspaceId)
        .map((spaces) => spaces.where((s) => s.id == spaceId).firstOrNull)
        .firstWhere((space) => space == null || settled(space))
        .timeout(timeout);
  } on TimeoutException {
    throw StateError('PR worktree provisioning timed out for #$prNumber');
  }
  settled(last);
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
