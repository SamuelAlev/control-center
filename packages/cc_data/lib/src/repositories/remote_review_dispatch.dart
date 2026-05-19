import 'package:cc_rpc/cc_rpc.dart';

/// Dispatches a review-fix agent into a channel over the RPC client — the
/// thin-client "send findings to an agent" path.
///
/// Forwards to the host's `dispatch.reviewFeedbackAgent` op. The agent process
/// spawns SERVER-SIDE via the flutter-bound dispatch stack, so the op is wired
/// only by a host that owns it (the desktop in-process host). Against a HEADLESS
/// server (which omits the op) the call fails loudly and the web client surfaces
/// an honest "runs on the server host" state. The agent's reply streams back
/// through the channel's existing `messaging.watchMessages` subscription.
///
/// Carries no `workspace_id` and no working directory: the op is
/// workspace-scoped, so the host injects the authoritative bound workspace per
/// session and resolves the working directory from it server-side — a client
/// can never aim the agent at an arbitrary directory (the workspace-isolation
/// invariant).
class RemoteReviewDispatch {
  /// Creates a [RemoteReviewDispatch] over [_client].
  RemoteReviewDispatch(this._client);

  final RemoteRpcClient _client;

  /// Dispatches [agentId] with [prompt] into [channelId] (server-side).
  Future<void> dispatch({
    required String agentId,
    required String prompt,
    required String channelId,
  }) => _client.call('dispatch.reviewFeedbackAgent', {
    'agent_id': agentId,
    'prompt': prompt,
    'channel_id': channelId,
  });
}
