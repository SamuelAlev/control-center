import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';

/// What one audit log page asks for.
class AuditLogQuery {
  /// Creates a query.
  const AuditLogQuery({
    this.cursor,
    this.limit = 25,
    this.search = '',
    this.searchUserIds = const {},
    this.actorIds = const {},
    this.sources = const {},
    this.outcomes = const {},
    this.ip,
    this.countryCode,
    this.localNetwork = false,
    this.time = const [],
  });

  /// Opaque page cursor, or null for the newest page.
  final String? cursor;

  /// Rows per page.
  final int limit;

  /// Free-text search.
  final String search;

  /// Actors whose display name matched [search].
  final Set<String> searchUserIds;

  /// Only these actors.
  final Set<String> actorIds;

  /// Only these source keys ([AuditLogScopeDto.key]); empty reads all.
  final Set<String> sources;

  /// Only these outcomes.
  final Set<AuditOutcome> outcomes;

  /// Exact client address.
  final String? ip;

  /// Exact country code.
  final String? countryCode;

  /// Private/loopback addresses (no country).
  final bool localNetwork;

  /// Time conditions, all applied.
  final List<AuditTimeCondition> time;

  /// The subscription arguments.
  Map<String, dynamic> toArgs() => {
    'cursor': ?cursor,
    'limit': limit,
    if (search.trim().isNotEmpty) 'query': search.trim(),
    if (searchUserIds.isNotEmpty) 'search_user_ids': searchUserIds.toList(),
    if (actorIds.isNotEmpty) 'actor_ids': actorIds.toList(),
    if (sources.isNotEmpty) 'sources': sources.toList(),
    if (outcomes.isNotEmpty) 'outcomes': [for (final o in outcomes) o.name],
    'ip': ?ip,
    'country_code': ?countryCode,
    if (localNetwork) 'local_network': true,
    if (time.isNotEmpty)
      'time': [
        for (final c in time)
          {'op': c.op.wire, 'at': c.at.toUtc().toIso8601String()},
      ],
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogQuery &&
          cursor == other.cursor &&
          limit == other.limit &&
          search == other.search &&
          _sameSet(searchUserIds, other.searchUserIds) &&
          _sameSet(actorIds, other.actorIds) &&
          _sameSet(sources, other.sources) &&
          _sameSet(outcomes, other.outcomes) &&
          ip == other.ip &&
          countryCode == other.countryCode &&
          localNetwork == other.localNetwork &&
          _sameList(time, other.time);

  @override
  int get hashCode => Object.hash(
    cursor,
    limit,
    search,
    Object.hashAllUnordered(searchUserIds),
    Object.hashAllUnordered(actorIds),
    Object.hashAllUnordered(sources),
    Object.hashAllUnordered(outcomes),
    ip,
    countryCode,
    localNetwork,
    Object.hashAll(time),
  );
}

/// Which trail an audit log record or filter option belongs to.
enum AuditLogScopeKind {
  /// The server-scope trail (install-wide ops).
  server,

  /// One workspace's trail.
  workspace,
}

/// One trail the caller may read.
class AuditLogScopeDto {
  /// Creates a scope.
  const AuditLogScopeDto({
    required this.key,
    required this.kind,
    this.workspaceId,
    this.name,
  });

  /// Decodes one `scopes` row, or null when it is not one this client reads.
  static AuditLogScopeDto? tryParse(Map<String, dynamic> json) {
    final key = json['key'];
    final kind = AuditLogScopeKind.values.asNameMap()[json['kind']];
    if (key is! String || key.isEmpty || kind == null) {
      return null;
    }
    return AuditLogScopeDto(
      key: key,
      kind: kind,
      workspaceId: json['workspace_id'] as String?,
      name: json['name'] as String?,
    );
  }

  /// The source key filters name.
  final String key;

  /// Server or workspace.
  final AuditLogScopeKind kind;

  /// The workspace, for a workspace scope.
  final String? workspaceId;

  /// The workspace's name, for a workspace scope.
  final String? name;
}

/// One audit log record.
class AuditLogEntryDto {
  /// Creates an entry.
  const AuditLogEntryDto({
    required this.id,
    required this.source,
    required this.userId,
    required this.action,
    required this.outcome,
    required this.createdAt,
    this.workspaceId,
    this.deviceId,
    this.ip,
    this.countryCode,
    this.targetType,
    this.targetId,
    this.details,
    this.argNames = const [],
  });

  /// Decodes one entry, or null when it lacks what a row needs.
  static AuditLogEntryDto? tryParse(Map<String, dynamic> json) {
    final id = json['id'];
    final source = json['source'];
    final userId = json['user_id'];
    final action = json['action'];
    final outcome = AuditOutcome.values.asNameMap()[json['outcome']];
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    if (id is! String ||
        id.isEmpty ||
        source is! String ||
        userId is! String ||
        userId.isEmpty ||
        action is! String ||
        action.isEmpty ||
        outcome == null ||
        createdAt == null) {
      return null;
    }
    final details = json['details'];
    final argNames = json['arg_names'];
    return AuditLogEntryDto(
      id: id,
      source: source,
      userId: userId,
      action: action,
      outcome: outcome,
      createdAt: createdAt,
      workspaceId: json['workspace_id'] as String?,
      deviceId: json['device_id'] as String?,
      ip: json['ip'] as String?,
      countryCode: json['country_code'] as String?,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      details: details is Map
          ? details.map((k, v) => MapEntry('$k', v as Object?))
          : null,
      argNames: [if (argNames is List) ...argNames.whereType<String>()],
    );
  }

  /// Unique id.
  final String id;

  /// The source key ([AuditLogScopeDto.key]).
  final String source;

  /// Who made the call.
  final String userId;

  /// The op or semantic action.
  final String action;

  /// How it ended.
  final AuditOutcome outcome;

  /// When, in UTC.
  final DateTime createdAt;

  /// The workspace, for a workspace record; null for a server record.
  final String? workspaceId;

  /// The device, when known.
  final String? deviceId;

  /// The client address, when known.
  final String? ip;

  /// The resolved country, when known.
  final String? countryCode;

  /// Kind of entity acted on, when known.
  final String? targetType;

  /// Id of the entity acted on, when known (and visible).
  final String? targetId;

  /// Recorded arguments, for a workspace record (when visible).
  final Map<String, Object?>? details;

  /// Argument names, for a server record. Never their values.
  final List<String> argNames;

  /// Whether this is a server-scope record.
  bool get isServer => workspaceId == null;
}

/// One newest-first page of the audit log.
class AuditLogPageDto {
  /// Creates a page.
  const AuditLogPageDto({
    required this.entries,
    required this.total,
    required this.start,
    required this.scopes,
    this.nextCursor,
    this.prevCursor,
    this.actorCounts = const {},
    this.sourceCounts = const {},
    this.outcomeCounts = const {},
  });

  /// Decodes an `audit.watchLog` frame.
  factory AuditLogPageDto.fromJson(Map<String, dynamic> json) {
    Map<String, int> counts(Object? raw) => {
      if (raw is Map)
        for (final e in raw.entries)
          if (e.value is num) '${e.key}': (e.value as num).toInt(),
    };
    final facets = json['facets'];
    final f = facets is Map ? facets : const {};
    final byName = AuditOutcome.values.asNameMap();
    return AuditLogPageDto(
      entries: [
        if (json['entries'] case final List rows)
          for (final row in rows.whereType<Map<Object?, Object?>>())
            ?AuditLogEntryDto.tryParse(row.cast<String, dynamic>()),
      ],
      scopes: [
        if (json['scopes'] case final List rows)
          for (final row in rows.whereType<Map<Object?, Object?>>())
            ?AuditLogScopeDto.tryParse(row.cast<String, dynamic>()),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
      start: (json['start'] as num?)?.toInt() ?? 1,
      nextCursor: json['next_cursor'] as String?,
      prevCursor: json['prev_cursor'] as String?,
      actorCounts: counts(f['actors']),
      sourceCounts: counts(f['sources']),
      outcomeCounts: {
        for (final e in counts(f['outcomes']).entries) ?byName[e.key]: e.value,
      },
    );
  }

  /// The page's entries, newest first.
  final List<AuditLogEntryDto> entries;

  /// How many records match across the selected trails.
  final int total;

  /// 1-based index of the first entry.
  final int start;

  /// The trails the caller may read; empty when they may read none.
  final List<AuditLogScopeDto> scopes;

  /// Cursor of the next older page.
  final String? nextCursor;

  /// Cursor of the previous newer page; null when that page is the first.
  final String? prevCursor;

  /// Matching records per actor (ignoring the actor filter).
  final Map<String, int> actorCounts;

  /// Matching records per source key (over every visible trail).
  final Map<String, int> sourceCounts;

  /// Matching records per outcome (ignoring the outcome filter).
  final Map<AuditOutcome, int> outcomeCounts;

  /// 1-based index of the last entry.
  int get end => entries.isEmpty ? start - 1 : start + entries.length - 1;
}

bool _sameSet<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

bool _sameList<T>(List<T> a, List<T> b) {
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
