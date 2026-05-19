import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How far back and forward the phone's agenda reaches, as whole local days.
///
/// A phone calendar answers "what is next" — yesterday is context for a
/// meeting that ran late, three weeks out is a desk question. Both ends are
/// bounded so one subscription covers the whole surface: the range is a
/// SUBSCRIPTION argument, so widening it later would re-register the stream.
const int kAgendaDaysBack = 1;

/// See [kAgendaDaysBack].
const int kAgendaDaysForward = 30;

/// The agenda window `[today − [kAgendaDaysBack], today + [kAgendaDaysForward])`,
/// anchored to local midnight.
///
/// Anchored to the DAY rather than to `now` on purpose: a `now`-based range
/// changes on every rebuild, and since the range is part of the subscription's
/// args that would tear down and re-register the stream continuously.
({DateTime from, DateTime to}) agendaWindow([DateTime? now]) {
  final day = startOfDay(now ?? DateTime.now());
  return (
    from: day.subtract(const Duration(days: kAgendaDaysBack)),
    to: day.add(const Duration(days: kAgendaDaysForward)),
  );
}

/// Connected calendar accounts in the active workspace (live).
///
/// The phone cannot connect one — the OAuth device-code flow stores a refresh
/// token server-side and is driven from the desktop — but it has to be able to
/// say "no calendar is connected" rather than showing a convincing empty week.
final calendarAccountsProvider = StreamProvider<List<CalendarAccountDto>>((
  ref,
) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  return RemoteCalendarRepository(
    client,
  ).watchAccounts(workspaceId: workspaceId);
});

/// Live events across the agenda window, in the active workspace.
///
/// Workspace-scoped EXPLICITLY (not through the client's ambient id) so a
/// workspace switch re-registers the stream instead of leaving the phone
/// showing the previous workspace's calendar.
final agendaEventsProvider = StreamProvider<List<CalendarEventDto>>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  if (client == null || workspaceId == null) return const Stream.empty();
  final window = agendaWindow();
  final repository = RemoteCalendarRepository(client);
  // The host syncs a rolling window; a 30-day agenda can reach past its far
  // edge. Fire-and-forget: the watch below delivers whatever the fill adds.
  repository
      .ensureRangeLoaded(window.from, window.to, workspaceId: workspaceId)
      .ignore();
  return repository.watchEventsInRange(
    window.from,
    window.to,
    workspaceId: workspaceId,
  );
});

/// One day of the agenda: the local day and the events starting on it, in
/// start order.
typedef AgendaDay = ({DateTime day, List<CalendarEventDto> events});

/// The agenda grouped into days, oldest first, empty days omitted.
///
/// Cancelled events are dropped: the server keeps the row so a sync can tell
/// "cancelled" from "deleted upstream", but a cancelled meeting is not an
/// agenda item. Grouping is by the event's LOCAL start day so a 23:30 UTC
/// event lands on the day the operator will actually attend it.
final agendaDaysProvider = Provider<AsyncValue<List<AgendaDay>>>((ref) {
  return ref.watch(agendaEventsProvider).whenData((events) {
    final byDay = <int, List<CalendarEventDto>>{};
    final dayOf = <int, DateTime>{};
    for (final e in events) {
      if (e.status == 'cancelled') {
        continue;
      }
      final start = DateTime.tryParse(e.startTime);
      if (start == null) {
        continue;
      }
      final day = startOfDay(start);
      final key = day.millisecondsSinceEpoch;
      dayOf[key] = day;
      (byDay[key] ??= []).add(e);
    }
    final keys = byDay.keys.toList()..sort();
    return [
      for (final key in keys)
        (
          day: dayOf[key]!,
          events: byDay[key]!
            ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        ),
    ];
  });
});

/// The event that is happening now, or the next one to start — the "up next"
/// the phone leads with. Null when the agenda holds nothing ahead.
///
/// Ordered by START among the events that have not ENDED, so a meeting already
/// under way wins over a shorter one later in the morning. Ordering by end
/// time instead would quietly hide the call the operator is currently in.
final nextEventProvider = Provider<CalendarEventDto?>((ref) {
  final events = ref.watch(agendaEventsProvider).value ?? const [];
  final now = DateTime.now();
  CalendarEventDto? best;
  DateTime? bestStart;
  for (final e in events) {
    if (e.status == 'cancelled') {
      continue;
    }
    final start = DateTime.tryParse(e.startTime);
    final end = DateTime.tryParse(e.endTime);
    if (start == null || end == null || end.isBefore(now)) {
      continue;
    }
    if (bestStart == null || start.isBefore(bestStart)) {
      best = e;
      bestStart = start;
    }
  }
  return best;
});
