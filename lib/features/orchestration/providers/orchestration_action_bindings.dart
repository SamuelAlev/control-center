/// The orchestration approve/cancel actions invoked by the proposal bubble's
/// notifier.
///
/// Materialization (hiring agents, creating teams, starting and cancelling
/// pipelines) runs inside the connected `cc_server`; every client drives it
/// over RPC (`orchestration.approve` / `orchestration.cancel`). Only the
/// orchestration id goes over the wire: the request's `workspace_id` names
/// the workspace and the server re-validates that the orchestration belongs
/// to it.
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
