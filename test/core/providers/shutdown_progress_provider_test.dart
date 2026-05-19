import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart'
    show RemoteRpcClient, ServerBuild, ServerConnectionPhase, ServerConnectionStatus;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/server_connection_status_provider.dart';
import 'package:control_center/core/providers/shutdown_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal [RemoteRpcClient] stand-in: only `notifications` is exercised by the
/// provider, everything else throws if touched.
class _FakeRpcClient implements RemoteRpcClient {
  _FakeRpcClient(this.notifications);

  @override
  final Stream<JsonRpcNotification> notifications;

  @override
  ServerBuild? get serverBuild => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeRpcClient.${invocation.memberName}');
}

void main() {
  late StreamController<JsonRpcNotification> controller;
  late ProviderContainer container;

  setUp(() {
    controller = StreamController<JsonRpcNotification>.broadcast();
    container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(_FakeRpcClient(controller.stream)),
      ],
    );
    // Build the notifier so its notification subscription is live.
    container.read(shutdownProgressProvider);
  });

  tearDown(() {
    container.dispose();
    controller.close();
  });

  void emit(Map<String, dynamic> params) => controller.add(
    JsonRpcNotification(method: 'server/shutdown_progress', params: params),
  );

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('initial state is inactive with no services', () {
    final state = container.read(shutdownProgressProvider);
    expect(state.active, isFalse);
    expect(state.services, isEmpty);
  });

  test('begin() flips active on before any server frame arrives', () {
    container.read(shutdownProgressProvider.notifier).begin();
    final state = container.read(shutdownProgressProvider);
    expect(state.active, isTrue);
    expect(state.services, isEmpty); // indeterminate until the server reports
  });

  test('begin frame seeds the ordered service list as pending', () async {
    emit({
      'phase': 'begin',
      'services': ['approvals', 'meetings', 'codeEditors'],
    });
    await pump();

    final state = container.read(shutdownProgressProvider);
    expect(state.active, isTrue);
    expect(state.services.map((s) => '${s.id}:${s.status.name}'), [
      'approvals:pending',
      'meetings:pending',
      'codeEditors:pending',
    ]);
  });

  test('step frames flip services to done in order', () async {
    emit({
      'phase': 'begin',
      'services': ['approvals', 'meetings', 'codeEditors'],
    });
    await pump();

    emit({'phase': 'step', 'service': 'approvals'});
    await pump();

    var state = container.read(shutdownProgressProvider);
    // First pending is implicitly "in progress"; approvals is now done.
    expect(state.services.first.id, 'approvals');
    expect(state.services.first.status, ShutdownServiceStatus.done);
    expect(
      state.services.skip(1).map((s) => s.status),
      everyElement(ShutdownServiceStatus.pending),
    );

    emit({'phase': 'step', 'service': 'meetings'});
    await pump();
    state = container.read(shutdownProgressProvider);
    expect(state.services.map((s) => s.status.name).toList(), [
      'done',
      'done',
      'pending',
    ]);
  });

  test('complete frame marks every service done', () async {
    emit({
      'phase': 'begin',
      'services': ['approvals', 'meetings'],
    });
    await pump();
    emit({'phase': 'step', 'service': 'approvals'});
    await pump();

    emit({'phase': 'complete'});
    await pump();

    final state = container.read(shutdownProgressProvider);
    expect(state.complete, isTrue);
    expect(
      state.services.map((s) => s.status),
      everyElement(ShutdownServiceStatus.done),
    );
  });

  test('non-shutdown notifications are ignored', () async {
    container.read(shutdownProgressProvider.notifier).begin();
    controller.add(
      JsonRpcNotification(
        method: 'notifications/message_received',
        params: {'space_id': 'x'},
      ),
    );
    final state = container.read(shutdownProgressProvider);
    expect(state.services, isEmpty); // unchanged
    expect(state.active, isTrue);
  });

  test(
    'clears on connection drop and does not reappear on reconnect',
    () async {
      final status = StreamController<ServerConnectionStatus>.broadcast();
      final notifs = StreamController<JsonRpcNotification>.broadcast();
      final c = ProviderContainer(
        overrides: [
          rpcClientProvider.overrideWithValue(_FakeRpcClient(notifs.stream)),
          serverConnectionStatusProvider.overrideWith((ref) => status.stream),
        ],
      );
      addTearDown(() {
        c.dispose();
        status.close();
        notifs.close();
      });
      // Keep the notifier alive so its connection-status listener is active.
      c.listen(shutdownProgressProvider, (_, _) {});

      // A shutdown begins and streams over the still-live connection.
      status.add(
        const ServerConnectionStatus(phase: ServerConnectionPhase.connected),
      );
      notifs.add(
        JsonRpcNotification(
          method: 'server/shutdown_progress',
          params: const {
            'phase': 'begin',
            'services': ['approvals'],
          },
        ),
      );
      await pump();
      expect(c.read(shutdownProgressProvider).active, isTrue);

      // The server dies: the connection drops → the overlay state clears.
      status.add(
        const ServerConnectionStatus(phase: ServerConnectionPhase.reconnecting),
      );
      await pump();
      expect(c.read(shutdownProgressProvider).active, isFalse);

      // The server comes back: the overlay must NOT reappear.
      status.add(
        const ServerConnectionStatus(phase: ServerConnectionPhase.connected),
      );
      await pump();
      expect(c.read(shutdownProgressProvider).active, isFalse);
    },
  );
}
