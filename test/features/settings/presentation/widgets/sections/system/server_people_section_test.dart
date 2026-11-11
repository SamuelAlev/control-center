import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes, UserDto;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/server_people_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/fake_rpc_client.dart';
import '../../../../../../helpers/test_wrap.dart';

/// Settings → Server → People: the owner sees whose email nobody confirmed
/// and can vouch for it.
void main() {
  final confirmAction = find.byWidgetPredicate(
    (w) => w is CcIconButton && w.semanticLabel == 'Confirm email',
  );
  final typed = UserDto(
    id: 'u-sam',
    handle: 'sam',
    displayName: 'Sam Rivera',
    email: 'sam@example.com',
  );
  final vouched = UserDto(
    id: 'u-ada',
    handle: 'ada',
    displayName: 'Ada Lovelace',
    email: 'ada@example.com',
    emailVerified: true,
  );
  final noEmail = UserDto(id: 'u-bo', handle: 'bo', displayName: 'Bo');

  Future<List<Map<String, dynamic>>> pump(
    WidgetTester tester, {
    required bool owner,
    Map<String, dynamic> Function(String op, Map<String, dynamic> args)? onCall,
  }) async {
    final calls = <Map<String, dynamic>>[];
    final host = FakeRpcHost()
      ..onCall = (op, args) {
        // Only the people ops: identity loads ride the same host.
        if (op.startsWith('users.')) {
          calls.add({'op': op, ...args});
        }
        return onCall?.call(op, args) ?? const {};
      };
    final rpc = host.client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rpcClientProvider.overrideWithValue(rpc),
          isServerOwnerProvider.overrideWithValue(owner),
          usersByIdProvider.overrideWith(
            (ref) => Stream.value({
              for (final u in [typed, vouched, noEmail]) u.id: u,
            }),
          ),
        ],
        child: testWrap(const ServerPeopleSection()),
      ),
    );
    await tester.pump();
    await tester.pump();
    return calls;
  }

  testWidgets('only an unconfirmed address is marked and offered', (
    tester,
  ) async {
    await pump(tester, owner: true);

    expect(find.text('Sam Rivera'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Bo'), findsOneWidget);
    expect(find.text('Email not confirmed'), findsOneWidget);
    expect(confirmAction, findsOneWidget);
  });

  testWidgets('confirming asks first, then vouches through the server', (
    tester,
  ) async {
    final calls = await pump(
      tester,
      owner: true,
      onCall: (op, args) => {
        'user': {
          'id': 'u-sam',
          'handle': 'sam',
          'display_name': 'Sam Rivera',
          'email': 'sam@example.com',
          'email_verified': true,
        },
      },
    );

    await tester.tap(confirmAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        'Confirm that sam@example.com belongs to Sam Rivera? Single sign-on '
        'will match this address to their account.',
      ),
      findsOneWidget,
    );
    expect(calls, isEmpty);

    await tester.tap(find.widgetWithText(CcButton, 'Confirm email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(calls, [
      {'op': 'users.vouchEmail', 'user_id': 'u-sam'},
    ]);
    expect(find.text('Email not confirmed'), findsNothing);
    expect(confirmAction, findsNothing);
    expect(find.text('Confirmed sam@example.com.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('an owner-only refusal is worded, not raw', (tester) async {
    await pump(
      tester,
      owner: true,
      onCall: (op, args) => throw RemoteRpcException(
        RpcErrorCodes.unauthorized,
        'server owner required',
        {'kind': 'server_owner_required'},
      ),
    );

    await tester.tap(confirmAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(CcButton, 'Confirm email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        "Only the server's owner can see everyone's account and confirm "
        'email addresses.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('server owner required'), findsNothing);
    expect(find.text('Email not confirmed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets("anyone else sees that the list is the owner's", (tester) async {
    await pump(tester, owner: false);

    expect(find.text('Sam Rivera'), findsNothing);
    expect(find.text('Email not confirmed'), findsNothing);
    expect(find.text('Only the server owner can do this'), findsOneWidget);
  });
}
