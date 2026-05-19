import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';

/// Persistence port for the calendar feature. Every method is workspace-scoped
/// (the workspace clause, not id uniqueness, is the isolation boundary).
abstract class CalendarRepository {
  /// The connected accounts for [workspaceId] (empty when none).
  Future<List<CalendarAccount>> getAccounts(String workspaceId);

  /// Watches the connected accounts for [workspaceId].
  Stream<List<CalendarAccount>> watchAccounts(String workspaceId);

  /// Inserts or updates a connected account (idempotent per
  /// `(workspaceId, accountEmail)`).
  Future<void> upsertAccount(CalendarAccount account);

  /// Records the last-synced timestamp for an account (and clears any
  /// "needs reauth" flag — a successful sync proves the tokens are healthy).
  Future<void> setLastSyncedAt(
    String workspaceId,
    String accountId,
    DateTime at,
  );

  /// Flags an account as needing the user to reconnect (its OAuth refresh token
  /// is dead). Returns `true` only on the null→set transition so the caller can
  /// notify exactly once per disconnection episode; `false` if absent or
  /// already flagged. Cleared by [setLastSyncedAt] / [upsertAccount].
  Future<bool> markNeedsReauth(
    String workspaceId,
    String accountId,
    DateTime at,
  );

  /// Deletes the workspace's account (cascades to its events).
  Future<void> deleteAccount(String workspaceId, String id);

  /// Inserts or updates events (idempotent on the provider event id).
  Future<void> upsertEvents(List<CalendarEvent> events);

  /// Watches events overlapping `[from, to)` in [workspaceId].
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  );

  /// Watches a single event by id, scoped to [workspaceId] (null when absent),
  /// with no time window — so the detail panel can resolve a past event that
  /// falls outside the currently-synced range.
  Stream<CalendarEvent?> watchEventById(String workspaceId, String eventId);

  /// Reconciles deletions for one calendar+window: removes locally-stored
  /// events in [calendarId] (on [accountId] in [workspaceId]) overlapping
  /// `[from, to)` whose provider id is not in [keepExternalIds]. Lets a sync
  /// drop events the provider no longer returns (deleted/moved on the server).
  Future<void> deleteEventsMissingFrom({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required DateTime from,
    required DateTime to,
    required Set<String> keepExternalIds,
  });

  /// Timed, not-yet-alerted events whose start falls in
  /// `[windowStart, windowEnd]`.
  Future<List<CalendarEvent>> getUpcomingEventsNeedingAlert(
    String workspaceId,
    DateTime windowStart,
    DateTime windowEnd,
  );

  /// Marks an event's "starting soon" alert as fired.
  Future<void> markAlerted(String workspaceId, String eventId, DateTime at);

  /// Links a recorded meeting to its source event (1:1 per meeting).
  Future<void> linkMeetingToEvent({
    required String workspaceId,
    required String meetingId,
    required String calendarEventId,
  });

  /// The event a meeting was recorded for, scoped to [workspaceId].
  Future<CalendarEvent?> getEventForMeeting(
    String workspaceId,
    String meetingId,
  );

  /// The id of the meeting recorded for an event, if any, scoped to
  /// [workspaceId].
  Future<String?> getMeetingIdForEvent(
    String workspaceId,
    String calendarEventId,
  );
}
