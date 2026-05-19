import 'dart:async';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

/// An in-memory transport emulating an MCP server: responds to initialize /
/// tools/list / tools/call and can push notifications + simulate a drop.
class FakeServerTransport implements McpTransport {
  FakeServerTransport({
    this.tools = const ['echo'],
    this.failInitialize = false,
  });

  List<String> tools;
  final bool failInitialize;

  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _done = Completer<void>();
  bool started = false;
  int closeCount = 0;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> start() async {
    started = true;
    if (failInitialize) {
      throw const McpTransportException('boom');
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    final id = message['id'];
    final method = message['method'];
    scheduleMicrotask(() {
      switch (method) {
        case 'initialize':
          _reply(id, {
            'protocolVersion': '2025-06-18',
            'serverInfo': {'name': 'fake'},
            'capabilities': {
              'tools': {'listChanged': true},
            },
          });
        case 'notifications/initialized':
          break;
        case 'tools/list':
          _reply(id, {
            'tools': [
              for (final t in tools)
                {
                  'name': t,
                  'description': 'tool $t',
                  'inputSchema': {'type': 'object', 'properties': {}},
                },
            ],
          });
        case 'tools/call':
          _reply(id, {
            'content': [
              {
                'type': 'text',
                'text': 'called ${(message['params'] as Map)['name']}',
              },
            ],
            'isError': false,
          });
      }
    });
  }

  void _reply(Object? id, Map<String, dynamic> result) {
    if (!_incoming.isClosed) {
      _incoming.add({'jsonrpc': '2.0', 'id': id, 'result': result});
    }
  }

  /// Pushes a tools/list_changed notification (for hot-reload tests).
  void pushToolListChanged() {
    _incoming.add({
      'jsonrpc': '2.0',
      'method': 'notifications/tools/list_changed',
      'params': <String, dynamic>{},
    });
  }

  /// Simulates the channel dropping.
  void drop() {
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  @override
  Future<void> close() async {
    closeCount++;
    if (!_done.isCompleted) {
      _done.complete();
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}

void main() {
  test('connects, bridges tools, and reports status', () async {
    final transport = FakeServerTransport(tools: ['echo', 'add']);
    final manager = ConnectionManager(
      transportFactory: (_) async => transport,
    );
    addTearDown(manager.shutdown);

    await manager.connectAll([
      McpServerConfig.stdio(name: 'srv', command: 'noop'),
    ]);

    expect(manager.statuses.single.lifecycle, McpServerLifecycle.connected);
    expect(manager.tools.map((t) => t.name),
        ['mcp__srv__add', 'mcp__srv__echo']);

    final result = await manager.tools.first.call({});
    expect(result.content.first.text, contains('called add'));
  });

  test('disabled server is tracked but not dialled', () async {
    var built = 0;
    final manager = ConnectionManager(
      transportFactory: (_) async {
        built++;
        return FakeServerTransport();
      },
    );
    addTearDown(manager.shutdown);

    await manager.connectAll([
      McpServerConfig.stdio(name: 'srv', command: 'noop', enabled: false),
    ]);

    expect(built, 0);
    expect(manager.statuses.single.lifecycle, McpServerLifecycle.disabled);
    expect(manager.tools, isEmpty);
  });

  test('failed initialize → failed lifecycle', () async {
    final manager = ConnectionManager(
      transportFactory: (_) async => FakeServerTransport(failInitialize: true),
    );
    addTearDown(manager.shutdown);

    await manager.connectAll([
      McpServerConfig.stdio(name: 'srv', command: 'noop'),
    ]);

    expect(manager.statuses.single.lifecycle, McpServerLifecycle.failed);
  });

  test('hot-reload re-lists tools on tools/list_changed', () async {
    final transport = FakeServerTransport(tools: ['echo']);
    final manager = ConnectionManager(
      transportFactory: (_) async => transport,
    );
    addTearDown(manager.shutdown);
    await manager.connectAll([
      McpServerConfig.stdio(name: 'srv', command: 'noop'),
    ]);
    expect(manager.tools.length, 1);

    final changed = manager.toolsChanged.first;
    transport.tools = ['echo', 'add', 'remove'];
    transport.pushToolListChanged();
    await changed;
    // allow the re-list round trip
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(manager.tools.length, 3);
  });

  test('circuit breaker opens after burst of reconnects', () async {
    var attempts = 0;
    final manager = ConnectionManager(
      reconnectBurstLimit: 3,
      reconnectBurstWindow: const Duration(seconds: 30),
      reconnectBackoff: const [Duration(milliseconds: 1)],
      transportFactory: (_) async {
        attempts++;
        // Always connects, then immediately drops → triggers reconnect loop.
        final t = FakeServerTransport();
        scheduleMicrotask(() async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          t.drop();
        });
        return t;
      },
    );
    addTearDown(manager.shutdown);

    await manager.connectAll([
      McpServerConfig.stdio(name: 'flap', command: 'noop'),
    ]);

    // Wait for the flap loop to exhaust the breaker.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      manager.statuses.single.lifecycle,
      McpServerLifecycle.circuitOpen,
    );
    // The breaker stopped the loop rather than reconnecting forever.
    expect(attempts, lessThan(20));
  });
}
