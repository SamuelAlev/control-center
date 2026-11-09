import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Disconnects Google Calendar accounts (`calendar.disconnect`).
///
/// Connecting one is the generic browser sign-in on the `google` lane — see
/// `showGoogleCalendarConnectDialog`. The server, or Connect, holds every
/// token; this client never sees one.
final calendarConnectRepositoryProvider = Provider<RemoteCalendarConnect>(
  (ref) => RemoteCalendarConnect(ref.watch(rpcClientProvider)),
);

/// Disconnects [accountId] in [workspaceId]: the host clears its stored
/// tokens and removes its synced events + row.
Future<void> disconnectGoogleCalendar(
  WidgetRef ref, {
  required String workspaceId,
  required String accountId,
}) async {
  try {
    await ref.read(calendarConnectRepositoryProvider).disconnect(accountId);
    ref.track(AnalyticsEvents.calendarDisconnected(workspaceId: workspaceId));
  } on Object catch (e, st) {
    AppLog.e('GoogleAuth', 'Calendar disconnect failed', e, st);
  }
}
