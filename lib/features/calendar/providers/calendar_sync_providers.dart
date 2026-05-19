import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/data/services/meeting_alert_scheduler.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client controller that triggers Google Calendar sync actions SERVER-SIDE
/// over RPC. The host owns the OAuth token and runs the periodic sweep + the
/// reads (`calendar.watchEventsInRange`); the thin client only drives the
/// manual "refresh" and the on-demand range load when the calendar is navigated
/// outside the host's rolling window. There is no client-side Google sync.
class CalendarSyncController {
  /// Creates a [CalendarSyncController].
  CalendarSyncController(this._rpc);

  final RemoteRpcClient _rpc;

  /// No-op: the host runs the periodic sweep, not the client.
  void start() {}

  /// No-op (kept for call-site symmetry with the old in-process service).
  void stop() {}

  /// No-op (the controller holds no resources).
  void dispose() {}

  /// Triggers an immediate sync of the bound workspace on the host. Best-effort
  /// — a failure leaves the last-synced events in place.
  Future<void> refreshNow() async {
    try {
      await _rpc.call('calendar.refreshNow', const {});
    } on Object {
      // Best-effort; the periodic host sweep will catch up.
    }
  }

  /// Ensures events in `[from, to]` are loaded on the host (the bound workspace
  /// is server-supplied, so [workspaceId] is accepted for call-site symmetry
  /// but not sent). Best-effort.
  Future<void> ensureRangeLoaded(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      await _rpc.call('calendar.ensureRangeLoaded', {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      });
    } on Object {
      // Best-effort; the range stays whatever the periodic sweep covered.
    }
  }
}

/// The calendar sync controller — drives host-side sync over RPC.
final calendarSyncServiceProvider = Provider<CalendarSyncController>((ref) {
  return CalendarSyncController(ref.watch(rpcClientProvider));
});

/// Keep-alive notifier (the host runs the periodic sweep, so `start()` is a
/// no-op; retained so the boot wiring's `listen` has a target).
class CalendarSyncNotifier extends Notifier<void> {
  @override
  void build() {
    ref.watch(calendarSyncServiceProvider).start();
  }
}

/// Retained for boot-wiring symmetry; the host owns the periodic sync now.
final calendarSyncAliveProvider = NotifierProvider<CalendarSyncNotifier, void>(
  CalendarSyncNotifier.new,
);

/// The per-minute "meeting starting soon" alert scheduler.
final meetingAlertSchedulerProvider = Provider<MeetingAlertScheduler>((ref) {
  final scheduler = MeetingAlertScheduler(
    repository: ref.watch(calendarRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
    activeWorkspaceId: () => ref.read(activeWorkspaceIdProvider),
    leadTimeMinutes: () =>
        ref.read(notificationPreferencesProvider).getCalendarAlertLeadMinutes(),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

/// Keep-alive notifier that starts the [MeetingAlertScheduler].
class MeetingAlertSchedulerNotifier extends Notifier<void> {
  @override
  void build() {
    ref.watch(meetingAlertSchedulerProvider).start();
  }
}

/// Keeps the meeting-alert scheduler running across the app lifetime.
final meetingAlertSchedulerAliveProvider =
    NotifierProvider<MeetingAlertSchedulerNotifier, void>(
  MeetingAlertSchedulerNotifier.new,
);
