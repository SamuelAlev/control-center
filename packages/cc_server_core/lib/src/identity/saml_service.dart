import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_natives/cc_natives.dart'
    show CcSaml, SamlAuthnRequest, SamlIdpMetadata, SamlIdentity;
import 'package:cc_server_core/src/identity/sso_provisioner.dart';

/// SAML 2.0 service-provider configuration.
///
/// Configured in **Settings → Server → Single sign-on** and nowhere else — the
/// saved row is pushed in by `SsoSettingsService.loadAndApply` at boot. There
/// is deliberately no `CC_SAML_*` environment path: a connection that could
/// arrive from two places is one the settings screen can disagree with.
///
/// Strictly optional: with no IdP metadata the whole surface is absent and a
/// solo operator never sees it.
class SamlConfig {
  /// Creates a [SamlConfig].
  const SamlConfig({
    required this.idpMetadataXml,
    this.spEntityId = '',
    this.emailAttribute = 'email',
    this.displayNameAttribute = 'displayName',
    this.groupsAttribute = 'groups',
    required this.defaultRole,
    required this.groupRoleMap,
    this.autoMemberMode = SsoAutoMemberMode.all,
    this.allowJit = true,
    this.allowIdpInitiated = false,
    this.wantResponseSigned = false,
    this.clockSkew = const Duration(seconds: 90),
  });

  /// Clamps a configured clock skew to the `[0, 600]`s window.
  ///
  /// A negative value would reject valid assertions; an unbounded one silently
  /// widens the expiry/replay-acceptance window the native enforces, so a
  /// fat-fingered value cannot turn into a multi-day acceptance slop.
  static Duration clampClockSkew(int seconds) =>
      Duration(seconds: seconds.clamp(0, 600));

  /// The IdP EntityDescriptor XML; empty = SAML disabled.
  final String idpMetadataXml;

  /// Our entityID; empty = derive `<origin>/saml` per request.
  final String spEntityId;

  /// Attribute carrying the email.
  final String emailAttribute;

  /// Attribute carrying the display name.
  final String displayNameAttribute;

  /// Attribute carrying group names.
  final String groupsAttribute;

  /// Role granted when no group maps.
  final WorkspaceRole defaultRole;

  /// Whether SSO users are auto-added to workspace memberships on login.
  final SsoAutoMemberMode autoMemberMode;

  /// Whether a login by an identity with no existing account may provision
  /// one just-in-time. False = only pre-provisioned accounts may sign in.
  final bool allowJit;

  /// Group value → role.
  final Map<String, WorkspaceRole> groupRoleMap;

  /// Accept unsolicited (IdP-initiated) Responses.
  final bool allowIdpInitiated;

  /// Require a Response-root signature in addition to assertion signatures.
  final bool wantResponseSigned;

  /// Validation clock skew allowance.
  final Duration clockSkew;

  /// Whether SAML is configured at all.
  bool get enabled => idpMetadataXml.isNotEmpty;

  /// The shared provisioning policy derived from this config.
  SsoProvisioningPolicy get provisioningPolicy => SsoProvisioningPolicy(
    defaultRole: defaultRole,
    groupRoleMap: groupRoleMap,
    autoMemberMode: autoMemberMode,
    allowJit: allowJit,
  );
}

/// The crypto backend seam: the real one is the `cc_saml` native; tests fake
/// it. Exists so [SamlService]'s state/policy logic is unit-testable without
/// the dylib while the native keeps its own Rust-side conformance corpus.
abstract class SamlBackend {
  /// Parses an IdP EntityDescriptor.
  SamlIdpMetadata parseIdpMetadata(String xml);

  /// Builds an HTTP-Redirect AuthnRequest.
  SamlAuthnRequest buildAuthnRequest({
    required String idpMetadataXml,
    required String spEntityId,
    required String acsUrl,
    String? relayState,
  });

  /// Verifies a POST-binding Response.
  SamlIdentity verifyResponse({
    required String idpMetadataXml,
    required String spEntityId,
    required String acsUrl,
    required String responseXml,
    required DateTime now,
    required Duration clockSkew,
    String? trackerJson,
    bool wantAssertionsSigned,
    bool wantResponseSigned,
    bool allowUnsolicited,
  });

  /// Emits SP EntityDescriptor XML.
  String spMetadata({required String spEntityId, required String acsUrl});
}

/// [SamlBackend] over the required `cc_saml` native.
class NativeSamlBackend implements SamlBackend {
  /// Creates a [NativeSamlBackend] over [saml] (defaults to `CcSaml.require`).
  NativeSamlBackend({CcSaml? saml}) : _saml = saml;

  final CcSaml? _saml;

  CcSaml get _require => _saml ?? CcSaml.require;

  @override
  SamlIdpMetadata parseIdpMetadata(String xml) =>
      _require.parseIdpMetadata(xml);

  @override
  SamlAuthnRequest buildAuthnRequest({
    required String idpMetadataXml,
    required String spEntityId,
    required String acsUrl,
    String? relayState,
  }) => _require.buildAuthnRequest(
    idpMetadataXml: idpMetadataXml,
    spEntityId: spEntityId,
    acsUrl: acsUrl,
    relayState: relayState,
  );

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
  }) => _require.verifyResponse(
    idpMetadataXml: idpMetadataXml,
    spEntityId: spEntityId,
    acsUrl: acsUrl,
    responseXml: responseXml,
    now: now,
    clockSkew: clockSkew,
    trackerJson: trackerJson,
    wantAssertionsSigned: wantAssertionsSigned,
    wantResponseSigned: wantResponseSigned,
    allowUnsolicited: allowUnsolicited,
  );

  @override
  String spMetadata({required String spEntityId, required String acsUrl}) =>
      _require.spMetadata(spEntityId: spEntityId, acsUrl: acsUrl);
}

/// Optional SAML 2.0 SP login for teams whose IdP speaks SAML — never
/// required and absent unless configured.
///
/// SP-initiated HTTP-Redirect flow mirroring `OidcService`: `beginLogin`
/// stores the native's login tracker server-side keyed by the AuthnRequest
/// ID (single-use, short-lived); `handleAcs` feeds the tracker back to the
/// native for full XML-DSig + profile validation (audience, destination,
/// InResponseTo, lifetime ± skew, recipient — all inside the verified
/// native), applies the caller-side assertion-ID replay cache, then rides
/// the shared [SsoProvisioner] and the same device-PSK minting as OIDC, so
/// a completed login is indistinguishable from an OIDC one downstream.
class SamlService {
  /// Creates a [SamlService].
  SamlService({
    required this.config,
    required UserRepository users,
    required WorkspaceMembershipRepository members,
    required WorkspaceRepository workspaces,
    required Future<({String deviceId, String psk})> Function(
      String userId,
      String label,
    )
    mintDevice,
    SamlBackend? backend,
    DomainEventBus? eventBus,
    DateTime Function()? now,
  }) : _provisioner = SsoProvisioner(
         users: users,
         members: members,
         workspaces: workspaces,
         eventBus: eventBus,
         now: now,
       ),
       _backend = backend ?? NativeSamlBackend(),
       _mintDevice = mintDevice,
       _now = now ?? DateTime.now;

  /// Upper bound on concurrent pending logins. The `/saml/login` endpoint is
  /// unauthenticated, so the pending-tracker map needs flood backpressure:
  /// at the cap the soonest-to-expire entries are evicted (a huge concurrent
  /// login wave is legitimate; an unbounded map is not).
  static const int maxPendingLogins = 256;

  /// The (possibly disabled) SSO configuration.
  SamlConfig config;

  final SsoProvisioner _provisioner;
  final SamlBackend _backend;
  final Future<({String deviceId, String psk})> Function(
    String userId,
    String label,
  )
  _mintDevice;
  final DateTime Function() _now;

  /// The crypto backend — exposed for the settings service's metadata test
  /// op (parse-only; never mutates login state).
  SamlBackend get backend => _backend;

  /// Swaps the configuration at runtime (the `sso.saveConfig` path) and
  /// drops every pending login — a config change invalidates outstanding
  /// trackers/replay entries by construction, so none survive the swap.
  void updateConfig(SamlConfig next) {
    config = next;
    _pending.clear();
    _seenAssertions.clear();
    _idpMetadata = null;
  }

  /// AuthnRequest ID → (tracker, expiry, connect-tab origin). Single-use;
  /// mirrors the OIDC pending-state map. Replaced, never consulted, after
  /// use or TTL.
  final _pending =
      <
        String,
        ({String trackerJson, DateTime expiresAt, String? clientOrigin})
      >{};

  /// Assertion ID → expiry. The caller-side replay cache (the native is
  /// stateless by design; see the cc_saml README).
  final _seenAssertions = <String, DateTime>{};

  SamlIdpMetadata? _idpMetadata;

  /// The parsed IdP metadata (cached after first parse; throws on invalid
  /// XML so the route can surface a configuration error, not a crash).
  SamlIdpMetadata get idpMetadata {
    final cached = _idpMetadata;
    if (cached != null) {
      return cached;
    }
    if (!config.enabled) {
      throw const AuthException('SAML SSO is not configured on this server');
    }
    return _idpMetadata = _backend.parseIdpMetadata(config.idpMetadataXml);
  }

  /// This SP's entityID for the request origin [origin]
  /// (`https://host:port`), stable as long as the origin is.
  String spEntityIdFor(String origin) =>
      config.spEntityId.isEmpty ? '$origin/saml' : config.spEntityId;

  /// Tests a SAML connection end-to-end short of the browser round-trip:
  /// parses [idpMetadataXml], confirms a usable SSO endpoint and builds a
  /// real AuthnRequest through the crypto backend against [origin]. Throws
  /// with the typed reason on any failure — this is the settings screen's
  /// "test connection" button, so the message reaches the admin verbatim.
  ///
  /// Stateless by design: the request this builds is discarded, never
  /// registered in the pending map.
  ({String entityId, String ssoEndpoint, String spEntityId, String acsUrl})
  testConnection({required String idpMetadataXml, required String origin}) {
    final metadata = _backend.parseIdpMetadata(idpMetadataXml);
    if (metadata.entityId.isEmpty) {
      throw const AuthException('The metadata carries no entity ID');
    }
    final endpoint =
        metadata.ssoRedirect ??
        metadata.ssoPost ??
        (throw const AuthException(
          'The metadata declares no single sign-on endpoint',
        ));
    final spEntityId = spEntityIdFor(origin);
    final acsUrl = acsUrlFor(origin);
    // Exercises entity-ID/ACS derivation and the native — a failure here is
    // a connection that cannot start a login.
    _backend.buildAuthnRequest(
      idpMetadataXml: idpMetadataXml,
      spEntityId: spEntityId,
      acsUrl: acsUrl,
    );
    return (
      entityId: metadata.entityId,
      ssoEndpoint: endpoint,
      spEntityId: spEntityId,
      acsUrl: acsUrl,
    );
  }

  /// The ACS URL for the request origin.
  String acsUrlFor(String origin) => '$origin/saml/acs';

  /// Builds the IdP redirect for one SP-initiated login. [relayState]
  /// round-trips through the IdP and back to the ACS (client-kind hint).
  /// For the `web-popup` relay, [clientOrigin] is the connect tab's browser
  /// origin — held server-side (never sent to the IdP) so the completion
  /// page can postMessage the credential to the tab's actual origin.
  Uri beginLogin({
    required String origin,
    String? relayState,
    String? clientOrigin,
  }) {
    if (!config.enabled) {
      throw const AuthException('SAML SSO is not configured on this server');
    }
    idpMetadata; // Fail fast on unusable metadata.
    _evictExpired();
    // Backpressure for the unauthenticated login endpoint: a flood of
    // /saml/login hits must not grow the pending map without bound. Evicting
    // the soonest-to-expire entries keeps honest concurrent logins working
    // while capping memory.
    if (_pending.length >= maxPendingLogins) {
      final ordered = _pending.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
      for (final entry in ordered.take(
        _pending.length - maxPendingLogins + 1,
      )) {
        _pending.remove(entry.key);
      }
    }
    final request = _backend.buildAuthnRequest(
      idpMetadataXml: config.idpMetadataXml,
      spEntityId: spEntityIdFor(origin),
      acsUrl: acsUrlFor(origin),
      relayState: relayState,
    );
    _pending[request.requestId] = (
      trackerJson: request.trackerJson,
      expiresAt: _now().add(const Duration(minutes: 10)),
      clientOrigin: relayState == 'web-popup'
          ? SsoProvisioner.sanitizeClientOrigin(clientOrigin)
          : null,
    );
    return Uri.parse(request.redirectUrl);
  }

  /// Consumes a POST-binding `SAMLResponse` (raw XML) at our ACS and returns
  /// the login result (provisioned user + minted device credential).
  ///
  /// The [responseXml]'s `InResponseTo` is peeked ONLY to pick which cached
  /// tracker to hand the native — the native re-validates it against signed
  /// data, so a forged peek changes nothing.
  Future<SsoLoginResult> handleAcs({
    required String origin,
    required String responseXml,
  }) async {
    if (!config.enabled) {
      throw const AuthException('SAML SSO is not configured on this server');
    }
    _evictExpired();
    final inResponseTo = _peekInResponseTo(responseXml);
    final pending = inResponseTo == null ? null : _pending.remove(inResponseTo);
    if (inResponseTo != null && pending == null) {
      // A response claiming to answer a request we never made (or one that
      // already consumed / expired): refuse even when unsolicited is allowed.
      throw const AuthException('Login expired — try again');
    }
    final identity = _backend.verifyResponse(
      idpMetadataXml: config.idpMetadataXml,
      spEntityId: spEntityIdFor(origin),
      acsUrl: acsUrlFor(origin),
      responseXml: responseXml,
      now: _now(),
      clockSkew: config.clockSkew,
      trackerJson: pending?.trackerJson,
      wantAssertionsSigned: true,
      wantResponseSigned: config.wantResponseSigned,
      allowUnsolicited: config.allowIdpInitiated && pending == null,
    );
    if (!_rememberAssertion(identity.assertionId, identity.notOnOrAfter)) {
      throw const AuthException('Login expired — try again');
    }
    final claims = _claimsFrom(identity);
    final user = await _provisioner.provisionUser(
      claims,
      policy: config.provisioningPolicy,
    );
    await _provisioner.ensureMemberships(
      user,
      claims,
      config.provisioningPolicy,
    );
    final device = await _mintDevice(user.id, 'SSO (${user.handle})');
    return SsoLoginResult(
      user: user,
      deviceId: device.deviceId,
      psk: device.psk,
      groups: claims.groups,
      clientOrigin: pending?.clientOrigin,
    );
  }

  /// This SP's EntityDescriptor XML for the admin to register at the IdP.
  String spMetadataXml({required String origin}) => _backend.spMetadata(
    spEntityId: spEntityIdFor(origin),
    acsUrl: acsUrlFor(origin),
  );

  SsoClaims _claimsFrom(SamlIdentity identity) {
    final email =
        _first(identity, config.emailAttribute) ??
        (identity.nameId.contains('@') ? identity.nameId : null);
    return SsoClaims(
      email: email,
      displayName: _first(identity, config.displayNameAttribute),
      groups: identity.attributes[config.groupsAttribute] ?? const [],
      ssoSubject: identity.nameId,
      ssoIssuer: idpMetadata.entityId,
    );
  }

  String? _first(SamlIdentity identity, String attribute) {
    final values = identity.attributes[attribute];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  /// Records an assertion ID; false when it was already seen within its
  /// acceptance window (a replay). The horizon is NotOnOrAfter PLUS the
  /// configured clock skew: the native still accepts the assertion until
  /// `notOnOrAfter + skew`, so a cache that sweeps at the signed expiry
  /// would re-admit a replay inside the skew tail.
  bool _rememberAssertion(String assertionId, DateTime notOnOrAfter) {
    _sweepSeenAssertions();
    final existing = _seenAssertions[assertionId];
    if (existing != null && _now().isBefore(existing)) {
      return false;
    }
    _seenAssertions[assertionId] = notOnOrAfter.add(config.clockSkew);
    return true;
  }

  void _sweepSeenAssertions() {
    final now = _now();
    _seenAssertions.removeWhere((_, expiry) => now.isAfter(expiry));
  }

  void _evictExpired() {
    final now = _now();
    _pending.removeWhere((_, pending) => now.isAfter(pending.expiresAt));
  }

  /// Peeks `InResponseTo="…"` / `InResponseTo='…'` out of the raw XML. A
  /// HINT for tracker lookup only — never a validation. Both quote styles are
  /// valid XML, so a single-quoted attribute (some IdPs emit them) must not
  /// make a legitimate solicited response look unsolicited.
  static String? _peekInResponseTo(String responseXml) {
    final match = RegExp(
      'InResponseTo=(?:"([^"]+)"|\'([^\']+)\')',
    ).firstMatch(responseXml);
    return match == null ? null : (match.group(1) ?? match.group(2));
  }
}
