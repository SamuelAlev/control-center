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
    this.email,
    this.avatarRef,
    this.gitAuthorName,
    this.gitAuthorEmail,
    required this.createdAt,
  }) : assert(id.isNotEmpty, 'User id must not be empty'),
       assert(handle.isNotEmpty, 'User handle must not be empty'),
       assert(displayName.isNotEmpty, 'User displayName must not be empty');

  /// Unique identifier.
  final String id;

  /// Unique short handle (mention name, git-less identifier).
  final String handle;

  /// Display name shown across the UI.
  final String displayName;

  /// Optional email address (invites work without one).
  final String? email;

  /// Optional avatar reference (server media ref or remote URL).
  final String? avatarRef;

  /// Git author name used when the server commits on this user's behalf.
  /// Falls back to [displayName] when unset.
  final String? gitAuthorName;

  /// Git author email used when the server commits on this user's behalf.
  /// Falls back to a handle-derived noreply address when unset.
  final String? gitAuthorEmail;

  /// Creation timestamp.
  final DateTime createdAt;

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
          avatarRef == other.avatarRef &&
          gitAuthorName == other.gitAuthorName &&
          gitAuthorEmail == other.gitAuthorEmail &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    handle,
    displayName,
    email,
    avatarRef,
    gitAuthorName,
    gitAuthorEmail,
    createdAt,
  );

  /// Returns a copy with optional overrides.
  User copyWith({
    String? id,
    String? handle,
    String? displayName,
    String? email,
    bool removeEmail = false,
    String? avatarRef,
    bool removeAvatarRef = false,
    String? gitAuthorName,
    bool removeGitAuthorName = false,
    String? gitAuthorEmail,
    bool removeGitAuthorEmail = false,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      email: removeEmail ? null : (email ?? this.email),
      avatarRef: removeAvatarRef ? null : (avatarRef ?? this.avatarRef),
      gitAuthorName: removeGitAuthorName
          ? null
          : (gitAuthorName ?? this.gitAuthorName),
      gitAuthorEmail: removeGitAuthorEmail
          ? null
          : (gitAuthorEmail ?? this.gitAuthorEmail),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
