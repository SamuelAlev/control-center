import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:test/test.dart';

/// Covers every AppException subclass's constructor, fields, and toString
/// contract. The sealed base formats `Type(message[, code: x])`; several
/// agent-facing subclasses override toString to return just the message so
/// surfaced explanations stay clean.
void main() {
  group('AppException base', () {
    test('toString formats type, message, and an optional code', () {
      const e = AuthException('bad token');
      expect(e.toString(), 'AuthException(bad token)');

      const coded = AuthException('bad token', code: 'auth/invalid');
      expect(coded.toString(), 'AuthException(bad token, code: auth/invalid)');
    });

    test('carries message and code fields', () {
      const e = AuthException('no', code: 'c1');
      expect(e.message, 'no');
      expect(e.code, 'c1');
    });

    test('an AppException is an Exception', () {
      expect(const AuthException('x'), isA<Exception>());
    });
  });

  group('NetworkException', () {
    test('carries status code and response body', () {
      const e = NetworkException(
        'timeout',
        statusCode: 504,
        responseBody: 'Gateway Timeout',
        code: 'net/timeout',
      );
      expect(e.message, 'timeout');
      expect(e.statusCode, 504);
      expect(e.responseBody, 'Gateway Timeout');
      expect(e.code, 'net/timeout');
      expect(e.toString(), 'NetworkException(timeout, code: net/timeout)');
    });

    test('status code and response body are optional', () {
      const e = NetworkException('err');
      expect(e.statusCode, isNull);
      expect(e.responseBody, isNull);
      expect(e.code, isNull);
    });
  });

  group('simple AppException subclasses', () {
    test('AuthException carries message and code', () {
      const e = AuthException('unauthenticated', code: 'auth/needed');
      expect(e.message, 'unauthenticated');
      expect(e.code, 'auth/needed');
    });

    test('NotFoundException carries message and code', () {
      const e = NotFoundException('missing', code: 'not-found');
      expect(e.message, 'missing');
      expect(e.code, 'not-found');
      expect(e.toString(), 'NotFoundException(missing, code: not-found)');
    });

    test('CacheException carries message and code', () {
      const e = CacheException('corrupt', code: 'cache/corrupt');
      expect(e.message, 'corrupt');
      expect(e.code, 'cache/corrupt');
    });
  });

  group('ShellException', () {
    test('carries an exit code', () {
      const e = ShellException('boom', exitCode: 2, code: 'shell/exit');
      expect(e.message, 'boom');
      expect(e.exitCode, 2);
      expect(e.code, 'shell/exit');
      expect(e.toString(), 'ShellException(boom, code: shell/exit)');
    });

    test('exit code is optional', () {
      const e = ShellException('fail');
      expect(e.exitCode, isNull);
    });
  });

  group('EditorLaunchException and PrWorktreeException', () {
    test('EditorLaunchException surfaces the message verbatim', () {
      const e = EditorLaunchException('editor not installed', code: 'editor');
      expect(e.message, 'editor not installed');
      expect(e.code, 'editor');
    });

    test('PrWorktreeException surfaces the message verbatim', () {
      const e = PrWorktreeException('no remote', code: 'prwt');
      expect(e.message, 'no remote');
      expect(e.code, 'prwt');
    });
  });

  group('ServerException', () {
    test('carries an underlying cause', () {
      final cause = StateError('port in use');
      final e = ServerException('failed to start', cause: cause, code: 'srv');
      expect(e.message, 'failed to start');
      expect(e.cause, same(cause));
      expect(e.code, 'srv');
    });

    test('cause is optional', () {
      const e = ServerException('down');
      expect(e.cause, isNull);
    });
  });

  group('ConcurrencyConflictException', () {
    test('carries message and code', () {
      const e = ConcurrencyConflictException('stale', code: 'cc/409');
      expect(e.message, 'stale');
      expect(e.code, 'cc/409');
    });
  });

  group('GoogleOAuthException', () {
    test('carries the classified failure kind', () {
      const e = GoogleOAuthException(
        'denied',
        kind: GoogleOAuthFailureKind.consentDenied,
        code: 'oauth',
      );
      expect(e.message, 'denied');
      expect(e.kind, GoogleOAuthFailureKind.consentDenied);
      expect(e.code, 'oauth');
    });

    test('kind is optional', () {
      const e = GoogleOAuthException('refresh failed');
      expect(e.kind, isNull);
    });

    test('every GoogleOAuthFailureKind value exists', () {
      // Guards against a future rename dropping a kind a caller switches on.
      expect(
        GoogleOAuthFailureKind.values,
        containsAll(<GoogleOAuthFailureKind>[
          GoogleOAuthFailureKind.userCancelled,
          GoogleOAuthFailureKind.consentDenied,
          GoogleOAuthFailureKind.timedOut,
          GoogleOAuthFailureKind.stateMismatch,
          GoogleOAuthFailureKind.tokenExchangeFailed,
          GoogleOAuthFailureKind.invalidGrant,
          GoogleOAuthFailureKind.missingClientId,
        ]),
      );
    });
  });

  group('agent-facing exceptions return just the message in toString', () {
    test('WorkspaceMismatchException returns the bare message', () {
      const e = WorkspaceMismatchException('cross-workspace', code: 'ws/403');
      expect(e.toString(), 'cross-workspace');
      expect(e.message, 'cross-workspace');
      expect(e.code, 'ws/403');
    });

    test('ValidationException returns the bare message', () {
      const e = ValidationException('bad input', code: 'val/400');
      expect(e.toString(), 'bad input');
    });

    test('OrgChartException returns the bare message', () {
      const e = OrgChartException('cycle', code: 'org/cycle');
      expect(e.toString(), 'cycle');
    });

    test('InvalidApprovalTransitionException returns the bare message', () {
      const e = InvalidApprovalTransitionException(
        'already approved',
        code: 'approval',
      );
      expect(e.toString(), 'already approved');
    });

    test('DelegationRefusedException returns the bare message', () {
      const e = DelegationRefusedException('depth cap', code: 'deleg');
      expect(e.toString(), 'depth cap');
    });

    test('CheckoutConflictException returns the bare message + holder', () {
      const e = CheckoutConflictException(
        'held by other',
        holderAgentId: 'a9',
        code: 'checkout',
      );
      expect(e.toString(), 'held by other');
      expect(e.holderAgentId, 'a9');
    });

    test(
      'OutputContractViolationException returns the bare message + fields',
      () {
        const e = OutputContractViolationException(
          'schema mismatch',
          violations: [r'$.status: required'],
          terminal: true,
          code: 'contract',
        );
        expect(e.toString(), 'schema mismatch');
        expect(e.violations, [r'$.status: required']);
        expect(e.terminal, isTrue);
      },
    );
  });
}
