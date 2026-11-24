import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_mcp/cc_mcp.dart' show McpToolDispatcher;
import 'package:cc_server_core/src/runtime/host_execution.dart';
import 'package:test/test.dart';

/// MCP servers discovered in the server OS user's own tool configs (the
/// registry's personal layer) reach only runs the server owner is accountable
/// for. Asserted on the tools a real [DispatchSession] hands the harness loop,
/// with the owner fact answered by the server's own [hostExecutionGate].

const _owner = 'user-owner';
const _member = 'user-member';

/// `ws-owner` is owned by the server owner, `ws-member` by a member; both
/// people belong to both.
const _workspaceOwners = {'ws-owner': _owner, 'ws-member': _member};
const _members = {_owner, _member};

const _personalTool = 'mcp__home__notes_search';

/// A server configured for `ws-owner` (the registry's workspace layer).
const _workspaceTool = 'mcp__linear__create_issue';
const _sharedTool = 'list_things';

class _Tool extends McpTool {
  _Tool(this.name);

  @override
  final String name;

  @override
  String get description => 'Test tool $name.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ran $name');
}

class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedRunLogRepo implements AgentRunLogRepository {
  @override
  Future<void> upsert(AgentRunLog log) async {}

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => null;

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OneKeyStore implements ProviderCredentialStore {
  static const _cred = ProviderCredential(
    providerId: 'openai',
    method: HarnessAuthMethod.apiKey,
    apiKey: 'placeholder',
    accountLabel: 'test',
    baseUrl: 'http://127.0.0.1:1',
  );

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      _cred;

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    _cred,
  ];

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

/// Records every tool name the run handed the loop, eager or deferred.
class _RecordingLoop implements AgentLoop {
  final Set<String> handed = {};
  int runs = 0;

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) {
    runs++;
    handed.addAll([
      for (final t in [...tools, ...deferredTools]) t.name,
    ]);
    return Stream.fromIterable(const [
      LoopTextDelta('done'),
      LoopDone(LoopDoneReason.completed),
    ]);
  }
}

McpToolRegistry _registry() => McpToolRegistry([_Tool(_sharedTool)])
  ..setPersonalTools('ws-owner', _member, [_Tool(_personalTool)])
  ..setWorkspaceTools('ws-owner', [_Tool(_workspaceTool)]);

/// The server's gate, owned by [serverOwner], answering membership the way the
/// agent run gateway does: the acting user while a member, else the
/// workspace owner.
HostExecutionGate _gate({required String? serverOwner}) => hostExecutionGate(
  posture: HostExecutionPosture.offByOwner,
  serverOwnerUserId: serverOwner,
  accountableHuman: (workspaceId, {actingUserId}) async =>
      actingUserId != null && _members.contains(actingUserId)
      ? actingUserId
      : _workspaceOwners[workspaceId],
);

void main() {
  Future<Set<String>> handedToHarness({
    required HostExecutionGate gate,
    required String workspaceId,
    required String? requestedBy,
  }) async {
    final tempDir = Directory.systemTemp.createTempSync('cc_personal_mcp_');
    addTearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException {
        // Best effort: a Windows handle may still be closing.
      }
    });
    final loop = _RecordingLoop();
    final session = DispatchSession(
      freshHistory: false,
      readOnly: false,
      deps: SandboxDispatchDeps(
        hostExecution: gate,
        sandbox: _NoopSandbox(),
        agentRepo: _UnusedAgentRepo(),
        runLogRepo: _UnusedRunLogRepo(),
        eventBus: null,
        resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
            AgentCommitIdentity.person((
              name: 'Test User',
              email: 'test@example.test',
            )),
        backendRegistry: BackendRegistry({
          'cc-harness': const HarnessBackend(),
        }),
        harnessCredentialStore: _OneKeyStore(),
        harnessProviderFactory: const HarnessProviderFactory(),
        agentLoop: loop,
        mcpRegistry: _registry(),
      ),
      onResolveHandle:
          ({
            required String sessionId,
            required SandboxSpec spec,
            required void Function(AgentProcessEvent) emit,
          }) async => SandboxHandle(
            sessionId: sessionId,
            backend: SandboxBackend.none,
            state: SandboxState.warm,
          ),
      onScheduleCooldown: (_) {},
      dispatchId: 'd1',
      cliName: 'cc-harness',
      prompt: 'hello',
      agentDirHostPath: tempDir.path,
      modelId: 'openai/test-model',
      callerEnv: const {},
      agentId: 'agent-1',
      workspaceId: workspaceId,
      conversationId: 'conv-1',
      runLogId: 'run-1',
      mode: Mode.chat,
      requestedByUserId: requestedBy,
    );
    final sub = session.controller.stream.listen((_) {});
    await session.run();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    expect(loop.runs, 1, reason: 'the run reached the harness');
    expect(loop.handed, contains(_sharedTool));
    return loop.handed;
  }

  // `_member` has one server of their own, in `ws-owner`.
  group('a member\'s own MCP servers reach the harness', () {
    test('in a run that member started in that workspace', () async {
      final tools = await handedToHarness(
        gate: _gate(serverOwner: _owner),
        workspaceId: 'ws-owner',
        requestedBy: _member,
      );
      expect(tools, contains(_personalTool));
    });

    test('whether or not a server owner is recorded', () async {
      final tools = await handedToHarness(
        gate: _gate(serverOwner: null),
        workspaceId: 'ws-owner',
        requestedBy: _member,
      );
      expect(tools, contains(_personalTool));
    });
  });

  group('a member\'s own MCP servers never reach the harness', () {
    test('in another member\'s run, the server owner\'s included', () async {
      final tools = await handedToHarness(
        gate: _gate(serverOwner: _owner),
        workspaceId: 'ws-owner',
        requestedBy: _owner,
      );
      expect(tools, isNot(contains(_personalTool)));
    });

    test('in that member\'s run in another workspace', () async {
      final tools = await handedToHarness(
        gate: _gate(serverOwner: _owner),
        workspaceId: 'ws-member',
        requestedBy: _member,
      );
      expect(tools, isNot(contains(_personalTool)));
    });

    test('in automation nobody started', () async {
      final tools = await handedToHarness(
        gate: _gate(serverOwner: _owner),
        workspaceId: 'ws-owner',
        requestedBy: null,
      );
      expect(tools, isNot(contains(_personalTool)));
    });

    test('once that member has left the workspace', () async {
      final tools = await handedToHarness(
        gate: hostExecutionGate(
          posture: HostExecutionPosture.offByOwner,
          serverOwnerUserId: _owner,
          // Nobody is a member any more: the workspace owner answers.
          accountableHuman: (workspaceId, {actingUserId}) async =>
              _workspaceOwners[workspaceId],
        ),
        workspaceId: 'ws-owner',
        requestedBy: _member,
      );
      expect(tools, isNot(contains(_personalTool)));
    });

    test('when the gate cannot say who started the run', () async {
      final tools = await handedToHarness(
        gate: const HostExecutionGate(posture: HostExecutionPosture.offByOwner),
        workspaceId: 'ws-owner',
        requestedBy: _member,
      );
      expect(tools, isNot(contains(_personalTool)));
    });

    test('when the membership check fails', () async {
      final tools = await handedToHarness(
        gate: HostExecutionGate(
          posture: HostExecutionPosture.offByOwner,
          startedBy: ({required workspaceId, required requestedByUserId}) =>
              Future.error(StateError('membership lookup failed')),
        ),
        workspaceId: 'ws-owner',
        requestedBy: _member,
      );
      expect(tools, isNot(contains(_personalTool)));
    });
  });

  group('the MCP surface every run and paired device shares', () {
    test('never lists a personal tool', () async {
      final dispatcher = McpToolDispatcher(registry: _registry());
      final response = await dispatcher.handleRequest(
        JsonRpcRequest(method: 'tools/list', params: const {}, id: 1),
      );
      final tools =
          (response['result'] as Map<String, dynamic>)['tools'] as List;
      final names = {
        for (final t in tools) (t as Map<String, dynamic>)['name'],
      };
      expect(names, contains(_sharedTool));
      expect(names, isNot(contains(_personalTool)));
    });

    test('never calls a personal tool, nor names it', () async {
      final dispatcher = McpToolDispatcher(registry: _registry());
      final response = await dispatcher.handleRequest(
        JsonRpcRequest(
          method: 'tools/call',
          params: const {
            'name': _personalTool,
            'arguments': <String, dynamic>{},
          },
          id: 2,
        ),
      );
      expect(response['result'], isNull);
      final error = response['error'] as Map<String, dynamic>;
      expect(error['message'], contains('Unknown tool'));
      expect('$response', isNot(contains('ran $_personalTool')));
    });

    test('never offers a personal tool to catalogue search', () {
      final names = _registry().allToolDefinitions().map((d) => d.name);
      expect(names, contains(_sharedTool));
      expect(names, isNot(contains(_personalTool)));
      expect(names, isNot(contains(_workspaceTool)));
    });
  });

  group('a workspace\'s configured MCP servers', () {
    test('reach every harness run in that workspace', () async {
      final tools = await handedToHarness(
        gate: _gate(serverOwner: _owner),
        workspaceId: 'ws-owner',
        requestedBy: _owner,
      );
      expect(tools, contains(_workspaceTool));
      expect(tools, isNot(contains(_personalTool)));
    });

    test('never reach a run in another workspace', () async {
      final tools = await handedToHarness(
        gate: _gate(serverOwner: _owner),
        workspaceId: 'ws-member',
        requestedBy: _owner,
      );
      expect(tools, isNot(contains(_workspaceTool)));
    });

    Future<Set<Object?>> listed(McpCallScope? scope) async {
      final dispatcher = McpToolDispatcher(registry: _registry());
      final response = await dispatcher.handleScopedRequest(
        JsonRpcRequest(method: 'tools/list', params: const {}, id: 1),
        scope: scope,
      );
      final tools =
          (response['result'] as Map<String, dynamic>)['tools'] as List;
      return {for (final t in tools) (t as Map<String, dynamic>)['name']};
    }

    Future<Map<String, dynamic>> called(String tool, McpCallScope? scope) =>
        McpToolDispatcher(registry: _registry()).handleScopedRequest(
          JsonRpcRequest(
            method: 'tools/call',
            params: {'name': tool, 'arguments': <String, dynamic>{}},
            id: 2,
          ),
          scope: scope,
        );

    const ownerRun = McpCallScope(
      workspaceId: 'ws-owner',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      attested: true,
    );

    test('reach a Claude Code run of that workspace through the MCP '
        'endpoint, callable though they name no workspace', () async {
      expect(await listed(ownerRun), contains(_workspaceTool));
      final response = await called(_workspaceTool, ownerRun);
      expect('$response', contains('ran $_workspaceTool'));
    });

    test('are neither listed nor callable for a run of another '
        'workspace', () async {
      const other = McpCallScope(workspaceId: 'ws-member', attested: true);
      expect(await listed(other), isNot(contains(_workspaceTool)));
      final response = await called(_workspaceTool, other);
      expect(
        (response['error'] as Map<String, dynamic>)['message'],
        contains('Unknown tool'),
      );
    });

    test('are never served to the owner\'s token or a paired device, '
        'whatever workspace their headers name', () async {
      const unattested = McpCallScope(workspaceId: 'ws-owner');
      expect(await listed(null), isNot(contains(_workspaceTool)));
      expect(await listed(unattested), isNot(contains(_workspaceTool)));
      final response = await called(_workspaceTool, unattested);
      expect('$response', isNot(contains('ran $_workspaceTool')));
    });

    test('a member\'s own servers reach a Claude Code run only when its '
        'grant names that member', () async {
      expect(await listed(ownerRun), isNot(contains(_personalTool)));
      const another = McpCallScope(
        workspaceId: 'ws-owner',
        attested: true,
        personalMcpUserId: _owner,
      );
      expect(await listed(another), isNot(contains(_personalTool)));
      const elsewhere = McpCallScope(
        workspaceId: 'ws-member',
        attested: true,
        personalMcpUserId: _member,
      );
      expect(await listed(elsewhere), isNot(contains(_personalTool)));
      const mine = McpCallScope(
        workspaceId: 'ws-owner',
        attested: true,
        personalMcpUserId: _member,
      );
      expect(await listed(mine), contains(_personalTool));
      final response = await called(_personalTool, mine);
      expect('$response', contains('ran $_personalTool'));
    });

    test('a workspace server never shadows a member\'s own of the same name '
        'in that member\'s run', () async {
      final own = _Tool('mcp__x__t');
      final registry = McpToolRegistry(const [])
        ..setPersonalTools('ws-owner', _member, [own])
        ..setWorkspaceTools('ws-owner', [_Tool('mcp__x__t')]);
      expect(
        registry.lookup(
          'mcp__x__t',
          view: const McpToolView(
            workspaceId: 'ws-owner',
            personalUserId: _member,
          ),
        ),
        same(own),
      );
    });
  });
}
