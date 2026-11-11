import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's Google accounts in the active workspace.
///
/// The server already filters by caller; this keeps only the caller's own
/// rows regardless.
final googleAccountsProvider =
    StreamProvider.autoDispose<List<CalendarAccount>>((ref) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Stream.value(const <CalendarAccount>[]);
      }
      final userId = ref.watch(currentUserIdProvider) ?? '';
      return ref
          .watch(calendarRepositoryProvider)
          .watchAccounts(workspaceId)
          .map(
            (accounts) => [
              for (final account in accounts)
                if (account.userId == userId) account,
            ],
          );
    });

/// Connected accounts whose OAuth token died and need the user to reconnect.
/// Drives the calendar "reconnect" banner. Empty while every account is healthy.
final accountsNeedingReauthProvider = Provider<List<CalendarAccount>>((ref) {
  final accounts = ref.watch(googleAccountsProvider).asData?.value ?? const [];
  return accounts.where((a) => a.needsReauth).toList(growable: false);
});
