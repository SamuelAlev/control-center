import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';

/// Lets tests flip the active workspace without the Drift bootstrap stream.
class _WorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-a';
}

Map<String, dynamic> _github({
  required String username,
  required String source,
}) => {
  'forge': 'github',
  'authenticated': true,
  'username': username,
  'source': source,
};

void main() {
  late FakeRpcHost host;
  late ProviderContainer container;
  late List<String?> listedWorkspaces;
  late List<String?> identityWorkspaces;

  setUp(() {
    listedWorkspaces = [];
    identityWorkspaces = [];
    host = FakeRpcHost()
      ..onCall = (op, args) {
        final workspaceId = args['workspace_id'] as String?;
        if (op == 'forge.listConnections') {
          listedWorkspaces.add(workspaceId);
          return {
            'connections': [
              if (workspaceId == 'ws-a')
                _github(username: 'alice-app', source: 'oauth')
              else if (workspaceId == 'ws-b')
                _github(username: 'bob-pat', source: 'settings'),
            ],
          };
        }
        if (op == 'oauth.providers') {
          return {
            'providers': [
              if (workspaceId != 'ws-b')
                {'provider': 'github', 'flow': 'device'},
              {'provider': 'linear', 'flow': 'redirect'},
            ],
          };
        }
        if (op == 'identity.me') {
          identityWorkspaces.add(workspaceId);
          return {
            'user': {
              'id': 'u-1',
              'display_name': workspaceId == 'ws-b'
                  ? 'Bob in B'
                  : 'Alice in A',
            },
            'device_id': 'dev-1',
            'is_server_owner': true,
            'memberships': const [],
          };
        }
        throw StateError('unexpected op $op');
      };
    container = ProviderContainer(
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

  test(
    'GitHub login on workspace A stays distinct from a PAT on workspace B',
    () async {
      final inA = await container.read(forgeConnectionsProvider.future);
      expect(inA.single.username, 'alice-app');
      expect(inA.single.source.wire, 'oauth');

      final signInA = await container.read(signInProvidersProvider.future);
      expect(signInA.containsKey('github'), isTrue);

      final meA = await container.read(currentIdentityProvider.future);
      expect(meA.user.displayName, 'Alice in A');

      await container.read(activeWorkspaceIdProvider.notifier).setActive('ws-b');

      final inB = await container.read(forgeConnectionsProvider.future);
      expect(inB.single.username, 'bob-pat');
      expect(inB.single.source.wire, 'settings');

      final signInB = await container.read(signInProvidersProvider.future);
      expect(signInB.containsKey('github'), isFalse);

      final meB = await container.read(currentIdentityProvider.future);
      expect(meB.user.displayName, 'Bob in B');

      await container.read(activeWorkspaceIdProvider.notifier).setActive('ws-a');

      final backToA = await container.read(forgeConnectionsProvider.future);
      expect(backToA.single.username, 'alice-app');
      expect(
        (await container.read(currentIdentityProvider.future)).user.displayName,
        'Alice in A',
      );
      expect(listedWorkspaces, ['ws-a', 'ws-b', 'ws-a']);
      expect(identityWorkspaces, ['ws-a', 'ws-b', 'ws-a']);
    },
  );
}
