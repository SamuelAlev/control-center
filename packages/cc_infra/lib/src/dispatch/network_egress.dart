import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Resolves the "network egress" rule for a sandboxed process in
/// [workspaceId]: only a deny takes the sandbox's network away. Without a
/// [guard] (tests, minimal hosts) or a workspace there is no rule to read, and
/// the network stays on; a failed resolution keeps it on too, and says so
/// under [label].
Future<bool> resolveNetworkEgress(
  ActionGuardService? guard, {
  required String? workspaceId,
  required Mode mode,
  required String label,
  String? spaceId,
  String? agentId,
}) async {
  if (guard == null || workspaceId == null || workspaceId.isEmpty) {
    return true;
  }
  try {
    final resolution = await guard.resolve(
      workspaceId: workspaceId,
      classes: const {ActionClass.networkEgress},
      spaceId: spaceId,
      agentId: agentId,
      mode: mode,
    );
    return resolution.decision != ActionDecision.deny;
  } on Object catch (e) {
    CcInfraLog.warning(
      '$label: network-egress rule resolution failed, keeping the network '
      'on: $e',
    );
    return true;
  }
}
