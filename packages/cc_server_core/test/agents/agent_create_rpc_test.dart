import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/agents/domain/usecases/create_agent.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/agents/agent_create_rpc.dart';
import 'package:test/test.dart';

void main() {
  late _FakeAgents agents;
  late RepoOp create;

  setUp(() {
    agents = _FakeAgents();
    create = buildAgentCreateOps(
      agentRepository: agents,
      filesystem: _NoFs(),
    ).singleWhere((o) => o.name == 'agents.create');
  });

  RepoOpContext ctx(Map<String, dynamic> args) => RepoOpContext(
    args: args,
    workspaceId: 'ws-1',
    deviceId: 'dev-1',
    userId: 'user-1',
    role: WorkspaceRole.admin,
  );

  test('mints an agent and refuses a duplicate name', () async {
    final first = await create.handler(
      ctx({'name': 'reviewer', 'title': 'Reviewer'}),
    );
    final wire = first['agent'] as Map;
    expect(wire['name'], 'reviewer');
    expect(wire['id'], isNotEmpty);
    expect(agents.store, hasLength(1));

    await expectLater(
      create.handler(ctx({'name': 'reviewer', 'title': 'Other'})),
      throwsA(isA<DuplicateAgentNameException>()),
    );
    expect(agents.store, hasLength(1));
  });
}

class _FakeAgents implements AgentRepository {
  final Map<String, Agent> store = {};

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    for (final a in store.values) {
      if (a.workspaceId == workspaceId && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    store[agent.id] = agent;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoFs implements WorkspaceFilesystemPort {
  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      '$workspaceId/agents/$agentSlug/AGENTS.md';

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String agentSlug,
    String content,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
