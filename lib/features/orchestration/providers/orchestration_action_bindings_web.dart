// Web binding for the orchestration approve/cancel actions.
//
// Approving/cancelling an orchestration is server-side execution (hires agents,
// starts/cancels pipelines via the concrete engine over the local DB). On web
// it routes over RPC to the host's `orchestration.approve` /
// `orchestration.cancel` ops, executing server-side. The proposal bubble still
// renders (it reads the orchestration over RPC), and the action now drives the
// real materialization on a host that owns the engine (the desktop in-process
// host). Against a HEADLESS server (which omits these ops) the call fails
// loudly and degrades to an honest "orchestration runs on the server host"
// state.
//
// `workspaceId` is a param for parity with the io binding, but the SERVER binds
// the authoritative workspace per session — only `orchestrationId` goes over the
// wire; the op uses `ctx.workspaceId` and re-validates ownership.
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Approves an orchestration proposal over RPC (server-side materialization).
Future<void> approveOrchestration(
  Ref ref, {
  required String workspaceId,
  required String orchestrationId,
}) {
  return RemoteOrchestrationActions(
    ref.read(rpcClientProvider),
  ).approve(orchestrationId);
}

/// Cancels (rejects) an orchestration over RPC (server-side).
Future<void> cancelOrchestration(
  Ref ref, {
  required String workspaceId,
  required String orchestrationId,
}) {
  return RemoteOrchestrationActions(
    ref.read(rpcClientProvider),
  ).cancel(orchestrationId);
}
