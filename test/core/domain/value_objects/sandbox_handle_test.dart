import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SandboxState', () {
    test('has all six values', () {
      expect(SandboxState.values, [
        SandboxState.created,
        SandboxState.warm,
        SandboxState.active,
        SandboxState.suspended,
        SandboxState.destroyed,
        SandboxState.error,
      ]);
    });
  });

  group('SandboxHandle', () {
    test('default state is created', () {
      final handle = SandboxHandle(
        sessionId: 's1',
        backend: SandboxBackend.native,
      );
      expect(handle.state, SandboxState.created);
    });

    test('default details is empty map', () {
      final handle = SandboxHandle(
        sessionId: 's1',
        backend: SandboxBackend.native,
      );
      expect(handle.details, <String, Object?>{});
    });

    test('default error is null', () {
      final handle = SandboxHandle(
        sessionId: 's1',
        backend: SandboxBackend.native,
      );
      expect(handle.error, isNull);
    });

    test('construction with all fields', () {
      final err = Exception('boom');
      final handle = SandboxHandle(
        sessionId: 's1',
        backend: SandboxBackend.none,
        state: SandboxState.error,
        error: err,
        details: {'pid': 42},
      );
      expect(handle.sessionId, 's1');
      expect(handle.backend, SandboxBackend.none);
      expect(handle.state, SandboxState.error);
      expect(handle.error, err);
      expect(handle.details, {'pid': 42});
    });

    group('copyWith', () {
      test('changes only specified fields', () {
        final original = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.warm,
          details: {'key': 'val'},
        );
        final copy = original.copyWith(
          state: SandboxState.active,
          details: {'pid': 99},
        );
        expect(copy.sessionId, 's1');
        expect(copy.backend, SandboxBackend.native);
        expect(copy.state, SandboxState.active);
        expect(copy.details, {'pid': 99});
      });

      test('with no args returns equal but not identical instance', () {
        final original = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.warm,
        );
        final copy = original.copyWith();
        expect(copy, equals(original));
        expect(identical(copy, original), isFalse);
      });
    });

    group('equality', () {
      test('equal with same fields including map equality', () {
        final a = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.warm,
          details: {'pid': 42},
        );
        final b = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.warm,
          details: {'pid': 42},
        );
        expect(a, equals(b));
      });

      test('not equal with different sessionId', () {
        final a = SandboxHandle(sessionId: 's1', backend: SandboxBackend.native);
        final b = SandboxHandle(sessionId: 's2', backend: SandboxBackend.native);
        expect(a, isNot(equals(b)));
      });

      test('not equal with different backend', () {
        final a = SandboxHandle(sessionId: 's1', backend: SandboxBackend.native);
        final b = SandboxHandle(sessionId: 's1', backend: SandboxBackend.none);
        expect(a, isNot(equals(b)));
      });

      test('not equal with different state', () {
        final a = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.created,
        );
        final b = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.warm,
        );
        expect(a, isNot(equals(b)));
      });

      test('not equal with different error', () {
        final a = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          error: Exception('a'),
        );
        final b = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          error: Exception('b'),
        );
        expect(a, isNot(equals(b)));
      });

      test('not equal with different details', () {
        final a = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          details: {'a': 1},
        );
        final b = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          details: {'b': 2},
        );
        expect(a, isNot(equals(b)));
      });

      test('hashCode consistency', () {
        final a = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.warm,
          details: {'pid': 42},
        );
        final b = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          state: SandboxState.warm,
          details: {'pid': 42},
        );
        expect(a.hashCode, equals(b.hashCode));
      });

      test('details map equality works for different instances with same content', () {
        final a = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          details: {'x': 1, 'y': 'z'},
        );
        final b = SandboxHandle(
          sessionId: 's1',
          backend: SandboxBackend.native,
          details: {'x': 1, 'y': 'z'},
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });
  });
}
