/// One append-only audit record: which human did what, where.
///
/// Workspace-scoped accountability trail behind the activity surfaces and
/// presence. Rows are written at the op chokepoint for every mutating call
/// and pruned by the retention service; they are never updated.
class UserActivityEntry {
  /// Creates a [UserActivityEntry].
  UserActivityEntry({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.action,
    this.targetType,
    this.targetId,
    this.deviceId,
    this.ip,
    this.countryCode,
    this.details,
    required this.createdAt,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('UserActivityEntry id must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('UserActivityEntry workspaceId must not be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('UserActivityEntry userId must not be empty');
    }
    if (action.isEmpty) {
      throw ArgumentError('UserActivityEntry action must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// The workspace the action happened in.
  final String workspaceId;

  /// The human who performed the action.
  final String userId;

  /// What happened — the op name (`ticket.upsert`) or a semantic action
  /// (`member.role_changed`).
  final String action;

  /// Kind of entity acted on (`ticket`, `space`, `member`…), when known.
  final String? targetType;

  /// Id of the entity acted on, when known.
  final String? targetId;

  /// The device the action came from, when known.
  final String? deviceId;

  /// The client IP the session observed for the call, when known (the
  /// server's view: loopback for local sockets, the tunnel/relay endpoint for
  /// relayed sessions).
  final String? ip;

  /// ISO 3166-1 alpha-2 country code resolved from [ip] at record time
  /// (uppercase), when resolvable. Null for private/loopback addresses,
  /// unknown IPs and rows recorded before geo resolution existed.
  final String? countryCode;

  /// Sanitized snapshot of the mutation's arguments (and a few contextual
  /// result fields): which setting, which value, which rig, which space.
  /// Null on rows recorded before details existed, or when nothing useful
  /// survived redaction.
  final Map<String, Object?>? details;

  /// When the action happened.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserActivityEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          userId == other.userId &&
          action == other.action &&
          targetType == other.targetType &&
          targetId == other.targetId &&
          deviceId == other.deviceId &&
          ip == other.ip &&
          countryCode == other.countryCode &&
          _mapEquals(details, other.details) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    userId,
    action,
    targetType,
    targetId,
    deviceId,
    ip,
    countryCode,
    details == null ? null : Object.hashAll(details!.entries),
    createdAt,
  );
}

bool _mapEquals(Map<String, Object?>? a, Map<String, Object?>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
