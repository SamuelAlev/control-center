import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/sso_provisioner.dart';
import 'package:uuid/uuid.dart';

/// A SCIM 2.0 (RFC 7644) provisioning endpoint for the IdP to push users
/// into this server and, critically, to DEPROVISION them (`active: false`).
///
/// Auth: a single bearer token (constant-time compared; regenerate via the
/// server's `sso.scimRegenerateToken` op) — SCIM has no concept of
/// per-request users, one secret gates the whole surface, exactly like the
/// webhook tokens. The endpoint must be reachable BY THE IdP directly:
/// behind NAT that means the tunnel origin (`bulkHttpBase`) or a public URL
/// — the WebSocket relay cannot carry HTTP callbacks. JIT provisioning
/// works without any of this; SCIM is the lifecycle half.
///
/// Coverage is deliberately the subset Okta's provisioning integration
/// exercises: Users CRUD (create / get / list+filter / PUT / PATCH with the
/// `active` flag), plus read-only Group stubs (group→role mapping happens at
/// LOGIN from the SAML/OIDC group attributes, not from pushed groups).
class ScimService {
  /// Creates a [ScimService].
  ScimService({
    required Future<bool> Function(String presented) verifyScimToken,
    required UserRepository users,
    required WorkspaceMembershipRepository members,
    required PairedDeviceDao devices,
    required FileSecretsStore secrets,
    DomainEventBus? eventBus,
    DateTime Function()? now,
  }) : _verifyScimToken = verifyScimToken,
       _users = users,
       _members = members,
       _devices = devices,
       _secrets = secrets,
       _eventBus = eventBus,
       _now = now ?? DateTime.now;

  /// The issuer namespace pinned onto SCIM-provisioned users' subject ids.
  static const scimIssuer = 'scim';

  final Future<bool> Function(String presented) _verifyScimToken;
  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final PairedDeviceDao _devices;
  final FileSecretsStore _secrets;
  final DomainEventBus? _eventBus;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  /// Handles a routed SCIM request; returns `(status, body)` with RFC 7644
  /// error shapes. Throws nothing — every failure maps onto a SCIM error.
  Future<({int status, Map<String, Object?> body})> handle({
    required String method,
    required List<String> segments,
    required Map<String, String> query,
    String? body,
  }) async {
    // segments: ['scim', 'v2', 'Users', id?] / ['scim', 'v2', 'Groups', ...]
    final resource = segments.length > 2 ? segments[2] : '';
    final id = segments.length > 3 ? segments[3] : null;
    try {
      if (resource == 'Users') {
        if (id == null || id.isEmpty) {
          return switch (method) {
            'POST' => await _createUser(_decodeBody(body)),
            'GET' => await _list(query),
            _ => _error(405, 'Method not allowed'),
          };
        }
        return switch (method) {
          'GET' => await _get(id),
          'PUT' => await _replace(id, _decodeBody(body)),
          'PATCH' => await _patch(id, _decodeBody(body)),
          'DELETE' => await _deactivate(id),
          _ => _error(405, 'Method not allowed'),
        };
      }
      if (resource == 'Groups') {
        if (method != 'GET') {
          return _error(
            501,
            'Group push is not supported; map groups to roles at login via '
            'the SAML/OIDC group attributes instead',
          );
        }
        return (
          status: 200,
          body: _listResponse(const <Map<String, Object?>>[]),
        );
      }
      if (resource == 'ServiceProviderConfig' && method == 'GET') {
        return (status: 200, body: _providerConfig());
      }
      return _error(404, 'Resource not found');
    } on AuthException catch (e) {
      return _error(400, e.message);
    } on FormatException catch (e) {
      return _error(400, e.message);
    } on Object {
      // The raw error can carry internal detail (stack fragments, paths) —
      // log-worthy server-side, never part of the HTTP response even to the
      // token-holding IdP.
      return _error(500, 'Internal error');
    }
  }

  /// Whether the presented bearer token matches the generated one.
  Future<bool> authorize(String? authorizationHeader) async {
    if (authorizationHeader == null) {
      return false;
    }
    final presented = authorizationHeader.startsWith('Bearer ')
        ? authorizationHeader.substring(7).trim()
        : '';
    if (presented.isEmpty) {
      return false;
    }
    return _verifyScimToken(presented);
  }

  // ── Users ────────────────────────────────────────────────────────────────

  Future<({int status, Map<String, Object?> body})> _list(
    Map<String, String> query,
  ) async {
    final all = (await _users.getAll()).where(_isScimVisible).toList();
    final filter = query['filter'] ?? '';
    String? userName;
    String? externalId;
    final userNameMatch = RegExp(
      'userName\\s+eq\\s+"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(filter);
    if (userNameMatch != null) {
      userName = userNameMatch.group(1)!.toLowerCase();
    }
    final externalIdMatch = RegExp(
      'externalId\\s+eq\\s+"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(filter);
    if (externalIdMatch != null) {
      externalId = externalIdMatch.group(1)!.toLowerCase();
    }
    var filtered = all;
    if (userName != null) {
      filtered = filtered
          .where((u) => (u.email ?? u.handle).toLowerCase() == userName)
          .toList();
    }
    if (externalId != null) {
      filtered = filtered
          .where((u) => (u.ssoSubject ?? '').toLowerCase() == externalId)
          .toList();
    }
    // Pagination (RFC 7644 §3.4.2.4); 1-based startIndex.
    final startIndex = (int.tryParse(query['startIndex'] ?? '') ?? 1) - 1;
    final count = int.tryParse(query['count'] ?? '') ?? filtered.length;
    final page = filtered
        .skip(startIndex.clamp(0, filtered.length))
        .take(count.clamp(0, 200))
        .toList();
    return (
      status: 200,
      body: _listResponse([for (final u in page) _userJson(u)]),
    );
  }

  Future<({int status, Map<String, Object?> body})> _get(String id) async {
    final user = await _users.getById(id);
    if (user == null || !_isScimVisible(user)) {
      return _error(404, 'User not found');
    }
    return (status: 200, body: _userJson(user));
  }

  Future<({int status, Map<String, Object?> body})> _createUser(
    Map<String, dynamic> body,
  ) async {
    final email = _userNameOf(body);
    final displayName =
        _displayNameOf(body) ?? (email?.split('@').first ?? 'scim-user');
    final externalId = body['externalId'] as String?;
    final active = body['active'] as bool? ?? true;

    var matched = externalId == null
        ? null
        : await _users.getBySsoSubject(scimIssuer, externalId);
    // Match by email only among SSO-managed accounts: a bare email collision
    // must never let a SCIM push adopt (and then modify or deactivate) a
    // local/bootstrap account the IdP does not own.
    if (matched == null && email != null) {
      final byEmail = await _users.getByEmail(email);
      if (byEmail != null && _isScimVisible(byEmail)) {
        matched = byEmail;
      }
    }
    if (matched != null && matched.deactivatedAt != null && active) {
      // Reactivation: restore the account; memberships are NOT re-granted
      // (explicit re-invite, or the next login's auto-member policy).
      final reactivated = matched.copyWith(reactivate: true);
      await _users.upsert(reactivated);
      return (status: 200, body: _userJson(reactivated));
    }
    var created = false;
    if (matched == null) {
      final user = User(
        id: _uuid.v4(),
        handle: await _uniqueHandleFor(email ?? 'scim-user'),
        displayName: displayName,
        email: email,
        ssoSubject: externalId,
        // Always mark the account SCIM-managed (even without an externalId) so
        // it stays in [_isScimVisible] scope and is never confused with a
        // locally-provisioned account.
        ssoIssuer: scimIssuer,
        createdAt: _now(),
      );
      await _users.upsert(user);
      _eventBus?.publish(UserCreated(userId: user.id, occurredAt: _now()));
      matched = user;
      created = true;
    }
    if (!active && matched.deactivatedAt == null) {
      matched = await _deactivateUser(matched);
      await _users.upsert(matched);
    }
    // 201 for a fresh account, 200 for an idempotent re-push of a known one.
    return (status: created ? 201 : 200, body: _userJson(matched));
  }

  Future<({int status, Map<String, Object?> body})> _replace(
    String id,
    Map<String, dynamic> body,
  ) async {
    final user = await _users.getById(id);
    if (user == null || !_isScimVisible(user)) {
      return _error(404, 'User not found');
    }
    final active = body['active'] as bool? ?? true;
    var updated = user.copyWith(
      displayName: _displayNameOf(body) ?? user.displayName,
      email: _userNameOf(body) ?? user.email,
    );
    if (active && updated.deactivatedAt != null) {
      updated = updated.copyWith(reactivate: true);
    } else if (!active && updated.deactivatedAt == null) {
      updated = await _deactivateUser(updated);
    }
    await _users.upsert(updated);
    return (status: 200, body: _userJson(updated));
  }

  Future<({int status, Map<String, Object?> body})> _patch(
    String id,
    Map<String, dynamic> body,
  ) async {
    // RFC 7644 §3.5.2: the only op IdPs reliably send us is
    // `replace active` (deactivate on offboarding).
    final user = await _users.getById(id);
    if (user == null || !_isScimVisible(user)) {
      return _error(404, 'User not found');
    }
    final operations = body['Operations'];
    var active = user.deactivatedAt == null;
    var handled = false;
    if (operations is List) {
      for (final op in operations) {
        if (op is! Map) {
          continue;
        }
        final path = '${op['path'] ?? ''}';
        final value = op['value'];
        if (op['op']?.toString().toLowerCase() == 'replace' &&
            (path == 'active' || value is Map && value.containsKey('active'))) {
          active = value is Map ? value['active'] == true : value == true;
          handled = true;
        }
      }
    }
    if (!handled) {
      return _error(400, 'Only "replace active" patches are supported');
    }
    var updated = user;
    if (active && user.deactivatedAt != null) {
      updated = user.copyWith(reactivate: true);
    } else if (!active && user.deactivatedAt == null) {
      updated = await _deactivateUser(user);
    }
    await _users.upsert(updated);
    return (status: 200, body: _userJson(updated));
  }

  Future<({int status, Map<String, Object?> body})> _deactivate(
    String id,
  ) async {
    final user = await _users.getById(id);
    if (user == null || !_isScimVisible(user)) {
      return _error(404, 'User not found');
    }
    if (user.deactivatedAt == null) {
      final deactivated = await _deactivateUser(user);
      await _users.upsert(deactivated);
    }
    // DELETE is a deactivation, not a row removal: attribution is permanent.
    return (status: 204, body: <String, Object?>{});
  }

  /// The deprovision lifecycle: stamp the account, revoke every device
  /// credential (PSK deleted FIRST, fail closed — the pairing.revoke rule),
  /// and drop every workspace membership. The existing device watch makes
  /// session termination live within seconds.
  Future<User> _deactivateUser(User user) async {
    // Never let the IdP's SCIM token deprovision a workspace owner: stripping
    // the owner's memberships + device credentials would lock the server's
    // controller out (and SSO group mappings can never grant owner, so a
    // legitimate SCIM-managed user is never one). Ownership must be transferred
    // by an admin first. Throws → mapped to a SCIM error by `handle`.
    final memberships = await _members.getForUser(user.id);
    if (memberships.any((m) => m.role == WorkspaceRole.owner)) {
      throw const AuthException(
        'Refusing to deprovision a workspace owner via SCIM; transfer '
        'ownership first',
      );
    }
    final devices = await _devices.getForUser(user.id);
    for (final device in devices) {
      await _secrets.deletePsk(device.id);
      await _devices.remove(device.id);
      _eventBus?.publish(
        UserDeviceRevoked(
          userId: user.id,
          deviceId: device.id,
          occurredAt: _now(),
        ),
      );
    }
    for (final membership in memberships) {
      await _members.remove(membership.workspaceId, user.id);
      _eventBus?.publish(
        WorkspaceMemberRemoved(
          workspaceId: membership.workspaceId,
          userId: user.id,
          occurredAt: _now(),
        ),
      );
    }
    return user.copyWith(deactivatedAt: _now());
  }

  // ── Wire shapes ──────────────────────────────────────────────────────────

  Map<String, Object?> _userJson(User user) => {
    'schemas': ['urn:ietf:params:scim:schemas:core:2.0:User'],
    'id': user.id,
    'externalId': user.ssoIssuer == scimIssuer ? user.ssoSubject : null,
    'userName': user.email ?? user.handle,
    'name': {'formatted': user.displayName},
    'displayName': user.displayName,
    'active': user.deactivatedAt == null,
    'emails': user.email == null
        ? const <Object>[]
        : [
            {'primary': true, 'value': user.email},
          ],
    'meta': {'resourceType': 'User'},
  };

  Map<String, Object?> _listResponse(List<Map<String, Object?>> resources) => {
    'schemas': ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
    'totalResults': resources.length,
    'startIndex': 1,
    'itemsPerPage': resources.length,
    'Resources': resources,
  };

  Map<String, Object?> _providerConfig() => {
    'schemas': ['urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'],
    'patch': {'supported': true},
    'bulk': {'supported': false, 'maxOperations': 0, 'maxPayloadSize': 0},
    'filter': {'supported': true, 'maxResults': 200},
    'changePassword': {'supported': false},
    'sort': {'supported': false},
    'etag': {'supported': false},
    'authenticationSchemes': [
      {
        'type': 'oauthbearertoken',
        'name': 'OAuth Bearer Token',
        'description': 'Authentication scheme using the Bearer token',
      },
    ],
  };

  ({int status, Map<String, Object?> body}) _error(int status, String detail) =>
      (
        status: status,
        body: {
          'schemas': ['urn:ietf:params:scim:api:messages:2.0:Error'],
          'status': '$status',
          'detail': detail,
        },
      );

  /// Whether the SCIM surface may see and act on [user]. Only SSO/SCIM-managed
  /// accounts (those carrying an [User.ssoIssuer]) are in scope — the IdP's
  /// bearer token must NOT enumerate or deprovision locally-provisioned
  /// accounts (the bootstrap owner, manually-paired users), which the IdP
  /// never created and does not own. SCIM-created users are always stamped
  /// with the [scimIssuer], so they always qualify.
  bool _isScimVisible(User user) => user.ssoIssuer != null;

  /// Decodes the request body; an absent body is an empty map, a malformed
  /// one is a 400.
  Map<String, dynamic> _decodeBody(String? body) {
    if (body == null || body.trim().isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('body must be a JSON object');
    }
    return decoded;
  }

  String? _userNameOf(Map<String, dynamic> body) {
    final raw = body['userName'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    final emails = body['emails'];
    if (emails is List) {
      for (final email in emails) {
        if (email is Map && email['value'] is String) {
          return email['value'] as String;
        }
      }
    }
    return null;
  }

  String? _displayNameOf(Map<String, dynamic> body) {
    final name = body['name'];
    if (name is Map && name['formatted'] is String) {
      return name['formatted'] as String;
    }
    final raw = body['displayName'];
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  Future<String> _uniqueHandleFor(String seed) async {
    final base = SsoProvisioner.sanitizeHandle(seed.split('@').first);
    var candidate = base;
    var suffix = 1;
    while (await _users.getByHandle(candidate) != null) {
      suffix += 1;
      candidate = '$base$suffix';
    }
    return candidate;
  }
}
