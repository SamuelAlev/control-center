import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/bootstrap/desktop_session.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/shutdown_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _QuietClient implements RemoteRpcClient {
  _QuietClient(this.notifications);

  @override
  final Stream<JsonRpcNotification> notifications;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Records the order the quit sequence touches the backend in.
class _RecordingBackend extends ServerBackend {
  _RecordingBackend(this.order, {required this.spawned, this.onStop})
    : super(client: ResilientRpcClient(_supervisor), supervisor: _supervisor);

  static final _supervisor = ServerConnectionSupervisor(
    descriptor: ConnectionDescriptor(
      serverId: 'srv',
      serverName: 'Server',
      fingerprint: 'fp',
      paths: const [LoopbackPath(port: 9030)],
    ),
    deviceId: 'dev',
    psk: 'psk',
  );

  final List<String> order;
  final bool spawned;
  final void Function()? onStop;

  @override
  bool get isLocal => spawned;

  @override
  Future<void> stopLocalServer() async {
    order.add('stop server');
    onStop?.call();
  }

  @override
  Future<void> dispose() async => order.add('dispose backend');
}

void main() {
  late StreamController<JsonRpcNotification> notifications;
  late ProviderContainer container;

  setUp(() {
    notifications = StreamController<JsonRpcNotification>.broadcast();
    container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(_QuietClient(notifications.stream)),
      ],
    );
  });

  tearDown(() => notifications.close());

  test('quitting a local session stops the server while the overlay and its '
      'container are still alive, then disposes', () async {
    // H1: the container (the overlay's watchers) and the client used to be
    // disposed BEFORE the child was signalled, so its teardown progress had
    // nowhere to go.
    final order = <String>[];
    late _RecordingBackend backend;
    backend = _RecordingBackend(
      order,
      spawned: true,
      onStop: () {
        // The server streams its progress over the still-open client while
        // stopping; the overlay's provider is alive to show it.
        notifications.add(
          JsonRpcNotification(
            method: 'server/shutdown_progress',
            params: const {
              'phase': 'begin',
              'services': ['approvals'],
            },
          ),
        );
        order.add(
          'overlay active=${container.read(shutdownProgressProvider).active}',
        );
      },
    );
    final session = DesktopBackendSession.forTesting(backend, container);

    await session.quit(nextFrame: () async => order.add('frame'));

    expect(order, [
      'frame',
      'stop server',
      'overlay active=true',
      'dispose backend',
    ]);
  });

  test(
    'quitting a remote session never stops a server it does not own',
    () async {
      final order = <String>[];
      final session = DesktopBackendSession.forTesting(
        _RecordingBackend(order, spawned: false),
        container,
      );

      await session.quit(nextFrame: () async => order.add('frame'));

      expect(order, ['dispose backend']);
    },
  );

  test('dispose is idempotent', () async {
    final order = <String>[];
    final session = DesktopBackendSession.forTesting(
      _RecordingBackend(order, spawned: false),
      container,
    );

    await session.dispose();
    await session.dispose();

    expect(order, ['dispose backend']);
  });
}
