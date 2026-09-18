import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';

/// Default page size for the workspace audit trail table.
const int defaultUserActivityPageSize = 10;

/// Optional filters applied to an audit-trail page (AND). Text search is OR
/// across the raw columns and [userIds].
class UserActivityFilter {
  /// Creates a [UserActivityFilter].
  const UserActivityFilter({
    this.query,
    this.ip,
    this.countryCode,
    this.localNetwork = false,
    this.userIds = const [],
  });

  /// Case-insensitive substring over action, target, IP and details.
  final String? query;

  /// Exact client IP.
  final String? ip;

  /// Exact ISO 3166-1 alpha-2 country code.
  final String? countryCode;

  /// Rows whose IP was captured but GeoIP produced no country (private /
  /// loopback literals in the UI).
  final bool localNetwork;

  /// Actor ids to OR into the text search (display-name matches resolved
  /// client-side — users live in `global.db`).
  final List<String> userIds;

  /// Whether no filter is set.
  bool get isEmpty =>
      (query == null || query!.trim().isEmpty) &&
      (ip == null || ip!.isEmpty) &&
      (countryCode == null || countryCode!.isEmpty) &&
      !localNetwork &&
      userIds.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserActivityFilter &&
          query == other.query &&
          ip == other.ip &&
          countryCode == other.countryCode &&
          localNetwork == other.localNetwork &&
          _listEquals(userIds, other.userIds);

  @override
  int get hashCode => Object.hash(
    query,
    ip,
    countryCode,
    localNetwork,
    Object.hashAll(userIds),
  );
}

/// One newest-first page of the workspace audit trail, plus the real total
/// and cursors for the adjacent pages.
class UserActivityPage {
  /// Creates a [UserActivityPage].
  const UserActivityPage({
    required this.entries,
    required this.total,
    required this.start,
    this.nextCursor,
    this.prevCursor,
  });

  /// An empty page.
  static const UserActivityPage empty = UserActivityPage(
    entries: [],
    total: 0,
    start: 1,
  );

  /// The page's entries, newest first.
  final List<UserActivityEntry> entries;

  /// How many rows match the filter across the whole trail.
  final int total;

  /// 1-based index of the first row on this page in the filtered trail.
  final int start;

  /// Opaque cursor for the next older page; null when this is the last page.
  final String? nextCursor;

  /// Opaque cursor for the previous newer page; null when this is the first
  /// page (the URL then drops `?cursor=`).
  final String? prevCursor;

  /// Whether an older page exists.
  bool get hasMore => nextCursor != null;

  /// 1-based index of the last row on this page.
  int get end => entries.isEmpty ? start - 1 : start + entries.length - 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserActivityPage &&
          total == other.total &&
          start == other.start &&
          nextCursor == other.nextCursor &&
          prevCursor == other.prevCursor &&
          _entryListEquals(entries, other.entries);

  @override
  int get hashCode =>
      Object.hash(total, start, nextCursor, prevCursor, entries.length);
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

bool _entryListEquals(List<UserActivityEntry> a, List<UserActivityEntry> b) {
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
