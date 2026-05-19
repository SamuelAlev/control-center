import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';

/// A source of [MeetingSignal]s. The auto-detection controller polls one of
/// these (usually a [CompositeMeetingSignalCollector]) on a timer, then fuses
/// the result with [resolveMeetingCandidate].
///
/// Implementations are per-OS for richer signals (frontmost window, camera,
/// mic, system audio) but several are fully portable (calendar, process scan).
abstract interface class MeetingSignalCollector {
  /// Returns the currently-asserted signals observed at [now]. Should be cheap
  /// and non-throwing (return `const []` on any error) — it runs on a timer.
  Future<List<MeetingSignal>> sample(DateTime now);
}

/// Fans a single [sample] out across several collectors and concatenates their
/// signals. A collector that throws contributes nothing rather than failing the
/// whole sweep.
class CompositeMeetingSignalCollector implements MeetingSignalCollector {
  /// Creates a [CompositeMeetingSignalCollector] over [collectors].
  const CompositeMeetingSignalCollector(this.collectors);

  /// The wrapped collectors.
  final List<MeetingSignalCollector> collectors;

  @override
  Future<List<MeetingSignal>> sample(DateTime now) async {
    final results = await Future.wait(
      collectors.map((c) async {
        try {
          return await c.sample(now);
        } on Object {
          return const <MeetingSignal>[];
        }
      }),
    );
    return [for (final r in results) ...r];
  }
}

/// The seam for OS-native signal sources — frontmost conferencing window,
/// camera-in-use, microphone-captured-by-another-app, and sustained system
/// audio output. These require platform channels (macOS CoreAudio/EventKit,
/// Windows WASAPI sessions, Linux PipeWire) and are the precise signals that
/// make always-running clients (Teams, Slack) detectable.
///
/// The default [NoopNativeMeetingSignalCollector] returns nothing, so detection
/// degrades gracefully to the portable calendar + per-meeting-process signals
/// until a platform implementation is registered.
abstract interface class NativeMeetingSignalCollector
    implements MeetingSignalCollector {}

/// A [NativeMeetingSignalCollector] that observes nothing — the cross-platform
/// default until per-OS collectors are implemented.
class NoopNativeMeetingSignalCollector implements NativeMeetingSignalCollector {
  /// Creates a [NoopNativeMeetingSignalCollector].
  const NoopNativeMeetingSignalCollector();

  @override
  Future<List<MeetingSignal>> sample(DateTime now) async =>
      const <MeetingSignal>[];
}
