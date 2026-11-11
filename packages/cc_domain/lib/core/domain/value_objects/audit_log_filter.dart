import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';

/// How a time condition compares a record's `createdAt` with its instant.
enum AuditTimeOperator {
  /// `createdAt >= at`.
  atOrAfter('gte'),

  /// `createdAt > at`.
  after('gt'),

  /// `createdAt < at`.
  before('lt'),

  /// `createdAt <= at`.
  atOrBefore('lte');

  const AuditTimeOperator(this.wire);

  /// The wire token (`gte`, `gt`, `lt`, `lte`).
  final String wire;

  /// The operator for [wire], or null when it names none.
  static AuditTimeOperator? fromWire(Object? wire) {
    for (final op in values) {
      if (op.wire == wire) {
        return op;
      }
    }
    return null;
  }
}

/// One time bound on the audit log: records whose `createdAt` compares to
/// [at] by [op]. Several conditions apply together (AND), so `>= Monday` and
/// `< Tuesday` select one day.
class AuditTimeCondition {
  /// Creates a condition; [at] is kept in UTC.
  AuditTimeCondition({required this.op, required DateTime at})
    : at = at.toUtc();

  /// The comparison.
  final AuditTimeOperator op;

  /// The instant compared against, in UTC.
  final DateTime at;

  /// Whether a record made at [createdAt] satisfies this condition.
  bool admits(DateTime createdAt) {
    final t = createdAt.toUtc();
    return switch (op) {
      AuditTimeOperator.atOrAfter => !t.isBefore(at),
      AuditTimeOperator.after => t.isAfter(at),
      AuditTimeOperator.before => t.isBefore(at),
      AuditTimeOperator.atOrBefore => !t.isAfter(at),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditTimeCondition && op == other.op && at == other.at;

  @override
  int get hashCode => Object.hash(op, at);
}

/// The filters one audit log page applies, all together (AND). Text search
/// matches any of the record's machine columns, or an actor in
/// [searchUserIds] (display-name matches the client resolved; users live in
/// `global.db`, the records do not join them).
///
/// Which trails are read (the server log, which workspaces) is not a field
/// here: each trail is its own store, and the reader picks them.
class AuditLogFilter {
  /// Creates an [AuditLogFilter].
  const AuditLogFilter({
    this.query,
    this.searchUserIds = const {},
    this.actorIds = const {},
    this.outcomes = const {},
    this.ip,
    this.countryCode,
    this.localNetwork = false,
    this.time = const [],
  });

  /// Case-insensitive substring over the action, target, address and
  /// recorded arguments.
  final String? query;

  /// Actors whose name matched [query]; OR-ed into the text match.
  final Set<String> searchUserIds;

  /// Only records made by one of these people. Empty: anyone.
  final Set<String> actorIds;

  /// Only records that ended one of these ways. Empty: any outcome.
  final Set<AuditOutcome> outcomes;

  /// Exact client address.
  final String? ip;

  /// Exact ISO 3166-1 alpha-2 country code.
  final String? countryCode;

  /// Records whose address was captured but resolved to no country (private
  /// and loopback addresses).
  final bool localNetwork;

  /// Time bounds on `createdAt`, all applied.
  final List<AuditTimeCondition> time;

  /// Whether a country filter ([countryCode] or [localNetwork]) is set.
  bool get filtersCountry =>
      (countryCode != null && countryCode!.isNotEmpty) || localNetwork;

  /// This filter with no actor restriction (for the actor facet).
  AuditLogFilter withoutActors() => _copy(actorIds: const {});

  /// This filter with no outcome restriction (for the outcome facet).
  AuditLogFilter withoutOutcomes() => _copy(outcomes: const {});

  AuditLogFilter _copy({
    Set<String>? actorIds,
    Set<AuditOutcome>? outcomes,
  }) => AuditLogFilter(
    query: query,
    searchUserIds: searchUserIds,
    actorIds: actorIds ?? this.actorIds,
    outcomes: outcomes ?? this.outcomes,
    ip: ip,
    countryCode: countryCode,
    localNetwork: localNetwork,
    time: time,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogFilter &&
          query == other.query &&
          _setEquals(searchUserIds, other.searchUserIds) &&
          _setEquals(actorIds, other.actorIds) &&
          _setEquals(outcomes, other.outcomes) &&
          ip == other.ip &&
          countryCode == other.countryCode &&
          localNetwork == other.localNetwork &&
          _listEquals(time, other.time);

  @override
  int get hashCode => Object.hash(
    query,
    Object.hashAllUnordered(searchUserIds),
    Object.hashAllUnordered(actorIds),
    Object.hashAllUnordered(outcomes),
    ip,
    countryCode,
    localNetwork,
    Object.hashAll(time),
  );
}

/// Lowercased LIKE needle for [query], with SQL wildcards stripped so a typed
/// `%` cannot widen the scan; null when nothing is left to match.
String? auditSearchNeedle(String? query) {
  if (query == null) {
    return null;
  }
  final needle = query
      .toLowerCase()
      .replaceAll('%', '')
      .replaceAll('_', '')
      .trim();
  return needle.isEmpty ? null : needle;
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

bool _listEquals<T>(List<T> a, List<T> b) {
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
