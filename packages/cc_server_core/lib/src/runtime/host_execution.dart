import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/cc_infra.dart' show HostExecutionGate;

/// The dispatch gate for [posture], with the owner fact this server answers.
///
/// A run is the server owner's when its accountable human is
/// [serverOwnerUserId]: the acting person for an interactive run, and for
/// automation whoever [accountableHuman] resolves, the way the agent run
/// gateway's grant does (the acting user while still a member, else the
/// workspace owner). A run with no workspace is the owner's only when the
/// owner asked for it.
HostExecutionGate hostExecutionGate({
  required HostExecutionPosture posture,
  required String? serverOwnerUserId,
  required Future<String?> Function(String workspaceId, {String? actingUserId})
  accountableHuman,
}) => HostExecutionGate(
  posture: posture,
  ownerAccountable:
      ({
        required String? workspaceId,
        required String? requestedByUserId,
      }) async {
        final owner = serverOwnerUserId;
        if (owner == null || owner.isEmpty) {
          return false;
        }
        if (workspaceId == null || workspaceId.isEmpty) {
          return requestedByUserId == owner;
        }
        return await accountableHuman(
              workspaceId,
              actingUserId: requestedByUserId,
            ) ==
            owner;
      },
);
