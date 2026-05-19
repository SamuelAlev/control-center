import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/identity/sso_provisioner.dart';
import 'package:crypto/crypto.dart';

/// OIDC single sign-on configuration, sourced from the environment. SSO is
/// strictly optional: with no issuer configured the whole surface is absent
/// and a solo operator never sees it.
///
/// Env surface:
///  * `CC_OIDC_ISSUER` — the issuer base URL (enables SSO when set).
///  * `CC_OIDC_CLIENT_ID` — the public-client id registered at the issuer.
///  * `CC_OIDC_CLIENT_SECRET` — optional; only CONFIDENTIAL IdP clients need
///    one (public clients authenticate with PKCE alone). It is never part of
///    the persisted connection row — the settings service holds it in the
///    secrets store.
///  * `CC_OIDC_DEFAULT_ROLE` — role for users with no mapped group
///    (default `member`). `owner` is refused: SSO must never mint a
///    workspace owner.
///  * `CC_OIDC_GROUP_ROLE_MAP` — JSON object mapping a group-claim value to a
///    role wire name, e.g. `{"platform-leads":"admin"}`.
///  * `CC_OIDC_GROUPS_CLAIM` — the claim carrying group names
///    (default `groups`).
///  * `CC_OIDC_AUTO_MEMBER` — whether SSO users are auto-added to workspace
///    memberships on first login: `all` (default) or `none` (require invite).
///  * `CC_OIDC_ALLOW_JIT` — whether an unknown identity may provision an
///    account at login: `true` (default) or `false` (pre-provisioned only).
class OidcConfig {
  /// Creates an [OidcConfig].
  const OidcConfig({
    required this.issuer,
    required this.clientId,
    required this.defaultRole,
    required this.groupRoleMap,
    required this.groupsClaim,
    this.clientSecret = '',
    this.autoMemberMode = SsoAutoMemberMode.all,
    this.allowJit = true,
  });

  /// Reads the config from [env]; [enabled] is false when unset.
  factory OidcConfig.fromEnvironment(Map<String, String> env) {
    final issuer = env['CC_OIDC_ISSUER']?.trim() ?? '';
    final clientId = env['CC_OIDC_CLIENT_ID']?.trim() ?? '';
    Map<String, WorkspaceRole> groupMap = const {};
    final rawMap = env['CC_OIDC_GROUP_ROLE_MAP'];
    if (rawMap != null && rawMap.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMap);
        if (decoded is Map) {
          groupMap = {
            for (final entry in decoded.entries)
              if (WorkspaceRole.fromWire(entry.value as String?)
                  case final WorkspaceRole role
                  when role != WorkspaceRole.owner)
                entry.key as String: role,
          };
        }
      } catch (_) {
        // A malformed map disables mapping, never crashes boot.
      }
    }
    // The RPC save path refuses an owner default role; the env path must
    // apply the same invariant (it seeds the connection row directly,
    // bypassing that validation), so a fat-fingered CC_OIDC_DEFAULT_ROLE
    // can never turn SSO into an owner-minting machine.
    final parsedDefault = WorkspaceRole.fromWire(env['CC_OIDC_DEFAULT_ROLE']);
    return OidcConfig(
      issuer: issuer,
      clientId: clientId,
      clientSecret: env['CC_OIDC_CLIENT_SECRET']?.trim() ?? '',
      defaultRole: parsedDefault == null || parsedDefault == WorkspaceRole.owner
          ? WorkspaceRole.member
          : parsedDefault,
      groupRoleMap: groupMap,
      groupsClaim: env['CC_OIDC_GROUPS_CLAIM']?.trim() ?? 'groups',
      autoMemberMode: switch (env['CC_OIDC_AUTO_MEMBER']
          ?.trim()
          .toLowerCase()) {
        'none' => SsoAutoMemberMode.none,
        _ => SsoAutoMemberMode.all,
      },
      allowJit: env['CC_OIDC_ALLOW_JIT']?.trim().toLowerCase() != 'false',
    );
  }

  /// The issuer base URL; empty = SSO disabled.
  final String issuer;

  /// The registered public-client id.
  final String clientId;

  /// The client secret for CONFIDENTIAL IdP clients (empty = public
  /// PKCE-only client). Sent to the token endpoint as `client_secret_post`;
  /// never persisted in the connection row.
  final String clientSecret;

  /// Role granted when no group maps.
  final WorkspaceRole defaultRole;

  /// Whether SSO users are auto-added to workspace memberships on login.
  final SsoAutoMemberMode autoMemberMode;

  /// Whether a login by an identity with no existing account may provision
  /// one just-in-time. False = only pre-provisioned accounts may sign in.
  final bool allowJit;

  /// Group-claim value → role.
  final Map<String, WorkspaceRole> groupRoleMap;

  /// The claim carrying group names.
  final String groupsClaim;

  /// Whether SSO is configured at all.
  bool get enabled => issuer.isNotEmpty && clientId.isNotEmpty;

  /// Whether [issuer] is acceptable as a trust anchor. This service performs
  /// NO local JWT signature verification — the TLS channel to the issuer's
  /// discovery/token endpoints is the ONLY thing authenticating the claims,
  /// so a plaintext (http) issuer hands claim forgery to any on-path
  /// attacker. http is tolerated for loopback only (local dev IdPs).
  static bool isIssuerAllowed(String issuer) {
    final uri = Uri.tryParse(issuer);
    if (uri == null || uri.host.isEmpty) {
      return false;
    }
    if (uri.isScheme('https')) {
      return true;
    }
    return uri.isScheme('http') &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '::1');
  }

  /// The shared provisioning policy derived from this config.
  SsoProvisioningPolicy get provisioningPolicy => SsoProvisioningPolicy(
    defaultRole: defaultRole,
    groupRoleMap: groupRoleMap,
    autoMemberMode: autoMemberMode,
    allowJit: allowJit,
  );
}

/// Optional OIDC login for teams that want SSO — never required.
///
/// Authorization-code + PKCE as a public client: `beginLogin` builds the
/// authorization URL (state + nonce + S256 challenge held server-side,
/// single-use, short-lived); `handleCallback` exchanges the code at the
/// issuer's token endpoint and provisions the user just-in-time. Claims are
/// taken from the token-endpoint response, which this server fetches
/// directly from the issuer over TLS — the browser never supplies them —
/// so no local JWT signature verification is repeated here; the `iss`,
/// `aud`, `sub` and `nonce` claims ARE still validated against what this
/// server requested, so a token minted for a different issuer/audience or
/// login attempt is refused even though its bytes came over TLS.
///
/// JIT provisioning lives in the shared [SsoProvisioner] (extracted from
/// this service; the SAML path rides the identical semantics): users match
/// by email (then handle); new users are created and granted membership in
/// every workspace at the role mapped from the group claim (or the
/// configured default). Existing memberships are never downgraded.
class OidcService {
  /// Creates an [OidcService].
  OidcService({
    required this.config,
    required UserRepository users,
    required WorkspaceMembershipRepository members,
    required WorkspaceRepository workspaces,
    required Future<({String deviceId, String psk})> Function(
      String userId,
      String label,
    )
    mintDevice,
    DomainEventBus? eventBus,
    HttpClient? httpClient,
    DateTime Function()? now,
  }) : _provisioner = SsoProvisioner(
         users: users,
         members: members,
         workspaces: workspaces,
         eventBus: eventBus,
         now: now,
       ),
       _mintDevice = mintDevice,
       _http = httpClient ?? (HttpClient()..connectionTimeout = _httpTimeout),
       _now = now ?? DateTime.now;

  /// Bound on every issuer round-trip (connect + response). A wedged IdP
  /// must not pin the login path open indefinitely.
  static const Duration _httpTimeout = Duration(seconds: 15);

  /// Upper bound on the discovery document size.
  static const int _maxDiscoveryBytes = 64 * 1024;

  /// Upper bound on the token-endpoint response size.
  static const int _maxTokenResponseBytes = 256 * 1024;

  /// The (possibly disabled) SSO configuration.
  OidcConfig config;

  final SsoProvisioner _provisioner;
  final Future<({String deviceId, String psk})> Function(
    String userId,
    String label,
  )
  _mintDevice;
  final HttpClient _http;
  final DateTime Function() _now;

  /// Swaps the configuration at runtime (the `sso.saveConfig` path) and
  /// drops every pending login + the cached discovery.
  void updateConfig(OidcConfig next) {
    config = next;
    _pending.clear();
    _authorizationEndpoint = null;
    _tokenEndpoint = null;
  }

  /// Upper bound on concurrent pending logins, mirroring
  /// [SamlService.maxPendingLogins]: the `/oidc/login` endpoint is
  /// unauthenticated, so the pending-state map needs flood backpressure.
  static const int maxPendingLogins = 256;

  final _pending =
      <
        String,
        ({
          String verifier,
          String nonce,
          DateTime expiresAt,
          String? clientOrigin,
        })
      >{};

  Uri? _authorizationEndpoint;
  Uri? _tokenEndpoint;

  /// Builds the issuer authorization URL for one login attempt.
  /// [redirectUri] is this server's `/oidc/callback`. [relay] names the
  /// post-login handoff and round-trips as a state prefix: `web-popup`
  /// (`p.`) serves the new-tab completion page (the connect tab is waiting
  /// on a postMessage), `desktop` (`d.`) bounces to the app's
  /// `control-center://pair` deep link; anything else is the same-tab
  /// fragment redirect. For `web-popup`, [clientOrigin] is the connect
  /// tab's browser origin — held server-side here (never round-tripped
  /// through the IdP) so the completion page can postMessage the credential
  /// to the tab's actual origin, not a guessed one.
  Future<Uri> beginLogin({
    required Uri redirectUri,
    String relay = '',
    String? clientOrigin,
  }) async {
    if (!config.enabled) {
      throw const AuthException('SSO is not configured on this server');
    }
    await _discover();
    _evictExpired();
    // Backpressure for the unauthenticated login endpoint, mirroring
    // `SamlService.beginLogin`: a flood of /oidc/login hits must not grow
    // the pending map without bound. Evicting the soonest-to-expire entries
    // keeps honest concurrent logins working while capping memory.
    if (_pending.length >= maxPendingLogins) {
      final ordered = _pending.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
      for (final entry in ordered.take(
        _pending.length - maxPendingLogins + 1,
      )) {
        _pending.remove(entry.key);
      }
    }
    final state =
        '${switch (relay) {
          'web-popup' => 'p.',
          'desktop' => 'd.',
          _ => '',
        }}${_randomToken()}';
    final nonce = _randomToken();
    final verifier = _randomToken() + _randomToken();
    _pending[state] = (
      verifier: verifier,
      nonce: nonce,
      expiresAt: _now().add(const Duration(minutes: 10)),
      clientOrigin: relay == 'web-popup'
          ? SsoProvisioner.sanitizeClientOrigin(clientOrigin)
          : null,
    );
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(verifier)).bytes,
    ).replaceAll('=', '');
    return _authorizationEndpoint!.replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': config.clientId,
        'redirect_uri': redirectUri.toString(),
        'scope': 'openid profile email',
        'state': state,
        'nonce': nonce,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  /// Completes the login from the issuer's redirect back to
  /// `/oidc/callback?code=…&state=…`.
  Future<SsoLoginResult> handleCallback({
    required Uri requestUri,
    required Uri redirectUri,
  }) async {
    final state = requestUri.queryParameters['state'];
    final code = requestUri.queryParameters['code'];
    final pending = state == null ? null : _pending.remove(state);
    if (pending == null ||
        code == null ||
        code.isEmpty ||
        _now().isAfter(pending.expiresAt)) {
      throw const AuthException('Login expired — try again');
    }
    await _discover();
    final claims = await _exchangeCode(
      code: code,
      verifier: pending.verifier,
      redirectUri: redirectUri,
    );
    _validateTokenClaims(claims, expectedNonce: pending.nonce);
    // Pin the immutable subject (`sub`) so a later email change/reuse at the
    // provider cannot silently take over a colleague's account — the exact
    // guard the shared provisioner already applies to SAML NameIDs. Without
    // this, OIDC would match purely by email and the guard would be inert. The
    // issuer half of the pin is the server-configured issuer (deterministic,
    // not influenced by token contents), not the token's own `iss` claim.
    final subject = claims['sub'] as String;
    final ssoClaims = SsoClaims(
      email: claims['email'] as String?,
      // RFC 9700: an email is only an identifier when the issuer explicitly
      // vouches for it. A MISSING `email_verified` claim is not a vouch —
      // treating it as one let a self-service IdP account asserting a
      // colleague's address match (and take over) their pre-provisioned
      // account. Unverified emails still seed new accounts; they never match
      // existing ones.
      emailVerified: claims['email_verified'] == true,
      displayName: claims['name'] as String?,
      handle: claims['preferred_username'] as String?,
      groups: _groupsFrom(claims),
      ssoSubject: subject,
      ssoIssuer: config.issuer,
    );
    final user = await _provisioner.provisionUser(
      ssoClaims,
      policy: config.provisioningPolicy,
    );
    await _provisioner.ensureMemberships(
      user,
      ssoClaims,
      config.provisioningPolicy,
    );
    final device = await _mintDevice(user.id, 'SSO (${user.handle})');
    return SsoLoginResult(
      user: user,
      deviceId: device.deviceId,
      psk: device.psk,
      groups: ssoClaims.groups,
      clientOrigin: pending.clientOrigin,
    );
  }

  List<String> _groupsFrom(Map<String, dynamic> claims) {
    final groups = claims[config.groupsClaim];
    return groups is List ? groups.whereType<String>().toList() : const [];
  }

  /// Runs discovery against an arbitrary [issuerBase] and returns the
  /// authorization + token endpoints — the settings screen's "test
  /// connection" path. Independent of the live [config] (it tests what is
  /// on screen, saved or not); throws [AuthException] with a plain reason
  /// when the issuer is unreachable or its document is incomplete.
  Future<({String authorizationEndpoint, String tokenEndpoint})> testDiscovery(
    String issuerBase,
  ) async {
    _requireAllowedIssuer(issuerBase);
    final base = issuerBase.endsWith('/')
        ? issuerBase.substring(0, issuerBase.length - 1)
        : issuerBase;
    final Map<String, dynamic> doc;
    try {
      doc = await _getJson(Uri.parse('$base/.well-known/openid-configuration'));
    } on AuthException {
      rethrow;
    } on Object {
      throw const AuthException(
        'Could not reach the issuer — check the URL and the server\'s '
        'outbound network',
      );
    }
    final authorization = doc['authorization_endpoint'];
    final token = doc['token_endpoint'];
    if (authorization is! String || token is! String) {
      throw const AuthException(
        'The issuer\'s discovery document is missing its endpoints',
      );
    }
    return (authorizationEndpoint: authorization, tokenEndpoint: token);
  }

  Future<void> _discover() async {
    if (_authorizationEndpoint != null && _tokenEndpoint != null) {
      return;
    }
    _requireAllowedIssuer(config.issuer);
    final base = config.issuer.endsWith('/')
        ? config.issuer.substring(0, config.issuer.length - 1)
        : config.issuer;
    final doc = await _getJson(
      Uri.parse('$base/.well-known/openid-configuration'),
    );
    final authorization = doc['authorization_endpoint'];
    final token = doc['token_endpoint'];
    if (authorization is! String || token is! String) {
      throw const AuthException('Issuer discovery failed');
    }
    _authorizationEndpoint = Uri.parse(authorization);
    _tokenEndpoint = Uri.parse(token);
  }

  /// The trust-anchor gate: TLS to the issuer is the ONLY authentication of
  /// the claims (no local JWT signature verification), so a plaintext issuer
  /// is refused outright rather than silently degrading to forgeable logins.
  static void _requireAllowedIssuer(String issuer) {
    if (!OidcConfig.isIssuerAllowed(issuer)) {
      throw const AuthException(
        'The issuer must be an https URL (http is allowed only for a '
        'loopback issuer during local development)',
      );
    }
  }

  Future<Map<String, dynamic>> _exchangeCode({
    required String code,
    required String verifier,
    required Uri redirectUri,
  }) async {
    final request = await _http.postUrl(_tokenEndpoint!);
    // Never follow redirects: on a 307/308 dart:io would RE-POST the body —
    // the authorization code AND the client secret — to an arbitrary
    // Location. The token endpoint must answer directly.
    request.followRedirects = false;
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    );
    request.write(
      Uri(
        queryParameters: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri.toString(),
          'client_id': config.clientId,
          'code_verifier': verifier,
          // Confidential clients authenticate at the token endpoint with
          // client_secret_post; public clients rely on PKCE alone.
          if (config.clientSecret.isNotEmpty)
            'client_secret': config.clientSecret,
        },
      ).query,
    );
    final response = await request.close().timeout(_httpTimeout);
    final body = await _readBounded(response, _maxTokenResponseBytes);
    if (response.statusCode != 200) {
      // The IdP's own error (usually `invalid_client` when a confidential
      // client sent no/​wrong secret, or `invalid_grant` on a redirect_uri
      // mismatch) is the ONLY usable diagnostic — surface it in the server
      // log instead of a bare "failed".
      final excerpt = body.length > 300 ? body.substring(0, 300) : body;
      throw AuthException(
        'Login failed at the identity provider '
        '(HTTP ${response.statusCode}: $excerpt)',
      );
    }
    final decoded = jsonDecode(body);
    final idToken = decoded is Map ? decoded['id_token'] : null;
    if (idToken is! String) {
      throw const AuthException('Identity provider returned no identity');
    }
    return _decodeJwtClaims(idToken);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final request = await _http.getUrl(uri);
    // Same redirect rule as the token exchange: the discovery document is
    // configuration, not a browser session — a redirect is a misconfigured
    // (or attacker-influenced) issuer, not something to chase.
    request.followRedirects = false;
    final response = await request.close().timeout(_httpTimeout);
    final body = await _readBounded(response, _maxDiscoveryBytes);
    if (response.statusCode != 200) {
      throw const AuthException('Issuer discovery failed');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Issuer discovery failed');
    }
    return decoded;
  }

  /// Reads [response] fully, bounded to [maxBytes] and [_httpTimeout]. A
  /// buggy or hostile endpoint must not pin memory or the connection.
  static Future<String> _readBounded(
    HttpClientResponse response,
    int maxBytes,
  ) async {
    final chunks = <int>[];
    await for (final chunk in response.timeout(_httpTimeout)) {
      chunks.addAll(chunk);
      if (chunks.length > maxBytes) {
        throw const AuthException(
          'Identity provider returned an oversized response',
        );
      }
    }
    return utf8.decode(chunks, allowMalformed: true);
  }

  static Map<String, dynamic> _decodeJwtClaims(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw const AuthException('Identity provider returned no identity');
    }
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Identity provider returned no identity');
    }
    return decoded;
  }

  /// Enforces the OIDC Core §3.1.3.7 claim checks on the freshly exchanged
  /// id_token. The token came from the configured issuer's token endpoint
  /// over TLS (that is the trust anchor — no local signature check), but the
  /// issuer's own contents still have to say what the protocol says they
  /// say, or a misbehaving/misconfigured issuer silently degrades the
  /// subject pin into pure email matching.
  void _validateTokenClaims(
    Map<String, dynamic> claims, {
    required String expectedNonce,
  }) {
    // `iss` MUST be the configured issuer (trailing-slash tolerant; the
    // discovery URL builder applies the same trim).
    final iss = claims['iss'];
    if (iss is! String ||
        _trimTrailingSlash(iss) != _trimTrailingSlash(config.issuer)) {
      throw const AuthException(
        'Identity provider returned a token for a different issuer',
      );
    }
    // `aud` MUST contain our client id (string or array form).
    final aud = claims['aud'];
    final audienceOk = aud is String
        ? aud == config.clientId
        : aud is List && aud.whereType<String>().contains(config.clientId);
    if (!audienceOk) {
      throw const AuthException(
        'Identity provider returned a token for a different audience',
      );
    }
    // `sub` is REQUIRED — without it the provisioner's subject pin is inert
    // and matching degrades to (attackable) email equality.
    final sub = claims['sub'];
    if (sub is! String || sub.isEmpty) {
      throw const AuthException('Identity provider returned no identity');
    }
    // `exp` is REQUIRED in an id_token (OIDC Core §2) and MUST be validated
    // (§3.1.3.7): a token without expiry — or an expired one — is refused.
    // The fresh token-endpoint exchange makes replay impractical, but a
    // misbehaving issuer must not get to skip lifetime checks. One minute of
    // skew covers clock drift between issuer and server.
    final exp = claims['exp'];
    if (exp is! num) {
      throw const AuthException('Identity provider returned no expiry');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    if (_now().isAfter(expiresAt.add(const Duration(minutes: 1)))) {
      throw const AuthException('Login expired — try again');
    }
    // The nonce binds this token to the login attempt that started it.
    final nonce = claims['nonce'];
    if (nonce is! String || nonce != expectedNonce) {
      throw const AuthException('Login expired — try again');
    }
  }

  static String _trimTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  void _evictExpired() {
    final now = _now();
    _pending.removeWhere((_, pending) => now.isAfter(pending.expiresAt));
  }

  static String _randomToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
