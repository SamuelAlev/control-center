import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/calendar/data/services/google_oauth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canned-response adapter that also captures the (form-encoded) request body
/// so token-endpoint calls can be asserted without any network.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.body);

  final Map<String, dynamic> body;
  String? capturedRequestBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
      capturedRequestBody = utf8.decode(bytes);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter that returns a fixed non-2xx status + JSON body, so the token
/// endpoint's error path (Google `{error, error_description}`) can be driven.
class _ErrorAdapter implements HttpClientAdapter {
  _ErrorAdapter(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Never-resolving redirect waiter for the construction sites that don't drive
/// the interactive flow (buildAuthUrl / refresh / static-method tests).
Future<Uri> _noRedirect(Duration _) => Completer<Uri>().future;

GoogleOAuthService _service(Dio dio) => GoogleOAuthService(
      clientId: 'test-client',
      tokenDio: dio,
      launcher: (_) async => true,
      awaitRedirect: _noRedirect,
    );

void main() {
  group('GoogleOAuthService.buildAuthUrl', () {
    test('encodes scope, PKCE, offline access and consent prompt', () {
      final svc = _service(Dio());
      final url = svc.buildAuthUrl(
        redirectUri: 'http://127.0.0.1:1234',
        codeChallenge: 'CHALLENGE',
        state: 'STATE',
      );
      expect('${url.scheme}://${url.host}${url.path}',
          'https://accounts.google.com/o/oauth2/v2/auth');
      final qp = url.queryParameters;
      expect(qp['client_id'], 'test-client');
      expect(qp['redirect_uri'], 'http://127.0.0.1:1234');
      expect(qp['response_type'], 'code');
      expect(qp['scope'], contains('calendar.readonly'));
      expect(qp['scope'], contains('openid'));
      expect(qp['access_type'], 'offline');
      expect(qp['prompt'], 'consent');
      expect(qp['code_challenge'], 'CHALLENGE');
      expect(qp['code_challenge_method'], 'S256');
      expect(qp['state'], 'STATE');
    });
  });

  group('GoogleOAuthService.redirectUriFor', () {
    test('reverses the iOS client id and strips the apps suffix', () {
      expect(
        GoogleOAuthService.reversedClientIdScheme(
          '123-abc.apps.googleusercontent.com',
        ),
        'com.googleusercontent.apps.123-abc',
      );
      expect(
        GoogleOAuthService.redirectUriFor('123-abc.apps.googleusercontent.com'),
        'com.googleusercontent.apps.123-abc:/oauth2redirect',
      );
    });

    test('leaves an id without the standard suffix intact', () {
      expect(
        GoogleOAuthService.reversedClientIdScheme('raw-id'),
        'com.googleusercontent.apps.raw-id',
      );
    });
  });

  group('GoogleOAuthService.authenticate', () {
    test('exchanges the redirected code (no client_secret) for tokens',
        () async {
      final adapter = _CapturingAdapter({
        'access_token': 'at',
        'refresh_token': 'rt',
        'expires_in': 3600,
        'scope': 'https://www.googleapis.com/auth/calendar.readonly',
      });
      final dio = Dio()..httpClientAdapter = adapter;

      // The flow starts awaiting the redirect *before* launching, so resolve
      // it lazily — only once the launcher has fired and exposed the generated
      // state — exactly as the real deep-link channel does.
      final stateReady = Completer<String>();
      final svc = GoogleOAuthService(
        clientId: 'cid.apps.googleusercontent.com',
        tokenDio: dio,
        launcher: (url) async {
          stateReady.complete(url.queryParameters['state']);
          return true;
        },
        awaitRedirect: (_) async {
          final state = await stateReady.future;
          return Uri.parse(
            'com.googleusercontent.apps.cid:/oauth2redirect?code=THECODE&state=$state',
          );
        },
      );

      final tokens = await svc.authenticate();

      expect(tokens.accessToken, 'at');
      expect(tokens.refreshToken, 'rt');
      expect(adapter.capturedRequestBody, contains('grant_type=authorization_code'));
      expect(adapter.capturedRequestBody, contains('code=THECODE'));
      expect(adapter.capturedRequestBody, contains('code_verifier='));
      expect(adapter.capturedRequestBody, isNot(contains('client_secret')));
    });

    test('rejects a redirect whose state does not match', () async {
      final svc = GoogleOAuthService(
        clientId: 'cid.apps.googleusercontent.com',
        tokenDio: Dio(),
        launcher: (_) async => true,
        awaitRedirect: (_) async =>
            Uri.parse('com.googleusercontent.apps.cid:/oauth2redirect?code=c&state=WRONG'),
      );
      await expectLater(
        svc.authenticate(),
        throwsA(
          isA<GoogleOAuthException>().having(
            (e) => e.kind,
            'kind',
            GoogleOAuthFailureKind.stateMismatch,
          ),
        ),
      );
    });
  });

  group('GoogleOAuthService PKCE', () {
    test('S256 challenge matches the RFC 7636 test vector', () {
      // RFC 7636 Appendix B.
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      expect(
        GoogleOAuthService.codeChallengeS256(verifier),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('code verifier is within length bounds and unreserved charset', () {
      final verifier = GoogleOAuthService.generateCodeVerifier(Random(7));
      expect(verifier.length, inInclusiveRange(43, 128));
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(verifier), isTrue);
    });
  });

  group('GoogleOAuthService.refresh', () {
    test('posts grant_type=refresh_token and returns the new access token',
        () async {
      final adapter = _CapturingAdapter({
        'access_token': 'new-access',
        'expires_in': 3600,
        'scope': 'https://www.googleapis.com/auth/calendar.readonly',
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = _service(dio);

      final result = await svc.refresh('the-refresh-token');

      expect(result.accessToken, 'new-access');
      expect(result.expiresAt.isAfter(DateTime.now()), isTrue);
      expect(adapter.capturedRequestBody, contains('grant_type=refresh_token'));
      expect(
        adapter.capturedRequestBody,
        contains('refresh_token=the-refresh-token'),
      );
    });

    test('throws when client id is missing', () async {
      final svc = GoogleOAuthService(
        clientId: '',
        tokenDio: Dio(),
        launcher: (_) async => true,
        awaitRedirect: _noRedirect,
      );
      await expectLater(
        svc.refresh('x'),
        throwsA(isA<Exception>()),
      );
    });

    test('classifies a 400 invalid_grant as the terminal invalidGrant kind',
        () async {
      final dio = Dio()
        ..httpClientAdapter = _ErrorAdapter(400, {
          'error': 'invalid_grant',
          'error_description': 'Token has been expired or revoked.',
        });
      final svc = _service(dio);

      await expectLater(
        svc.refresh('dead-token'),
        throwsA(
          isA<GoogleOAuthException>()
              .having((e) => e.kind, 'kind',
                  GoogleOAuthFailureKind.invalidGrant)
              // The real Google reason is surfaced in the message (it is *not*
              // part of DioException.message), so logs reveal the cause.
              .having((e) => e.message, 'message',
                  contains('expired or revoked')),
        ),
      );
    });

    test('classifies other token-endpoint errors as transient, body in message',
        () async {
      final dio = Dio()
        ..httpClientAdapter = _ErrorAdapter(429, {
          'error': 'rate_limit_exceeded',
          'error_description': 'Slow down.',
        });
      final svc = _service(dio);

      await expectLater(
        svc.refresh('rt'),
        throwsA(
          isA<GoogleOAuthException>()
              .having((e) => e.kind, 'kind',
                  GoogleOAuthFailureKind.tokenExchangeFailed)
              .having((e) => e.message, 'message', contains('Slow down')),
        ),
      );
    });
  });

  group('GoogleOAuthService.emailFromIdToken', () {
    test('extracts the email claim from a JWT payload', () {
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({'email': 'me@example.com'})))
          .replaceAll('=', '');
      final idToken = 'header.$payload.sig';
      expect(GoogleOAuthService.emailFromIdToken(idToken), 'me@example.com');
    });

    test('returns null for malformed tokens', () {
      expect(GoogleOAuthService.emailFromIdToken('not-a-jwt'), isNull);
      expect(GoogleOAuthService.emailFromIdToken(null), isNull);
    });
  });
}
