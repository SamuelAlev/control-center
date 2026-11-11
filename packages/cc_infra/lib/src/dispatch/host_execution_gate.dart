import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';

/// Whether the server owner is accountable for a run in [workspaceId] that
/// [requestedByUserId] asked for: the acting person for an interactive run;
/// for automation the human the gateway's grant resolves (the acting user
/// while still a member, else the workspace owner).
typedef OwnerAccountable =
    Future<bool> Function({
      required String? workspaceId,
      required String? requestedByUserId,
    });

/// Admits or refuses a dispatch under the server's [HostExecutionPosture].
///
/// Asked once per run, before anything starts. The owner fact comes from the
/// server, which knows its owner and the workspace's members; this layer never
/// infers it.
class HostExecutionGate {
  /// Creates a [HostExecutionGate].
  const HostExecutionGate({required this.posture, this.ownerAccountable});

  /// The posture decided at boot.
  final HostExecutionPosture posture;

  /// Answers the owner fact. Null admits nobody under
  /// [HostExecutionPosture.unavailable].
  final OwnerAccountable? ownerAccountable;

  /// Throws [HostSandboxUnavailableException] when the run may not start.
  Future<void> admit({
    required String? workspaceId,
    required String? requestedByUserId,
  }) async {
    if (posture != HostExecutionPosture.unavailable) {
      return;
    }
    final ownerCheck = ownerAccountable;
    final owner =
        ownerCheck != null &&
        await ownerCheck(
          workspaceId: workspaceId,
          requestedByUserId: requestedByUserId,
        );
    if (!posture.admits(ownerAccountable: owner)) {
      throw const HostSandboxUnavailableException();
    }
  }
}
