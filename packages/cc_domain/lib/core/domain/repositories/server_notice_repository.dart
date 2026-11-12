/// What a notice for the server owner is about.
enum ServerNoticeKind {
  /// A workspace's database failed its integrity check and is read-only until
  /// it is restored. The subject is the workspace id.
  workspaceReadOnly('workspace_read_only');

  const ServerNoticeKind(this.wire);

  /// The value stored in `server_notices.kind` and sent on the wire.
  final String wire;
}

/// Something the server owner has to act on, kept until they do.
final class ServerNotice {
  /// Creates a notice of [kind] about [subject]. Throws [ArgumentError] on an
  /// empty subject.
  ServerNotice({
    required this.kind,
    required this.subject,
    required this.detail,
    required this.createdAt,
  }) {
    if (subject.isEmpty) {
      throw ArgumentError.value(subject, 'subject', 'must not be empty');
    }
  }

  /// What it is about.
  final ServerNoticeKind kind;

  /// The thing it names (a workspace id for [ServerNoticeKind.workspaceReadOnly]).
  final String subject;

  /// The operator-facing finding (SQLite's own words), never shown to
  /// workspace members.
  final String detail;

  /// When it was first raised.
  final DateTime createdAt;

  /// The wire form of `server.notices`.
  Map<String, dynamic> toWire() => {
    'kind': kind.wire,
    'subject': subject,
    'detail': detail,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is ServerNotice &&
      other.kind == kind &&
      other.subject == subject &&
      other.detail == detail &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(kind, subject, detail, createdAt);
}

/// Durable notices for the server owner, in the server-global database.
///
/// They live outside every workspace on purpose: the notice that a workspace's
/// database is damaged cannot be stored in that database.
abstract interface class ServerNoticeRepository {
  /// Records [notice] unless one of the same kind about the same subject is
  /// already open. Returns whether this call recorded it.
  Future<bool> raise(ServerNotice notice);

  /// Every open notice, oldest first.
  Future<List<ServerNotice>> open();

  /// Closes the notice of [kind] about [subject]. A no-op when none is open.
  Future<void> resolve(ServerNoticeKind kind, String subject);
}
