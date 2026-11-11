import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_server_core/src/forge/person_forge_access.dart';
import 'package:test/test.dart';

NetworkException _e(int status, String code, [String? body]) =>
    NetworkException('x', statusCode: status, responseBody: body, code: code);

void main() {
  group('isForgeRepoDenial', () {
    test('a 404 or an access-refusing 403 is a denial', () {
      expect(isForgeRepoDenial(_e(404, 'not_found')), isTrue);
      expect(isForgeRepoDenial(_e(403, 'auth_error')), isTrue);
      expect(
        isForgeRepoDenial(
          _e(
            403,
            'auth_error',
            '{"message":"Resource protected by organization SAML '
                'enforcement."}',
          ),
        ),
        isTrue,
      );
    });

    test('a rate limit, a 5xx or a suspended install is not remembered', () {
      expect(isForgeRepoDenial(_e(429, 'rate_limited')), isFalse);
      expect(isForgeRepoDenial(_e(403, 'rate_limited')), isFalse);
      // A 403 the mapper could not classify, whose body still says so.
      expect(
        isForgeRepoDenial(
          _e(
            403,
            'auth_error',
            '{"message":"You have exceeded a secondary '
                'rate limit."}',
          ),
        ),
        isFalse,
      );
      expect(isForgeRepoDenial(_e(500, 'server_error')), isFalse);
      expect(isForgeRepoDenial(_e(503, 'server_error')), isFalse);
      expect(isForgeRepoDenial(_e(403, 'installation_suspended')), isFalse);
      expect(
        isForgeRepoDenial(const NetworkException('t', code: 'timeout')),
        isFalse,
      );
    });
  });
}
