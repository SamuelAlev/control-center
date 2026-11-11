import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/worktree_file_pane.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/fake_rpc_client.dart';
import '../../../../../helpers/test_wrap.dart';

/// The quick-fix editor words a refused read by its code (and offers the
/// sign-in a missing one needs) instead of calling the file missing.
void main() {
  Future<void> pumpPane(
    WidgetTester tester,
    Map<String, dynamic> Function(String op, Map<String, dynamic> args) onCall,
  ) async {
    final host = FakeRpcHost()..onCall = onCall;
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rpcClientProvider.overrideWithValue(rpc)],
        child: testWrap(
          const WorktreeFilePane(
            workspaceId: 'ws-1',
            spaceId: 'sp-1',
            repoId: 'repo-1',
            path: 'lib/main.dart',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a read refused with needs_sign_in offers the sign-in', (
    tester,
  ) async {
    await pumpPane(
      tester,
      (op, _) => throw RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'Sign in to GitHub to continue.',
        {'kind': 'needs_sign_in', 'lane': 'github'},
      ),
    );

    expect(
      find.text("Sign in to GitHub to see this repository's code."),
      findsOneWidget,
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('GitHub sign-in needed'), findsOneWidget);
  });

  testWidgets('a read refused with repo_replaced says so', (tester) async {
    await pumpPane(
      tester,
      (op, _) => throw RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'replaced',
        {'kind': 'repo_replaced'},
      ),
    );

    expect(
      find.text(
        'This path now points to a different repository. A workspace admin '
        'has to relink it before it can be used.',
      ),
      findsOneWidget,
    );
    expect(
      find.text("This file isn't available in this worktree."),
      findsNothing,
    );
  });

  testWidgets('a file the worktree lacks is unavailable, with a retry', (
    tester,
  ) async {
    var reads = 0;
    await pumpPane(tester, (op, _) {
      reads++;
      return {'ok': false};
    });

    expect(
      find.text("This file isn't available in this worktree."),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(reads, 2);
  });

  testWidgets('a save refused for want of a write grant says so', (
    tester,
  ) async {
    await pumpPane(tester, (op, _) {
      if (op == 'worktree.readFile') {
        return {'ok': true, 'content': 'void main() {}', 'binary': false};
      }
      throw RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'No write access to this repo',
        {'kind': 'repo_grant_required', 'level': 'write'},
      );
    });
    await tester.enterText(find.byType(EditableText).last, 'void main() {1}');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'You can read this repository but not change it. A workspace admin '
        'can grant write access.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('No write access'), findsNothing);
  });
}
