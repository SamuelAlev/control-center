import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// The public URL every test Connect claims to live at. Requests actually go
/// to a loopback port; signatures cover this URL, never the Host header.
const String testPublicUrl = 'https://connect.test';

/// One recorded upstream call.
final class RecordedCall {
  RecordedCall(this.request);

  final UpstreamRequest request;

  String get method => request.method;
  Uri get url => request.url;

  Map<String, String> get form =>
      Uri.splitQueryString(utf8.decode(request.body ?? const []));

  Map<String, Object?> get json =>
      jsonDecode(utf8.decode(request.body ?? const [])) as Map<String, Object?>;
}

typedef FakeHandler = FutureOr<UpstreamResponse> Function(RecordedCall call);

/// A scripted [UpstreamHttp]: `METHOD host/path` → handler. Unscripted calls
/// answer 599 (transient) and are recorded.
final class FakeUpstream implements UpstreamHttp {
  final Map<String, FakeHandler> _routes = {};
  final List<RecordedCall> calls = [];

  void on(String method, String url, FakeHandler handler) {
    final uri = Uri.parse(url);
    _routes['$method ${uri.host}${uri.path}'] = handler;
  }

  void json(String method, String url, int status, Object? body) =>
      on(method, url, (_) => UpstreamResponse.json(status, body));

  List<RecordedCall> callsTo(String method, String url) {
    final uri = Uri.parse(url);
    return [
      for (final call in calls)
        if (call.method == method &&
            call.url.host == uri.host &&
            call.url.path == uri.path)
          call,
    ];
  }

  @override
  Future<UpstreamResponse> send(UpstreamRequest request) async {
    final call = RecordedCall(request);
    calls.add(call);
    final handler =
        _routes['${request.method} ${request.url.host}${request.url.path}'];
    if (handler == null) {
      return UpstreamResponse(599, utf8.encode('{}'));
    }
    return handler(call);
  }

  @override
  void close() {}
}

/// An HTTP answer read by a test.
final class TestResponse {
  TestResponse(this.status, this.headers, this.body);

  final int status;
  final HttpHeaders headers;
  final String body;

  Map<String, Object?> get json => jsonDecode(body) as Map<String, Object?>;

  String? header(String name) => headers.value(name);
}

Uint8List seed(int fill) => Uint8List.fromList(List.filled(32, fill));

/// A running Connect plus helpers.
final class Harness {
  Harness._(this.handle, this.upstream, this.dataDir, this.logs, this.publicUrl)
    : mount = Uri.parse(publicUrl).path;

  /// Starts a Connect from [env] (merged over a complete default).
  static Future<Harness> start({
    required List<ConnectInstallIdentity> allowed,
    Map<String, String> env = const {},
    Duration pollTimeout = const Duration(seconds: 25),
    FakeUpstream? upstream,
  }) async {
    final dir = await Directory.systemTemp.createTemp('cc_connect_test');
    final fake = upstream ?? FakeUpstream();
    final logs = <String>[];
    final merged = {...defaultEnv(allowed, dir.path), ...env}
      ..removeWhere((_, value) => value.isEmpty);
    final ConnectServiceConfig config;
    final ConnectServerHandle handle;
    try {
      config = ConnectServiceConfig.fromEnvironment(merged);
      final service = await ConnectService.start(
        config,
        upstream: fake,
        logSink: logs.add,
        pollTimeout: pollTimeout,
      );
      handle = await serveConnect(service, host: '127.0.0.1', port: 0);
    } on Object {
      await dir.delete(recursive: true);
      rethrow;
    }
    return Harness._(handle, fake, dir, logs, config.publicBaseUrl);
  }

  static Map<String, String> defaultEnv(
    List<ConnectInstallIdentity> allowed,
    String dataDir,
  ) => {
    'CONNECT_PUBLIC_URL': testPublicUrl,
    'CONNECT_ALLOWED_INSTALLS': allowed.map((i) => i.installId).join(','),
    'CONNECT_GITHUB_APP_ID': '4242',
    'CONNECT_GITHUB_APP_SLUG': 'cc-test',
    'CONNECT_GITHUB_CLIENT_ID': 'Iv23test',
    'CONNECT_GITHUB_CLIENT_SECRET': 'gh-secret-2',
    'CONNECT_GITHUB_CLIENT_SECRET_PREVIOUS': 'gh-secret-1',
    'CONNECT_GITHUB_SECRET_GENERATION': '2',
    'CONNECT_GOOGLE_CLIENT_ID': 'g-client.apps.googleusercontent.com',
    'CONNECT_GOOGLE_CLIENT_SECRET': 'goog-secret',
    'CONNECT_LINEAR_CLIENT_ID': 'lin_client',
    'CONNECT_SLACK_APP_ID': 'A0TEST',
    'CONNECT_SLACK_CLIENT_ID': '111.222',
    'CONNECT_SLACK_CLIENT_SECRET': 'slack-secret',
    'CONNECT_SLACK_SIGNING_SECRET': 'signing-secret',
    'CONNECT_KLIPY_APP_KEY': 'klipy-key-123',
    'CONNECT_SEAL_KEYS': 'k1:${base64.encode(List.filled(32, 9))}',
    'CONNECT_DATA_DIR': dataDir,
  };

  final ConnectServerHandle handle;
  final FakeUpstream upstream;
  final Directory dataDir;
  final List<String> logs;

  /// The canonical public base URL requests are signed against.
  final String publicUrl;

  /// The path prefix requests are sent under (empty unless mounted).
  final String mount;
  final HttpClient _client = HttpClient();

  ConnectService get service => handle.service;

  Future<void> close() async {
    _client.close(force: true);
    await handle.close();
    await dataDir.delete(recursive: true);
  }

  Future<TestResponse> _read(HttpClientResponse response) async {
    final body = await utf8.decodeStream(response);
    return TestResponse(response.statusCode, response.headers, body);
  }

  /// A raw request (no signature) to [path] exactly as given.
  Future<TestResponse> raw(
    String method,
    String path, {
    Map<String, String> headers = const {},
    List<int>? body,
  }) async {
    final request = await _client.open(method, '127.0.0.1', handle.port, path);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    if (body != null) {
      request.contentLength = body.length;
      request.add(body);
    }
    return _read(await request.close());
  }

  /// A signed call as [identity]. [nonce] pins the nonce (replay tests).
  Future<TestResponse> call(
    ConnectInstallIdentity identity,
    String method,
    String path, {
    Object? body,
    String? nonce,
    Map<String, String> extraHeaders = const {},
    DateTime? signedAt,
    String? signedUrl,
    List<int>? sentBody,
  }) async {
    final bytes = body == null ? <int>[] : utf8.encode(jsonEncode(body));
    final signer = ConnectRequestSigner(
      identity,
      now: signedAt == null ? null : () => signedAt,
    );
    final headers = await signer.sign(
      method: method,
      targetUri: Uri.parse(signedUrl ?? '$publicUrl$path'),
      body: bytes,
      nonce: nonce,
    );
    return raw(
      method,
      '$mount$path',
      headers: {...headers, ...extraHeaders},
      body: sentBody ?? bytes,
    );
  }

  /// A browser GET, optionally with the login cookie.
  Future<TestResponse> browser(String pathAndQuery, {String? cookie}) => raw(
    'GET',
    '$mount$pathAndQuery',
    headers: {if (cookie != null) 'cookie': '__Host-cc_connect=$cookie'},
  );
}

/// The cookie value a 303 set, or null.
String? cookieFrom(TestResponse response) {
  final header = response.headers['set-cookie']?.single;
  if (header == null) {
    return null;
  }
  final match = RegExp('__Host-cc_connect=([^;]+)').firstMatch(header);
  return match?.group(1);
}

/// The confirm code shown on a `/done` page.
String? confirmCodeFrom(String html) {
  final match = RegExp(
    r'class="code">([0-9A-Z]{4})-([0-9A-Z]{4})<',
  ).firstMatch(html);
  return match == null ? null : '${match.group(1)}${match.group(2)}';
}

/// A fake JWT (unsigned: Connect trusts token-endpoint id_tokens over TLS).
String fakeJwt(Map<String, Object?> claims) =>
    '${b64url(utf8.encode('{"alg":"none"}'))}.'
    '${b64url(utf8.encode(jsonEncode(claims)))}.sig';

/// Scripts a GitHub that issues and rotates tokens. Each rotation bumps a
/// counter so tests can see whether upstream was called.
final class FakeGitHub {
  FakeGitHub(this.upstream, {this.userId = 1001, this.login = 'octo'}) {
    upstream
      ..on('POST', 'https://github.com/login/oauth/access_token', _token)
      ..on('GET', 'https://api.github.com/user', (call) {
        if (!_live(call)) {
          return UpstreamResponse.json(401, {'message': 'Bad credentials'});
        }
        return UpstreamResponse.json(200, {
          'id': userId,
          'login': login,
          'type': 'User',
        });
      });
  }

  final FakeUpstream upstream;
  final int userId;
  final String login;
  int issued = 0;
  final Set<String> liveAccess = {};
  final Set<String> liveRefresh = {};

  /// Client secrets GitHub accepts right now.
  Set<String> acceptedSecrets = {'gh-secret-2', 'gh-secret-1'};

  /// When set, the token endpoint answers this status instead.
  int? failStatus;

  /// `expires_in` for tokens issued from an authorization code (refreshes
  /// always issue 8 hours).
  int codeExpiresIn = 28800;

  bool _live(RecordedCall call) {
    final auth = call.request.headers['authorization'] ?? '';
    return liveAccess.contains(auth.replaceFirst('Bearer ', ''));
  }

  UpstreamResponse _token(RecordedCall call) {
    final status = failStatus;
    if (status != null) {
      return UpstreamResponse.json(status, {'message': 'down'});
    }
    final form = call.form;
    if (!acceptedSecrets.contains(form['client_secret'])) {
      return UpstreamResponse.json(200, {
        'error': 'incorrect_client_credentials',
        'error_description': 'echo-me-not',
      });
    }
    if (form['grant_type'] == 'refresh_token') {
      if (!liveRefresh.remove(form['refresh_token'])) {
        return UpstreamResponse.json(200, {'error': 'bad_refresh_token'});
      }
    } else if (form['code'] != 'gh-code') {
      return UpstreamResponse.json(200, {'error': 'bad_verification_code'});
    }
    issued++;
    final access = 'ghu_access$issued';
    final refresh = 'ghr_refresh$issued';
    liveAccess.add(access);
    liveRefresh.add(refresh);
    return UpstreamResponse.json(200, {
      'access_token': access,
      'expires_in': form['grant_type'] == 'refresh_token'
          ? 28800
          : codeExpiresIn,
      'refresh_token': refresh,
      'refresh_token_expires_in': 15897600,
      'token_type': 'bearer',
      'scope': '',
    });
  }
}

/// The parsed query of an authorize URL.
Map<String, String> queryOf(String url) => Uri.parse(url).queryParameters;

/// Runs start → callback → done for [lane] and returns the claim inputs.
Future<({String loginId, String confirmCode, PkcePair pkce, TestResponse done})>
browserFlow(
  Harness harness,
  ConnectInstallIdentity identity,
  ConnectOAuthLane lane, {
  String workspaceId = 'ws1',
  String code = 'gh-code',
  String? callbackSegment,
}) async {
  final pkce = PkcePair.generate();
  final start = await harness.call(
    identity,
    'POST',
    '/v1/oauth/${lane.wire}/start',
    body: OAuthStartRequest(
      workspaceId: workspaceId,
      codeChallenge: pkce.challenge,
    ).toJson(),
  );
  if (start.status != 200) {
    throw StateError('start failed: ${start.status} ${start.body}');
  }
  final started = OAuthStartResponse.fromJson(start.json);
  final state = started.authorizeUrl.queryParameters['state']!;
  final segment = callbackSegment ?? lane.firstCallbackSegment;
  final callback = await harness.browser(
    '/oauth/$segment/callback?code=$code&state=$state',
  );
  if (callback.status != 303) {
    throw StateError('callback failed: ${callback.status}');
  }
  final cookie = cookieFrom(callback)!;
  final done = await harness.browser(
    '/oauth/${lane.wire}/done',
    cookie: cookie,
  );
  return (
    loginId: started.loginId,
    confirmCode: confirmCodeFrom(done.body)!,
    pkce: pkce,
    done: done,
  );
}

/// Signs in to GitHub end to end and returns the grant.
Future<SealedGrant> signInGitHub(
  Harness harness,
  ConnectInstallIdentity identity, {
  String workspaceId = 'ws1',
}) async {
  final flow = await browserFlow(
    harness,
    identity,
    ConnectOAuthLane.github,
    workspaceId: workspaceId,
  );
  final claim = await harness.call(
    identity,
    'POST',
    '/v1/oauth/github/claim',
    body: OAuthClaimRequest(
      loginId: flow.loginId,
      confirmCode: flow.confirmCode,
      codeVerifier: flow.pkce.verifier,
      workspaceId: workspaceId,
    ).toJson(),
  );
  if (claim.status != 200) {
    throw StateError('claim failed: ${claim.status} ${claim.body}');
  }
  return SealedGrant.fromJson(claim.json);
}
