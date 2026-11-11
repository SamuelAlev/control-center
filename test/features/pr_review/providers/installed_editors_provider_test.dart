import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/pr_review/providers/ide_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';

/// An editor opens on the server's own display, so only someone who may use
/// the server host is offered one, and nobody else's client even asks which
/// editors the host has.
void main() {
  Future<(List<String>, int)> detect({required bool canUseHost}) async {
    final host = FakeRpcHost();
    final ops = <String>[];
    host.onCall = (op, _) {
      ops.add(op);
      return {
        'editors': [
          {'id': 'vscode', 'display_name': 'VS Code', 'installed': true},
        ],
      };
    };
    final rpc = host.client();
    addTearDown(rpc.close);
    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(rpc),
        canUseHostProvider.overrideWithValue(canUseHost),
      ],
    );
    addTearDown(container.dispose);
    final editors = await container.read(installedEditorsProvider.future);
    return (ops, editors.length);
  }

  test('the server owner is offered the host editors', () async {
    final (ops, count) = await detect(canUseHost: true);
    expect(ops, ['ide.detectEditors']);
    expect(count, 1);
  });

  test('anyone else is offered none, and the host is not asked', () async {
    final (ops, count) = await detect(canUseHost: false);
    expect(ops, isEmpty);
    expect(count, 0);
  });
}
