import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/providers/terminal_registry_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [RemoteRpcChannelPort] answering the `terminal.*` ops the
/// registry's controllers drive (`spawn` / `kill` / subscriptions). Minimal
/// copy of the panel test's `_FakeChannel` — test internals stay unexported.
class _FakeChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _stateCtl = StreamController<RemoteChannelState>.broadcast();
  bool _open = true;

  /// How many `terminal.spawn` calls this space served.
  int spawnCount = 0;

  /// How many `terminal.kill` calls this space served.
  int killCount = 0;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _stateCtl.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    final method = frame['method'] as String?;
    final id = frame['id'];
    if (method == 'repo/call') {
      final params = (frame['params'] as Map).cast<String, dynamic>();
      final op = params['op'] as String?;
      if (op == 'terminal.spawn') {
        spawnCount++;
        _incoming.add({
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'data': {'session_id': 'fake-session-$spawnCount'},
          },
        });
        return;
      }
      if (op == 'terminal.kill') {
        killCount++;
      }
      if (op == 'terminal.kill' ||
          op == 'terminal.write' ||
          op == 'terminal.resize') {
        _incoming.add({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'data': <String, dynamic>{}},
        });
        return;
      }
    }
    if (method == 'sub/subscribe') {
      final params = (frame['params'] as Map).cast<String, dynamic>();
      final query = params['query'] as String? ?? '';
      _incoming.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': {
          'subscriptionId': query == 'terminal.titles'
              ? 'fake-sub-titles'
              : 'fake-sub-1',
        },
      });
      return;
    }
    if (method == 'sub/unsubscribe') {
      _incoming.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': <String, dynamic>{},
      });
    }
  }

  @override
  Future<void> close() async {
    _open = false;
    _stateCtl.add(RemoteChannelState.closed);
    await _incoming.close();
    await _stateCtl.close();
  }
}

void main() {
  TerminalSession sessionFor(String id) =>
      TerminalSession(sessionId: id, spaceId: 'chan-1', workspaceId: 'ws-1');

  ({
    _FakeChannel space,
    ProviderContainer container,
    TerminalRegistryNotifier notifier,
  })
  setup() {
    final space = _FakeChannel();
    final client = RemoteRpcClient(space)..start();
    final container = ProviderContainer(
      overrides: [rpcClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
    return (
      space: space,
      container: container,
      notifier: container.read(terminalRegistryProvider.notifier),
    );
  }

  test(
    'obtain returns the same controller for a session id and touches it',
    () {
      final (:container, :notifier, space: _) = setup();

      final first = notifier.obtain(sessionFor('s1'));
      notifier.obtain(sessionFor('s2'));
      final again = notifier.obtain(sessionFor('s1'));

      expect(again, same(first));
      // The touch moved s1 to most-recent: insertion order is [s2, s1].
      expect(container.read(terminalRegistryProvider).controllers.keys, [
        's2',
        's1',
      ]);
    },
  );

  test('never evicts a claimed (on-screen) shell past the cap', () async {
    final (:space, :container, :notifier) = setup();

    final ids = List.generate(6, (i) => 's${i + 1}');
    for (final id in ids) {
      await notifier.obtain(sessionFor(id)).ensureBooted();
    }
    notifier.syncClaims(ids.toSet());

    // A 7th tab in the same space: every entry is claimed, so the cap
    // yields — nothing is evicted, nothing is killed.
    final seventh = notifier.obtain(sessionFor('s7'));
    await seventh.ensureBooted();

    final state = container.read(terminalRegistryProvider);
    expect(state.controllers.length, 7);
    expect(state.controllers['s7'], same(seventh));
    expect(space.killCount, 0);
  });

  test('past the cap, the least-recently-touched UNCLAIMED shells are evicted '
      'and their PTYs killed', () async {
    final (:space, :container, :notifier) = setup();

    // Six shells claimed by on-screen tabs; a 7th obtain yields (cap yields
    // to all-claimed — the fresh entry protects itself).
    final ids = List.generate(6, (i) => 's${i + 1}');
    for (final id in ids) {
      await notifier.obtain(sessionFor(id)).ensureBooted();
    }
    notifier.syncClaims(ids.toSet());
    await notifier.obtain(sessionFor('s7')).ensureBooted();
    expect(container.read(terminalRegistryProvider).controllers.length, 7);

    // The user navigated away from every space: no claims left. The next
    // obtain (s8) evicts the LRU shells down to the cap.
    notifier.syncClaims(const {});
    final eighth = notifier.obtain(sessionFor('s8'));
    await eighth.ensureBooted();
    await pumpEventQueue();

    final state = container.read(terminalRegistryProvider);
    expect(state.controllers.keys, [
      's3',
      's4',
      's5',
      's6',
      's7',
      's8',
    ], reason: 's1 and s2 are the least-recently-touched unclaimed shells');
    await pumpEventQueue();
    expect(space.killCount, 2);
  });

  test(
    'kill removes and disposes the session; a second kill is a no-op',
    () async {
      final (:space, :container, :notifier) = setup();

      final controller = notifier.obtain(sessionFor('s1'));
      await controller.ensureBooted();
      expect(space.killCount, 0);

      notifier.kill('s1');
      expect(
        container.read(terminalRegistryProvider).controllers.containsKey('s1'),
        isFalse,
      );
      await pumpEventQueue();
      expect(space.killCount, 1);

      notifier.kill('s1');
      await pumpEventQueue();
      expect(space.killCount, 1);
    },
  );
}
