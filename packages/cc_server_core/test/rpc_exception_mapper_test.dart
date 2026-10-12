import 'package:cc_domain/cc_domain.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

RhttpStatusCodeException _status(
  int code, {
  List<(String, String)> headers = const [],
  Object? body = '{}',
}) => RhttpStatusCodeException(
  request: HttpRequest(url: 'https://api.example.test/x'),
  statusCode: code,
  headers: headers,
  body: body,
);

void main() {
  // cc_infra forge clients deliberately let an unhandled status through as a raw
  // [RhttpException] (GitLab/Bitbucket's optional-status branches), so the RPC
  // boundary must classify it instead of reporting a generic internal error.
  group('mapAppExceptionToRpc - raw transport failures', () {
    test('404 becomes notFound', () {
      expect(mapAppExceptionToRpc(_status(404))?.code, RpcErrorCodes.notFound);
    });

    test('401 and a non-rate-limit 403 become unauthorized', () {
      expect(
        mapAppExceptionToRpc(_status(401))?.code,
        RpcErrorCodes.unauthorized,
      );
      expect(
        mapAppExceptionToRpc(_status(403))?.code,
        RpcErrorCodes.unauthorized,
      );
    });

    test('400 and 422 become validation', () {
      expect(
        mapAppExceptionToRpc(_status(400))?.code,
        RpcErrorCodes.validation,
      );
      expect(
        mapAppExceptionToRpc(_status(422))?.code,
        RpcErrorCodes.validation,
      );
    });

    test('409 becomes conflict and 429 becomes rateLimited', () {
      expect(mapAppExceptionToRpc(_status(409))?.code, RpcErrorCodes.conflict);
      expect(
        mapAppExceptionToRpc(_status(429))?.code,
        RpcErrorCodes.rateLimited,
      );
    });

    test(
      'a server failure stays unmapped (internal error, logged locally)',
      () {
        expect(mapAppExceptionToRpc(_status(500)), isNull);
      },
    );

    test('a transport failure without a status stays unmapped', () {
      expect(
        mapAppExceptionToRpc(
          RhttpConnectionException(
            HttpRequest(url: 'https://api.example.test/x'),
            'refused',
          ),
        ),
        isNull,
      );
    });

    test('a cancellation maps to requestCancelled, not an internal error', () {
      expect(
        mapAppExceptionToRpc(
          RhttpCancelException(HttpRequest(url: 'https://api.example.test/x')),
        )?.code,
        RpcErrorCodes.requestCancelled,
      );
    });

    test('a suspended App installation reads as unauthorized', () {
      final mapped = mapAppExceptionToRpc(
        _status(
          403,
          body: '{"message":"This installation has been suspended"}',
        ),
      );
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.message, contains('suspended'));
    });
  });

  test('domain exceptions keep their existing codes', () {
    expect(
      mapAppExceptionToRpc(const WorkspaceMismatchException('nope'))?.code,
      RpcErrorCodes.workspaceMismatch,
    );
    expect(
      mapAppExceptionToRpc(const NotFoundException('gone'))?.code,
      RpcErrorCodes.notFound,
    );
  });
}
