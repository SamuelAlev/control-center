import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

void main() {
  group('RepoOpDispatcher capability gate', () {
    RepoOpDispatcher dispatcherWith(SessionCapability? required) =>
        RepoOpDispatcher(
          registry: RepoOpRegistry([
            RepoOp(
              name: 'pairing.mint',
              kind: RepoOpKind.mutate,
              workspaceScoped: false,
              requiredCapability: required,
              handler: (ctx) async => {'ok': true},
            ),
          ]),
        );

    Future<Map<String, dynamic>> callAs(
      RepoOpDispatcher d,
      SessionCapability cap,
    ) => d.call(
      id: 1,
      params: const {'op': 'pairing.mint', 'args': <String, dynamic>{}},
      deviceId: 'caller',
      sessionCapability: cap,
    );

    test('a phone session is DENIED a fullClient-only op', () async {
      final res = await callAs(
        dispatcherWith(SessionCapability.fullClient),
        SessionCapability.phone,
      );
      expect(res['result'], isNull);
      expect((res['error'] as Map)['code'], RpcErrorCodes.unauthorized);
    });

    test('a fullClient session is ALLOWED a fullClient-only op', () async {
      final res = await callAs(
        dispatcherWith(SessionCapability.fullClient),
        SessionCapability.fullClient,
      );
      expect(res['error'], isNull);
      expect((res['result'] as Map)['data'], {'ok': true});
    });

    test('an op with no requiredCapability is allowed for ANY session', () async {
      for (final cap in SessionCapability.values) {
        final res = await callAs(dispatcherWith(null), cap);
        expect(res['error'], isNull, reason: 'cap=$cap');
        expect((res['result'] as Map)['data'], {'ok': true}, reason: 'cap=$cap');
      }
    });
  });

  group('SessionCapability.fromPlatform', () {
    test('first-party platforms map to fullClient', () {
      expect(SessionCapability.fromPlatform('web'), SessionCapability.fullClient);
      expect(
        SessionCapability.fromPlatform('desktop'),
        SessionCapability.fullClient,
      );
    });

    test('phone / unknown / null platforms map to phone (fail closed)', () {
      expect(SessionCapability.fromPlatform('ios'), SessionCapability.phone);
      expect(SessionCapability.fromPlatform('android'), SessionCapability.phone);
      expect(SessionCapability.fromPlatform('weird'), SessionCapability.phone);
      expect(SessionCapability.fromPlatform(null), SessionCapability.phone);
    });
  });
}
