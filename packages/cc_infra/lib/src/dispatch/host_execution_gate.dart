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

/// The member who started a run in [workspaceId]: [requestedByUserId] while
/// they are still a member of it, else null. A run nobody started
/// (automation) has none.
typedef RunStartedBy =
    Future<String?> Function({
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
  const HostExecutionGate({
    required this.posture,
    this.ownerAccountable,
    this.startedBy,
  });

  /// The posture decided at boot.
  final HostExecutionPosture posture;

  /// Answers the owner fact. Null admits nobody under
  /// [HostExecutionPosture.unavailable].
  final OwnerAccountable? ownerAccountable;

  /// Answers who started a run, which decides whose own MCP servers it is
  /// handed. Null hands out nobody's.
  final RunStartedBy? startedBy;

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
