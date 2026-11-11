import 'package:cc_data/cc_data.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server that cannot answer.
class _Unreachable implements RemoteProviderSignIn {
  @override
  Future<List<SignInLaneInfo>> lanes({String? workspaceId}) =>
      Future.error(RemoteRpcException(-32000, 'unreachable'));

  @override
  Future<List<ProviderConnection>> connections({String? workspaceId}) =>
      Future.error(RemoteRpcException(-32000, 'unreachable'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An unreachable server is not "nothing set up" or "not connected": the
/// providers complete with its error for the card to say so.
void main() {
  test('lanes and connections surface the server error', () async {
    final c = ProviderContainer(
      // Riverpod retries a failed provider; the first error is the answer.
      retry: (_, _) => null,
      overrides: [
        providerSignInRepositoryProvider.overrideWithValue(_Unreachable()),
      ],
    );
    addTearDown(c.dispose);
    await expectLater(
      c.read(oauthLanesProvider('ws-1').future),
      throwsA(isA<RemoteRpcException>()),
    );
    await expectLater(
      c.read(oauthConnectionsProvider('ws-1').future),
      throwsA(isA<RemoteRpcException>()),
    );
  });
}
