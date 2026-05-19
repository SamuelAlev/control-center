/// Platform seam for the meeting-detection signal collector.
///
/// The desktop collector fuses portable calendar signals with per-meeting OS
/// process detection (cc_infra, which reaches the OS process space) — there is
/// no browser equivalent for the process source. The VM build exports the real
/// composite collector (`meeting_signal_collector_bindings_io.dart`); the web
/// build exports an inert no-signal collector
/// (`meeting_signal_collector_bindings_web.dart`) so the detection controller
/// compiles and runs (it simply never detects a meeting to auto-record).
///
/// Both variants expose the same `meetingSignalCollectorProvider`.
library;

export 'meeting_signal_collector_bindings_io.dart'
    if (dart.library.js_interop) 'meeting_signal_collector_bindings_web.dart';
