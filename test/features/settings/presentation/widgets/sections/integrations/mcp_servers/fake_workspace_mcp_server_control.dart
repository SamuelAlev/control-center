import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;

/// A scripted [WorkspaceMcpServerControl]: lists the servers of each scope,
/// records every call, and answers sign-ins from `begins` and `completions`
/// in order.
class FakeWorkspaceMcpServerControl implements WorkspaceMcpServerControl {
  /// Creates the fake.
  FakeWorkspaceMcpServerControl({
    this.workspace = const [],
    this.personal = const [],
    this.unavailable = false,
    List<Object>? begins,
    List<McpServerAuthorization>? completions,
  }) : begins = begins ?? [authorization()],
       completions = completions ?? [];

  /// The workspace's servers.
  final List<WorkspaceMcpServerEntry> workspace;

  /// The caller's own servers.
  final List<WorkspaceMcpServerEntry> personal;

  /// Whether the server lacks the `mcpServers.*` ops.
  final bool unavailable;

  /// What each `beginAuthorization` returns ([McpServerAuthorization]) or
  /// throws (anything else), in order; the last one repeats.
  final List<Object> begins;

  /// What each `completeAuthorization` returns, in order.
  final List<McpServerAuthorization> completions;

  /// Every call but `list`, as `op workspace scope args…`.
  final calls = <String>[];

  /// The drafts saved.
  final saved = <McpServerDraft>[];

  /// `list` calls per scope.
  final listCalls = <McpServerScope, int>{};

  List<WorkspaceMcpServerEntry> _of(McpServerScope scope) =>
      scope == McpServerScope.workspace ? workspace : personal;

  @override
  Future<List<WorkspaceMcpServerEntry>> list(
    String workspaceId,
    McpServerScope scope,
  ) async {
    listCalls[scope] = (listCalls[scope] ?? 0) + 1;
    if (unavailable) {
      throw RemoteRpcException(RpcErrorCodes.opUnknown, 'unknown op');
    }
    return _of(scope);
  }

  @override
  Future<WorkspaceMcpServerEntry> save(
    String workspaceId,
    McpServerScope scope,
    McpServerDraft draft,
  ) async {
    saved.add(draft);
    calls.add('save $workspaceId ${scope.wire} ${draft.id}');
    return _of(scope).firstWhere((e) => e.definition.id == draft.id);
  }

  @override
  Future<void> delete(
    String workspaceId,
    McpServerScope scope,
    String id,
  ) async => calls.add('delete $workspaceId ${scope.wire} $id');

  @override
  Future<WorkspaceMcpServerEntry> approve(String workspaceId, String id) async {
    calls.add('approve $workspaceId $id');
    return workspace.firstWhere((e) => e.definition.id == id);
  }

  @override
  Future<void> reconnect(
    String workspaceId,
    McpServerScope scope,
    String id,
  ) async => calls.add('reconnect $workspaceId ${scope.wire} $id');

  int _begun = 0;

  @override
  Future<McpServerAuthorization> beginAuthorization(
    String workspaceId,
    McpServerScope scope,
    String id,
  ) async {
    calls.add('authorize $workspaceId ${scope.wire} $id');
    final next = begins[_begun < begins.length ? _begun : begins.length - 1];
    _begun++;
    if (next is McpServerAuthorization) {
      return next;
    }
    throw next;
  }

  @override
  Future<McpServerAuthorization> completeAuthorization(
    String workspaceId,
    McpServerScope scope,
    String attemptId,
    String code,
  ) async {
    calls.add('complete $workspaceId ${scope.wire} $attemptId $code');
    return completions.removeAt(0);
  }
}

/// An authorization of attempt [attemptId] in [status].
McpServerAuthorization authorization({
  String attemptId = 'att-1',
  String url = 'https://auth.example.com/authorize?state=s1',
  McpServerAuthorizationStatus status = McpServerAuthorizationStatus.pending,
  int triesLeft = 0,
}) => McpServerAuthorization(
  attemptId: attemptId,
  url: url,
  status: status,
  triesLeft: triesLeft,
);

final _at = DateTime.utc(2026, 11, 2);

/// A command server of the workspace, awaiting the owner's approval.
WorkspaceMcpServerEntry stdioEntry() => WorkspaceMcpServerEntry(
  definition: McpServerDefinition(
    id: 'srv-1',
    workspaceId: 'ws-1',
    name: 'github',
    transport: McpServerTransport.stdio,
    command: 'npx',
    args: const ['-y', 'server-github'],
    envNames: const ['GITHUB_TOKEN'],
    createdAt: _at,
    updatedAt: _at,
  ),
  lifecycle: WorkspaceMcpServerEntry.awaitingApproval,
  hostApproved: false,
);

/// A remote server; [userId] makes it that member's own.
WorkspaceMcpServerEntry httpEntry({
  String id = 'srv-2',
  String name = 'linear',
  bool approved = true,
  String lifecycle = 'connected',
  bool enabled = true,
  String? userId,
}) => WorkspaceMcpServerEntry(
  definition: McpServerDefinition(
    id: id,
    workspaceId: 'ws-1',
    userId: userId,
    name: name,
    transport: McpServerTransport.http,
    url: 'https://mcp.example.com/mcp',
    headerNames: const ['Authorization'],
    enabled: enabled,
    hostApprovedBy: approved ? 'owner' : null,
    createdAt: _at,
    updatedAt: _at,
  ),
  lifecycle: lifecycle,
  hostApproved: approved,
  toolCount: lifecycle == 'connected' ? 7 : 0,
);
