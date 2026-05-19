import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/data/repositories/google_credentials_repository.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/providers/calendar_sync_providers.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives connecting / disconnecting Google Calendar accounts for the active
/// workspace. A workspace can hold several accounts; `connect` adds one and
/// `disconnect` removes a specific one. Exposes an [AsyncValue] for progress.
final connectGoogleCalendarProvider =
    NotifierProvider<ConnectGoogleCalendarNotifier, AsyncValue<void>>(
  ConnectGoogleCalendarNotifier.new,
);

/// Notifier for the connect/disconnect flow.
class ConnectGoogleCalendarNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Runs the OAuth consent flow and adds the resulting account (tokens +
  /// account row) to the active workspace, then kicks off an immediate sync.
  /// Calling it again connects an additional account. Surfaces failures via
  /// state (user-cancel is treated as benign).
  Future<void> connect() async {
    state = const AsyncLoading();
    try {
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        state = const AsyncData(null);
        return;
      }
      if (ref.read(googleClientIdProvider).isEmpty) {
        throw const GoogleOAuthException(
          'Google client id is not configured. Set GOOGLE_OAUTH_CLIENT_ID.',
          kind: GoogleOAuthFailureKind.missingClientId,
        );
      }

      final tokens = await ref.read(googleOAuthServiceProvider).authenticate();
      final email = tokens.accountEmail;
      if (email.isEmpty) {
        throw const GoogleOAuthException(
          'Could not determine the connected account email.',
          code: 'no_account_email',
        );
      }

      final accountId = googleAccountId(workspaceId, email);
      await ref.read(googleCredentialsRepositoryProvider).save(
            accountId,
            GoogleCredentials(
              accessToken: tokens.accessToken,
              refreshToken: tokens.refreshToken,
              expiresAt: tokens.expiresAt,
              accountEmail: email,
              scope: tokens.scope,
            ),
          );
      await ref.read(calendarRepositoryProvider).upsertAccount(
            CalendarAccount(
              id: accountId,
              workspaceId: workspaceId,
              providerId: 'google',
              accountEmail: email,
            ),
          );

      // The account IS connected now — report success before the first sync so
      // a transient Calendar API hiccup isn't misreported as "couldn't connect".
      state = const AsyncData(null);
      try {
        await ref.read(calendarSyncServiceProvider).refreshNow();
      } on Object catch (e, st) {
        AppLog.e('GoogleAuth', 'Initial calendar sync after connect failed', e, st);
      }
    } on GoogleOAuthException catch (e, st) {
      if (e.kind == GoogleOAuthFailureKind.userCancelled) {
        state = const AsyncData(null);
      } else {
        AppLog.e('GoogleAuth', 'Google Calendar connect failed', e, st);
        state = AsyncError(e, st);
      }
    } on Object catch (e, st) {
      AppLog.e('GoogleAuth', 'Google Calendar connect failed', e, st);
      state = AsyncError(e, st);
    }
  }

  /// Disconnects the account [accountId]: removes its synced events + row and
  /// clears its stored tokens.
  Future<void> disconnect(String accountId) async {
    state = const AsyncLoading();
    try {
      final workspaceId = ref.read(activeWorkspaceIdProvider);
      if (workspaceId != null) {
        await ref
            .read(calendarRepositoryProvider)
            .deleteAccount(workspaceId, accountId);
      }
      await ref.read(googleCredentialsRepositoryProvider).clear(accountId);
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
