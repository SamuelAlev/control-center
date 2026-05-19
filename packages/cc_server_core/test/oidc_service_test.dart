import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/identity/oidc_service.dart';
import 'package:cc_server_core/src/identity/sso_provisioner.dart';
import 'package:test/test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake dart:io HttpClient stack. The OIDC service issues exactly two kinds of
// request: a GET to the discovery doc and a POST to the token endpoint. The
// fake routes by URI path and returns a scripted [HttpClientResponse]; every
// other [HttpClient] member routes through [noSuchMethod].
// ─────────────────────────────────────────────────────────────────────────────

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this._routes);

  /// Maps a path substring (e.g. `.well-known/openid-configuration`) to a
  /// [_FakeResponse] producer. The first matching route wins.
  final Map<bool Function(Uri uri), _FakeResponse Function(Uri uri)> _routes;

  /// Every request body passed to [HttpClientRequest.write], in call order.
  final List<String> requestBodies = [];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeRequest(_resolve(url), requestBodies);

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _FakeRequest(_resolve(url), requestBodies);

  _FakeResponse _resolve(Uri url) {
    for (final entry in _routes.entries) {
      if (entry.key(url)) {
        return entry.value(url);
      }
    }
    return _FakeResponse(statusCode: 404, body: '');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this._response, this._bodies);

  final _FakeResponse _response;
  final List<String> _bodies;

  @override
  HttpHeaders headers = _FakeHeaders();

  @override
  bool followRedirects = true;

  @override
  void write(Object? obj) {
    _bodies.add('$obj');
  }

  @override
  Future<HttpClientResponse> close() async => _response;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeResponse implements HttpClientResponse {
  _FakeResponse({required this.statusCode, required this.body})
    : _bytes = Stream.value(utf8.encode(body));

  @override
  final int statusCode;

  final String body;

  final Stream<List<int>> _bytes;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _bytes.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      streamTransformer.bind(_bytes);

  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>> sink)? onTimeout,
  }) =>
      _bytes.timeout(timeLimit, onTimeout: onTimeout);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeHeaders implements HttpHeaders {
  @override
  ContentType? contentType = ContentType.text;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

_FakeResponse _discoveryOk(Uri _) => _FakeResponse(
  statusCode: 200,
  body: jsonEncode({
    'authorization_endpoint': 'https://idp.test/authorize',
    'token_endpoint': 'https://idp.test/token',
  }),
);

_FakeResponse _discoveryBroken(Uri _) =>
    _FakeResponse(statusCode: 200, body: jsonEncode({'nope': true}));

_FakeResponse _discovery500(Uri _) =>
    _FakeResponse(statusCode: 500, body: 'oops');

_FakeResponse _discoveryIncomplete(Uri _) => _FakeResponse(
  statusCode: 200,
  body: jsonEncode({'issuer': 'https://idp.test'}),
);

/// Builds a token-endpoint response whose `id_token` carries [claims].
_FakeResponse _tokenWithClaims(Map<String, Object?> claims) => _FakeResponse(
  statusCode: 200,
  body: jsonEncode({'id_token': _jwt(claims)}),
);

_FakeResponse _tokenMissingIdToken(Uri _) =>
    _FakeResponse(statusCode: 200, body: jsonEncode({'access_token': 'x'}));

_FakeResponse _tokenError(Uri _) =>
    _FakeResponse(statusCode: 400, body: jsonEncode({'error': 'bad_code'}));

_FakeResponse _tokenNonMap(Uri _) =>
    _FakeResponse(statusCode: 200, body: '[1, 2, 3]');

/// Encodes [claims] as an unsigned JWT (header.payload.). The signature is a
/// fixed string — the service does not verify the signature (it trusts the
/// issuer's TLS-protected token endpoint), so any three base64url segments
/// suffice.
String _jwt(Map<String, Object?> claims) {
  final header = base64UrlEncode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64UrlEncode(utf8.encode(jsonEncode(claims)));
  return '${header.replaceAll('=', '')}.${payload.replaceAll('=', '')}.sig';
}

/// Valid id_token claims for the in-flight login: the issuer/client the
/// service is configured with, a subject, a far-future expiry (the service
/// clock is pinned at 2026-01-15) and the nonce `beginLogin` embedded in
/// [beginUrl]. Read at token-request time (inside the fake handler), so the
/// closure must capture a `beginUrl` variable that has been assigned by then
/// — declare it with `var` before `_buildService`.
Map<String, Object?> _claimsFor(
  Uri beginUrl, [
  Map<String, Object?>? extra,
]) => {
  'iss': 'https://idp.test',
  'aud': 'client-1',
  'sub': 'subject-1',
  'exp': DateTime.utc(2030, 1, 1).millisecondsSinceEpoch ~/ 1000,
  'nonce': beginUrl.queryParameters['nonce'],
  ...?extra,
};

// ─────────────────────────────────────────────────────────────────────────────
// Fake repositories.
// ─────────────────────────────────────────────────────────────────────────────

class _FakeUserRepository implements UserRepository {
  final Map<String, User> byId = {};
  final Map<String, User> byHandle = {};
  final Map<String, User> byEmail = {};

  @override
  Future<User?> getById(String id) async => byId[id];

  @override
  Future<User?> getByHandle(String handle) async => byHandle[handle];

  @override
  Future<User?> getByEmail(String email) async => byEmail[email];

  @override
  Future<User?> getBySsoSubject(String issuer, String subject) async {
    for (final user in byId.values) {
      if (user.ssoIssuer == issuer && user.ssoSubject == subject) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(User user) async {
    byId[user.id] = user;
    byHandle[user.handle] = user;
    if (user.email != null) {
      byEmail[user.email!] = user;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  List<Workspace> workspaces = const [];

  @override
  Stream<List<Workspace>> watchAll() => Stream.value(workspaces);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeMembershipRepository implements WorkspaceMembershipRepository {
  final List<WorkspaceMember> members = [];

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    for (final m in members) {
      if (m.workspaceId == workspaceId && m.userId == userId) {
        return m;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(WorkspaceMember member) async {
    members.add(member);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

DateTime _fixedNow() => DateTime.utc(2026, 1, 15, 12);

OidcService _buildService({
  required _FakeHttpClient http,
  required _FakeUserRepository users,
  required _FakeWorkspaceRepository workspaces,
  required _FakeMembershipRepository members,
  String issuer = 'https://idp.test',
  String clientSecret = '',
  WorkspaceRole defaultRole = WorkspaceRole.member,
  Map<String, WorkspaceRole> groupRoleMap = const {},
  SsoAutoMemberMode autoMemberMode = SsoAutoMemberMode.all,
  bool allowJit = true,
  DateTime Function()? now,
}) {
  return OidcService(
    config: OidcConfig(
      issuer: issuer,
      clientId: 'client-1',
      clientSecret: clientSecret,
      defaultRole: defaultRole,
      groupRoleMap: groupRoleMap,
      groupsClaim: 'groups',
      autoMemberMode: autoMemberMode,
      allowJit: allowJit,
    ),
    users: users,
    members: members,
    workspaces: workspaces,
    mintDevice: (userId, label) async =>
        (deviceId: 'device-$userId', psk: 'psk-$userId'),
    httpClient: http,
    now: now ?? _fixedNow,
  );
}

void main() {
  group('OidcService.testDiscovery', () {
    test('returns the issuer endpoints for an arbitrary issuer', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      final endpoints = await service.testDiscovery('https://other-idp.test');
      expect(endpoints.authorizationEndpoint, 'https://idp.test/authorize');
      expect(endpoints.tokenEndpoint, 'https://idp.test/token');
    });

    test('throws a plain reason when the issuer is unreachable', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discovery500,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      await expectLater(
        service.testDiscovery('https://down.test'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws when the document lacks endpoints', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryIncomplete,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      await expectLater(
        service.testDiscovery('https://idp.test'),
        throwsA(isA<AuthException>()),
      );
    });
  });


  group('OidcService.beginLogin', () {
    test('throws when SSO is not configured', () async {
      final service = OidcService(
        config: const OidcConfig(
          issuer: '',
          clientId: '',
          defaultRole: WorkspaceRole.member,
          groupRoleMap: {},
          groupsClaim: 'groups',
        ),
        users: _FakeUserRepository(),
        members: _FakeMembershipRepository(),
        workspaces: _FakeWorkspaceRepository(),
        mintDevice: (_, _) async => (deviceId: 'd', psk: 'p'),
      );
      await expectLater(
        service.beginLogin(redirectUri: Uri.parse('https://app/cb')),
        throwsA(isA<AuthException>()),
      );
    });

    test('builds the authorization URL with PKCE challenge + state', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      final url = await service.beginLogin(
        redirectUri: Uri.parse('https://app/oidc/callback'),
      );
      expect(url.toString(), startsWith('https://idp.test/authorize'));
      expect(url.queryParameters['client_id'], 'client-1');
      expect(url.queryParameters['response_type'], 'code');
      expect(url.queryParameters['redirect_uri'], 'https://app/oidc/callback');
      expect(url.queryParameters['scope'], 'openid profile email');
      expect(url.queryParameters['code_challenge_method'], 'S256');
      expect(url.queryParameters['code_challenge']!.length, greaterThan(0));
      expect(url.queryParameters['state']!.isNotEmpty, isTrue);
    });

    test('discovery failure surfaces an AuthException', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discovery500,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      await expectLater(
        service.beginLogin(redirectUri: Uri.parse('https://app/cb')),
        throwsA(isA<AuthException>()),
      );
    });

    test('refuses a plaintext (non-loopback) issuer before any HTTP', () async {
      // TLS to the issuer is the ONLY claim authentication — an http issuer
      // would let any on-path attacker forge "verified" identities.
      final http = _FakeHttpClient({
        (u) => u.path.contains('.well-known'): _discoveryOk,
      });
      final service = _buildService(
        http: http,
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
        issuer: 'http://idp.test',
      );
      await expectLater(
        service.beginLogin(redirectUri: Uri.parse('https://app/cb')),
        throwsA(isA<AuthException>()),
      );
      expect(http.requestBodies, isEmpty); // No request ever went out.
    });

    test('accepts a loopback http issuer (local development)', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
        issuer: 'http://localhost:8080',
      );
      final url = await service.beginLogin(
        redirectUri: Uri.parse('http://localhost:8080/cb'),
      );
      expect(url.toString(), startsWith('https://idp.test/authorize'));
    });

    test('testDiscovery refuses a plaintext issuer', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      await expectLater(
        service.testDiscovery('http://idp.test'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('OidcService.beginLogin', () {
    test('prefixes the state for the new-tab (popup) flow', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      final sameTab = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      final newTab = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'web-popup',
      );
      final desktop = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'desktop',
      );
      expect(sameTab.queryParameters['state'], isNot(startsWith('p.')));
      expect(sameTab.queryParameters['state'], isNot(startsWith('d.')));
      expect(newTab.queryParameters['state'], startsWith('p.'));
      expect(desktop.queryParameters['state'], startsWith('d.'));
    });
  });

  group('OidcService.handleCallback', () {
    test('round-trips the connect tab origin for the popup flow', () async {
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims(_claimsFor(beginUrl)),
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'web-popup',
        clientOrigin: 'https://app.example.com',
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.clientOrigin, 'https://app.example.com');
    });

    test('drops the declared client origin on non-popup flows', () async {
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims(_claimsFor(beginUrl)),
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'desktop',
        clientOrigin: 'https://app.example.com',
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.clientOrigin, isNull);
    });

    test(
      'provisions a brand-new user, grants memberships and mints a device',
      () async {
        final users = _FakeUserRepository();
        final workspaces = _FakeWorkspaceRepository()
          ..workspaces = [
            Workspace(
              id: 'ws-1',
              name: 'Acme',
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          ];
        final members = _FakeMembershipRepository();
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'email': 'ada@example.com',
                'name': 'Ada Lovelace',
                'preferred_username': 'ada',
                'groups': ['platform-leads'],
              }),
            ),
          }),
          users: users,
          workspaces: workspaces,
          members: members,
          groupRoleMap: const {'platform-leads': WorkspaceRole.admin},
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/oidc/callback'),
        );

        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {
              ...beginUrl.queryParameters,
              'code': 'authcode-1',
            },
          ),
          redirectUri: Uri.parse('https://app/oidc/callback'),
        );

        expect(result.user.email, 'ada@example.com');
        expect(result.user.handle, 'ada');
        expect(result.user.displayName, 'Ada Lovelace');
        expect(result.deviceId, 'device-${result.user.id}');
        expect(result.psk, 'psk-${result.user.id}');
        // The mapped group role was granted.
        expect(members.members.single.role, WorkspaceRole.admin);
        expect(members.members.single.workspaceId, 'ws-1');
        expect(members.members.single.userId, result.user.id);
      },
    );

    test(
      'matches an existing user by email and never downgrades a membership',
      () async {
        final users = _FakeUserRepository();
        final existing = User(
          id: 'u-1',
          handle: 'ada',
          displayName: 'Ada',
          email: 'ada@example.com',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[existing.id] = existing;
        users.byEmail[existing.email!] = existing;
        users.byHandle[existing.handle] = existing;
        final workspaces = _FakeWorkspaceRepository()
          ..workspaces = [
            Workspace(
              id: 'ws-1',
              name: 'Acme',
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          ];
        final members = _FakeMembershipRepository()
          ..members.add(
            WorkspaceMember(
              id: 'm-0',
              workspaceId: 'ws-1',
              userId: 'u-1',
              role: WorkspaceRole.owner, // higher than the default member role.
              joinedAt: DateTime.utc(2025, 1, 1),
            ),
          );

        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'email': 'ada@example.com',
                'email_verified': true,
              }),
            ),
          }),
          users: users,
          workspaces: workspaces,
          members: members,
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/oidc/callback'),
        );

        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {
              ...beginUrl.queryParameters,
              'code': 'authcode-2',
            },
          ),
          redirectUri: Uri.parse('https://app/oidc/callback'),
        );

        expect(result.user.id, 'u-1');
        // The pre-existing owner membership is preserved (no second row added).
        expect(members.members, hasLength(1));
        expect(members.members.single.role, WorkspaceRole.owner);
      },
    );

    test(
      'auto-member none provisions the user but grants no memberships',
      () async {
        final users = _FakeUserRepository();
        final workspaces = _FakeWorkspaceRepository()
          ..workspaces = [
            Workspace(
              id: 'ws-1',
              name: 'Acme',
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          ];
        final members = _FakeMembershipRepository();
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {'email': 'grace@example.com', 'name': 'Grace'}),
            ),
          }),
          users: users,
          workspaces: workspaces,
          members: members,
          autoMemberMode: SsoAutoMemberMode.none,
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/oidc/callback'),
        );
        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {
              ...beginUrl.queryParameters,
              'code': 'authcode-3',
            },
          ),
          redirectUri: Uri.parse('https://app/oidc/callback'),
        );
        expect(result.user.email, 'grace@example.com');
        expect(members.members, isEmpty);
      },
    );

    test('skips deleted workspaces when granting memberships', () async {
      final workspaces = _FakeWorkspaceRepository()
        ..workspaces = [
          Workspace(
            id: 'ws-live',
            name: 'Live',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          Workspace(
            id: 'ws-dead',
            name: 'Dead',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
            deletedAt: DateTime.utc(2026, 1, 5),
          ),
        ];
      final members = _FakeMembershipRepository();
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) => _tokenWithClaims(
            _claimsFor(beginUrl, {'email': 'x@example.com', 'name': 'X'}),
          ),
        }),
        users: _FakeUserRepository(),
        workspaces: workspaces,
        members: members,
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/oidc/callback'),
      );
      await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'authcode-4'},
        ),
        redirectUri: Uri.parse('https://app/oidc/callback'),
      );
      expect(members.members.single.workspaceId, 'ws-live');
    });

    test('throws when the state is unknown or the code is missing', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      // An unknown state with no prior beginLogin.
      await expectLater(
        service.handleCallback(
          requestUri: Uri.parse('https://app/cb?state=ghost&code=c'),
          redirectUri: Uri.parse('https://app/cb'),
        ),
        throwsA(isA<AuthException>()),
      );

      final beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      // Missing code.
      await expectLater(
        service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws when the pending login has expired', () async {
      var clock = DateTime.utc(2026, 1, 1, 12);
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
        now: () => clock,
      );
      final beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      // Advance past the 10-minute pending-window.
      clock = clock.add(const Duration(minutes: 11));
      await expectLater(
        service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws when discovery returns a malformed doc', () async {
      // `_discover` runs on the first call; with a doc missing the endpoints
      // it fails fast during beginLogin (discovery is then cached per service).
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryBroken,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      await expectLater(
        service.beginLogin(redirectUri: Uri.parse('https://app/cb')),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws when the token endpoint rejects the code', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): _tokenError,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      final beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      await expectLater(
        service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('the token error surfaces the HTTP status and the IdP body', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): _tokenError,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      final beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      await expectLater(
        service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        ),
        throwsA(
          isA<AuthException>()
              .having((e) => e.message, 'message', contains('HTTP 400'))
              .having((e) => e.message, 'message', contains('bad_code')),
        ),
      );
    });

    test(
      'a confidential client authenticates with client_secret_post',
      () async {
        var beginUrl = Uri.parse('https://app/cb');
        final http = _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims(_claimsFor(beginUrl)),
        });
        final service = _buildService(
          http: http,
          users: _FakeUserRepository(),
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
          clientSecret: 'topsecret',
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        );
        expect(http.requestBodies.last, contains('client_secret=topsecret'));
      },
    );

    test('a public client sends no client_secret', () async {
      var beginUrl = Uri.parse('https://app/cb');
      final http = _FakeHttpClient({
        (u) => u.path.contains('.well-known'): _discoveryOk,
        (u) => u.path.contains('token'): (_) =>
            _tokenWithClaims(_claimsFor(beginUrl)),
      });
      final service = _buildService(
        http: http,
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(http.requestBodies.last, isNot(contains('client_secret')));
    });

    test('throws when the token response carries no id_token', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): _tokenMissingIdToken,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      final beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      await expectLater(
        service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws when the token response is not a JSON object', () async {
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): _tokenNonMap,
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      final beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      await expectLater(
        service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('JIT provisioning edge cases', () {
    test(
      'an unverified email-less login never matches an existing account by handle',
      () async {
        // Regression: the handle-match used to run for ANY email-less login,
        // so a co-resident IdP user asserting a colleague's
        // preferred_username matched, got pinned and took the account over.
        // Matching by self-asserted username now requires a vouched claim
        // set (SAML's signed assertions; never an unverified OIDC one).
        final users = _FakeUserRepository();
        final existing = User(
          id: 'u-2',
          handle: 'bob',
          displayName: 'Bob',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[existing.id] = existing;
        users.byHandle[existing.handle] = existing;
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {'preferred_username': 'bob'}),
            ),
          }),
          users: users,
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        );
        // A brand-new account (handle deduped past 'bob') — Bob's was NOT
        // taken over and the attacker's subject was pinned on the NEW
        // account only.
        expect(result.user.id, isNot('u-2'));
        expect(result.user.handle, isNot('bob'));
        expect(users.byId['u-2']!.ssoSubject, isNull);
      },
    );

    test(
      'an unverified email seeds a new account WITHOUT shadowing the owner',
      () async {
        // Regression: seeding a duplicate row with a colleague's (unverified)
        // email made their later VERIFIED login ambiguous — getByEmail could
        // not resolve two rows and denied them service. The address is now
        // dropped at seed time when it is already owned.
        final users = _FakeUserRepository();
        final victim = User(
          id: 'u-v',
          handle: 'victim',
          displayName: 'Victim',
          email: 'victim@example.com',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[victim.id] = victim;
        users.byEmail[victim.email!] = victim;
        users.byHandle[victim.handle] = victim;
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'email': 'victim@example.com',
                'preferred_username': 'attacker',
                // No email_verified claim — unverified.
              }),
            ),
          }),
          users: users,
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        );
        // New attacker account, but with NO email — the victim's row stays
        // the only owner of the address, so their verified login still
        // resolves.
        expect(result.user.id, isNot('u-v'));
        expect(result.user.email, isNull);
      },
    );

    test('sanitizes the handle and dedupes collisions', () async {
      final users = _FakeUserRepository();
      users.byHandle['bob'] = User(
        id: 'u-x',
        handle: 'bob',
        displayName: 'Bob',
        createdAt: DateTime.utc(2025, 1, 1),
      );
      users.byHandle['bob2'] = User(
        id: 'u-y',
        handle: 'bob2',
        displayName: 'Bob 2',
        createdAt: DateTime.utc(2025, 1, 1),
      );
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'preferred_username': 'Bob!! The Builder',
                'name': 'Bob The Builder',
              }),
            ),
        }),
        users: users,
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      // Sanitized to 'bob-the-builder' (the collision suffix path uses the
      // already-sanitized base, so 'bob' and 'bob2' are skipped past).
      expect(result.user.handle, 'bob-the-builder');
      expect(result.user.displayName, 'Bob The Builder');
    });

    test('falls back to sso-user when the handle sanitizes to empty', () async {
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {'preferred_username': '!!!@@@'}),
            ),
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.user.handle, 'sso-user');
    });

    test('uses the configured default role when no group maps', () async {
      final workspaces = _FakeWorkspaceRepository()
        ..workspaces = [
          Workspace(
            id: 'ws-1',
            name: 'Acme',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ];
      final members = _FakeMembershipRepository();
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) => _tokenWithClaims(
            _claimsFor(beginUrl, {'email': 'n@example.com', 'name': 'N'}),
          ),
        }),
        users: _FakeUserRepository(),
        workspaces: workspaces,
        members: members,
        defaultRole: WorkspaceRole.viewer,
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(members.members.single.role, WorkspaceRole.viewer);
    });

    test('picks the highest-ranked mapped group', () async {
      final workspaces = _FakeWorkspaceRepository()
        ..workspaces = [
          Workspace(
            id: 'ws-1',
            name: 'Acme',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ];
      final members = _FakeMembershipRepository();
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) => _tokenWithClaims(
            _claimsFor(beginUrl, {
              'email': 'm@example.com',
              'name': 'M',
              'groups': ['viewers', 'platform-leads'],
            }),
          ),
        }),
        users: _FakeUserRepository(),
        workspaces: workspaces,
        members: members,
        groupRoleMap: const {
          'viewers': WorkspaceRole.viewer,
          'platform-leads': WorkspaceRole.admin,
        },
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(members.members.single.role, WorkspaceRole.admin);
    });
  });

  group('OIDC subject pinning', () {
    test('pins the subject (sub) and issuer onto a new account', () async {
      final users = _FakeUserRepository();
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) => _tokenWithClaims(
            _claimsFor(beginUrl, {
              'sub': 'subject-1',
              'email': 'ada@example.com',
              'name': 'Ada',
            }),
          ),
        }),
        users: users,
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.user.ssoSubject, 'subject-1');
      expect(result.user.ssoIssuer, 'https://idp.test');
    });

    test(
      'refuses a login whose email matches an account pinned to another subject',
      () async {
        final users = _FakeUserRepository();
        final existing = User(
          id: 'u-1',
          handle: 'ada',
          displayName: 'Ada',
          email: 'ada@example.com',
          ssoSubject: 'real-subject',
          ssoIssuer: 'https://idp.test',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[existing.id] = existing;
        users.byEmail[existing.email!] = existing;
        users.byHandle[existing.handle] = existing;
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'sub': 'attacker-subject',
                'email': 'ada@example.com',
                'email_verified': true,
              }),
            ),
          }),
          users: users,
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        await expectLater(
          service.handleCallback(
            requestUri: beginUrl.replace(
              queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
            ),
            redirectUri: Uri.parse('https://app/cb'),
          ),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test(
      'an explicitly unverified email never matches an existing account',
      () async {
        final users = _FakeUserRepository();
        final invited = User(
          id: 'u-inv',
          handle: 'victim',
          displayName: 'Victim',
          email: 'victim@example.com',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[invited.id] = invited;
        users.byEmail[invited.email!] = invited;
        users.byHandle[invited.handle] = invited;
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'sub': 'attacker',
                'email': 'victim@example.com',
                'email_verified': false,
                'preferred_username': 'attacker',
              }),
            ),
          }),
          users: users,
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        );
        // A brand-new account — the invited victim's was NOT taken over.
        expect(result.user.id, isNot('u-inv'));
      },
    );

    test(
      'a MISSING email_verified claim is not a vouch — no email match',
      () async {
        // Regression: the exact takeover an absent flag used to allow. A
        // self-service IdP that omits `email_verified` while letting users
        // pick any address must not get email-matching by default.
        final users = _FakeUserRepository();
        final invited = User(
          id: 'u-inv',
          handle: 'victim',
          displayName: 'Victim',
          email: 'victim@example.com',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[invited.id] = invited;
        users.byEmail[invited.email!] = invited;
        users.byHandle[invited.handle] = invited;
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'sub': 'attacker',
                'email': 'victim@example.com',
                'preferred_username': 'attacker',
                // NOTE: no email_verified claim at all.
              }),
            ),
          }),
          users: users,
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        );
        // A brand-new account — the invited victim's was NOT taken over.
        expect(result.user.id, isNot('u-inv'));
      },
    );
  });

  group('id_token claim validation', () {
    late Uri lastBeginUrl;

    Future<OidcService> serviceWithClaims(
      _FakeUserRepository users,
      Map<String, Object?> Function(Uri beginUrl) claims,
    ) async {
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) => _tokenWithClaims(
            claims(beginUrl),
          ),
        }),
        users: users,
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
      );
      lastBeginUrl = beginUrl;
      return service;
    }

    Future<void> expectRejected(OidcService service) => expectLater(
      service.handleCallback(
        requestUri: lastBeginUrl.replace(
          queryParameters: {...lastBeginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      ),
      throwsA(isA<AuthException>()),
    );

    test('rejects an id_token minted by a different issuer', () async {
      final service = await serviceWithClaims(
        _FakeUserRepository(),
        (beginUrl) => _claimsFor(beginUrl, {'iss': 'https://evil.test'}),
      );
      await expectRejected(service);
    });

    test('rejects an id_token for a different audience', () async {
      final service = await serviceWithClaims(
        _FakeUserRepository(),
        (beginUrl) => _claimsFor(beginUrl, {'aud': 'other-client'}),
      );
      await expectRejected(service);
    });

    test('accepts the aud claim in list form', () async {
      final service = await serviceWithClaims(
        _FakeUserRepository(),
        (beginUrl) =>
            _claimsFor(beginUrl, {'aud': ['other-client', 'client-1']}),
      );
      final result = await service.handleCallback(
        requestUri: lastBeginUrl.replace(
          queryParameters: {...lastBeginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.user, isNotNull);
    });

    test('rejects an id_token without a subject', () async {
      final service = await serviceWithClaims(
        _FakeUserRepository(),
        (beginUrl) => _claimsFor(beginUrl, {'sub': ''}),
      );
      await expectRejected(service);
    });

    test('rejects an id_token whose nonce does not match the login', () async {
      final service = await serviceWithClaims(
        _FakeUserRepository(),
        (beginUrl) => _claimsFor(beginUrl, {'nonce': 'not-the-login-nonce'}),
      );
      await expectRejected(service);
    });

    test('rejects an expired id_token', () async {
      final service = await serviceWithClaims(
        _FakeUserRepository(),
        (beginUrl) => _claimsFor(beginUrl, {
          // 2020 — long before the pinned service clock (2026-01-15).
          'exp': DateTime.utc(2020, 1, 1).millisecondsSinceEpoch ~/ 1000,
        }),
      );
      await expectRejected(service);
    });

    test('rejects an id_token without an expiry', () async {
      final service = await serviceWithClaims(
        _FakeUserRepository(),
        (beginUrl) => _claimsFor(beginUrl, {'exp': null}),
      );
      await expectRejected(service);
    });
  });

  group('pending-login backpressure', () {
    test(
      'caps the pending map and evicts the soonest-to-expire logins',
      () async {
        // An advancing clock so eviction order (soonest expiry) is
        // deterministic: every login expires 10 min out, each a second after
        // the previous one.
        var clock = DateTime.utc(2026, 1, 1, 12);
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) =>
                _tokenWithClaims(_claimsFor(beginUrl)),
          }),
          users: _FakeUserRepository(),
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
          now: () => clock,
        );
        Uri? first;
        for (var i = 0; i < 300; i++) {
          final url = await service.beginLogin(
            redirectUri: Uri.parse('https://app/cb'),
          );
          first ??= url;
          clock = clock.add(const Duration(seconds: 1));
        }
        // The very first login (soonest to expire) was evicted by the cap;
        // its state is no longer recognized.
        await expectLater(
          service.handleCallback(
            requestUri: first!.replace(
              queryParameters: {...first.queryParameters, 'code': 'c'},
            ),
            redirectUri: Uri.parse('https://app/cb'),
          ),
          throwsA(isA<AuthException>()),
        );
        // The most recent login is still pending and completes.
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        );
        expect(result.user, isNotNull);
      },
    );
  });

  group('client origin sanitization', () {
    test('drops a client origin that is not an absolute http(s) URL', () async {
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims(_claimsFor(beginUrl)),
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'web-popup',
        clientOrigin: 'javascript:alert(1)',
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.clientOrigin, isNull);
    });

    test('stores the CANONICAL origin, never the raw input', () async {
      // The stored value becomes a postMessage targetOrigin, parsed by a
      // DIFFERENT URL parser (WHATWG) than the allow-list check (Dart Uri).
      // Canonicalizing makes both see the identical string and kills the
      // parser-differential class outright.
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims(_claimsFor(beginUrl)),
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'web-popup',
        clientOrigin: 'HTTPS://App.Example.COM:8443/some/path?x=1',
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.clientOrigin, 'https://app.example.com:8443');
    });

    test('drops a client origin carrying userinfo', () async {
      // `scheme://user@host` is not an origin and userinfo is the classic
      // carrier of parser-differential payloads.
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims(_claimsFor(beginUrl)),
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'web-popup',
        clientOrigin: 'https://user@app.example.com',
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.clientOrigin, isNull);
    });

    test('drops an oversized client origin', () async {
      var beginUrl = Uri.parse('https://app/cb');
      final service = _buildService(
        http: _FakeHttpClient({
          (u) => u.path.contains('.well-known'): _discoveryOk,
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims(_claimsFor(beginUrl)),
        }),
        users: _FakeUserRepository(),
        workspaces: _FakeWorkspaceRepository(),
        members: _FakeMembershipRepository(),
      );
      beginUrl = await service.beginLogin(
        redirectUri: Uri.parse('https://app/cb'),
        relay: 'web-popup',
        clientOrigin: 'https://${'a' * 5000}.example.com',
      );
      final result = await service.handleCallback(
        requestUri: beginUrl.replace(
          queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
        ),
        redirectUri: Uri.parse('https://app/cb'),
      );
      expect(result.clientOrigin, isNull);
    });
  });

  group('JIT disablement (allowJit)', () {
    test(
      'refuses to provision an unknown identity when JIT is disabled',
      () async {
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {'email': 'new@example.com'}),
            ),
          }),
          users: _FakeUserRepository(),
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
          allowJit: false,
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        await expectLater(
          service.handleCallback(
            requestUri: beginUrl.replace(
              queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
            ),
            redirectUri: Uri.parse('https://app/cb'),
          ),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test(
      'a pre-provisioned (pinned) account still logs in when JIT is disabled',
      () async {
        final users = _FakeUserRepository();
        final existing = User(
          id: 'u-1',
          handle: 'ada',
          displayName: 'Ada',
          email: 'ada@example.com',
          ssoSubject: 'subject-1',
          ssoIssuer: 'https://idp.test',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[existing.id] = existing;
        users.byEmail[existing.email!] = existing;
        users.byHandle[existing.handle] = existing;
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {'sub': 'subject-1'}),
            ),
          }),
          users: users,
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
          allowJit: false,
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        final result = await service.handleCallback(
          requestUri: beginUrl.replace(
            queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
          ),
          redirectUri: Uri.parse('https://app/cb'),
        );
        expect(result.user.id, 'u-1');
      },
    );
  });

  group('cross-issuer subject pinning', () {
    test(
      'refuses a login whose subject collides with another issuer\'s pin',
      () async {
        // Subject ids are only unique PER issuer: a SAML NameID / SCIM
        // externalId equal to this OIDC sub must not cross-link accounts,
        // even when the (verified) email matches.
        final users = _FakeUserRepository();
        final existing = User(
          id: 'u-1',
          handle: 'ada',
          displayName: 'Ada',
          email: 'ada@example.com',
          ssoSubject: 'subject-1',
          ssoIssuer: 'scim', // pinned by SCIM, not by this OIDC issuer.
          createdAt: DateTime.utc(2025, 1, 1),
        );
        users.byId[existing.id] = existing;
        users.byEmail[existing.email!] = existing;
        users.byHandle[existing.handle] = existing;
        var beginUrl = Uri.parse('https://app/cb');
        final service = _buildService(
          http: _FakeHttpClient({
            (u) => u.path.contains('.well-known'): _discoveryOk,
            (u) => u.path.contains('token'): (_) => _tokenWithClaims(
              _claimsFor(beginUrl, {
                'sub': 'subject-1',
                'email': 'ada@example.com',
                'email_verified': true,
              }),
            ),
          }),
          users: users,
          workspaces: _FakeWorkspaceRepository(),
          members: _FakeMembershipRepository(),
        );
        beginUrl = await service.beginLogin(
          redirectUri: Uri.parse('https://app/cb'),
        );
        await expectLater(
          service.handleCallback(
            requestUri: beginUrl.replace(
              queryParameters: {...beginUrl.queryParameters, 'code': 'c'},
            ),
            redirectUri: Uri.parse('https://app/cb'),
          ),
          throwsA(isA<AuthException>()),
        );
      },
    );
  });
}
