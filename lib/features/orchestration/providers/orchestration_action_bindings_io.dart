// Desktop (thin-client) binding for the orchestration approve/cancel actions.
//
// Orchestration materialization (hiring agents, creating teams, starting and
// cancelling pipelines) runs inside the connected `cc_server`, so the desktop
// drives it over RPC via `RemoteOrchestrationActions`, exactly like the web
// client.
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Approves an orchestration proposal and kicks off materialization.
Future<void> approveOrchestration(
  Ref ref, {
  required String workspaceId,
  required String orchestrationId,
}) {
  return RemoteOrchestrationActions(
    ref.read(rpcClientProvider),
  ).approve(orchestrationId);
}

/// Cancels (rejects) an orchestration proposal or a running orchestration.
Future<void> cancelOrchestration(
  Ref ref, {
  required String workspaceId,
  required String orchestrationId,
}) {
  return RemoteOrchestrationActions(
    ref.read(rpcClientProvider),
  ).cancel(orchestrationId);
}
