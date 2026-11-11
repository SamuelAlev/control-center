import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_head_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/fake_rpc_client.dart';
import '../../../../../helpers/test_wrap.dart';

void main() {
  /// A button that syncs, answered by [onCall]; reports each outcome.
  Future<List<bool>> pumpSync(
    WidgetTester tester,
    Map<String, dynamic> Function(String op, Map<String, dynamic> args) onCall,
  ) async {
    final host = FakeRpcHost()..onCall = onCall;
    final rpc = host.client();
    addTearDown(rpc.close);
    final outcomes = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rpcClientProvider.overrideWithValue(rpc)],
        child: testWrap(
          Consumer(
            builder: (context, ref, _) => CcButton(
              onPressed: () => unawaited(
                syncPrWorktreeToHead(
                  context,
                  ref,
                  workspaceId: 'ws-1',
                  spaceId: 'sp-1',
                  repoId: 'repo-1',
                ).then(outcomes.add),
              ),
              child: const Text('Sync'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Sync'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return outcomes;
  }

  testWidgets('a missing GitHub sign-in offers it instead of failing', (
    tester,
  ) async {
    final outcomes = await pumpSync(
      tester,
      (op, _) => throw RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'Sign in to GitHub to continue.',
        {'kind': 'needs_sign_in', 'lane': 'github'},
      ),
    );

    expect(outcomes, [false]);
    expect(find.text('GitHub sign-in needed'), findsOneWidget);
    expect(find.text("Couldn't sync to the PR head"), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('any other failure is the sync failure', (tester) async {
    final outcomes = await pumpSync(
      tester,
      (op, _) => throw RemoteRpcException(RpcErrorCodes.internalError, 'boom'),
    );

    expect(outcomes, [false]);
    expect(find.text("Couldn't sync to the PR head"), findsOneWidget);
    expect(find.text('GitHub sign-in needed'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('an advanced tree reports success', (tester) async {
    final outcomes = await pumpSync(tester, (op, args) {
      expect(op, 'worktree.syncToPrHead');
      expect(args['repo_id'], 'repo-1');
      return {'ok': true, 'synced': true};
    });

    expect(outcomes, [true]);
    expect(find.text('Synced to the latest PR commits'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });
}
