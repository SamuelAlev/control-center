import 'package:cc_domain/features/meetings/domain/services/meeting_signal_collector.dart';
import 'package:cc_infra/src/meetings/calendar_meeting_signal_collector.dart';
import 'package:cc_infra/src/meetings/process_meeting_signal_collector.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fused signal collector (desktop): portable calendar + per-meeting-process
/// sources, plus the (currently no-op) native seam. Swap
/// [NoopNativeMeetingSignalCollector] for a per-OS implementation to detect
/// always-on clients (Teams/Slack) and camera/mic/system-audio.
final meetingSignalCollectorProvider = Provider<MeetingSignalCollector>((ref) {
  final calendar = CalendarMeetingSignalCollector(
    repository: ref.watch(calendarRepositoryProvider),
    activeWorkspaceId: () => ref.read(activeWorkspaceIdProvider),
  );
  final process = ProcessMeetingSignalCollector();
  const native = NoopNativeMeetingSignalCollector();
  return CompositeMeetingSignalCollector([calendar, process, native]);
});
