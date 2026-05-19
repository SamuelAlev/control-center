import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/domain/repositories/calendar_repository.dart';

/// In-memory fake [CalendarRepository] that records calls, for service tests.
class FakeCalendarRepository implements CalendarRepository {
  /// The connected accounts (empty = not connected).
  List<CalendarAccount> accounts = [];

  /// Convenience setter for tests with a single account.
  set account(CalendarAccount? value) =>
      accounts = value == null ? [] : [value];

  /// Events captured by [upsertEvents].
  final List<CalendarEvent> upsertedEvents = [];

  /// `setLastSyncedAt` calls.
  final List<({String workspaceId, String accountId, DateTime at})> lastSynced =
      [];

  /// Events returned by [getUpcomingEventsNeedingAlert].
  List<CalendarEvent> upcoming = [];

  /// `markAlerted` calls.
  final List<({String workspaceId, String eventId, DateTime at})> alerted = [];

  /// `linkMeetingToEvent` calls.
  final List<({String workspaceId, String meetingId, String calendarEventId})>
      links = [];

  /// Event returned by [getEventForMeeting].
  CalendarEvent? eventForMeeting;

  @override
  Future<List<CalendarAccount>> getAccounts(String workspaceId) async =>
      accounts;

  @override
  Stream<List<CalendarAccount>> watchAccounts(String workspaceId) =>
      Stream.value(accounts);

  @override
  Future<void> upsertAccount(CalendarAccount account) async {
    accounts = [
      for (final a in accounts)
        if (a.accountEmail != account.accountEmail) a,
      account,
    ];
  }

  @override
  Future<void> setLastSyncedAt(
    String workspaceId,
    String accountId,
    DateTime at,
  ) async {
    lastSynced.add((workspaceId: workspaceId, accountId: accountId, at: at));
    // Mirror the DAO: a successful sync stamps lastSyncedAt and clears any
    // "needs reauth" flag. (copyWith can't null a field, so rebuild it.)
    accounts = [
      for (final a in accounts)
        if (a.id == accountId && a.workspaceId == workspaceId)
          CalendarAccount(
            id: a.id,
            workspaceId: a.workspaceId,
            providerId: a.providerId,
            accountEmail: a.accountEmail,
            displayName: a.displayName,
            lastSyncedAt: at,
          )
        else
          a,
    ];
  }

  /// `markNeedsReauth` calls, in order.
  final List<({String workspaceId, String accountId, DateTime at})>
      markedNeedsReauth = [];

  @override
  Future<bool> markNeedsReauth(
    String workspaceId,
    String accountId,
    DateTime at,
  ) async {
    markedNeedsReauth.add(
      (workspaceId: workspaceId, accountId: accountId, at: at),
    );
    final idx = accounts.indexWhere(
      (a) => a.id == accountId && a.workspaceId == workspaceId,
    );
    if (idx < 0 || accounts[idx].authExpiredAt != null) {
      return false; // absent or already flagged → no transition
    }
    accounts = [
      for (final a in accounts)
        if (a.id == accountId && a.workspaceId == workspaceId)
          a.copyWith(authExpiredAt: at)
        else
          a,
    ];
    return true;
  }

  @override
  Future<void> deleteAccount(String workspaceId, String id) async {
    accounts = [for (final a in accounts) if (a.id != id) a];
  }

  @override
  Future<void> upsertEvents(List<CalendarEvent> events) async {
    upsertedEvents.addAll(events);
  }

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) =>
      Stream.value(upsertedEvents);

  @override
  Stream<CalendarEvent?> watchEventById(String workspaceId, String eventId) =>
      Stream.value(
        upsertedEvents.where((e) => e.id == eventId).firstOrNull,
      );

  /// `deleteEventsMissingFrom` reconciliation calls, in order.
  final List<
      ({
        String workspaceId,
        String accountId,
        String calendarId,
        DateTime from,
        DateTime to,
        Set<String> keepExternalIds,
      })> reconciled = [];

  @override
  Future<void> deleteEventsMissingFrom({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required DateTime from,
    required DateTime to,
    required Set<String> keepExternalIds,
  }) async {
    reconciled.add((
      workspaceId: workspaceId,
      accountId: accountId,
      calendarId: calendarId,
      from: from,
      to: to,
      keepExternalIds: keepExternalIds,
    ));
  }

  @override
  Future<List<CalendarEvent>> getUpcomingEventsNeedingAlert(
    String workspaceId,
    DateTime windowStart,
    DateTime windowEnd,
  ) async =>
      upcoming;

  @override
  Future<void> markAlerted(
    String workspaceId,
    String eventId,
    DateTime at,
  ) async {
    alerted.add((workspaceId: workspaceId, eventId: eventId, at: at));
    upcoming = upcoming.where((e) => e.id != eventId).toList();
  }

  @override
  Future<void> linkMeetingToEvent({
    required String workspaceId,
    required String meetingId,
    required String calendarEventId,
  }) async {
    links.add((
      workspaceId: workspaceId,
      meetingId: meetingId,
      calendarEventId: calendarEventId,
    ));
  }

  @override
  Future<CalendarEvent?> getEventForMeeting(
    String workspaceId,
    String meetingId,
  ) async =>
      eventForMeeting;

  /// Meeting id returned by [getMeetingIdForEvent].
  String? meetingIdForEvent;

  @override
  Future<String?> getMeetingIdForEvent(
    String workspaceId,
    String calendarEventId,
  ) async =>
      meetingIdForEvent;
}
