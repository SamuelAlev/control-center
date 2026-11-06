import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/space_provisioning_log_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';

const _query = 'messaging.watchSpaceProvisioningLog';
const _key = (workspaceId: 'ws-1', spaceId: 'space-1');

void main() {
  late FakeRpcHost host;
  late ProviderContainer container;

  setUp(() async {
    host = FakeRpcHost();
    final client = host.client();
    container = ProviderContainer(
      overrides: [rpcClientProvider.overrideWithValue(client)],
    );
    addTearDown(() async {
      container.dispose();
      await client.close();
      await host.close();
    });
    container.listen(spaceProvisioningLogLinesProvider(_key), (_, _) {});
    await pumpEventQueue();
  });

  Future<void> emit(int seq, String line) async {
    host.emit(_query, {'seq': seq, 'line': line});
    await pumpEventQueue();
  }

  List<String> lines() =>
      container.read(spaceProvisioningLogLinesProvider(_key)).value ?? const [];

  test('appends new lines in order', () async {
    await emit(1, 'Copying');
    await emit(2, 'Fetching main');

    expect(lines(), ['Copying', 'Fetching main']);
  });

  test('a repeated number rewrites its line', () async {
    await emit(1, 'Fetching main');
    await emit(2, 'Receiving objects:  1% (1/100)');
    await emit(2, 'Receiving objects: 50% (50/100)');

    expect(lines(), ['Fetching main', 'Receiving objects: 50% (50/100)']);
  });

  test('a reconnect replays nothing already shown', () async {
    await emit(1, 'Copying');
    await emit(2, 'Fetching main');
    await emit(3, 'Checking out');

    await emit(1, 'Copying');
    await emit(2, 'Fetching main');
    await emit(3, 'Checking out');
    await emit(4, 'Workspace ready');

    expect(lines(), [
      'Copying',
      'Fetching main',
      'Checking out',
      'Workspace ready',
    ]);
  });

  test('keeps only the newest lines', () async {
    for (var seq = 0; seq <= kSpaceProvisioningLogLines; seq++) {
      host.emit(_query, {'seq': seq, 'line': 'line $seq'});
    }
    await pumpEventQueue();

    expect(lines(), hasLength(kSpaceProvisioningLogLines));
    expect(lines().first, 'line 1');
  });
}
