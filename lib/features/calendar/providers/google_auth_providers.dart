import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the deterministic account id for a workspace + Google account email.
/// Embedding the workspace keeps the keychain key (and thus the tokens)
/// workspace-isolated; embedding the email lets a workspace hold many accounts.
String googleAccountId(String workspaceId, String email) =>
    'google:$workspaceId:$email';

/// Recovers the workspace id embedded in a [googleAccountId], or null if
/// [accountId] is not a well-formed Google account id. Safe to split on `:`:
/// workspace ids are UUIDs and an email's local-part/domain contain no `:`, so
/// the workspace id is always the second `:`-separated segment. Fails closed
/// (returns null) rather than throwing so a future id-format change is caught.
String? googleAccountWorkspaceId(String accountId) {
  final parts = accountId.split(':');
  if (parts.length < 3 || parts[0] != 'google' || parts[1].isEmpty) {
    return null;
  }
  return parts[1];
}

/// The connected Google accounts for the active workspace (empty when none).
/// Backed by the DB, so connecting/disconnecting updates it reactively.
final googleAccountsProvider = StreamProvider<List<CalendarAccount>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const <CalendarAccount>[]);
  }
  return ref.watch(calendarRepositoryProvider).watchAccounts(workspaceId);
});

/// Connected accounts whose OAuth token died and need the user to reconnect.
/// Drives the calendar "reconnect" banner. Empty while every account is healthy.
final accountsNeedingReauthProvider = Provider<List<CalendarAccount>>((ref) {
  final accounts = ref.watch(googleAccountsProvider).asData?.value ?? const [];
  return accounts.where((a) => a.needsReauth).toList(growable: false);
});
