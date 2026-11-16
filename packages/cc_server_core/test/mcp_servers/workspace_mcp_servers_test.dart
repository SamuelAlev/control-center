import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/repositories/mcp_server_definition_repository.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/mcp_server_secrets.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/workspace_mcp_servers.dart';
import 'package:test/test.dart';

const _owner = 'user-owner';
const _admin = 'user-admin';
const _ws = 'ws-1';

/// Each workspace's rows in memory, refusing a name clash like the database.
class _MemoryRepository implements WorkspaceMcpServerRepository {
  final Map<String, Map<String, McpServerDefinition>> rows = {};

  @override
  Future<List<McpServerDefinition>> list(String workspaceId) async =>
      (rows[workspaceId]?.values.toList() ?? [])
        ..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<McpServerDefinition?> get(String workspaceId, String id) async =>
      rows[workspaceId]?[id];

  @override
  Future<void> save(McpServerDefinition definition) async {
    final ws = rows.putIfAbsent(definition.workspaceId!, () => {});
    if (ws.values.any(
      (d) => d.id != definition.id && d.name == definition.name,
    )) {
      throw const McpServerDefinitionException.nameTaken();
    }
    ws[definition.id] = definition;
  }

  @override
  Future<bool> delete(String workspaceId, String id) async =>
      rows[workspaceId]?.remove(id) != null;
}

class _Tool extends McpTool {
  _Tool(this.name);

  @override
  final String name;

  @override
  String get description => name;

  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success(name);
}

void main() {
  late _MemoryRepository repository;
  late InMemorySecretStore secrets;
  late McpToolRegistry registry;
  late Map<String, McpClientService> clients;
  late WorkspaceMcpServers servers;
  var ids = 0;

  setUp(() {
    repository = _MemoryRepository();
    secrets = InMemorySecretStore();
    registry = McpToolRegistry(const []);
    clients = {};
    servers = WorkspaceMcpServers(
      repository: repository,
      secrets: McpServerSecrets(secrets),
      registry: registry,
      serverOwnerUserId: _owner,
      clientFactory: (workspaceId, publishTools) =>
          clients[workspaceId] = McpClientService(publishTools: publishTools),
      newId: () => 'srv-${ids++}',
    );
  });
  tearDown(() => servers.shutdown());

  /// The servers the workspace's client was handed (dialled or tracked).
  Set<String> handed(String workspaceId) => {
    for (final s
        in clients[workspaceId]?.serverStatuses ??
            const <McpServerStatusSnapshot>[])
      s.name,
  };

  // Disabled, so nothing is spawned or dialled: a disabled server the client
  // was handed is still tracked, which is what these tests look at.
  McpServerDraft stdio({String? id, String command = 'my-mcp'}) =>
      McpServerDraft(
        id: id,
        name: 'local',
        transport: McpServerTransport.stdio,
        command: command,
        enabled: false,
        envSet: const {'API_TOKEN': 'shh'},
      );

  test('an admin\'s stdio server waits for the server owner and is never '
      'handed to the client until approved', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      draft: stdio().copyEnabled(true),
      actorUserId: _admin,
    );
    expect(saved.hostApproved, isFalse);
    expect(saved.lifecycle, WorkspaceMcpServerEntry.awaitingApproval);
    expect(handed(_ws), isEmpty);

    await expectLater(
      servers.approve(
        workspaceId: _ws,
        id: saved.definition.id,
        actorUserId: _admin,
      ),
      throwsStateError,
    );

    // Approved while disabled, so it is tracked but never started.
    await servers.save(
      workspaceId: _ws,
      draft: stdio(id: saved.definition.id),
      actorUserId: _admin,
    );
    final approved = await servers.approve(
      workspaceId: _ws,
      id: saved.definition.id,
      actorUserId: _owner,
    );
    expect(approved.hostApproved, isTrue);
    expect(approved.definition.hostApprovedBy, _owner);
    expect(handed(_ws), {'local'});
  });

  test('an admin\'s change to the launch drops the approval; toggling it '
      'does not', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      draft: stdio(),
      actorUserId: _owner,
    );
    expect(saved.hostApproved, isTrue, reason: 'the owner saved it');
    final id = saved.definition.id;

    final toggled = await servers.save(
      workspaceId: _ws,
      draft: McpServerDraft(
        id: id,
        name: 'local',
        transport: McpServerTransport.stdio,
        command: 'my-mcp',
        enabled: false,
      ),
      actorUserId: _admin,
    );
    expect(toggled.hostApproved, isTrue);

    final edited = await servers.save(
      workspaceId: _ws,
      draft: stdio(id: id, command: 'something-else'),
      actorUserId: _admin,
    );
    expect(edited.hostApproved, isFalse);
    expect(handed(_ws), isEmpty);
  });

  test('a new value for an existing variable is a launch change', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      draft: stdio(),
      actorUserId: _owner,
    );
    final edited = await servers.save(
      workspaceId: _ws,
      draft: stdio(id: saved.definition.id),
      actorUserId: _admin,
    );
    expect(edited.hostApproved, isFalse);
  });

  test('values stay in the secrets store and out of every entry', () async {
    final saved = await servers.save(
      workspaceId: _ws,
      draft: McpServerDraft(
        name: 'remote',
        transport: McpServerTransport.http,
        url: 'https://mcp.example.com/mcp',
        enabled: false,
        headerSet: const {'Authorization': 'Bearer top-secret'},
      ),
      actorUserId: _admin,
    );
    expect(saved.definition.headerNames, ['Authorization']);
    expect('${saved.toJson()}', isNot(contains('top-secret')));
    expect(
      '${(await servers.list(_ws)).map((e) => e.toJson())}',
      isNot(contains('top-secret')),
    );
    expect(secrets.values.values, contains('Bearer top-secret'));

    // Moving it to a process drops the header value it can no longer use.
    await servers.save(
      workspaceId: _ws,
      draft: stdio(id: saved.definition.id),
      actorUserId: _admin,
    );
    expect(secrets.values.values, isNot(contains('Bearer top-secret')));
    expect(secrets.values.values, contains('shh'));

    await servers.delete(workspaceId: _ws, id: saved.definition.id);
    expect(secrets.values, isEmpty);
    expect(await servers.list(_ws), isEmpty);
  });

  test('an unapproved remote server is confined to public addresses; the '
      'owner\'s approval lifts it', () async {
    final definition = McpServerDefinition(
      id: 's',
      workspaceId: _ws,
      name: 'remote',
      transport: McpServerTransport.http,
      url: 'http://127.0.0.1:9/mcp',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final store = McpServerSecrets(secrets);
    final confined = await store.configFor(
      definition,
      source: WorkspaceMcpServers.source,
      publicOnly: true,
    );
    expect(confined.publicOnly, isTrue);
    expect(
      (await store.configFor(definition, source: 'x')).publicOnly,
      isFalse,
    );
  });

  test('a workspace\'s servers and values are gone with it, and other '
      'workspaces keep theirs', () async {
    await servers.save(workspaceId: _ws, draft: stdio(), actorUserId: _owner);
    await servers.save(
      workspaceId: 'ws-2',
      draft: stdio(),
      actorUserId: _owner,
    );
    registry.setWorkspaceTools(_ws, [_Tool('mcp__local__t')]);
    await servers.forgetWorkspace(_ws);
    expect(
      registry.toolNames(view: const McpToolView(workspaceId: _ws)),
      isEmpty,
    );
    expect(secrets.values.keys, everyElement(contains('ws:ws-2:')));
    expect(secrets.values, isNotEmpty);
  });

  test('a name clash and an unknown id are refused', () async {
    await servers.save(workspaceId: _ws, draft: stdio(), actorUserId: _admin);
    await expectLater(
      servers.save(workspaceId: _ws, draft: stdio(), actorUserId: _admin),
      throwsA(isA<McpServerDefinitionException>()),
    );
    await expectLater(
      servers.save(
        workspaceId: _ws,
        draft: stdio(id: 'ghost'),
        actorUserId: _admin,
      ),
      throwsA(isA<McpServerNotFoundException>()),
    );
    await expectLater(
      servers.delete(workspaceId: 'ws-2', id: 'srv-0'),
      throwsA(isA<McpServerNotFoundException>()),
      reason: 'another workspace cannot reach it by id',
    );
  });
}

extension on McpServerDraft {
  McpServerDraft copyEnabled(bool enabled) => McpServerDraft(
    id: id,
    name: name,
    transport: transport,
    command: command,
    args: args,
    url: url,
    enabled: enabled,
    envSet: envSet,
    envRemove: envRemove,
    headerSet: headerSet,
    headerRemove: headerRemove,
  );
}
