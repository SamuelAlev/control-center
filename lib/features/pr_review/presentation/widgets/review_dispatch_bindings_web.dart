// Web binding for dispatching an agent to address PR review findings.
//
// The agent process spawns SERVER-SIDE; the thin client drives it over the RPC
// `dispatch.reviewFeedbackAgent` op (forwarded by [RemoteReviewDispatch]). The
// working directory is resolved host-side from the bound workspace, so the
// client-side [workingDir] argument is ignored here (the desktop seam still uses
// it for the in-process path). Against a HEADLESS server the op is absent and
// the call fails loudly. The agent's reply streams back through the channel's
// existing `messaging.watchMessages` subscription.
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatches the agent identified by [agentId] with [prompt] over RPC. The
/// server resolves the working directory from the bound workspace, so
/// [workingDir] (and the client [workspaceId]) are not sent over the wire.
Future<void> dispatchReviewFeedbackAgent(
  WidgetRef ref, {
  required String agentId,
  required String prompt,
  required String workingDir,
  String? workspaceId,
  required String channelId,
}) {
  return RemoteReviewDispatch(ref.read(rpcClientProvider)).dispatch(
    agentId: agentId,
    prompt: prompt,
    channelId: channelId,
  );
}
