import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/identity/identity_audit.dart';
import 'package:uuid/uuid.dart';

/// How SSO-authenticated members are auto-added to workspaces (shared by the
/// OIDC and SAML login paths; see `OidcAutoMemberMode` for the history).
enum SsoAutoMemberMode {
  /// Every authenticated SSO user is auto-added as a member. The right
  /// default for a single-team deployment where SSO = trust.
  all,

  /// No auto-membership: each user must be invited explicitly. The secure
  /// default for multi-tenant / consulting setups (the PRD 14 §13 over-grant
  /// trap).
  none,
}

/// The identity claims every SSO flavor (OIDC, SAML) maps onto before
/// provisioning — the shared shape that keeps both login paths byte-identical
/// in behavior.
class SsoClaims {
  /// Creates [SsoClaims].
  const SsoClaims({
    this.email,
    this.emailVerified = true,
    this.displayName,
    this.handle,
    this.groups = const [],
    this.ssoSubject,
    this.ssoIssuer,
  });

  /// The user's email, when the provider supplied one.
  final String? email;

  /// Whether the provider vouches for the email. A SAML assertion attribute
  /// is signed, so SAML always passes `true`; OIDC passes `true` only when
  /// the `email_verified` claim is explicitly `true` (RFC 9700: an absent
  /// flag is NOT a vouch — a self-service IdP that omits it must not get
  /// email-matching by default). An unverified email is never used to MATCH
  /// an existing account (it may still seed a new one) — otherwise a
  /// self-service IdP account asserting a colleague's address could take
  /// over their pre-provisioned account.
  final bool emailVerified;

  /// Display name, when supplied.
  final String? displayName;

  /// The IdP's username, when supplied: only a suggestion for a NEW
  /// account's username (the email's local part otherwise), never used to
  /// match an existing account.
  final String? handle;

  /// Group/role names for role mapping.
  final List<String> groups;

  /// The provider's immutable subject id (SAML NameID / persistent OIDC
  /// sub). SSO subject pinning consults this before email matching once the
  /// users table carries the SSO columns.
  final String? ssoSubject;

  /// The issuing provider's entity id / issuer.
  final String? ssoIssuer;
}

/// The workspace-membership policy shared by both SSO flavors.
class SsoProvisioningPolicy {
  /// Creates [SsoProvisioningPolicy].
  const SsoProvisioningPolicy({
    required this.defaultRole,
    required this.groupRoleMap,
    required this.autoMemberMode,
    this.allowJit = true,
  });

  /// Role granted when no group maps.
  final WorkspaceRole defaultRole;

  /// Group name → role.
  final Map<String, WorkspaceRole> groupRoleMap;

  /// Whether SSO users are auto-added to workspace memberships on login.
  final SsoAutoMemberMode autoMemberMode;

  /// Whether a login by an identity with NO existing account may provision
  /// one (just-in-time). When false, only identities matching a
  /// pre-provisioned account (SCIM-pushed, invited, or previously pinned)
  /// may log in. Persisted per connection (`sso_connections.allow_jit`),
  /// editable in the settings UI — it MUST be enforced at provisioning time,
  /// not merely stored.
  final bool allowJit;

  /// The strongest role any of [groups] maps to, else [defaultRole].
  WorkspaceRole roleFor(List<String> groups) {
    WorkspaceRole? best;
    for (final group in groups) {
      final mapped = groupRoleMap[group];
      if (mapped != null && (best == null || mapped.rank > best.rank)) {
        best = mapped;
      }
    }
    return best ?? defaultRole;
  }
}

/// Shared just-in-time provisioning for every SSO login path (OIDC today,
/// SAML joining): find-or-create the user by SSO subject, then verified
/// email, and ensure workspace memberships under the over-grant-trap gate.
///
/// Extracted verbatim from `OidcService` so both flavors stay
/// behavior-identical — the security review that approved the OIDC semantics
/// (never downgrade an existing membership; `autoMemberMode.none` provisions
/// the account but grants nothing) keeps covering SAML unchanged.
class SsoProvisioner {
  /// Creates a [SsoProvisioner].
  SsoProvisioner({
    required this._users,
    required this._members,
    required this._workspaces,
    this._eventBus,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final WorkspaceRepository _workspaces;
  final DomainEventBus? _eventBus;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  /// Resolve/create user by SSO subject → vouched email; pin subject at
  /// first login. Refuse if account already pinned to a different
  /// subject/issuer. No JIT when `allowJit` is false.
  ///
  /// An email identifies an account only when both ends vouch for it: the
  /// provider's claim says it is verified, and the account's address was put
  /// there by a provider or the server owner ([User.emailVerified]). An
  /// address a person typed about themselves (profile, invite) never
  /// matches, so it can never receive someone else's login, subject pin or
  /// group-derived memberships.
  ///
  /// Never matches by username: people choose their own, so a username an
  /// IdP asserts says nothing about which account it is. It is only the
  /// suggestion for a new account's name.
  Future<User> provisionUser(
    SsoClaims claims, {
    required SsoProvisioningPolicy policy,
  }) async {
    final email = claims.email;
    final vouched = email != null && email.isNotEmpty && claims.emailVerified;

    User? matched;
    if (claims.ssoSubject != null && claims.ssoIssuer != null) {
      matched = await _users.getBySsoSubject(
        claims.ssoIssuer!,
        claims.ssoSubject!,
      );
    }
    matched ??= vouched ? await _users.getByVerifiedEmail(email) : null;
    if (matched != null) {
      if (matched.deactivatedAt != null) {
        // SCIM-deprovisioned accounts never log back in, whatever the IdP
        // says; reactivation is an explicit SCIM/admin action.
        throw const AuthException('This account has been deactivated');
      }
      final pinnedToOther =
          claims.ssoSubject != null &&
          matched.ssoSubject != null &&
          (matched.ssoSubject != claims.ssoSubject ||
              (matched.ssoIssuer != null &&
                  claims.ssoIssuer != null &&
                  matched.ssoIssuer != claims.ssoIssuer));
      if (pinnedToOther) {
        throw const AuthException(
          'This account is already linked to a different SSO identity',
        );
      }
      var updated = matched;
      if (claims.ssoSubject != null &&
          claims.ssoIssuer != null &&
          matched.ssoSubject == null) {
        // First SSO login for an invited/bootstrap account: pin it.
        updated = updated.copyWith(
          ssoSubject: claims.ssoSubject,
          ssoIssuer: claims.ssoIssuer,
        );
      }
      if (vouched &&
          updated.email == normalizeEmail(email) &&
          !updated.emailVerified) {
        // The provider now stands behind the address this account holds.
        updated = updated.copyWith(emailVerified: true);
      }
      if (updated != matched) {
        await _users.upsert(updated);
      }
      return updated;
    }
    if (!policy.allowJit) {
      // JIT disabled by the admin: unknown identities are refused outright —
      // only pre-provisioned accounts (SCIM push, invite, prior pin) may log
      // in. Fail closed with no oracle about which emails exist.
      throw const AuthException(
        'This identity has no account on this server — ask an admin to '
        'provision or invite you first',
      );
    }
    final id = _uuid.v4();
    final seedEmail = await claimEmailFor(
      _users,
      userId: id,
      email: email,
      vouched: vouched,
    );
    // The IdP's username (else the email's local part) is only the
    // suggestion; the person picks their own in onboarding's first step.
    final suggested = Username.fromFreeText(
      claims.handle ?? email ?? '',
      fallback: 'member',
    );
    final displayName = claims.displayName?.trim() ?? '';
    return _users.insertWithFreeHandle(
      User(
        id: id,
        handle: suggested.value,
        displayName: displayName.isNotEmpty ? displayName : suggested.value,
        email: seedEmail,
        emailVerified: vouched && seedEmail != null,
        ssoSubject: claims.ssoSubject,
        ssoIssuer: claims.ssoIssuer,
        createdAt: _now(),
      ),
    );
  }

  /// Ensures memberships per [policy]. Security gate (PRD 14 §13 over-grant
  /// trap): in multi-tenant / consulting setups, auto-granting every SSO
  /// user membership in every workspace silently bypasses the per-workspace
  /// invite + per-repo grant model — `autoMemberMode.none` provisions the
  /// account but requires an explicit invite to join any workspace.
  Future<void> ensureMemberships(
    User user,
    SsoClaims claims,
    SsoProvisioningPolicy policy,
  ) async {
    if (policy.autoMemberMode == SsoAutoMemberMode.none) {
      return;
    }
    final role = policy.roleFor(claims.groups);
    final workspaces = await _workspaces.watchAll().first;
    for (final workspace in workspaces) {
      if (workspace.isDeleted) {
        continue;
      }
      final existing = await _members.getMember(workspace.id, user.id);
      if (existing != null) {
        continue; // Never downgrade an existing membership.
      }
      final joinedAt = _now();
      await _members.upsert(
        WorkspaceMember(
          id: _uuid.v4(),
          workspaceId: workspace.id,
          userId: user.id,
          role: role,
          joinedAt: joinedAt,
        ),
      );
      // Sessions are live at SSO login time (unlike the boot-time backfill),
      // and the event forwarder caches its per-workspace membership verdict
      // until one of these arrives — without it a just-provisioned member is
      // deaf to the workspace until the next reconnect.
      _eventBus?.publish(
        WorkspaceMemberAdded(
          workspaceId: workspace.id,
          userId: user.id,
          role: role,
          occurredAt: joinedAt,
        ),
      );
    }
  }

  /// Accept a web-popup connect-tab origin, or null if unusable.
  /// Canonicalize to `scheme://host[:port]` (≤2048, http/https, no userinfo) before storing;
  /// handoff still re-checks the origin allow-list.
  static String? sanitizeClientOrigin(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > 2048) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    // IPv6 literals lose their brackets in `Uri.host`; restore them so the
    // rebuilt origin reparses identically.
    final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://$host$port';
  }
}

/// The outcome of a completed SSO login (shared by OIDC and SAML): the
/// (possibly JIT-provisioned) user and the freshly minted device credential
/// the browser hands to the client.
class SsoLoginResult {
  /// Creates a [SsoLoginResult].
  const SsoLoginResult({
    required this.user,
    required this.deviceId,
    required this.psk,
    this.groups = const [],
    this.clientOrigin,
    this.recipientPublicKey,
  });

  /// The signed-in user.
  final User user;

  /// The minted device id.
  final String deviceId;

  /// The minted device credential (returned once).
  final String psk;

  /// The groups the provider asserted (for audit logging).
  final List<String> groups;

  /// The browser origin of the connect tab that started a `web-popup`
  /// login (declared at login start, held server-side in the pending
  /// tracker, validated against the server's origin allow-list at handoff).
  /// Null for the same-tab and desktop flows.
  final String? clientOrigin;

  /// Public key of the client that initiated this login. Never trust an
  /// unsealed device credential to a browser completion page.
  final String? recipientPublicKey;
}

/// The address a NEW account [userId] may hold, given that its identity
/// provider asserted [email] ([vouched] when it stands behind it).
///
/// Only one account holds a vouched address. A vouched identity takes the
/// address from the accounts that merely typed it (each is cleared and
/// audited by user id). It never takes one another account holds vouched
/// (a caller that may match that account has already done so), and an
/// unvouched identity never shadows any holder: either way the new account
/// gets no address.
Future<String?> claimEmailFor(
  UserRepository users, {
  required String userId,
  required String? email,
  required bool vouched,
}) async {
  if (email == null || email.isEmpty) {
    return null;
  }
  final holders = await users.getAllByEmail(email);
  if (!vouched) {
    return holders.isEmpty ? email : null;
  }
  if (holders.any((holder) => holder.emailVerified)) {
    return null;
  }
  for (final holder in holders) {
    await users.upsert(holder.copyWith(removeEmail: true));
    identityAudit(IdentityAuditEvent.unvouchedEmailCleared, {
      'user_id': userId,
      'holder_user_id': holder.id,
    });
  }
  return email;
}
