import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/providers/rpc_client_provider.dart';
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

