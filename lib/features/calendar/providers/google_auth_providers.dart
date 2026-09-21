import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the deterministic account id for a workspace + Google account email.
///
/// Embedding the workspace keeps tokens workspace-isolated; embedding [userId]
/// keeps two members who connect the same Google email on distinct rows.
/// Legacy three-part ids omit [userId] so existing rows keep loading.
String googleAccountId(
  String workspaceId,
  String email, {
  String userId = '',
}) => userId.isEmpty
    ? 'google:$workspaceId:$email'
    : 'google:$workspaceId:$userId:$email';

/// The signed-in user's Google accounts in the active workspace.
///
/// The server already filters by caller; this also drops another member's
/// rows if an older host streams the whole workspace pool.
final googleAccountsProvider = StreamProvider<List<CalendarAccount>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const <CalendarAccount>[]);
  }
  final userId = ref.watch(currentUserIdProvider) ?? '';
  return ref.watch(calendarRepositoryProvider).watchAccounts(workspaceId).map(
    (accounts) => [
      for (final account in accounts)
        if (account.userId == userId || account.userId.isEmpty) account,
    ],
  );
});

/// Connected accounts whose OAuth token died and need the user to reconnect.
/// Drives the calendar "reconnect" banner. Empty while every account is healthy.
final accountsNeedingReauthProvider = Provider<List<CalendarAccount>>((ref) {
  final accounts = ref.watch(googleAccountsProvider).asData?.value ?? const [];
  return accounts.where((a) => a.needsReauth).toList(growable: false);
});
