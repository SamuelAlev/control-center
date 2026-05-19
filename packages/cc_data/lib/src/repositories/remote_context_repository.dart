import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads the server-side context-window breakdown over the RPC client.
///
/// Mirrors the weather client: the inspection is workspace-scoped and the
/// workspace rides in the request args (the host is stateless — it binds no
/// "current workspace"), so the call never passes a `workspace_id` — the host
/// injects the authoritative one and scopes every query by it. Backs the
/// `context.inspect` op in the host catalog.
///
/// The payload carries only the PERSISTENT context (system prompt, rules,
/// skills, tool surface, subagents, memory); the conversation segment is
/// composed client-side from the live messages, so the meter stays live
/// without an RPC per message.
class RemoteContextRepository {
  /// Creates a [RemoteContextRepository] over [_client].
  RemoteContextRepository(this._client);

  final RemoteRpcClient _client;

  /// The persistent context breakdown for ([spaceId], [agentId]).
  ///
  /// [includeContent] asks the server to carry every part's verbatim text (the
  /// explorer); the default summary carries counts only.
  Future<ContextInspection> inspect({
    required String spaceId,
    required String agentId,
    bool includeContent = false,
  }) async {
    final data = await _client.call('context.inspect', {
      'space_id': spaceId,
      'agent_id': agentId,
      'include_content': includeContent,
    });
    return ContextInspection.fromJson(
      (data['inspection'] as Map).cast<String, dynamic>(),
    );
  }
}
