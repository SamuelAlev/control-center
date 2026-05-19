import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_signal_collector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inert signal collector for web: never reports a meeting signal.
///
/// The desktop sources (calendar + OS process detection) have no browser
/// equivalent — there is no process space to inspect — so auto-detection simply
/// never fires on web. Recording is device-only anyway (see the inert web
/// recorder), so a detected candidate would have nothing to start.
class _WebMeetingSignalCollector implements MeetingSignalCollector {
  const _WebMeetingSignalCollector();

  @override
  Future<List<MeetingSignal>> sample(DateTime now) async => const [];
}

/// The fused signal collector (web): the inert no-signal collector.
final meetingSignalCollectorProvider = Provider<MeetingSignalCollector>(
  (ref) => const _WebMeetingSignalCollector(),
);
