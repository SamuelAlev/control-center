import 'package:cc_domain/cc_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException', () {
    test('message is accessible on subclass', () {
      const ex = AuthException('Something went wrong');
      expect(ex.message, 'Something went wrong');
      expect(ex.code, isNull);
    });

    test('message and code accessible on subclass', () {
      const ex = NotFoundException('Error occurred', code: 'ERR_001');
      expect(ex.message, 'Error occurred');
      expect(ex.code, 'ERR_001');
    });

    test('toString includes code when present via subclass', () {
      const ex = NetworkException('Error', statusCode: 500, code: 'E100');
      expect(ex.toString(), contains('code: E100'));
    });

    test('toString excludes code section when null', () {
      const ex = AuthException('Error');
      expect(ex.toString(), isNot(contains('code:')));
    });

    test('is Exception', () {
      const ex = AuthException('test');
      expect(ex, isA<AppException>());
      expect(ex, isA<Exception>());
    });
  });

  group('NetworkException', () {
    test('creates with message and status code', () {
      const ex = NetworkException('Network error', statusCode: 404);
      expect(ex.message, 'Network error');
      expect(ex.statusCode, 404);
      expect(ex.responseBody, isNull);
      expect(ex.code, isNull);
    });

    test('creates with all fields', () {
      const ex = NetworkException(
        'Bad request',
        statusCode: 400,
        responseBody: '{"error": "invalid"}',
        code: 'NET_400',
      );
      expect(ex.message, 'Bad request');
      expect(ex.statusCode, 400);
      expect(ex.responseBody, '{"error": "invalid"}');
      expect(ex.code, 'NET_400');
    });

    test('is AppException', () {
      const ex = NetworkException('net', statusCode: 500);
      expect(ex, isA<AppException>());
    });

    test('inherits toString from AppException', () {
      const ex = NetworkException('Net issue', code: 'N1');
      expect(ex.toString(), contains('Net issue'));
      expect(ex.toString(), contains('code: N1'));
    });
  });

  group('AuthException', () {
    test('creates with message', () {
      const ex = AuthException('Unauthorized');
      expect(ex.message, 'Unauthorized');
      expect(ex.code, isNull);
    });

    test('creates with message and code', () {
      const ex = AuthException('Token expired', code: 'AUTH_001');
      expect(ex.message, 'Token expired');
      expect(ex.code, 'AUTH_001');
    });

    test('is AppException', () {
      const ex = AuthException('auth');
      expect(ex, isA<AppException>());
    });
  });

  group('NotFoundException', () {
    test('creates with message', () {
      const ex = NotFoundException('User not found');
      expect(ex.message, 'User not found');
      expect(ex.code, isNull);
    });

    test('creates with message and code', () {
      const ex = NotFoundException('Resource missing', code: 'NF_404');
      expect(ex.message, 'Resource missing');
      expect(ex.code, 'NF_404');
    });

    test('is AppException', () {
      const ex = NotFoundException('not found');
      expect(ex, isA<AppException>());
    });
  });

  group('Exception hierarchy', () {
  });
}
