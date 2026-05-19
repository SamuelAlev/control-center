/// One authenticated device belonging to one user.
///
/// Pairing mints a durable per-device credential (stored in the server's
/// secret store, referenced by [credentialRef]); the row here is metadata
/// only. Users list/rename/revoke their own devices; admins can revoke any.
/// Revocation is live: open sessions for a revoked device are terminated
/// immediately, not on next reconnect.
class UserDevice {
  /// Creates a [UserDevice].
  UserDevice({
    required this.id,
    required this.userId,
    required this.platform,
    required this.credentialRef,
    required this.label,
    required this.createdAt,
    this.lastSeenAt,
    this.revokedAt,
  }) : assert(id.isNotEmpty, 'UserDevice id must not be empty'),
       assert(userId.isNotEmpty, 'UserDevice userId must not be empty'),
       assert(
         credentialRef.isNotEmpty,
         'UserDevice credentialRef must not be empty',
       );

  /// Unique identifier (the device id presented at connect).
  final String id;

  /// The user this device authenticates as.
  final String userId;

  /// Coarse platform tag: `desktop`, `web`, or `phone`.
  final String platform;

  /// Secret-store key holding the device credential (never the secret
  /// itself).
  final String credentialRef;

  /// User-editable display label ("Work laptop").
  final String label;

  /// When the device was paired.
  final DateTime createdAt;

  /// Last successful authentication, or null if never seen since pairing.
  final DateTime? lastSeenAt;

  /// When the device was revoked, or null while active.
  final DateTime? revokedAt;

  /// Whether this device may still authenticate.
  bool get isActive => revokedAt == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          platform == other.platform &&
          credentialRef == other.credentialRef &&
          label == other.label &&
          createdAt == other.createdAt &&
          lastSeenAt == other.lastSeenAt &&
          revokedAt == other.revokedAt;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    platform,
    credentialRef,
    label,
    createdAt,
    lastSeenAt,
    revokedAt,
  );

  /// Returns a copy with optional overrides.
  UserDevice copyWith({
    String? id,
    String? userId,
    String? platform,
    String? credentialRef,
    String? label,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    DateTime? revokedAt,
  }) {
    return UserDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      credentialRef: credentialRef ?? this.credentialRef,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      revokedAt: revokedAt ?? this.revokedAt,
    );
  }
}
