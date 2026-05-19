import 'dart:async';
import 'dart:io';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'connection_manager_test.dart' show FakeServerTransport;

/// A transport whose `start()` stalls for [delay], modelling the stdio server
/// that takes seconds to come up and used to hold every other server hostage.
class SlowTransport implements McpTransport {
  SlowTransport(this.delay, {this.tools = const ['slow_tool']});

  final Duration delay;
  final List<String> tools;
  final _inner = FakeServerTransport();
  bool startedAt = false;

  @override
  Stream<Map<String, dynamic>> get incoming => _inner.incoming;
  @override
  Future<void> get done => _inner.done;

  @override
  Future<void> start() async {
    await Future<void>.delayed(delay);
    startedAt = true;
    _inner.tools = tools;
    await _inner.start();
  }

  @override
  Future<void> send(Map<String, dynamic> message) => _inner.send(message);
  @override
  Future<void> close() => _inner.close();
}

/// An in-memory [McpToolListCache] so the deferred-tool path is testable
/// without touching disk.
class MemoryToolCache implements McpToolListCache {
  final Map<String, (String, List<McpRemoteTool>)> entries = {};
  int evictions = 0;

  @override
  List<McpRemoteTool>? read(String serverName, String fingerprint) {
    final e = entries[serverName];
    return e != null && e.$1 == fingerprint ? e.$2 : null;
  }

  @override
  void write(String serverName, String fingerprint, List<McpRemoteTool> tools) {
    entries[serverName] = (fingerprint, tools);
  }

  @override
  void evict(String serverName) {
    if (entries.remove(serverName) != null) {
      evictions++;
    }
  }
}

void main() {
  group('startup gate', () {
    test('one slow server does not hold up the fast ones', () async {
      final fast = FakeServerTransport(tools: ['fast_tool']);
      final slow = SlowTransport(const Duration(seconds: 5));
      final manager = ConnectionManager(
        startupGate: const Duration(milliseconds: 100),
        transportFactory: (config) async =>
            config.name == 'fast' ? fast : slow,
      );
      addTearDown(manager.shutdown);

      final watch = Stopwatch()..start();
      await manager.connectAll([
        McpServerConfig.stdio(name: 'fast', command: 'noop'),
        McpServerConfig.stdio(name: 'slow', command: 'noop'),
      ]);
      watch.stop();

      expect(
        watch.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: 'connectAll must return on the gate, not the slowest server',
      );
      expect(
        manager.tools.map((t) => t.name),
        contains('mcp__fast__fast_tool'),
        reason: 'the fast server contributed its tools immediately',
      );
    });

    test('a straggler still registers its tools after the gate', () async {
      final slow = SlowTransport(
        const Duration(milliseconds: 300),
        tools: ['late_tool'],
      );
      var changes = 0;
      final manager = ConnectionManager(
        startupGate: const Duration(milliseconds: 50),
        onToolsChanged: () => changes++,
        transportFactory: (_) async => slow,
      );
      addTearDown(manager.shutdown);

      await manager.connectAll([
        McpServerConfig.stdio(name: 'slow', command: 'noop'),
      ]);
      expect(
        manager.tools,
        isEmpty,
        reason: 'nothing cached, so it contributes nothing at the gate',
      );

      // The dial was never cancelled — it lands on its own schedule.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(manager.tools.map((t) => t.name), ['mcp__slow__late_tool']);
      expect(manager.statuses.single.lifecycle, McpServerLifecycle.connected);
      expect(changes, greaterThan(0), reason: 'the host was told to re-read');
    });

    test('connectAll with nothing to dial returns without waiting', () async {
      final manager = ConnectionManager(
        startupGate: const Duration(seconds: 10),
        transportFactory: (_) async => FakeServerTransport(),
      );
      addTearDown(manager.shutdown);

      final watch = Stopwatch()..start();
      await manager.connectAll([]);
      watch.stop();
      expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    });
  });

  group('deferred tools from cache', () {
    test('a still-connecting server offers its cached tools', () async {
      final cache = MemoryToolCache();
      final config = McpServerConfig.stdio(name: 'slow', command: 'noop');
      cache.write(config.name, mcpToolCacheFingerprint(config), const [
        McpRemoteTool(
          name: 'cached_tool',
          description: 'from last boot',
          inputSchema: {'type': 'object'},
        ),
      ]);

      final manager = ConnectionManager(
        startupGate: const Duration(milliseconds: 50),
        toolCache: cache,
        transportFactory: (_) async =>
            SlowTransport(const Duration(milliseconds: 400)),
      );
      addTearDown(manager.shutdown);

      await manager.connectAll([config]);
      expect(
        manager.tools.map((t) => t.name),
        ['mcp__slow__cached_tool'],
        reason: 'the cached surface is available at the gate',
      );
      expect(manager.statuses.single.lifecycle, McpServerLifecycle.connecting);
    });

    test('a cached tool call waits for the connection instead of failing',
        () async {
      final cache = MemoryToolCache();
      final config = McpServerConfig.stdio(name: 'slow', command: 'noop');
      cache.write(config.name, mcpToolCacheFingerprint(config), const [
        McpRemoteTool(
          name: 'slow_tool',
          description: 'from last boot',
          inputSchema: {'type': 'object'},
        ),
      ]);

      final manager = ConnectionManager(
        startupGate: const Duration(milliseconds: 50),
        toolCache: cache,
        transportFactory: (_) async =>
            SlowTransport(const Duration(milliseconds: 300)),
      );
      addTearDown(manager.shutdown);

      await manager.connectAll([config]);
      final tool = manager.tools.single;

      // Calling it during the connect window must succeed, not throw
      // "not connected" — the wait moved here from startup.
      final result = await tool.call({});
      expect(result.content.first.text, contains('called slow_tool'));
    });

    test('a fingerprint change misses rather than serving stale tools', () {
      final cache = MemoryToolCache();
      final before = McpServerConfig.stdio(
        name: 'srv',
        command: 'noop',
        env: const {'MODE': 'a'},
      );
      final after = McpServerConfig.stdio(
        name: 'srv',
        command: 'noop',
        env: const {'MODE': 'b'},
      );
      cache.write(before.name, mcpToolCacheFingerprint(before), const [
        McpRemoteTool(
          name: 't',
          description: '',
          inputSchema: {'type': 'object'},
        ),
      ]);

      expect(cache.read('srv', mcpToolCacheFingerprint(before)), isNotNull);
      expect(
        cache.read('srv', mcpToolCacheFingerprint(after)),
        isNull,
        reason: 'a different env is a different tool surface',
      );
    });

    test('a failed server stops advertising cached tools', () async {
      final cache = MemoryToolCache();
      final config = McpServerConfig.stdio(name: 'srv', command: 'noop');
      cache.write(config.name, mcpToolCacheFingerprint(config), const [
        McpRemoteTool(
          name: 'ghost',
          description: '',
          inputSchema: {'type': 'object'},
        ),
      ]);

      final manager = ConnectionManager(
        toolCache: cache,
        transportFactory: (_) async =>
            FakeServerTransport(failInitialize: true),
      );
      addTearDown(manager.shutdown);

      await manager.connectAll([config]);
      expect(manager.statuses.single.lifecycle, McpServerLifecycle.failed);
      expect(
        manager.tools,
        isEmpty,
        reason: 'a menu of calls that cannot succeed is worse than none',
      );
      expect(cache.evictions, 1);
    });
  });

  group('FileMcpToolListCache', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('mcp_tool_cache'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('round-trips tools across instances', () {
      final path = p.join(dir.path, 'nested', 'tools.json');
      FileMcpToolListCache(path).write('srv', 'fp1', const [
        McpRemoteTool(
          name: 'a',
          description: 'first',
          inputSchema: {'type': 'object'},
        ),
      ]);

      final reopened = FileMcpToolListCache(path).read('srv', 'fp1');
      expect(reopened, isNotNull);
      expect(reopened!.single.name, 'a');
      expect(reopened.single.description, 'first');
    });

    test('a corrupt file degrades to a cold start, not a throw', () {
      final path = p.join(dir.path, 'tools.json');
      File(path).writeAsStringSync('{not json at all');
      final cache = FileMcpToolListCache(path);
      expect(cache.read('srv', 'fp1'), isNull);
      // And it recovers on the next write.
      cache.write('srv', 'fp1', const [
        McpRemoteTool(
          name: 'a',
          description: '',
          inputSchema: {'type': 'object'},
        ),
      ]);
      expect(FileMcpToolListCache(path).read('srv', 'fp1'), isNotNull);
    });

    test('evict removes the entry', () {
      final path = p.join(dir.path, 'tools.json');
      final cache = FileMcpToolListCache(path)
        ..write('srv', 'fp1', const [
          McpRemoteTool(
            name: 'a',
            description: '',
            inputSchema: {'type': 'object'},
          ),
        ])
        ..evict('srv');
      expect(cache.read('srv', 'fp1'), isNull);
      expect(FileMcpToolListCache(path).read('srv', 'fp1'), isNull);
    });

    test('header values are hashed, never stored in the fingerprint', () {
      final config = McpServerConfig.http(
        name: 'srv',
        url: 'https://example.test/mcp',
        headers: const {'Authorization': 'Bearer super-secret-token'},
      );
      expect(mcpToolCacheFingerprint(config), isNot(contains('super-secret')));
    });
  });
}
