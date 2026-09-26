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
