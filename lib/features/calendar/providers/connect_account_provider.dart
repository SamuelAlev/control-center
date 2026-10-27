import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phase of the GUI device-code connect flow.
enum CalendarConnectPhase {
  /// Showing the client id/secret form (idle or after a failure).
  idle,

  /// The `beginConnect` request is in flight.
  starting,

  /// Showing the user code + URL; polling until the user approves.
  awaitingApproval,

  /// Connected — the accounts stream will replace this view.
  success,
}

/// A classified connect failure the form localizes (no raw text leaks to UI).
enum CalendarConnectError {
  /// The user denied the authorization request.
  denied,

  /// The device code expired (or the flow was lost) before approval.
  expired,

  /// Starting the flow failed (bad credentials, network, host unavailable).
  failed,
}

/// Immutable state for the calendar connect form.
class CalendarConnectState {
  /// Creates a [CalendarConnectState].
  const CalendarConnectState({
    this.phase = CalendarConnectPhase.idle,
    this.userCode,
    this.verificationUrl,
    this.error,
  });

  /// The current flow phase.
  final CalendarConnectPhase phase;

  /// The short code to display while [phase] is
  /// [CalendarConnectPhase.awaitingApproval].
  final String? userCode;

  /// The verification URL to open while awaiting approval.
  final String? verificationUrl;

  /// The last failure, if any (shown on the idle form).
  final CalendarConnectError? error;
}

/// Whether the host has a Google app of its own, deciding whether the connect
/// dialog offers the no-setup path or only the bring-your-own form.
///
/// A build from source ships no built-in client and a self-hoster may configure
/// their own — so this is asked rather than assumed.
final calendarBuiltinClientAvailableProvider = FutureProvider<bool>(
  (ref) =>
      RemoteCalendarConnect(ref.watch(rpcClientProvider)).builtinAvailable(),
);

/// Drives the device-code Google Calendar connect from the GUI (web + desktop).
///
/// The user either approves with Control Center's own Google app or supplies an
/// OAuth client id + secret of their own; either way the HOST runs the
/// device-code flow, stores the refresh token server-side and owns the sync.
/// This notifier only relays: `beginConnect` → show the code + URL → poll until
/// the host reports the result. It holds no tokens.
final connectGoogleCalendarProvider =
    NotifierProvider<ConnectGoogleCalendarNotifier, CalendarConnectState>(
      ConnectGoogleCalendarNotifier.new,
    );

/// Notifier for the connect/disconnect flow.
class ConnectGoogleCalendarNotifier extends Notifier<CalendarConnectState> {
  Timer? _pollTimer;
  bool _polling = false;
  String? _handle;

  @override
  CalendarConnectState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return const CalendarConnectState();
  }

  RemoteCalendarConnect get _connect =>
      RemoteCalendarConnect(ref.read(rpcClientProvider));

  /// Begins a device-code connect, either with Control Center's own Google app
  /// ([useBuiltin]) or with the supplied [clientId] + [clientSecret]. Surfaces
  /// the user code + URL via state, then polls until the host reports the
  /// outcome.
  Future<void> connect({
    bool useBuiltin = false,
    String clientId = '',
    String clientSecret = '',
  }) async {
    _pollTimer?.cancel();
    _handle = null;
    _attemptStartedAt = DateTime.now();
    _attemptBuiltin = useBuiltin;
    state = const CalendarConnectState(phase: CalendarConnectPhase.starting);
    try {
      final begin = await _connect.begin(
        useBuiltin: useBuiltin,
        clientId: clientId.trim(),
        clientSecret: clientSecret.trim(),
      );
      _handle = begin.handle;
      state = CalendarConnectState(
        phase: CalendarConnectPhase.awaitingApproval,
        userCode: begin.userCode,
        verificationUrl: begin.verificationUrl,
      );
      // Poll no faster than Google's interval (and never below 3s).
      final period = begin.interval < const Duration(seconds: 3)
          ? const Duration(seconds: 3)
          : begin.interval;
      _pollTimer = Timer.periodic(period, (_) => unawaited(_poll()));
    } on Object catch (e, st) {
      AppLog.e('GoogleAuth', 'Calendar connect (begin) failed', e, st);
      state = const CalendarConnectState(error: CalendarConnectError.failed);
      _trackAttempt('failed');
    }
  }

  /// The current attempt's start and client choice, for analytics.
  DateTime? _attemptStartedAt;
  bool _attemptBuiltin = false;

  void _trackAttempt(String outcome) {
    final startedAt = _attemptStartedAt;
    if (startedAt == null) {
      return;
    }
    _attemptStartedAt = null;
    ref.track(
      AnalyticsEvents.calendarConnectFinished(
        outcome: outcome,
        builtinClient: _attemptBuiltin,
        durationS: DateTime.now().difference(startedAt).inSeconds,
      ),
    );
  }

  Future<void> _poll() async {
    final handle = _handle;
    if (handle == null || _polling) {
      return;
    }
    _polling = true;
    try {
      final poll = await _connect.poll(handle);
      switch (poll.status) {
        case CalendarConnectPollStatus.pending:
          return;
        case CalendarConnectPollStatus.connected:
          _finish(
            const CalendarConnectState(phase: CalendarConnectPhase.success),
          );
        case CalendarConnectPollStatus.denied:
          _finish(
            const CalendarConnectState(error: CalendarConnectError.denied),
          );
        case CalendarConnectPollStatus.expired:
        case CalendarConnectPollStatus.unknown:
          _finish(
            const CalendarConnectState(error: CalendarConnectError.expired),
          );
      }
    } on Object catch (e) {
      // A transient poll failure (e.g. network blip) — keep polling; the host's
      // device-code expiry ends the flow if it never recovers.
      AppLog.w('GoogleAuth', 'Calendar connect poll error: $e');
    } finally {
      _polling = false;
    }
  }

  void _finish(CalendarConnectState next) {
    _pollTimer?.cancel();
    _handle = null;
    state = next;
    _trackAttempt(switch (next) {
      CalendarConnectState(phase: CalendarConnectPhase.success) => 'connected',
      CalendarConnectState(error: CalendarConnectError.denied) => 'denied',
      CalendarConnectState(error: CalendarConnectError.expired) => 'expired',
      CalendarConnectState(error: _?) => 'failed',
      _ => 'cancelled',
    });
  }

  /// Cancels an in-flight connect and returns to the idle form.
  void cancel() => _finish(const CalendarConnectState());

  /// Disconnects the account [accountId]: the host clears its stored tokens and
  /// removes its synced events + row.
  Future<void> disconnect(String accountId) async {
    try {
      await _connect.disconnect(accountId);
      ref.track(
        AnalyticsEvents.calendarDisconnected(
          workspaceId: ref.read(activeWorkspaceIdProvider),
        ),
      );
    } on Object catch (e, st) {
      AppLog.e('GoogleAuth', 'Calendar disconnect failed', e, st);
    }
  }
}
