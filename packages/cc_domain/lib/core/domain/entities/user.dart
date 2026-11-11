import 'package:cc_domain/core/domain/value_objects/username.dart';

/// The one form of an email address the server stores and compares: trimmed
/// and lowercased, so case variants of one mailbox are one address.
String normalizeEmail(String email) => email.trim().toLowerCase();

/// A human user of this server.
///
/// Users are global (like repos): identity is server-wide, while *membership*
/// is workspace-scoped (`WorkspaceMember`). The first user minted on a fresh
/// server is the owner; further users arrive through invites or OIDC.
class User {
  /// Creates a [User].
  User({
    required this.id,
    required this.handle,
    required this.displayName,
    String? email,
    this.emailVerified = false,
    this.avatarRef,
    this.gitAuthorName,
    this.gitAuthorEmail,
    this.ssoSubject,
    this.ssoIssuer,
    this.deactivatedAt,
    this.onboardingFinishedAt,
    required this.createdAt,
  }) : email = email == null ? null : normalizeEmail(email) {
    if (id.isEmpty) {
      throw ArgumentError('User id must not be empty');
    }
    if (!Username.isValid(handle)) {
      throw ArgumentError.value(handle, 'handle', 'is not a valid username');
    }
    if (displayName.isEmpty) {
      throw ArgumentError('User displayName must not be empty');
    }
    final stored = this.email;
    if (emailVerified && (stored == null || stored.isEmpty)) {
      throw ArgumentError('Only an email address can be vouched for');
    }
  }

  /// Unique identifier.
  final String id;

  /// The person's username: unique, chosen by them, valid by [Username]
  /// (the UI calls it "Username"; the wire and storage keep `handle`).
  /// Mentions resolve against it.
  final String handle;

  /// Display name shown across the UI.
  final String displayName;

  /// Optional email address (invites work without one), as [normalizeEmail]
  /// leaves it. The person may set it themselves, so on its own it proves
  /// nothing: see [emailVerified].
  final String? email;

  /// Whether [email] was put there by someone the server trusts to vouch for
  /// it: the identity provider (an SSO login whose `email_verified` claim is
  /// true, a SCIM push) or the server owner (their own address, or
  /// `users.vouchEmail`). Only a vouched address matches an SSO login or a
  /// SCIM push to this account; a self-set or invite-typed one never does.
  /// Any write of a different address clears it unless the writer vouches.
  final bool emailVerified;

  /// Optional avatar reference (server media ref or remote URL).
  final String? avatarRef;

  /// Git author name used when the server commits on this user's behalf.
  /// Falls back to [displayName] when unset.
  final String? gitAuthorName;

  /// Git author email used when the server commits on this user's behalf.
  /// Falls back to a handle-derived noreply address when unset.
  final String? gitAuthorEmail;

  /// The SSO provider's immutable subject id for this user (SAML NameID /
  /// SCIM externalId), when they arrived via SSO or SCIM provisioning.
  /// Pinned together with [ssoIssuer] so a later email change at the
  /// provider (or a reused email by a different person) cannot silently
  /// take over the account: subject match wins over email match.
  final String? ssoSubject;

  /// The issuer whose [ssoSubject] this is (IdP entity id, or a SCIM
  /// namespace). Null when the user is not SSO-pinned.
  final String? ssoIssuer;

  /// When SCIM deprovisioning disabled the account (null = active). A
  /// deactivated user keeps attribution but cannot log in, holds no devices,
  /// and belongs to no workspace.
  final DateTime? deactivatedAt;

  /// When this user finished first-run setup (null = never has).
  ///
  /// A fact about the PERSON, which is why it lives on the identity and not in
  /// the synced preference lane: preferences are promoted to the server from
  /// whichever device wrote them first, so a machine that had onboarded once
  /// could mark a brand-new account as already set up. See [hasOnboarded] for
  /// the question callers actually ask.
  final DateTime? onboardingFinishedAt;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Whether this user has ever finished first-run setup.
  ///
  /// Distinguishes "their forge credential lapsed, ask them to sign in again"
  /// from "they have never been set up, run the first-run flow". Deriving that
  /// from "they belong to a workspace" is wrong for an invited member, who has
  /// a workspace they never created and has never onboarded.
  bool get hasOnboarded => onboardingFinishedAt != null;

  /// The git author name to stamp on commits made for this user.
  String get effectiveGitAuthorName =>
      (gitAuthorName?.isNotEmpty ?? false) ? gitAuthorName! : displayName;

  /// The git author email to stamp on commits made for this user.
  String get effectiveGitAuthorEmail => (gitAuthorEmail?.isNotEmpty ?? false)
      ? gitAuthorEmail!
      : '$handle@users.noreply.local';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          handle == other.handle &&
          displayName == other.displayName &&
          email == other.email &&
          emailVerified == other.emailVerified &&
          avatarRef == other.avatarRef &&
          gitAuthorName == other.gitAuthorName &&
          gitAuthorEmail == other.gitAuthorEmail &&
          ssoSubject == other.ssoSubject &&
          ssoIssuer == other.ssoIssuer &&
          deactivatedAt == other.deactivatedAt &&
          onboardingFinishedAt == other.onboardingFinishedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    handle,
    displayName,
    email,
    emailVerified,
    avatarRef,
    gitAuthorName,
    gitAuthorEmail,
    ssoSubject,
    ssoIssuer,
    deactivatedAt,
    onboardingFinishedAt,
    createdAt,
  );

  /// Returns a copy with optional overrides.
  ///
  /// A different (or removed) [email] is not vouched unless [emailVerified]
  /// says so; the same address keeps its standing.
  User copyWith({
    String? id,
    String? handle,
    String? displayName,
    String? email,
    bool removeEmail = false,
    bool? emailVerified,
    String? avatarRef,
    bool removeAvatarRef = false,
    String? gitAuthorName,
    bool removeGitAuthorName = false,
    String? gitAuthorEmail,
    bool removeGitAuthorEmail = false,
    String? ssoSubject,
    bool removeSsoSubject = false,
    String? ssoIssuer,
    bool removeSsoIssuer = false,
    DateTime? deactivatedAt,
    bool reactivate = false,
    DateTime? onboardingFinishedAt,
    DateTime? createdAt,
  }) {
    final nextEmail = removeEmail
        ? null
        : (email == null ? this.email : normalizeEmail(email));
    return User(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      email: nextEmail,
      emailVerified:
          emailVerified ?? (nextEmail == this.email && this.emailVerified),
      avatarRef: removeAvatarRef ? null : (avatarRef ?? this.avatarRef),
      gitAuthorName: removeGitAuthorName
          ? null
          : (gitAuthorName ?? this.gitAuthorName),
      gitAuthorEmail: removeGitAuthorEmail
          ? null
          : (gitAuthorEmail ?? this.gitAuthorEmail),
      ssoSubject: removeSsoSubject ? null : (ssoSubject ?? this.ssoSubject),
      ssoIssuer: removeSsoIssuer ? null : (ssoIssuer ?? this.ssoIssuer),
      deactivatedAt: reactivate ? null : (deactivatedAt ?? this.deactivatedAt),
      // No `remove` flag: the flag is monotonic, so there is deliberately no
      // way to un-onboard someone through a copy.
      onboardingFinishedAt: onboardingFinishedAt ?? this.onboardingFinishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
