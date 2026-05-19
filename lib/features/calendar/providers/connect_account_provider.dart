import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
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

/// Drives the device-code Google Calendar connect from the GUI (web + desktop).
///
/// The user supplies an OAuth client id + secret; the HOST runs the device-code
/// flow, stores the refresh token server-side, and owns the sync. This notifier
/// only relays: `beginConnect` → show the code + URL → poll until the host
/// reports the result. It holds no tokens.
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

  /// Begins a device-code connect with the supplied [clientId] + [clientSecret].
  /// Surfaces the user code + URL via state, then polls until the host reports
  /// the outcome.
  Future<void> connect({
    required String clientId,
    required String clientSecret,
  }) async {
    _pollTimer?.cancel();
    _handle = null;
    state = const CalendarConnectState(phase: CalendarConnectPhase.starting);
    try {
      final begin = await _connect.begin(
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
    }
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
  }

  /// Cancels an in-flight connect and returns to the idle form.
  void cancel() => _finish(const CalendarConnectState());

  /// Disconnects the account [accountId]: the host clears its stored tokens and
  /// removes its synced events + row.
  Future<void> disconnect(String accountId) async {
    try {
      await _connect.disconnect(accountId);
    } on Object catch (e, st) {
      AppLog.e('GoogleAuth', 'Calendar disconnect failed', e, st);
    }
  }
}
