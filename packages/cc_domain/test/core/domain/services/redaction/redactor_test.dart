import 'dart:convert';

import 'package:cc_domain/core/domain/services/redaction/redactor.dart';
import 'package:test/test.dart';

void main() {
  group('HeaderRedactor', () {
    test('drops non-allow-listed headers and redacts sensitive ones', () {
      const redactor = HeaderRedactor.request(
        allow: ['content-type', 'authorization'],
      );
      final out = redactor.redactRequest(
        const RequestSnapshot(
          method: 'GET',
          url: 'https://api.example.com',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer secret-token-value',
            'X-Trace': 'keep-out',
          },
          body: '',
        ),
      );
      expect(out.headers, {
        'authorization': kRedacted,
        'content-type': 'application/json',
      });
      expect(out.headers.containsKey('x-trace'), isFalse);
    });
  });

  group('UrlQueryRedactor', () {
    test('scrubs sensitive query params and user info', () {
      final out = UrlQueryRedactor().redactRequest(
        const RequestSnapshot(
          method: 'GET',
          url: 'https://u:p@api.example.com/x?token=abc&page=2',
          headers: {},
          body: '',
        ),
      );
      final uri = Uri.parse(out.url);
      expect(uri.queryParameters['token'], kRedacted);
      expect(uri.queryParameters['page'], '2');
      // userInfo is stored percent-encoded; it must no longer carry the creds.
      expect(Uri.decodeComponent(uri.userInfo), kRedacted);
      expect(out.url.contains('u:p@'), isFalse);
    });
  });

  group('BodyRedactor', () {
    test('rewrites JSON bodies and leaves non-JSON untouched', () {
      final redactor = BodyRedactor((parsed) {
        final map = Map<String, dynamic>.from(parsed as Map);
        map['password'] = kRedacted;
        return map;
      });
      final out = redactor.redactRequest(
        const RequestSnapshot(
          method: 'POST',
          url: 'https://api.example.com',
          headers: {},
          body: '{"user":"a","password":"hunter2"}',
        ),
      );
      expect(jsonDecode(out.body), {'user': 'a', 'password': kRedacted});

      final plain = redactor.redactRequest(
        const RequestSnapshot(
          method: 'POST',
          url: 'https://api.example.com',
          headers: {},
          body: 'not json',
        ),
      );
      expect(plain.body, 'not json');
    });
  });

  group('Redactor.compose / defaults', () {
    test('applies request and response transforms in order', () {
      final redactor = Redactor.defaults();
      final req = redactor.redactRequest(
        const RequestSnapshot(
          method: 'GET',
          url: 'https://api.example.com/x?api_key=zzz',
          headers: {'authorization': 'Bearer t', 'accept': 'application/json'},
          body: '',
        ),
      );
      expect(Uri.parse(req.url).queryParameters['api_key'], kRedacted);
      expect(req.headers.containsKey('authorization'), isFalse);
      expect(req.headers['accept'], 'application/json');

      final res = redactor.redactResponse(
        const ResponseSnapshot(
          status: 200,
          headers: {'content-type': 'application/json', 'set-cookie': 'a=b'},
          body: '{}',
        ),
      );
      expect(res.headers['content-type'], 'application/json');
      expect(res.headers.containsKey('set-cookie'), isFalse);
    });
  });

  group('snapshot round-trip', () {
    test('RequestSnapshot and ResponseSnapshot survive JSON', () {
      const req = RequestSnapshot(
        method: 'POST',
        url: 'https://x',
        headers: {'a': 'b'},
        body: '{}',
      );
      expect(RequestSnapshot.fromJson(req.toJson()).toJson(), req.toJson());

      const res = ResponseSnapshot(
        status: 201,
        headers: {'c': 'd'},
        body: 'AAA',
        bodyEncoding: 'base64',
      );
      expect(ResponseSnapshot.fromJson(res.toJson()).toJson(), res.toJson());
    });
  });
}
