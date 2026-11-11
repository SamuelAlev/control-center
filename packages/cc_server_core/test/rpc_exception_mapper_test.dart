import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_host_approval.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_infra/cc_infra.dart'
    show ForgeCredentialUnavailable, mapHttpException;
import 'package:cc_infra/src/environments/environment_host_approval.dart';
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
  test('a forge refusal names its kind and its forge', () {
    for (final (code, forge) in [
      ('forge_cannot_read', ForgeHost.github),
      ('forge_unconfirmed', ForgeHost.gitlab),
      ('repo_replaced', ForgeHost.bitbucket),
    ]) {
      final mapped = mapAppExceptionToRpc(
        ForgeAccessRefusedException('refused', code: code, forge: forge),
      );
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.message, 'refused');
      expect(mapped?.data, {'kind': code, 'forge': forge.wire});
    }
    // Any other coded refusal still carries its kind alone.
    expect(
      mapAppExceptionToRpc(
        const AuthException('no', code: 'repo_path.host_path'),
      )?.data,
      {'kind': 'repo_path.host_path'},
    );
  });

  test('an unapproved host definition is its own refusal, not the owner '
      'gate', () {
    final mapped = mapAppExceptionToRpc(
      const EnvironmentHostUnapprovedException(),
    );
    expect(mapped?.code, RpcErrorCodes.unauthorized);
    expect(mapped?.data, {'kind': environmentHostUnapprovedKind});
    expect(mapped?.message, contains('the server owner has not approved it'));
  });

  test('a surface the forge lacks is a named validation error', () {
    final mapped = mapAppExceptionToRpc(
      const ForgeUnsupportedError(ForgeHost.gitlab, 'issueSearch'),
    );
    expect(mapped?.code, RpcErrorCodes.validation);
    expect(mapped?.data, {
      'unsupported_capability': 'issueSearch',
      'forge': 'gitlab',
    });
  });

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

  // A person acting on GitLab/Bitbucket/Linear with no sign-in of their own
  // is refused locally; every shape that refusal reaches the RPC boundary in
  // carries the lane, so the client offers that sign-in.
  group('needs_sign_in', () {
    final request = HttpRequest(url: 'https://gitlab.example.test/api/v4/x');
    final local = const ForgeCredentialUnavailable.needsSignIn(
      'gitlab',
      'Connect your GitLab account to do this as yourself.',
    ).asStatusFailure(request);
    const expected = {'kind': 'needs_sign_in', 'lane': 'gitlab'};

    test('the raw local failure maps with its lane', () {
      final mapped = mapAppExceptionToRpc(local);
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, expected);
      expect(mapped?.message, contains('GitLab'));
    });

    test('a forge client that classified it keeps the lane', () {
      final classified = mapHttpException(local);
      expect(classified.code, 'needs_sign_in');
      final mapped = mapAppExceptionToRpc(classified);
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, expected);
    });

    test('a NeedsSignInException wrapped by an interceptor is unwrapped', () {
      final mapped = mapAppExceptionToRpc(
        RhttpInterceptorException(
          request,
          const NeedsSignInException('linear', 'Sign in to Linear.'),
        ),
      );
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, {'kind': 'needs_sign_in', 'lane': 'linear'});
    });

    test('an ordinary 401 stays a plain unauthorized', () {
      final mapped = mapAppExceptionToRpc(_status(401));
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, isNull);
    });
  });
}
