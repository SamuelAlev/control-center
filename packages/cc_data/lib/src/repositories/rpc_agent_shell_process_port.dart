import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_domain/core/domain/ports/agent_shell_process_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AgentShellProcessPort] over the RPC client: the shell commands live in
/// the SERVER's process table, so the TERMINALS section lists them over
/// `process.agentShells` and stops one over `process.killAgentShell`.
///
/// A host that wires no lister leaves the ops absent (`opUnknown`); the list
/// then reads empty rather than failing the section.
class RpcAgentShellProcessPort implements AgentShellProcessPort {
  /// Creates an [RpcAgentShellProcessPort] over [_client].
  RpcAgentShellProcessPort(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<AgentShellProcess>> list({
    required String workspaceId,
    required String spaceId,
  }) async {
    try {
      final data = await _client.call('process.agentShells', {
        'workspace_id': workspaceId,
        'space_id': spaceId,
      });
      return [
        for (final raw in (data['processes'] as List?) ?? const [])
          if (raw is Map)
            ?_fromWire(raw.cast<String, dynamic>(), workspaceId, spaceId),
      ];
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<bool> kill({
    required String workspaceId,
    required String spaceId,
    required int pid,
  }) async {
    final data = await _client.call('process.killAgentShell', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'pid': pid,
    });
    return data['killed'] == true;
  }

  static AgentShellProcess? _fromWire(
    Map<String, dynamic> w,
    String workspaceId,
    String spaceId,
  ) {
    final pid = (w['pid'] as num?)?.toInt() ?? 0;
    final started = DateTime.tryParse(w['started_at'] as String? ?? '');
    if (pid <= 0 || started == null) {
      return null;
    }
    return AgentShellProcess(
      pid: pid,
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: w['agent_id'] as String? ?? '',
      runId: w['run_id'] as String?,
      command: w['command'] as String? ?? '',
      startedAt: started.toLocal(),
      origin:
          AgentShellOrigin.values.asNameMap()[w['origin']] ??
          AgentShellOrigin.cli,
    );
  }
}
