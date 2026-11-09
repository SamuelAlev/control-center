/// Dispatching an agent to address PR review findings.
///
/// The agent process spawns on the connected `cc_server`, against its own
/// working tree; every client drives it over the `dispatch.reviewFeedbackAgent`
/// op (`RemoteReviewDispatch`). The server resolves the working directory from
/// the request's workspace, so `workingDir` and `workspaceId` are not sent.
/// The agent's reply streams back through the space's existing
/// `messaging.watchMessages` subscription.
library;

import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dispatches the agent identified by [agentId] with [prompt] to the
/// conversation [spaceId], on the server that owns the working tree.
Future<void> dispatchReviewFeedbackAgent(
  WidgetRef ref, {
  required String agentId,
  required String prompt,
  required String workingDir,
  String? workspaceId,
  required String spaceId,
  String? conversationId,
}) {
  return RemoteReviewDispatch(ref.read(rpcClientProvider)).dispatch(
    agentId: agentId,
    prompt: prompt,
    spaceId: spaceId,
    conversationId: conversationId,
  );
}
