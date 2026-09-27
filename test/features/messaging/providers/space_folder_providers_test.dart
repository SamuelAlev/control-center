import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/space_folder_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';

void main() {
  test(
    'folder edits preserve membership, survive a live snapshot and stay per workspace',
    () async {
      final initial = jsonEncode([
        {
          'id': 'old',
          'name': 'Old',
          'spaceIds': ['space-1'],
        },
      ]);
      final prefs = StreamController<Map<String, String>>.broadcast();
      final written = <String>[];
      final host = FakeRpcHost()
        ..onCall = (op, args) {
          if (op == 'prefs.set') {
            expect(args['key'], 'space_folders.ws-1');
            written.add(args['value'] as String);
          }
          return const <String, dynamic>{'ok': true};
        };
      final container = ProviderContainer(
        overrides: [
          rpcClientProvider.overrideWithValue(host.client()),
          ownServerPrefsProvider.overrideWith((ref) async* {
            yield {'space_folders.ws-1': initial};
            yield* prefs.stream;
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await prefs.close();
        await host.close();
      });

      final preferenceSubscription = container.listen(
        ownServerPrefsProvider,
        (_, _) {},
      );
      addTearDown(preferenceSubscription.close);
      await container.pump();
      expect(
        container.read(ownServerPrefsProvider).value?['space_folders.ws-1'],
        initial,
      );

      final actions = container.read(spaceFolderActionsProvider('ws-1'));
      // Two edits made before the server's first echo must not lose either one.
      final create = actions.create('Active');
      final move = actions.move('space-1', 'old');
      await Future.wait([create, move]);
      final folders = (jsonDecode(written.last) as List)
          .cast<Map<String, dynamic>>();
      final newId = folders.last['id'] as String;
      await actions.move('space-1', newId);
      await actions.move('space-2', newId);
      await actions.rename(newId, 'Current');
      await actions.delete('old');

      final saved = (jsonDecode(written.last) as List)
          .cast<Map<String, dynamic>>();
      expect(saved, [
        {
          'id': newId,
          'name': 'Current',
          'spaceIds': ['space-1', 'space-2'],
        },
      ]);
      prefs.add({'space_folders.ws-1': written.last});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(spaceFoldersProvider('ws-1')).single.spaceIds, [
        'space-1',
        'space-2',
      ]);
      expect(container.read(spaceFoldersProvider('ws-2')), isEmpty);

      await actions.delete(newId);
      expect(jsonDecode(written.last), isEmpty);
    },
  );
}
