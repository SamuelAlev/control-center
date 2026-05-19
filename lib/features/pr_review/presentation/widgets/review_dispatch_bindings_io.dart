// Desktop (thin-client) binding for dispatching an agent to address PR review
// findings.
//
// Agent dispatch runs inside the connected `cc_server` (it spawns the sandboxed
// agent process against the server-resident working tree), so the desktop drives
// it over RPC via `RemoteReviewDispatch`, exactly like the web client.
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatches the agent identified by [agentId] with [prompt] to the
/// conversation [channelId], on the server that owns the working tree.
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
