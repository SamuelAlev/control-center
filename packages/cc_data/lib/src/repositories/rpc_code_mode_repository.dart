import 'package:cc_domain/cc_domain.dart'
    show
        CodeExecutionDetailDto,
        CodeExecutionPageDto,
        CodeModeStatusDto,
        RpcErrorCodes;
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart'
    show kCodeModeLimitsSettingKey;
import 'package:cc_rpc/cc_rpc.dart';

/// Code mode over the RPC client: whether the server runs scripts, a
/// workspace's limits, and the executions its runs recorded.
///
/// Backs the `codeMode.*` ops. Every call names its workspace; the server
/// checks it is registered, then membership, then (for executions) the space
/// read gate, and answers only from that workspace. An execution id is opaque
/// (`<runId>/<toolCallId>`, sometimes with `#<n>`): pass it back exactly as it
/// came, and encode it as one path segment when it goes into a route.
class RpcCodeModeRepository {
  /// Creates an [RpcCodeModeRepository] over [_client].
  RpcCodeModeRepository(this._client);

  final RemoteRpcClient _client;

  /// Whether this server runs scripts (why not, when it does not), its caps
  /// and the limits a script in [workspaceId] runs under.
  ///
  /// Needs a member of the workspace.
  Future<CodeModeStatusDto> status(String workspaceId) async {
    final data = await _client.call('codeMode.status', {
      'workspace_id': workspaceId,
    });
    return CodeModeStatusDto.fromJson(
      (data['status'] as Map).cast<String, dynamic>(),
    );
  }

  /// Sets [workspaceId]'s limit overrides (keys as
  /// `CodeModeLimits.adjustable` names them), or clears them with null.
  ///
  /// Needs an admin. A key the server does not know
  /// (`code_mode_limit_unknown`) or a value outside its bound
  /// (`code_mode_limit_out_of_range`) is refused and nothing is stored.
  Future<void> setWorkspaceLimits(
    String workspaceId,
    Map<String, int>? overrides,
  ) => _client.call('codeMode.setWorkspaceSetting', {
    'workspace_id': workspaceId,
    'key': kCodeModeLimitsSettingKey,
    'value': overrides,
  });

  /// One page of [workspaceId]'s executions, newest first, summary fields
  /// only.
  ///
  /// Executions in spaces the caller cannot read are left out, so a page can
  /// be short (even empty) while [CodeExecutionPage.nextCursor] is set: keep
  /// paging until it is null.
  Future<CodeExecutionPage> listExecutions(
    String workspaceId,
    CodeExecutionQuery query,
  ) async {
    final data = await _client.call('codeMode.listExecutions', {
      'workspace_id': workspaceId,
      'cursor': ?query.cursor,
      'limit': query.limit,
      'run_id': ?query.runId,
      'tool_call_id': ?query.toolCallId,
      'conversation_id': ?query.conversationId,
      'agent_id': ?query.agentId,
      'space_id': ?query.spaceId,
      if (query.statuses.isNotEmpty)
        'statuses': [for (final s in query.statuses) s.wire],
      'surface': ?query.surface?.wire,
      'since': ?query.since?.toUtc().toIso8601String(),
      'until': ?query.until?.toUtc().toIso8601String(),
    });
    return CodeExecutionPageDto.fromJson(data).toPage();
  }

  /// One execution of [workspaceId] with its source, output and nested
  /// calls, or null when there is none with [executionId] in that workspace.
  Future<CodeExecutionDetail?> getExecution(
    String workspaceId,
    String executionId,
  ) async {
    try {
      final data = await _client.call('codeMode.getExecution', {
        'workspace_id': workspaceId,
        'id': executionId,
      });
      return CodeExecutionDetailDto.fromJson(
        (data['execution'] as Map).cast<String, dynamic>(),
      ).toDetail();
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }
}
