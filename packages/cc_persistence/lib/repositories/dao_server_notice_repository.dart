import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ServerNoticeRepository] over `global.db`'s `server_notices`.
class DaoServerNoticeRepository implements ServerNoticeRepository {
  /// Creates the repository over the server-global database.
  DaoServerNoticeRepository(this._global);

  final GlobalDatabase _global;

  @override
  Future<bool> raise(ServerNotice notice) async {
    final inserted = await _global
        .into(_global.serverNoticesTable)
        .insertReturningOrNull(
          ServerNoticesTableCompanion.insert(
            kind: notice.kind.wire,
            subject: notice.subject,
            detail: notice.detail,
            createdAt: notice.createdAt,
          ),
          onConflict: DoNothing(),
        );
    return inserted != null;
  }

  @override
  Future<List<ServerNotice>> open() async => [
    for (final row in await (_global.select(
      _global.serverNoticesTable,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get())
      ServerNotice(
        kind: ServerNoticeKind.values.firstWhere((k) => k.wire == row.kind),
        subject: row.subject,
        detail: row.detail,
        createdAt: row.createdAt,
      ),
  ];

  @override
  Future<void> resolve(ServerNoticeKind kind, String subject) async {
    await (_global.delete(
      _global.serverNoticesTable,
    )..where((t) => t.kind.equals(kind.wire) & t.subject.equals(subject))).go();
  }
}
