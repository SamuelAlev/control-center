import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  group('classifyConnectionError', () {
    test('NoReachablePathException is unreachable', () {
      const error = NoReachablePathException('srv-1', ['lo: unreachable']);
      expect(classifyConnectionError(error), ConnectionFailureKind.unreachable);
    });

    test('ServerIdentityMismatchException is identityMismatch', () {
      const error = ServerIdentityMismatchException(
        expectedFingerprint: 'aaaa',
        actualFingerprint: 'bbbb',
      );
      expect(
        classifyConnectionError(error),
        ConnectionFailureKind.identityMismatch,
      );
    });

    test('AuthRejectedException is authRejected', () {
      const error = AuthRejectedException('Server auth proof mismatch');
      expect(
        classifyConnectionError(error),
        ConnectionFailureKind.authRejected,
      );
    });

    test(
      'a supervisor status string carrying the type name classifies the same',
      () {
        expect(
          classifyConnectionError(
            'NoReachablePathException: no path to server srv-1 — lo: timeout',
          ),
          ConnectionFailureKind.unreachable,
        );
        expect(
          classifyConnectionError(
            const ServerIdentityMismatchException(
              expectedFingerprint: 'aaaa',
              actualFingerprint: 'bbbb',
            ).toString(),
          ),
          ConnectionFailureKind.identityMismatch,
        );
        expect(
          classifyConnectionError('Server rejected the device'),
          ConnectionFailureKind.authRejected,
        );
      },
    );

    test(
      'a wrapped exception whose text carries the marker classifies the same',
      () {
        expect(
          classifyConnectionError(
            Exception('connect failed: NoReachablePathException: …'),
          ),
          ConnectionFailureKind.unreachable,
        );
      },
    );

    test('anything else is unknown', () {
      expect(
        classifyConnectionError(StateError('Server did not complete auth')),
        ConnectionFailureKind.unknown,
      );
      expect(classifyConnectionError('bogus'), ConnectionFailureKind.unknown);
    });
  });
}
