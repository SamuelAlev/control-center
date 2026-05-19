import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [RemoteRpcChannelPort]: inject frames via [inject], inspect
/// outbound frames via [sent].
class _FakeChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> sent = [];
  final _stateController = StreamController<RemoteChannelState>.broadcast();
  bool open = true;

  void inject(Map<String, dynamic> frame) => _incoming.add(frame);

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _stateController.stream;

  @override
  bool get isOpen => open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    sent.add(frame);
  }

  @override
  Future<void> close() async {
    open = false;
    _stateController.add(RemoteChannelState.closed);
  }
}

/// Echoes its arguments back as JSON so the test can inspect exactly which
/// arguments the dispatcher received. The server is stateless, so the args reach
/// the tool unchanged (no session-level workspace injection or override).
/// Registered under a configurable [name] so tests can use both an allow-listed
/// tool ([RemoteToolPolicy]) and a disallowed one.
class _ArgsEchoTool extends McpTool {
  _ArgsEchoTool(this.name);

  @override
  final String name;

  @override
  String get description => 'Echoes arguments.';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    return CallResult.success(jsonEncode(arguments));
  }
}

Map<String, dynamic> _toolsCall(
  String tool,
  Map<String, dynamic> args, {
  Object? id = 1,
}) => JsonRpcRequest(
  method: 'tools/call',
  params: {'name': tool, 'arguments': args},
  id: id,
).toJson();

Map<String, dynamic>? _resultText(Map<String, dynamic> response) {
  final result = response['result'] as Map<String, dynamic>?;
  if (result == null) {
    return null;
  }
  final content = result['content'] as List;
  final text = (content.first as Map)['text'] as String;
  return jsonDecode(text) as Map<String, dynamic>;
}

void main() {
  // An allow-listed read tool and a disallowed mutating tool, both echoing args.
  const allowedTool = 'list_tickets';
  const disallowedTool = 'kill_agent';

  late McpToolDispatcher dispatcher;
  late _FakeChannel channel;
  late RemoteRpcSession session;

  RemoteRpcSession buildSession({RemoteRateLimiter? rateLimiter}) {
    return RemoteRpcSession(
      deviceId: 'dev-1',
      channel: channel,
      dispatcher: dispatcher,
      capability: SessionCapability.fullClient,
      workspaceResolver: () async => const [
        (id: 'workspace-a', name: 'Alpha'),
        (id: 'workspace-b', name: 'Beta'),
      ],
      rateLimiter: rateLimiter,
    );
  }

  setUp(() async {
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([
        _ArgsEchoTool(allowedTool),
        _ArgsEchoTool(disallowedTool),
      ]),
    );
    channel = _FakeChannel();
    session = buildSession();
    await session.start();
  });

  tearDown(() async {
    await session.stop();
  });

  test(
    'tools/call reaches the shared dispatcher and returns its response',
    () async {
      channel.inject(_toolsCall(allowedTool, {'foo': 'bar'}));
      await Future<void>.delayed(Duration.zero);
      expect(channel.sent, hasLength(1));
      final response = channel.sent.single;
      expect(response['id'], 1);
      final args = _resultText(response)!;
      expect(args['foo'], 'bar');
    },
  );

  test('omitted workspace_id is forwarded as-is (no server binding)', () async {
    // The server is stateless: it holds no per-session workspace, so it never
    // injects one. An arguments map with no workspace_id reaches the tool
    // unchanged — the tool is responsible for requiring/validating it.
    channel.inject(_toolsCall(allowedTool, {'foo': 'bar'}));
    await Future<void>.delayed(Duration.zero);
    final args = _resultText(channel.sent.single)!;
    expect(args.containsKey('workspace_id'), isFalse);
    expect(args['foo'], 'bar');
  });

  test(
    'the client-supplied workspace_id reaches the tool unchanged',
    () async {
      // Stateless server: there is no binding to override the client. The
      // workspace_id the client names is forwarded verbatim; ownership is
      // enforced inside the tool (per AGENTS.md), not by a session binding.
      channel.inject(_toolsCall(allowedTool, {'workspace_id': 'workspace-b'}));
      await Future<void>.delayed(Duration.zero);
      final args = _resultText(channel.sent.single)!;
      expect(args['workspace_id'], 'workspace-b');
    },
  );

  test('successive calls can each target a different workspace', () async {
    // Per-request scoping: each call carries its own workspace_id, so two calls
    // on the same session can address different workspaces without any shared
    // server-held "current workspace".
    channel.inject(_toolsCall(allowedTool, {'workspace_id': 'workspace-a'}));
    channel.inject(
      _toolsCall(allowedTool, {'workspace_id': 'workspace-b'}, id: 2),
    );
    await Future<void>.delayed(Duration.zero);

    final first = _resultText(channel.sent.firstWhere((m) => m['id'] == 1))!;
    final second = _resultText(channel.sent.firstWhere((m) => m['id'] == 2))!;
    expect(first['workspace_id'], 'workspace-a');
    expect(second['workspace_id'], 'workspace-b');
  });

  test('session/list_workspaces returns the resolver list', () async {
    channel.inject(
      JsonRpcRequest(
        method: 'session/list_workspaces',
        params: {},
        id: 3,
      ).toJson(),
    );
    await Future<void>.delayed(Duration.zero);
    final response = channel.sent.single;
    final workspaces = response['result']['workspaces'] as List;
    expect(workspaces.length, 2);
    expect((workspaces.first as Map)['id'], 'workspace-a');
  });

  test('notifications (no id) get no response', () async {
    channel.inject(
      JsonRpcRequest(method: 'notifications/initialized', params: {}).toJson(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(channel.sent, isEmpty);
  });

  test(
    'a tool not on the remote allow-list is denied (default-deny)',
    () async {
      channel.inject(_toolsCall(disallowedTool, {}, id: 7));
      await Future<void>.delayed(Duration.zero);
      final response = channel.sent.single;
      expect(response['id'], 7);
      expect(response['error'], isNotNull);
      expect((response['error'] as Map)['code'], -32601);
      // The disallowed tool never ran, so no echoed args came back.
      expect(response['result'], isNull);
    },
  );

  test('tools/list is filtered to the allow-list', () async {
    channel.inject(
      JsonRpcRequest(method: 'tools/list', params: {}, id: 8).toJson(),
    );
    await Future<void>.delayed(Duration.zero);
    final tools = channel.sent.single['result']['tools'] as List;
    final names = tools.map((t) => (t as Map)['name']).toSet();
    expect(names, contains(allowedTool));
    expect(names, isNot(contains(disallowedTool)));
  });

  test('per-session rate limit rejects calls over the budget', () async {
    // Fresh channel: the setUp session's channel is closed by [stop], and a
    // closed [_FakeChannel] silently drops sends.
    final ch = _FakeChannel();
    final limited = RemoteRpcSession(
      deviceId: 'dev-1',
      channel: ch,
      dispatcher: dispatcher,
      capability: SessionCapability.fullClient,
      workspaceResolver: () async => const [],
      rateLimiter: RemoteRateLimiter(maxCallsPerWindow: 1),
    );
    await limited.start();
    addTearDown(limited.stop);

    ch.inject(_toolsCall(allowedTool, {}, id: 1));
    ch.inject(_toolsCall(allowedTool, {}, id: 2));
    await Future<void>.delayed(Duration.zero);

    final first = ch.sent.firstWhere((m) => m['id'] == 1);
    final second = ch.sent.firstWhere((m) => m['id'] == 2);
    expect(first['result'], isNotNull);
    expect(second['error'], isNotNull);
    expect((second['error'] as Map)['code'], -32005);
  });
}
