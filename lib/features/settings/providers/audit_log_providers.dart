import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart';
import 'package:control_center/di/providers.dart' show auditLogPortProvider;
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rows per audit log page.
const int kAuditLogPageSize = 25;

/// Whether this person has an audit log to read: the server owner (the server
/// trail) or an admin of any workspace (that workspace's trail). The server
/// decides what each frame holds; this only decides whether the page is
/// offered. False while identity loads.
final canSeeAuditLogProvider = Provider<bool>(
  (ref) =>
      ref.watch(isServerOwnerProvider) ||
      ref.watch(isWorkspaceAdminAnywhereProvider),
);

/// One live page of the audit log.
final auditLogPageProvider = StreamProvider.autoDispose
    .family<AuditLogPageDto, AuditLogQuery>(
      (ref, query) => ref.watch(auditLogPortProvider).watchPage(query),
    );

/// The filters the audit log table applies. The page cursor is not here: it
/// lives in the URL (`?cursor=`), and every filter change drops it.
class AuditLogFilters {
  /// Creates filters; the defaults filter nothing.
  const AuditLogFilters({
    this.search = '',
    this.actorIds = const {},
    this.sources = const {},
    this.outcomes = const {},
    this.ip,
    this.country,
    this.time = const [],
  });

  /// Free-text search.
  final String search;

  /// Only these actors.
  final Set<String> actorIds;

  /// Only these source keys.
  final Set<String> sources;

  /// Only these outcomes.
  final Set<AuditOutcome> outcomes;

  /// Exact client address.
  final String? ip;

  /// A country chip's label: an ISO code, or the local-network label.
  final String? country;

  /// Time conditions, all applied.
  final List<AuditTimeCondition> time;

  /// Whether any filter other than [search] is set.
  bool get hasChips =>
      actorIds.isNotEmpty ||
      sources.isNotEmpty ||
      outcomes.isNotEmpty ||
      ip != null ||
      country != null ||
      time.isNotEmpty;

  /// Whether anything narrows the log.
  bool get isFiltering => search.trim().isNotEmpty || hasChips;

  /// The query for one page: [cursor], with display-name search resolved
  /// against [users] and [localLabel] (the local-network chip) mapped to its
  /// own filter.
  AuditLogQuery query({
    required String? cursor,
    required Map<String, UserDto> users,
    required String localLabel,
  }) {
    final needle = search.trim().toLowerCase();
    return AuditLogQuery(
      cursor: cursor,
      limit: kAuditLogPageSize,
      search: search.trim(),
      searchUserIds: needle.isEmpty
          ? const {}
          : {
              for (final e in users.entries)
                if (e.value.displayName.toLowerCase().contains(needle) ||
                    e.value.handle.toLowerCase().contains(needle))
                  e.key,
            },
      actorIds: actorIds,
      sources: sources,
      outcomes: outcomes,
      ip: ip,
      countryCode: country != null && country != localLabel ? country : null,
      localNetwork: country != null && country == localLabel,
      time: time,
    );
  }

  AuditLogFilters _copy({
    String? search,
    Set<String>? actorIds,
    Set<String>? sources,
    Set<AuditOutcome>? outcomes,
    (String?,)? ip,
    (String?,)? country,
    List<AuditTimeCondition>? time,
  }) => AuditLogFilters(
    search: search ?? this.search,
    actorIds: actorIds ?? this.actorIds,
    sources: sources ?? this.sources,
    outcomes: outcomes ?? this.outcomes,
    ip: ip == null ? this.ip : ip.$1,
    country: country == null ? this.country : country.$1,
    time: time ?? this.time,
  );
}

/// The audit log's filter state. Kept for as long as the page is open.
class AuditLogFiltersNotifier extends Notifier<AuditLogFilters> {
  @override
  AuditLogFilters build() => const AuditLogFilters();

  /// Sets the free-text search.
  void setSearch(String value) => state = state._copy(search: value);

  /// Sets the actor selection.
  void setActors(Set<String> ids) => state = state._copy(actorIds: ids);

  /// Sets the source selection.
  void setSources(Set<String> keys) => state = state._copy(sources: keys);

  /// Sets the outcome selection.
  void setOutcomes(Set<AuditOutcome> outcomes) =>
      state = state._copy(outcomes: outcomes);

  /// Filters to [ip], or clears it when it is already the filter.
  void toggleIp(String? ip) =>
      state = state._copy(ip: (state.ip == ip ? null : ip,));

  /// Filters to [country], or clears it when it is already the filter.
  void toggleCountry(String? country) => state = state._copy(
    country: (state.country == country ? null : country,),
  );

  /// Adds a time condition.
  void addTime(AuditTimeCondition condition) =>
      state = state._copy(time: [...state.time, condition]);

  /// Removes the time condition at [index].
  void removeTime(int index) =>
      state = state._copy(time: [...state.time]..removeAt(index));
}

/// The audit log's filters.
final auditLogFiltersProvider =
    NotifierProvider.autoDispose<AuditLogFiltersNotifier, AuditLogFilters>(
      AuditLogFiltersNotifier.new,
    );
