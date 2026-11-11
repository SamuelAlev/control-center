/// How an audited call ended. Workspace records are written only for calls
/// that returned, so they are always [ok].
enum AuditOutcome {
  /// The handler ran and returned.
  ok,

  /// A gate refused the call before its handler ran.
  denied,

  /// The handler threw.
  failed,
}

/// One server-scope audit record: which person called which install-wide
/// mutating op, with which argument names, and how it ended.
///
/// The counterpart of `UserActivityEntry` for ops that belong to no workspace
/// (server settings, Connect, provider apps, pairing). Argument VALUES are
/// never kept: a server op's arguments are where keys and secrets travel, so
/// only their names are recorded.
class ServerAuditEntry {
  /// Creates a [ServerAuditEntry].
  ServerAuditEntry({
    required this.id,
    required this.userId,
    required this.op,
    required List<String> argNames,
    required this.outcome,
    required DateTime createdAt,
    this.deviceId,
    this.ip,
  }) : argNames = List.unmodifiable([...argNames]..sort()),
       createdAt = createdAt.toUtc() {
    if (id.isEmpty) {
      throw ArgumentError('ServerAuditEntry id must not be empty');
    }
    if (userId.isEmpty) {
      throw ArgumentError('ServerAuditEntry userId must not be empty');
    }
    if (op.isEmpty) {
      throw ArgumentError('ServerAuditEntry op must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// The person who made the call.
  final String userId;

  /// The device the call came from, when known.
  final String? deviceId;

  /// The client address the session observed, when known.
  final String? ip;

  /// The op name (`connect.setChoice`).
  final String op;

  /// The names of the arguments the call carried, sorted. Never their values.
  final List<String> argNames;

  /// How the call ended.
  final AuditOutcome outcome;

  /// When the call ended, in UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerAuditEntry &&
          id == other.id &&
          userId == other.userId &&
          deviceId == other.deviceId &&
          ip == other.ip &&
          op == other.op &&
          _listEquals(argNames, other.argNames) &&
          outcome == other.outcome &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    deviceId,
    ip,
    op,
    Object.hashAll(argNames),
    outcome,
    createdAt,
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
