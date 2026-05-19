import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RequestOptions ro() => RequestOptions();

  group('mapDioException', () {
    group('auth errors', () {
      test('maps 401 status to auth_error', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 401,
            data: 'Unauthorized',
          ),
          message: 'Unauthorized',
        );

        final result = mapDioException(exception);

        expect(result, isA<NetworkException>());
        expect(result.code, 'auth_error');
        expect(result.statusCode, 401);
        expect(result.responseBody, 'Unauthorized');
      });

      test('maps 403 status to auth_error', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 403,
            data: 'Forbidden',
          ),
          message: 'Forbidden',
        );

        final result = mapDioException(exception);

        expect(result.code, 'auth_error');
        expect(result.statusCode, 403);
      });
    });

    group('not found errors', () {
      test('maps 404 status to not_found', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 404,
            data: 'Not Found',
          ),
          message: 'Not found',
        );

        final result = mapDioException(exception);

        expect(result.code, 'not_found');
        expect(result.statusCode, 404);
        expect(result.responseBody, 'Not Found');
      });

      test('response body can be null', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 404,
          ),
          message: 'Not found',
        );

        final result = mapDioException(exception);

        expect(result.code, 'not_found');
        expect(result.responseBody, isNull);
      });
    });

    group('server errors', () {
      test('maps 500 status to server_error', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 500,
            data: 'Internal Server Error',
          ),
        );

        final result = mapDioException(exception);

        expect(result.code, 'server_error');
        expect(result.statusCode, 500);
      });

      test('maps 502 status to server_error', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 502,
          ),
        );

        final result = mapDioException(exception);

        expect(result.code, 'server_error');
        expect(result.statusCode, 502);
      });

      test('maps 503 status to server_error', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 503,
          ),
        );

        final result = mapDioException(exception);

        expect(result.code, 'server_error');
        expect(result.statusCode, 503);
      });

      test('any 5xx status maps to server_error', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 599,
          ),
        );

        final result = mapDioException(exception);

        expect(result.code, 'server_error');
        expect(result.statusCode, 599);
      });
    });

    group('timeout errors', () {
      test('maps connectionTimeout to timeout', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        );

        final result = mapDioException(exception);

        expect(result.code, 'timeout');
        expect(result.statusCode, isNull);
      });

      test('maps receiveTimeout to timeout', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.receiveTimeout,
          message: 'Response timed out',
        );

        final result = mapDioException(exception);

        expect(result.code, 'timeout');
      });

      test('maps sendTimeout to timeout', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.sendTimeout,
          message: 'Send timed out',
        );

        final result = mapDioException(exception);

        expect(result.code, 'timeout');
      });

      test('timeout errors have no responseBody', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.connectionTimeout,
        );

        final result = mapDioException(exception);

        expect(result.responseBody, isNull);
      });

      test('timeout uses default message when message is null', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.connectionTimeout,
        );

        final result = mapDioException(exception);

        expect(result.message, 'Network timeout');
      });
    });

    group('connection errors', () {
      test('maps connectionError to connection_error', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.connectionError,
          message: 'No route to host',
        );

        final result = mapDioException(exception);

        expect(result.code, 'connection_error');
      });

      test('connection error uses default message when null', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.connectionError,
        );

        final result = mapDioException(exception);

        expect(result.message, 'Connection error');
      });
    });

    group('generic network errors', () {
      test('maps unknown DioException to network_error', () {
        final exception = DioException(
          requestOptions: ro(),

          message: 'Something went wrong',
          response: Response(
            requestOptions: ro(),
            statusCode: 422,
            data: 'Unprocessable',
          ),
        );

        final result = mapDioException(exception);

        expect(result.code, 'unprocessable_entity');
        expect(result.responseBody, 'Unprocessable');
      });

      test('maps null message to default', () {
        final exception = DioException(
          requestOptions: ro(),

        );

        final result = mapDioException(exception);

        expect(result.message, 'Network error');
      });
    });

    group('response body serialization', () {
      test('string response body is preserved', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 500,
            data: 'Server crash report',
          ),
        );

        final result = mapDioException(exception);

        expect(result.responseBody, 'Server crash report');
      });

      test('map response body is serialized to string', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 500,
            data: {'error': 'bad_gateway', 'detail': 'Upstream timeout'},
          ),
        );

        final result = mapDioException(exception);

        expect(result.responseBody, contains('detail'));
        expect(result.responseBody, contains('bad_gateway'));
      });

      test('list response body is serialized to string', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 422,
            data: ['error1', 'error2'],
          ),
        );

        final result = mapDioException(exception);

        expect(result.responseBody, contains('error1'));
        expect(result.responseBody, contains('error2'));
      });
    });

    group('priority order', () {
      test('auth errors (401) take priority over server errors', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 401,
          ),
        );

        final result = mapDioException(exception);

        expect(result.code, 'auth_error');
      });

      test('not found (404) takes priority over server errors', () {
        final exception = DioException(
          requestOptions: ro(),
          response: Response(
            requestOptions: ro(),
            statusCode: 404,
          ),
        );

        final result = mapDioException(exception);

        expect(result.code, 'not_found');
      });

      test('timeout takes priority over generic when no response', () {
        final exception = DioException(
          requestOptions: ro(),
          type: DioExceptionType.connectionTimeout,
        );

        final result = mapDioException(exception);

        expect(result.code, 'timeout');
      });
    });

    group('NetworkException', () {
      test('toString includes code and statusCode', () {
        const ex = NetworkException(
          'Auth failed',
          code: 'auth_error',
          statusCode: 401,
          responseBody: 'unauthorized',
        );

        final str = ex.toString();
        expect(str, contains('auth_error'));
        expect(str, contains('Auth failed'));
      });

      test('toString omits code when null', () {
        const ex = NetworkException('Error message');

        final str = ex.toString();
        expect(str, contains('Error message'));
        expect(str, isNot(contains('code')));
      });
    });
  });
}
