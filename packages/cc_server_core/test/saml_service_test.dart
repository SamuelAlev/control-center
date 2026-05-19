import 'dart:async';

import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_natives/cc_natives.dart'
    show SamlAuthnRequest, SamlIdpMetadata, SamlIdentity;
import 'package:cc_server_core/src/identity/saml_service.dart';
import 'package:cc_server_core/src/identity/sso_provisioner.dart';
import 'package:test/test.dart';

const _origin = 'https://cc.example.com';
const _acsUrl = 'https://cc.example.com/saml/acs';
const _idpEntityId = 'https://idp.example.com';
const _idpSsoUrl = 'https://idp.example.com/sso';

void main() {
  group('SamlConfig.fromEnvironment', () {
    test('is disabled without metadata', () {
      final config = SamlConfig.fromEnvironment(const {});
      expect(config.enabled, isFalse);
    });

    test('reads inline metadata and knobs', () {
      final config = SamlConfig.fromEnvironment(const {
        'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
        'CC_SAML_SP_ENTITY_ID': 'https://cc.example.com/saml',
        'CC_SAML_DEFAULT_ROLE': 'admin',
        'CC_SAML_GROUPS_ATTRIBUTE': 'teams',
        'CC_SAML_AUTO_MEMBER': 'none',
        'CC_SAML_ALLOW_IDP_INITIATED': 'true',
        'CC_SAML_CLOCK_SKEW_SECS': '45',
      });
      expect(config.enabled, isTrue);
      expect(config.spEntityId, 'https://cc.example.com/saml');
      expect(config.defaultRole, WorkspaceRole.admin);
      expect(config.groupsAttribute, 'teams');
      expect(config.autoMemberMode, SsoAutoMemberMode.none);
      expect(config.allowIdpInitiated, isTrue);
      expect(config.clockSkew, const Duration(seconds: 45));
    });

    test('derives entity id and ACS from the origin when unpinned', () {
      final service = _makeService(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
        }),
      );
      expect(service.spEntityIdFor(_origin), '$_origin/saml');
      expect(service.acsUrlFor(_origin), _acsUrl);
    });

    test('refuses owner as the default role (falls back to member)', () {
      // The env path seeds the connection row directly, bypassing the RPC
      // save-time validation — the invariant "SSO never mints an owner" must
      // hold here too.
      final config = SamlConfig.fromEnvironment(const {
        'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
        'CC_SAML_DEFAULT_ROLE': 'owner',
      });
      expect(config.defaultRole, WorkspaceRole.member);
    });

    test('allowJit defaults on and honors an explicit opt-out', () {
      expect(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
        }).allowJit,
        isTrue,
      );
      expect(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_ALLOW_JIT': 'false',
        }).allowJit,
        isFalse,
      );
    });
  });

  group('SamlService.testConnection', () {
    test('parses metadata and builds an AuthnRequest short of login', () async {
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: _FakeBackend(),
      );
      final result = service.testConnection(
        idpMetadataXml: '<EntityDescriptor/>',
        origin: _origin,
      );
      expect(result.entityId, _idpEntityId);
      expect(result.ssoEndpoint, _idpSsoUrl);
      expect(result.spEntityId, '$_origin/saml');
      expect(result.acsUrl, _acsUrl);
      // Stateless: the probe registers no pending login.
      expect(service, isNotNull);
    });

    test('refuses metadata without a sign-on endpoint', () async {
      final backend = _FakeBackend();
      backend.metadataOverride = const SamlIdpMetadata(entityId: 'x');
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );
      expect(
        () => service.testConnection(
          idpMetadataXml: '<EntityDescriptor/>',
          origin: _origin,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SamlService', () {
    test(
      'round-trips a solicited login: tracker, provisioning, mint',
      () async {
        final fakes = _Fakes();
        final backend = _FakeBackend();
        final service = _makeService(
          _enabledConfig(),
          fakes: fakes,
          backend: backend,
        );

        final redirect = service.beginLogin(origin: _origin, relayState: 'web');
        expect(redirect.toString(), contains('https://idp.example.com/sso'));
        expect(backend.lastRelayState, 'web');

        final result = await service.handleAcs(
          origin: _origin,
          responseXml: _responseXml(inResponseTo: backend.lastRequestId),
        );
        // The cached tracker reached the native seam.
        expect(backend.lastTrackerJson, backend.builtTrackerJson);
        // JIT provisioning + device mint.
        expect(result.user.email, 'alice@example.com');
        expect(result.user.handle, 'alice');
        expect(result.deviceId, 'device-${result.user.id}');
        expect(result.psk, 'psk-${result.user.id}');
        // autoMember all → membership in the one live workspace.
        expect(fakes.members.members.single.userId, result.user.id);
        expect(fakes.members.members.single.role, WorkspaceRole.member);
      },
    );

    test('round-trips the connect tab origin for the popup flow', () async {
      final backend = _FakeBackend();
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );

      service.beginLogin(
        origin: _origin,
        relayState: 'web-popup',
        clientOrigin: 'https://app.example.com',
      );
      final result = await service.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: backend.lastRequestId),
      );
      expect(result.clientOrigin, 'https://app.example.com');
    });

    test('stores the CANONICAL client origin, never the raw input', () async {
      final backend = _FakeBackend();
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );

      service.beginLogin(
        origin: _origin,
        relayState: 'web-popup',
        clientOrigin: 'HTTPS://App.Example.COM:8443/some/path',
      );
      final result = await service.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: backend.lastRequestId),
      );
      expect(result.clientOrigin, 'https://app.example.com:8443');
    });

    test('same-tab logins carry no client origin', () async {
      final backend = _FakeBackend();
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );

      service.beginLogin(origin: _origin);
      final result = await service.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: backend.lastRequestId),
      );
      expect(result.clientOrigin, isNull);
    });

    test('drops a client origin that is not an absolute http(s) URL', () async {
      final backend = _FakeBackend();
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );

      service.beginLogin(
        origin: _origin,
        relayState: 'web-popup',
        clientOrigin: 'javascript:alert(1)',
      );
      final result = await service.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: backend.lastRequestId),
      );
      expect(result.clientOrigin, isNull);
    });

    test('drops an oversized client origin', () async {
      final backend = _FakeBackend();
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );

      service.beginLogin(
        origin: _origin,
        relayState: 'web-popup',
        clientOrigin: 'https://${'a' * 5000}.example.com',
      );
      final result = await service.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: backend.lastRequestId),
      );
      expect(result.clientOrigin, isNull);
    });

    test('rejects a replayed assertion', () async {
      final backend = _FakeBackend();
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );
      service.beginLogin(origin: _origin);
      final xml = _responseXml(inResponseTo: backend.lastRequestId);
      await service.handleAcs(origin: _origin, responseXml: xml);
      await expectLater(
        service.handleAcs(origin: _origin, responseXml: xml),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects a replay inside the clock-skew tail', () async {
      // The native accepts an assertion until NotOnOrAfter + clockSkew, so
      // the caller-side replay cache must hold the ID for the same window.
      // An assertion 30s past its signed expiry (inside the default 90s
      // skew) replayed twice: the second attempt must be refused even
      // though the first cache entry's signed expiry has already passed.
      final backend = _FakeBackend(
        identity: _identity(
          notOnOrAfter: DateTime.now().subtract(const Duration(seconds: 30)),
        ),
      );
      final service = _makeService(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_ALLOW_IDP_INITIATED': 'true',
        }),
        fakes: _Fakes(),
        backend: backend,
      );
      final xml = _responseXml(inResponseTo: null);
      await service.handleAcs(origin: _origin, responseXml: xml);
      await expectLater(
        service.handleAcs(origin: _origin, responseXml: xml),
        throwsA(isA<Exception>()),
      );
    });

    test('refuses a response naming a request we never made', () async {
      final service = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: _FakeBackend(),
      );
      await expectLater(
        service.handleAcs(
          origin: _origin,
          responseXml: _responseXml(inResponseTo: 'forged'),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('accepts an unsolicited response only when configured', () async {
      final backend = _FakeBackend();
      final strict = _makeService(
        _enabledConfig(),
        fakes: _Fakes(),
        backend: backend,
      );
      await expectLater(
        strict.handleAcs(
          origin: _origin,
          responseXml: _responseXml(inResponseTo: null),
        ),
        throwsA(isA<Exception>()),
      );

      final permissive = _makeService(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_ALLOW_IDP_INITIATED': 'true',
        }),
        fakes: _Fakes(),
        backend: backend,
      );
      final result = await permissive.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: null),
      );
      expect(backend.lastTrackerJson, isNull);
      expect(result.user.email, 'alice@example.com');
    });

    test(
      'prefers the email attribute, falls back to email-shaped NameID',
      () async {
        final backend = _FakeBackend(
          identity: _identity(
            nameId: 'opaque-persistent-id',
            attributes: {
              'email': ['bob@example.com'],
            },
          ),
        );
        final service = _makeService(
          _enabledConfig(),
          fakes: _Fakes(),
          backend: backend,
        );
        service.beginLogin(origin: _origin);
        final result = await service.handleAcs(
          origin: _origin,
          responseXml: _responseXml(inResponseTo: backend.lastRequestId),
        );
        expect(result.user.email, 'bob@example.com');
        expect(result.user.handle, 'bob');
      },
    );

    test('autoMember none provisions the account but grants nothing', () async {
      final fakes = _Fakes();
      final backend = _FakeBackend();
      final service = _makeService(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_AUTO_MEMBER': 'none',
        }),
        fakes: fakes,
        backend: backend,
      );
      service.beginLogin(origin: _origin);
      final result = await service.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: backend.lastRequestId),
      );
      expect(result.user.email, 'alice@example.com');
      expect(fakes.members.members, isEmpty);
    });

    test('refuses unknown identities when JIT is disabled', () async {
      final backend = _FakeBackend();
      final service = _makeService(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_ALLOW_JIT': 'false',
        }),
        fakes: _Fakes(),
        backend: backend,
      );
      service.beginLogin(origin: _origin);
      await expectLater(
        service.handleAcs(
          origin: _origin,
          responseXml: _responseXml(inResponseTo: backend.lastRequestId),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'refuses a NameID colliding with another issuer\'s pinned subject',
      () async {
        // Subject ids are only unique PER issuer: a NameID equal to a
        // SCIM-pinned externalId must not cross-link accounts, even when the
        // email attribute matches.
        final fakes = _Fakes();
        final pinned = User(
          id: 'u-1',
          handle: 'alice',
          displayName: 'Alice',
          email: 'alice@example.com',
          ssoSubject: 'alice@example.com',
          ssoIssuer: 'scim',
          createdAt: DateTime.utc(2025, 1, 1),
        );
        fakes.users.byId[pinned.id] = pinned;
        fakes.users.byEmail[pinned.email!] = pinned;
        fakes.users.byHandle[pinned.handle] = pinned;
        final backend = _FakeBackend();
        final service = _makeService(
          _enabledConfig(),
          fakes: fakes,
          backend: backend,
        );
        service.beginLogin(origin: _origin);
        await expectLater(
          service.handleAcs(
            origin: _origin,
            responseXml: _responseXml(inResponseTo: backend.lastRequestId),
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('maps groups to the highest-ranked role', () async {
      final fakes = _Fakes();
      final backend = _FakeBackend(
        identity: _identity(groups: ['everyone', 'platform-leads']),
      );
      final service = _makeService(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_GROUP_ROLE_MAP': '{"platform-leads":"admin"}',
        }),
        fakes: fakes,
        backend: backend,
      );
      service.beginLogin(origin: _origin);
      await service.handleAcs(
        origin: _origin,
        responseXml: _responseXml(inResponseTo: backend.lastRequestId),
      );
      expect(fakes.members.members.single.role, WorkspaceRole.admin);
    });

    test(
      'matches a single-quoted InResponseTo so a solicited login still works',
      () async {
        final backend = _FakeBackend();
        final service = _makeService(
          _enabledConfig(),
          fakes: _Fakes(),
          backend: backend,
        );
        service.beginLogin(origin: _origin);
        // A perfectly valid XML doc that single-quotes its attributes: the
        // tracker peek must still find it (else it looks unsolicited and is
        // rejected).
        final xml =
            "<samlp:Response xmlns:samlp='urn:oasis:names:tc:SAML:2.0:protocol' "
            "InResponseTo='${backend.lastRequestId}'></samlp:Response>";
        final result = await service.handleAcs(origin: _origin, responseXml: xml);
        expect(result.user.email, 'alice@example.com');
        // The cached tracker was found and handed to the native.
        expect(backend.lastTrackerJson, backend.builtTrackerJson);
      },
    );
  });

  group('SamlConfig clock skew', () {
    test('clamps an out-of-range skew to [0, 600]s', () {
      expect(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_CLOCK_SKEW_SECS': '999999',
        }).clockSkew,
        const Duration(seconds: 600),
      );
      expect(
        SamlConfig.fromEnvironment(const {
          'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
          'CC_SAML_CLOCK_SKEW_SECS': '-30',
        }).clockSkew,
        Duration.zero,
      );
    });
  });
}

SamlConfig _enabledConfig() => SamlConfig.fromEnvironment(const {
  'CC_SAML_IDP_METADATA': '<EntityDescriptor/>',
});

/// A minimal `samlp:Response` shell — the service only peeks
/// `InResponseTo="…"` out of it; the fake backend does the "verification".
String _responseXml({String? inResponseTo}) =>
    '<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"'
    '${inResponseTo == null ? '' : ' InResponseTo="$inResponseTo"'}>'
    '</samlp:Response>';

SamlIdentity _identity({
  String nameId = 'alice@example.com',
  Map<String, List<String>> attributes = const {
    'email': ['alice@example.com'],
    'displayName': ['Alice Example'],
    'groups': ['everyone'],
  },
  List<String> groups = const [],
  DateTime? notOnOrAfter,
}) {
  Map<String, List<String>> effective = attributes;
  if (groups.isNotEmpty) {
    effective = {...attributes, 'groups': groups};
  }
  return SamlIdentity(
    nameId: nameId,
    nameIdFormat: 'EmailAddress',
    attributes: effective,
    assertionId: 'assertion-${_nextAssertionId++}',
    notOnOrAfter:
        notOnOrAfter ?? DateTime.now().add(const Duration(minutes: 10)),
    isOneTimeUse: false,
  );
}

int _nextAssertionId = 1;

class _FakeBackend implements SamlBackend {
  _FakeBackend({SamlIdentity? identity})
    : _scriptedIdentity = identity ?? _identity();

  final SamlIdentity _scriptedIdentity;
  int _requestCounter = 0;

  /// When set, returned by [parseIdpMetadata] instead of the default.
  SamlIdpMetadata? metadataOverride;

  String? lastTrackerJson;
  String? lastRelayState;
  String? lastRequestId;
  String builtTrackerJson = '';

  @override
  SamlAuthnRequest buildAuthnRequest({
    required String idpMetadataXml,
    required String spEntityId,
    required String acsUrl,
    String? relayState,
  }) {
    lastRelayState = relayState;
    lastRequestId = 'req-${++_requestCounter}';
    builtTrackerJson = '{"request_id":"$lastRequestId"}';
    return SamlAuthnRequest(
      redirectUrl: 'https://idp.example.com/sso?SAMLRequest=x',
      requestId: lastRequestId!,
      trackerJson: builtTrackerJson,
    );
  }

  @override
  SamlIdentity verifyResponse({
    required String idpMetadataXml,
    required String spEntityId,
    required String acsUrl,
    required String responseXml,
    required DateTime now,
    required Duration clockSkew,
    String? trackerJson,
    bool wantAssertionsSigned = true,
    bool wantResponseSigned = false,
    bool allowUnsolicited = false,
  }) {
    lastTrackerJson = trackerJson;
    if (trackerJson == null && !allowUnsolicited) {
      // The native's unsolicited-refusal contract (SamlFailure-equivalent).
      throw Exception('unsolicited response');
    }
    return _scriptedIdentity;
  }

  @override
  SamlIdpMetadata parseIdpMetadata(String xml) =>
      metadataOverride ??
      const SamlIdpMetadata(
        entityId: _idpEntityId,
        ssoRedirect: _idpSsoUrl,
        ssoPost: _idpSsoUrl,
      );

  @override
  String spMetadata({required String spEntityId, required String acsUrl}) =>
      '<EntityDescriptor entityID="$spEntityId"/>';
}

SamlService _makeService(
  SamlConfig config, {
  _Fakes? fakes,
  SamlBackend? backend,
}) {
  final f = fakes ?? _Fakes();
  return SamlService(
    config: config,
    users: f.users,
    members: f.members,
    workspaces: f.workspaces,
    mintDevice: (userId, label) async =>
        (deviceId: 'device-$userId', psk: 'psk-$userId'),
    backend: backend ?? _FakeBackend(),
  );
}

class _Fakes {
  final users = _FakeUserRepository();
  final members = _FakeMembershipRepository();
  final workspaces = _FakeWorkspaceRepository();
}

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
  _FakeWorkspaceRepository() {
    workspaces = [
      Workspace(
        id: 'ws-1',
        name: 'Main',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ];
  }

  List<Workspace> workspaces = [];

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
  Future<void> upsert(WorkspaceMember member) async => members.add(member);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
