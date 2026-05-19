import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/data/services/calendar_sync_service.dart';
import 'package:control_center/features/calendar/data/services/meeting_alert_scheduler.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The periodic read-only Google Calendar sync for the active workspace.
final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  final service = CalendarSyncService(
    apiClient: ref.watch(googleCalendarApiClientProvider),
    repository: ref.watch(calendarRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
    activeWorkspaceId: () => ref.read(activeWorkspaceIdProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Keep-alive notifier that starts the [CalendarSyncService].
class CalendarSyncNotifier extends Notifier<void> {
  @override
  void build() {
    ref.watch(calendarSyncServiceProvider).start();
  }
}

/// Keeps the calendar sync running across the app lifetime.
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
