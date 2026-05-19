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

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeRequest(_resolve(url));

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _FakeRequest(_resolve(url));

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
  _FakeRequest(this._response);

  final _FakeResponse _response;

  @override
  HttpHeaders headers = _FakeHeaders();

  @override
  void write(Object? obj) {}

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
  Map<String, String> env = const {},
  DateTime Function()? now,
}) {
  return OidcService(
    config: OidcConfig.fromEnvironment({
      'CC_OIDC_ISSUER': 'https://idp.test',
      'CC_OIDC_CLIENT_ID': 'client-1',
      ...env,
    }),
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
  group('OidcConfig.fromEnvironment', () {
    test('is disabled with no issuer or client id', () {
      expect(OidcConfig.fromEnvironment(const {}).enabled, isFalse);
      // A lone issuer without a client id is still disabled.
      expect(
        OidcConfig.fromEnvironment(const {
          'CC_OIDC_ISSUER': 'https://idp.test',
        }).enabled,
        isFalse,
      );
    });

    test('parses the default role, groups claim, and auto-member', () {
      final config = OidcConfig.fromEnvironment(const {
        'CC_OIDC_ISSUER': 'https://idp.test',
        'CC_OIDC_CLIENT_ID': 'c',
      });
      expect(config.enabled, isTrue);
      expect(config.defaultRole, WorkspaceRole.member);
      expect(config.groupsClaim, 'groups');
      expect(config.autoMemberMode, OidcAutoMemberMode.all);
      expect(config.groupRoleMap, isEmpty);
    });

    test('honours an explicit default role and groups claim', () {
      final config = OidcConfig.fromEnvironment(const {
        'CC_OIDC_ISSUER': 'https://idp.test',
        'CC_OIDC_CLIENT_ID': 'c',
        'CC_OIDC_DEFAULT_ROLE': 'admin',
        'CC_OIDC_GROUPS_CLAIM': 'teams',
        'CC_OIDC_AUTO_MEMBER': 'none',
      });
      expect(config.defaultRole, WorkspaceRole.admin);
      expect(config.groupsClaim, 'teams');
      expect(config.autoMemberMode, OidcAutoMemberMode.none);
    });

    test('parses a group-to-role map and excludes owner mappings', () {
      final config = OidcConfig.fromEnvironment({
        'CC_OIDC_ISSUER': 'https://idp.test',
        'CC_OIDC_CLIENT_ID': 'c',
        'CC_OIDC_GROUP_ROLE_MAP': jsonEncode({
          'platform-leads': 'admin',
          'viewers': 'viewer',
          'owners': 'owner', // owner is never auto-granted.
          'junk': 'not-a-role', // ignored.
        }),
      });
      expect(config.groupRoleMap['platform-leads'], WorkspaceRole.admin);
      expect(config.groupRoleMap['viewers'], WorkspaceRole.viewer);
      expect(config.groupRoleMap.containsKey('owners'), isFalse);
      expect(config.groupRoleMap.containsKey('junk'), isFalse);
    });

    test('a malformed group map disables mapping without crashing', () {
      final config = OidcConfig.fromEnvironment(const {
        'CC_OIDC_ISSUER': 'https://idp.test',
        'CC_OIDC_CLIENT_ID': 'c',
        'CC_OIDC_GROUP_ROLE_MAP': 'not-json',
      });
      expect(config.groupRoleMap, isEmpty);
    });

    test('a non-object group map is ignored', () {
      final config = OidcConfig.fromEnvironment(const {
        'CC_OIDC_ISSUER': 'https://idp.test',
        'CC_OIDC_CLIENT_ID': 'c',
        'CC_OIDC_GROUP_ROLE_MAP': '[1, 2]',
      });
      expect(config.groupRoleMap, isEmpty);
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
  });

  group('OidcService.handleCallback', () {
    test(
      'provisions a brand-new user, grants memberships, and mints a device',
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
            (u) => u.path.contains('token'): (_) => _tokenWithClaims({
              'email': 'ada@example.com',
              'name': 'Ada Lovelace',
              'preferred_username': 'ada',
              'groups': ['platform-leads'],
            }),
          }),
          users: users,
          workspaces: workspaces,
          members: members,
          env: {
            'CC_OIDC_GROUP_ROLE_MAP': jsonEncode({'platform-leads': 'admin'}),
          },
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
            (u) => u.path.contains('token'): (_) =>
                _tokenWithClaims({'email': 'ada@example.com'}),
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
            (u) => u.path.contains('token'): (_) => _tokenWithClaims({
              'email': 'grace@example.com',
              'name': 'Grace',
            }),
          }),
          users: users,
          workspaces: workspaces,
          members: members,
          env: {'CC_OIDC_AUTO_MEMBER': 'none'},
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
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims({'email': 'x@example.com', 'name': 'X'}),
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
      'matches an existing user by handle when no email is present',
      () async {
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
            (u) => u.path.contains('token'): (_) =>
                _tokenWithClaims({'preferred_username': 'bob'}),
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
        expect(result.user.id, 'u-2');
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
          (u) => u.path.contains('token'): (_) => _tokenWithClaims({
            'preferred_username': 'Bob!! The Builder',
            'name': 'Bob The Builder',
          }),
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
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims({'preferred_username': '!!!@@@'}),
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
          (u) => u.path.contains('token'): (_) =>
              _tokenWithClaims({'email': 'n@example.com', 'name': 'N'}),
        }),
        users: _FakeUserRepository(),
        workspaces: workspaces,
        members: members,
        env: {'CC_OIDC_DEFAULT_ROLE': 'viewer'},
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
          (u) => u.path.contains('token'): (_) => _tokenWithClaims({
            'email': 'm@example.com',
            'name': 'M',
            'groups': ['viewers', 'platform-leads'],
          }),
        }),
        users: _FakeUserRepository(),
        workspaces: workspaces,
        members: members,
        env: {
          'CC_OIDC_GROUP_ROLE_MAP': jsonEncode({
            'viewers': 'viewer',
            'platform-leads': 'admin',
          }),
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
}
