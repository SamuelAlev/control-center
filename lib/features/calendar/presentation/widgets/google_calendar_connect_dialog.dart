import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneMode;
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/provider_sign_in_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connects a Google Calendar account to [workspaceId]: the generic browser
/// sign-in on the `google` lane.
///
/// The server runs it with its own Google client when one is configured
/// (Settings → Server → Single sign-on → Provider apps, or `.env`), otherwise
/// through Control Center Connect, where the browser shows a code that comes
/// back by deep link or by typing it. Either way the server keeps the refresh
/// token and owns the sync. Every connect entry point — the calendar empty
/// state, the sidebar, the reauth banner, Settings — opens this.
Future<void> showGoogleCalendarConnectDialog(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
}) async {
  final startedAt = DateTime.now();
  final analytics = ref.read(analyticsProvider);
  final attempt = await showProviderSignInDialog(
    context,
    lane: ConnectOAuthLane.google,
    workspaceId: workspaceId,
  );
  analytics.track(
    AnalyticsEvents.calendarConnectFinished(
      outcome: attempt == null ? 'cancelled' : 'connected',
      builtinClient: attempt?.mode == SignInLaneMode.connect,
      durationS: DateTime.now().difference(startedAt).inSeconds,
    ),
  );
}
