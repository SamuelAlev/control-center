import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Controls whether SSO users are auto-added to workspace memberships on
/// first login.
///
/// - `all` (default): JIT-grants membership in every non-deleted workspace.
///   The right default for a single-team deployment where SSO = trust.
/// - `none`: provisions the user account but does NOT add them to any
///   workspace — they need an explicit invite per workspace. The secure
///   default for multi-tenant / consulting setups (the PRD 14 §13 over-grant
///   trap).
/// How OIDC-authenticated members are auto-added to a workspace.
enum OidcAutoMemberMode {
  /// Every authenticated OIDC user is auto-added as a member.
  all,

  /// No auto-membership: each user must be invited explicitly.
  none,
}

/// OIDC single sign-on configuration, sourced from the environment. SSO is
/// strictly optional: with no issuer configured the whole surface is absent
/// and a solo operator never sees it.
///
/// Env surface:
///  * `CC_OIDC_ISSUER` — the issuer base URL (enables SSO when set).
///  * `CC_OIDC_CLIENT_ID` — the public-client id registered at the issuer.
///  * `CC_OIDC_DEFAULT_ROLE` — role for users with no mapped group
///    (default `member`).
///  * `CC_OIDC_GROUP_ROLE_MAP` — JSON object mapping a group-claim value to a
///    role wire name, e.g. `{"platform-leads":"admin"}`.
///  * `CC_OIDC_GROUPS_CLAIM` — the claim carrying group names
///    (default `groups`).
///  * `CC_OIDC_AUTO_MEMBER` — whether SSO users are auto-added to workspace
///    memberships on first login: `all` (default) or `none` (require invite).
class OidcConfig {
  /// Creates an [OidcConfig].
  const OidcConfig({
    required this.issuer,
    required this.clientId,
    required this.defaultRole,
    required this.groupRoleMap,
    required this.groupsClaim,
    this.autoMemberMode = OidcAutoMemberMode.all,
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
    return OidcConfig(
      issuer: issuer,
      clientId: clientId,
      defaultRole:
          WorkspaceRole.fromWire(env['CC_OIDC_DEFAULT_ROLE']) ??
          WorkspaceRole.member,
      groupRoleMap: groupMap,
      groupsClaim: env['CC_OIDC_GROUPS_CLAIM']?.trim() ?? 'groups',
      autoMemberMode: switch (env['CC_OIDC_AUTO_MEMBER']
          ?.trim()
          .toLowerCase()) {
        'none' => OidcAutoMemberMode.none,
        _ => OidcAutoMemberMode.all,
      },
    );
  }

  /// The issuer base URL; empty = SSO disabled.
  final String issuer;

  /// The registered public-client id.
  final String clientId;

  /// Role granted when no group maps.
  final WorkspaceRole defaultRole;

  /// Whether SSO users are auto-added to workspace memberships on login.
  final OidcAutoMemberMode autoMemberMode;

  /// Group-claim value → role.
  final Map<String, WorkspaceRole> groupRoleMap;

  /// The claim carrying group names.
  final String groupsClaim;

  /// Whether SSO is configured at all.
  bool get enabled => issuer.isNotEmpty && clientId.isNotEmpty;
}

/// The outcome of a completed SSO login: the (possibly JIT-provisioned) user
/// and the freshly minted device credential the browser hands to the web
/// client.
class OidcLoginResult {
  /// Creates an [OidcLoginResult].
  const OidcLoginResult({
    required this.user,
    required this.deviceId,
    required this.psk,
  });

  /// The signed-in user.
  final User user;

  /// The minted device id.
  final String deviceId;

  /// The minted device credential (returned once).
  final String psk;
}

/// Optional OIDC login for teams that want SSO — never required.
///
/// Authorization-code + PKCE as a public client: `beginLogin` builds the
/// authorization URL (state + S256 challenge held server-side, single-use,
/// short-lived); `handleCallback` exchanges the code at the issuer's token
/// endpoint and provisions the user just-in-time. Claims are taken from the
/// token-endpoint response, which this server fetches directly from the
/// issuer over TLS — the browser never supplies them — so no local JWT
/// signature verification is repeated here.
///
/// JIT provisioning: users match by email (then handle); new users are
/// created and granted membership in every workspace at the role mapped from
/// the group claim (or the configured default). Existing memberships are
/// never downgraded.
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
    HttpClient? httpClient,
    DateTime Function()? now,
  }) : _users = users,
       _members = members,
       _workspaces = workspaces,
       _mintDevice = mintDevice,
       _http = httpClient ?? HttpClient(),
       _now = now ?? DateTime.now;

  /// The (possibly disabled) SSO configuration.
  final OidcConfig config;

  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final WorkspaceRepository _workspaces;
  final Future<({String deviceId, String psk})> Function(
    String userId,
    String label,
  )
  _mintDevice;
  final HttpClient _http;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  final _pending = <String, ({String verifier, DateTime expiresAt})>{};

  Uri? _authorizationEndpoint;
  Uri? _tokenEndpoint;

  /// Builds the issuer authorization URL for one login attempt.
  /// [redirectUri] is this server's `/oidc/callback`.
  Future<Uri> beginLogin({required Uri redirectUri}) async {
    if (!config.enabled) {
      throw const AuthException('SSO is not configured on this server');
    }
    await _discover();
    _evictExpired();
    final state = _randomToken();
    final verifier = _randomToken() + _randomToken();
    _pending[state] = (
      verifier: verifier,
      expiresAt: _now().add(const Duration(minutes: 10)),
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
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  /// Completes the login from the issuer's redirect back to
  /// `/oidc/callback?code=…&state=…`.
  Future<OidcLoginResult> handleCallback({
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
    final user = await _provisionUser(claims);
    await _ensureMemberships(user, claims);
    final device = await _mintDevice(user.id, 'SSO (${user.handle})');
    return OidcLoginResult(
      user: user,
      deviceId: device.deviceId,
      psk: device.psk,
    );
  }

  Future<void> _discover() async {
    if (_authorizationEndpoint != null && _tokenEndpoint != null) {
      return;
    }
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

  Future<Map<String, dynamic>> _exchangeCode({
    required String code,
    required String verifier,
    required Uri redirectUri,
  }) async {
    final request = await _http.postUrl(_tokenEndpoint!);
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
        },
      ).query,
    );
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw const AuthException('Login failed at the identity provider');
    }
    final decoded = jsonDecode(body);
    final idToken = decoded is Map ? decoded['id_token'] : null;
    if (idToken is! String) {
      throw const AuthException('Identity provider returned no identity');
    }
    return _decodeJwtClaims(idToken);
  }

  Future<User> _provisionUser(Map<String, dynamic> claims) async {
    final email = claims['email'] as String?;
    final handleClaim =
        (claims['preferred_username'] as String?) ??
        email?.split('@').first ??
        'sso-user';
    final displayName = (claims['name'] as String?) ?? handleClaim;

    final byEmail = email == null ? null : await _users.getByEmail(email);
    if (byEmail != null) {
      return byEmail;
    }
    final sanitized = _sanitizeHandle(handleClaim);
    final byHandle = await _users.getByHandle(sanitized);
    if (byHandle != null && email == null) {
      return byHandle;
    }
    var candidate = sanitized;
    var suffix = 1;
    while (await _users.getByHandle(candidate) != null) {
      suffix += 1;
      candidate = '$sanitized$suffix';
    }
    final user = User(
      id: _uuid.v4(),
      handle: candidate,
      displayName: displayName,
      email: email,
      createdAt: _now(),
    );
    await _users.upsert(user);
    return user;
  }

  Future<void> _ensureMemberships(
    User user,
    Map<String, dynamic> claims,
  ) async {
    // Security gate (PRD 14 §13 over-grant trap): in multi-tenant / consulting
    // setups, auto-granting every SSO user membership in every workspace
    // silently bypasses the per-workspace invite + per-repo grant model.
    // `none` provisions the user account but requires an explicit invite to
    // join any workspace.
    if (config.autoMemberMode == OidcAutoMemberMode.none) {
      return;
    }
    final role = _roleFor(claims);
    final workspaces = await _workspaces.watchAll().first;
    for (final workspace in workspaces) {
      if (workspace.isDeleted) {
        continue;
      }
      final existing = await _members.getMember(workspace.id, user.id);
      if (existing != null) {
        continue; // Never downgrade an existing membership.
      }
      await _members.upsert(
        WorkspaceMember(
          id: _uuid.v4(),
          workspaceId: workspace.id,
          userId: user.id,
          role: role,
          joinedAt: _now(),
        ),
      );
    }
  }

  WorkspaceRole _roleFor(Map<String, dynamic> claims) {
    final groups = claims[config.groupsClaim];
    if (groups is List) {
      WorkspaceRole? best;
      for (final group in groups.whereType<String>()) {
        final mapped = config.groupRoleMap[group];
        if (mapped != null && (best == null || mapped.rank > best.rank)) {
          best = mapped;
        }
      }
      if (best != null) {
        return best;
      }
    }
    return config.defaultRole;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final request = await _http.getUrl(uri);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw const AuthException('Issuer discovery failed');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Issuer discovery failed');
    }
    return decoded;
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

  void _evictExpired() {
    final now = _now();
    _pending.removeWhere((_, pending) => now.isAfter(pending.expiresAt));
  }

  static String _randomToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _sanitizeHandle(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_.-]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    return cleaned.isEmpty ? 'sso-user' : cleaned;
  }
}
