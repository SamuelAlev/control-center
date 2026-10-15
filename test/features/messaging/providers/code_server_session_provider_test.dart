import 'dart:async';

import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/code_server_session_provider.dart';
import 'package:control_center/features/settings/providers/editor_preferences_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_rpc_client.dart';

class _Workspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'workspace-a';

  void switchTo(String id) => state = id;
}

class _AutoSave extends EditorAutoSaveNotifier {
  @override
  EditorAutoSaveMode build() => EditorAutoSaveMode.off;
}

class _DelayedHost extends FakeRpcHost {
  final opening = Completer<void>();
  final finishOpen = Completer<void>();

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if ((frame['params'] as Map?)?['op'] == 'codeServer.open') {
      opening.complete();
      await finishOpen.future;
    }
    await super.send(frame);
  }
}

void main() {
  test(
    'an editor closed during startup releases its eventual session',
    () async {
      final host = _DelayedHost();
      final released = Completer<void>();
      var references = 0;
      host.onCall = (op, args) {
        expect(args['workspace_id'], 'workspace-a');
        if (op == 'codeServer.open') {
          references++;
          return {'session_id': 'session-a', 'url': '/proxy/vscode/session-a/'};
        }
        expect(op, 'codeServer.close');
        expect(args['session_id'], 'session-a');
        references--;
        released.complete();
        return {'ok': true};
      };
      final container = ProviderContainer(
        overrides: [
          rpcClientProvider.overrideWithValue(host.client()),
          activeWorkspaceIdProvider.overrideWith(_Workspace.new),
          editorAutoSaveModeProvider.overrideWith(_AutoSave.new),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await host.close();
      });
      const request = CodeServerSessionRequest(
        spaceId: 'space-a',
        repoId: 'repo-a',
      );
      final subscription = container.listen(
        codeServerSessionProvider(request),
        (_, _) {},
      );
      await host.opening.future;
      subscription.close();
      await container.pump();
      // Leaving the workspace while the open is in flight must not redirect its
      // cleanup to the newly selected workspace or leak the old server process.
      (container.read(activeWorkspaceIdProvider.notifier) as _Workspace)
          .switchTo('workspace-b');
      host.finishOpen.complete();
      await released.future;
      expect(references, 0);
    },
  );

  test('a shared session lives until its final view is disposed', () async {
    final host = FakeRpcHost();
    var references = 0;
    host.onCall = (op, args) {
      if (op == 'codeServer.open') {
        references++;
        return {'session_id': 'session-a', 'url': '/proxy/vscode/session-a/'};
      }
      references--;
      return {'ok': true};
    };
    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        activeWorkspaceIdProvider.overrideWith(_Workspace.new),
        editorAutoSaveModeProvider.overrideWith(_AutoSave.new),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await host.close();
    });
    const request = CodeServerSessionRequest(
      spaceId: 'space-a',
      repoId: 'repo-a',
    );
    final provider = codeServerSessionProvider(request);
    final pane = container.listen(provider, (_, _) {});
    final parking = container.listen(provider, (_, _) {});
    await container.read(provider.future);
    pane.close();
    await container.pump();
    expect(references, 1);
    parking.close();
    await container.pump();
    await Future<void>.delayed(Duration.zero);
    expect(references, 0);
  });
}
