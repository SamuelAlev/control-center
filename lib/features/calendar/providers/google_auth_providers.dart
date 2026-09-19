import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the deterministic account id for a workspace + Google account email.
/// Embedding the workspace keeps the keychain key (and thus the tokens)
/// workspace-isolated; embedding the email lets a workspace hold many accounts.
String googleAccountId(String workspaceId, String email) =>
    'google:$workspaceId:$email';

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
