import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_sign_in_banner.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';

class _WorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-a';
}

void main() {
  late FakeRpcHost host;
  late ProviderContainer container;
  late bool failList;
  late bool lapsed;

  setUp(() {
    failList = false;
    lapsed = false;
    host = FakeRpcHost()
      ..onCall = (op, args) {
        if (op == 'forge.listConnections') {
          if (failList) {
            throw StateError('host unreachable');
          }
          return {
            'connections': [
              {
                'forge': 'github',
                'status': lapsed ? 'needs_sign_in' : 'connected',
                'scope': 'global',
                'username': 'Alice',
                'source': 'oauth',
              },
              {'forge': 'gitlab', 'status': 'not_connected'},
            ],
          };
        }
        throw StateError('unexpected op $op');
      };
    container = ProviderContainer(
      // The provider schedules its own re-read; Riverpod's automatic retry
      // would hold `.future` open across its backoff.
      retry: (_, _) => null,
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        isDemoServerProvider.overrideWithValue(false),
        activeWorkspaceIdProvider.overrideWith(_WorkspaceId.new),
        appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(host.close);
  });

  test('a failed first read is an error, not an empty list', () async {
    failList = true;
    final sub = container.listen(forgeConnectionsProvider, (_, _) {});
    addTearDown(sub.close);
    await expectLater(
      container.read(forgeConnectionsProvider.future),
      throwsA(anything),
    );
    final state = container.read(forgeConnectionsProvider);
    expect(state.hasError, isTrue);
    expect(state.hasValue, isFalse);
    // Unresolved: the onboarding gate holds instead of reading "no forge".
    expect(container.read(liveOnboardingGateProvider), isNull);
  });

  test('a failed re-read keeps the previous list', () async {
    final sub = container.listen(forgeConnectionsProvider, (_, _) {});
    addTearDown(sub.close);
    final first = await container.read(forgeConnectionsProvider.future);
    expect(first.first.username, 'Alice');
    expect(container.read(viewerLoginsProvider), {ForgeHost.github: 'alice'});

    failList = true;
    container.invalidate(forgeConnectionsProvider);
    await expectLater(
      container.read(forgeConnectionsProvider.future),
      throwsA(anything),
    );
    final state = container.read(forgeConnectionsProvider);
    expect(state.hasError, isTrue);
    expect(state.value?.first.username, 'Alice');
    expect(container.read(hasAnyForgeConnectedProvider), isTrue);
    expect(container.read(viewerLoginsProvider), {ForgeHost.github: 'alice'});
  });

  test('a lapsed person grant reads as needs_sign_in from the server', () async {
    lapsed = true;
    final connections = await container.read(forgeConnectionsProvider.future);
    final github = connections.firstWhere((c) => c.forge == ForgeHost.github);
    expect(github.status, ForgeConnectionStatus.needsSignIn);
    expect(github.isUsable, isFalse);
    expect(needsForgeSignIn(connections), isTrue);
  });

  test('a working grant does not ask for a sign-in', () async {
    final connections = await container.read(forgeConnectionsProvider.future);
    expect(
      connections.any((c) => c.status == ForgeConnectionStatus.needsSignIn),
      isFalse,
    );
    expect(needsForgeSignIn(connections), isFalse);
  });
}
