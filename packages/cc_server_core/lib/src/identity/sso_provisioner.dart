import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
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

  /// Preferred handle/username, when supplied (defaults from the email).
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
/// SAML joining): find-or-create the user by email (then handle), publish
/// `UserCreated` for new users and ensure workspace memberships under the
/// over-grant-trap gate.
///
/// Extracted verbatim from `OidcService` so both flavors stay
/// behavior-identical — the security review that approved the OIDC semantics
/// (never downgrade an existing membership; `autoMemberMode.none` provisions
/// the account but grants nothing) keeps covering SAML unchanged.
class SsoProvisioner {
  /// Creates a [SsoProvisioner].
  SsoProvisioner({
    required UserRepository users,
    required WorkspaceMembershipRepository members,
    required WorkspaceRepository workspaces,
    DomainEventBus? eventBus,
    DateTime Function()? now,
  }) : _users = users,
       _members = members,
       _workspaces = workspaces,
       _eventBus = eventBus,
       _now = now ?? DateTime.now;

  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final WorkspaceRepository _workspaces;
  final DomainEventBus? _eventBus;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  /// Finds the user by SSO subject (when the claims carry one), then email
  /// (then handle), creating one when nothing matches. Publishes
  /// `UserCreated` for new users and pins the provider's subject id onto
  /// the account at first login.
  ///
  /// Account-takeover guard: when a matched account is ALREADY pinned to a
  /// different subject OR a different issuer, the login is refused — subject
  /// ids are only unique per issuer, so a SAML NameID / OIDC sub / SCIM
  /// externalId that happens to collide across providers must never
  /// cross-link accounts and a reused or changed email at the provider must
  /// never take over a colleague's account. Match order:
  /// subject (immutable) → email → handle.
  ///
  /// When [policy] disallows JIT (`allowJit == false`), an identity with no
  /// existing account is refused — only pre-provisioned accounts (SCIM push,
  /// invite, or a previously pinned login) may sign in.
  Future<User> provisionUser(
    SsoClaims claims, {
    required SsoProvisioningPolicy policy,
  }) async {
    final email = claims.email;
    final handleClaim = claims.handle ?? email?.split('@').first ?? 'sso-user';
    final displayName = claims.displayName ?? handleClaim;

    User? matched;
    if (claims.ssoSubject != null && claims.ssoIssuer != null) {
      matched = await _users.getBySsoSubject(
        claims.ssoIssuer!,
        claims.ssoSubject!,
      );
    }
    matched ??= (email == null || !claims.emailVerified)
        ? null
        : await _users.getByEmail(email);
    // Handle matching is only safe on a vouched claim set. An UNVERIFIED
    // (or email-less) login must never match an existing account by its
    // self-asserted username: a co-resident IdP user who omits email and
    // sets `preferred_username` to a colleague's handle would otherwise
    // match, get pinned and take the account over — the same class as the
    // unverified-email takeover. SAML assertions are signed, so they always
    // carry the vouch; OIDC does not unless the issuer verified the email.
    matched ??= (email == null && claims.emailVerified)
        ? await _users.getByHandle(sanitizeHandle(handleClaim))
        : null;
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
      if (claims.ssoSubject != null &&
          claims.ssoIssuer != null &&
          matched.ssoSubject == null) {
        // First SSO login for an invited/bootstrap account: pin it.
        final pinned = matched.copyWith(
          ssoSubject: claims.ssoSubject,
          ssoIssuer: claims.ssoIssuer,
        );
        await _users.upsert(pinned);
        return pinned;
      }
      return matched;
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
    final sanitized = sanitizeHandle(handleClaim);
    var candidate = sanitized;
    var suffix = 1;
    while (await _users.getByHandle(candidate) != null) {
      suffix += 1;
      candidate = '$sanitized$suffix';
    }
    // An unverified email may seed a new account, but never SHADOW an
    // existing one: a duplicate row would make the real owner's later
    // verified login ambiguous (getByEmail cannot resolve two rows) and
    // deny them service. Drop the address — the claim set was not vouched
    // anyway.
    var seedEmail = email;
    if (email != null && !claims.emailVerified) {
      final owned = await _users.getByEmail(email);
      if (owned != null) {
        seedEmail = null;
      }
    }
    final user = User(
      id: _uuid.v4(),
      handle: candidate,
      displayName: displayName,
      email: seedEmail,
      ssoSubject: claims.ssoSubject,
      ssoIssuer: claims.ssoIssuer,
      createdAt: _now(),
    );
    await _users.upsert(user);
    return user;
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

  /// Lowercases and reduces a raw provider handle to `[a-z0-9_.-]`.
  static String sanitizeHandle(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_.-]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    return cleaned.isEmpty ? 'sso-user' : cleaned;
  }

  /// Accepts a `web-popup` flow's declared connect-tab origin, or null when
  /// it is unusable. The value arrives as an unauthenticated query parameter
  /// and is held server-side in a pending-login map for the login TTL, so it
  /// must be shape-checked and length-bounded before storage: an absolute
  /// `http`/`https` URL with a host, at most 2048 chars.
  ///
  /// The stored value is the CANONICAL origin (`scheme://host[:port]`),
  /// never the raw input: it crosses two different URL parsers (Dart's
  /// `Uri` in the allow-list check, WHATWG URL in the browser when it
  /// becomes a postMessage `targetOrigin`) and anything the two can read
  /// differently — backslashes, userinfo, odd encodings — is a
  /// parser-differential credential-leak waiting to happen. Canonicalizing
  /// makes both parsers see the identical string. Userinfo is rejected
  /// outright (it is never part of an origin) and paths/queries are
  /// dropped. The handoff still re-checks the value against the origin
  /// allow-list — this only stops junk (and multi-kilobyte strings) from
  /// being pinned into memory.
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
}
