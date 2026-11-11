import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/repositories/server_audit_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show userActivityToWire;
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';

/// The source key of the server-scope trail.
const auditServerSourceKey = 'server';

/// The source key of workspace [workspaceId]'s trail.
String auditWorkspaceSourceKey(String workspaceId) => 'ws:$workspaceId';

/// One audit record as the audit log shows it: its sort key and its wire.
class AuditLogRow {
  /// Creates a row.
  const AuditLogRow({
    required this.id,
    required this.createdAt,
    required this.wire,
  });

  /// The record's id (the tie-breaker of the sort key).
  final String id;

  /// When it was recorded (the sort key).
  final DateTime createdAt;

  /// The record as the viewer may see it.
  final Map<String, dynamic> wire;

  /// The keyset cursor at this row.
  ActivityCursor get cursor => ActivityCursor(
    createdAtMs: createdAt.toUtc().millisecondsSinceEpoch,
    id: id,
  );

  /// Newest first: later `createdAt`, then the greater id.
  static int newestFirst(AuditLogRow a, AuditLogRow b) {
    final byTime = b.createdAt.compareTo(a.createdAt);
    return byTime != 0 ? byTime : b.id.compareTo(a.id);
  }
}

/// One trail the audit log reads: the server log or one workspace's trail,
/// already narrowed to what the viewer may see. Paging is keyset over
/// `(createdAt, id)`, identical in every source, so pages merge.
abstract interface class AuditLogSource {
  /// The stable key the client filters by ([auditServerSourceKey] or
  /// [auditWorkspaceSourceKey]).
  String get key;

  /// Matching rows strictly older than [olderThan], newest first.
  Future<List<AuditLogRow>> older(
    ActivityCursor? olderThan,
    int limit,
    AuditLogFilter filter,
  );

  /// Matching rows strictly newer than [newerThan], oldest first.
  Future<List<AuditLogRow>> newer(
    ActivityCursor newerThan,
    int limit,
    AuditLogFilter filter,
  );

  /// How many rows match (only those newer than [newerThan] when given).
  Future<int> count(AuditLogFilter filter, {ActivityCursor? newerThan});

  /// Matching rows per actor id.
  Future<Map<String, int>> countByActor(AuditLogFilter filter);

  /// Matching rows per outcome.
  Future<Map<AuditOutcome, int>> countByOutcome(AuditLogFilter filter);
}

/// The server-scope trail as a source. Its rows carry the op's argument
/// names and outcome, never argument values.
class ServerAuditLogSource implements AuditLogSource {
  /// Creates the source over [_audit].
  ServerAuditLogSource(this._audit);

  final ServerAuditRepository _audit;

  @override
  String get key => auditServerSourceKey;

  @override
  Future<List<AuditLogRow>> older(
    ActivityCursor? olderThan,
    int limit,
    AuditLogFilter filter,
  ) async => [
    for (final e in await _audit.pageRows(
      olderThan: olderThan,
      limit: limit,
      filter: filter,
    ))
      _row(e),
  ];

  @override
  Future<List<AuditLogRow>> newer(
    ActivityCursor newerThan,
    int limit,
    AuditLogFilter filter,
  ) async => [
    for (final e in await _audit.newerRows(
      newerThan: newerThan,
      limit: limit,
      filter: filter,
    ))
      _row(e),
  ];

  @override
  Future<int> count(AuditLogFilter filter, {ActivityCursor? newerThan}) =>
      _audit.count(filter: filter, newerThan: newerThan);

  @override
  Future<Map<String, int>> countByActor(AuditLogFilter filter) =>
      _audit.countByActor(filter: filter);

  @override
  Future<Map<AuditOutcome, int>> countByOutcome(AuditLogFilter filter) =>
      _audit.countByOutcome(filter: filter);

  AuditLogRow _row(ServerAuditEntry e) => AuditLogRow(
    id: e.id,
    createdAt: e.createdAt,
    wire: {
      'id': e.id,
      'source': key,
      'user_id': e.userId,
      'action': e.op,
      'outcome': e.outcome.name,
      'arg_names': e.argNames,
      'device_id': ?e.deviceId,
      'ip': ?e.ip,
      'created_at': e.createdAt.toIso8601String(),
    },
  );
}

/// One workspace's trail as a source, rendered through the viewer's
/// [PrDataView]: a record whose arguments name a repository or review space
/// they cannot see keeps who, what and when, but not its target or details.
/// Every record here returned, so each is `ok`.
class WorkspaceAuditLogSource implements AuditLogSource {
  /// Creates the source for [workspaceId] under [view].
  WorkspaceAuditLogSource(this._activity, this.workspaceId, this.view);

  final UserActivityRepository _activity;

  /// The workspace whose trail this reads.
  final String workspaceId;

  /// The viewer's PR view in [workspaceId].
  final PrDataView view;

  @override
  String get key => auditWorkspaceSourceKey(workspaceId);

  @override
  Future<List<AuditLogRow>> older(
    ActivityCursor? olderThan,
    int limit,
    AuditLogFilter filter,
  ) async => [
    for (final e in await _activity.pageRows(
      workspaceId,
      olderThan: olderThan,
      limit: limit,
      filter: filter,
    ))
      _row(e),
  ];

  @override
  Future<List<AuditLogRow>> newer(
    ActivityCursor newerThan,
    int limit,
    AuditLogFilter filter,
  ) async => [
    for (final e in await _activity.newerRows(
      workspaceId,
      newerThan: newerThan,
      limit: limit,
      filter: filter,
    ))
      _row(e),
  ];

  @override
  Future<int> count(AuditLogFilter filter, {ActivityCursor? newerThan}) =>
      _activity.count(workspaceId, filter: filter, newerThan: newerThan);

  @override
  Future<Map<String, int>> countByActor(AuditLogFilter filter) =>
      _activity.countByActor(workspaceId, filter: filter);

  @override
  Future<Map<AuditOutcome, int>> countByOutcome(AuditLogFilter filter) async {
    final n = await _activity.count(workspaceId, filter: filter);
    return {if (n > 0) AuditOutcome.ok: n};
  }

  AuditLogRow _row(UserActivityEntry e) => AuditLogRow(
    id: e.id,
    createdAt: e.createdAt,
    wire: {
      ...activityEntryWireFor(e, view, userActivityToWire),
      'source': key,
      'outcome': AuditOutcome.ok.name,
    },
  );
}

/// One newest-first page of the merged audit log.
class AuditLogPage {
  /// Creates a page.
  const AuditLogPage({
    required this.rows,
    required this.total,
    required this.start,
    required this.actorCounts,
    required this.sourceCounts,
    required this.outcomeCounts,
    this.nextCursor,
    this.prevCursor,
  });

  /// The page's rows, newest first.
  final List<AuditLogRow> rows;

  /// How many rows match across the selected sources.
  final int total;

  /// 1-based index of the first row in the filtered log.
  final int start;

  /// Cursor of the next older page; null on the last page.
  final String? nextCursor;

  /// Cursor of the previous newer page; null when that page is the first.
  final String? prevCursor;

  /// Matching rows per actor, ignoring the actor filter.
  final Map<String, int> actorCounts;

  /// Matching rows per source, over every visible source.
  final Map<String, int> sourceCounts;

  /// Matching rows per outcome, ignoring the outcome filter.
  final Map<AuditOutcome, int> outcomeCounts;

  /// The wire of this page.
  Map<String, dynamic> toWire() => {
    'entries': [for (final r in rows) r.wire],
    'total': total,
    'start': start,
    'next_cursor': nextCursor,
    'prev_cursor': prevCursor,
    'facets': {
      'actors': actorCounts,
      'sources': sourceCounts,
      'outcomes': {for (final e in outcomeCounts.entries) e.key.name: e.value},
    },
  };
}

/// Reads one page of the audit log merged over [selected] sources, with facet
/// counts over [visible] ones (a superset of [selected]).
///
/// Each source answers its own keyset query with [limit] + 1 rows; merging
/// those and keeping the newest [limit] + 1 is exact, because every row of
/// the true page is among its own source's newest matches.
Future<AuditLogPage> readAuditLogPage({
  required List<AuditLogSource> selected,
  required List<AuditLogSource> visible,
  required int limit,
  ActivityCursor? cursor,
  AuditLogFilter filter = const AuditLogFilter(),
}) async {
  Future<List<T>> each<T>(
    List<AuditLogSource> sources,
    Future<T> Function(AuditLogSource s) read,
  ) => Future.wait([for (final s in sources) read(s)]);

  final merged = [
    for (final rows in await each(
      selected,
      (s) => s.older(cursor, limit + 1, filter),
    ))
      ...rows,
  ]..sort(AuditLogRow.newestFirst);
  final hasMore = merged.length > limit;
  final rows = merged.take(limit).toList(growable: false);

  final sourceCounts = {
    for (final (i, n) in (await each(
      visible,
      (s) => s.count(filter),
    )).indexed)
      visible[i].key: n,
  };
  final selectedKeys = {for (final s in selected) s.key};
  final total = [
    for (final e in sourceCounts.entries)
      if (selectedKeys.contains(e.key)) e.value,
  ].fold(0, (a, b) => a + b);

  final actorCounts = <String, int>{};
  for (final counts in await each(
    selected,
    (s) => s.countByActor(filter.withoutActors()),
  )) {
    for (final e in counts.entries) {
      actorCounts[e.key] = (actorCounts[e.key] ?? 0) + e.value;
    }
  }
  final outcomeCounts = <AuditOutcome, int>{};
  for (final counts in await each(
    selected,
    (s) => s.countByOutcome(filter.withoutOutcomes()),
  )) {
    for (final e in counts.entries) {
      outcomeCounts[e.key] = (outcomeCounts[e.key] ?? 0) + e.value;
    }
  }

  if (rows.isEmpty) {
    return AuditLogPage(
      rows: const [],
      total: total,
      start: total == 0 ? 1 : total + 1,
      actorCounts: actorCounts,
      sourceCounts: sourceCounts,
      outcomeCounts: outcomeCounts,
    );
  }

  final first = rows.first.cursor;
  final start =
      (await each(
        selected,
        (s) => s.count(filter, newerThan: first),
      )).fold(0, (a, b) => a + b) +
      1;
  String? prevCursor;
  if (start > 1) {
    final newer = [
      for (final list in await each(
        selected,
        (s) => s.newer(first, limit + 1, filter),
      ))
        ...list,
    ]..sort((a, b) => AuditLogRow.newestFirst(b, a));
    if (newer.length > limit) {
      prevCursor = newer[limit].cursor.encode();
    }
  }
  return AuditLogPage(
    rows: rows,
    total: total,
    start: start,
    nextCursor: hasMore ? rows.last.cursor.encode() : null,
    prevCursor: prevCursor,
    actorCounts: actorCounts,
    sourceCounts: sourceCounts,
    outcomeCounts: outcomeCounts,
  );
}
