import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/l10n/app_localizations.dart';

/// Localized copy for a classified connection failure. Shared by the connect
/// screen and the shell's failed banner so the two never drift.
String failureReasonLabel(AppLocalizations l10n, RemoteFailureReason reason) {
  return switch (reason) {
    RemoteFailureReason.notPaired => l10n.failureNotPaired,
    RemoteFailureReason.unreachable => l10n.failureUnreachable,
    RemoteFailureReason.identityChanged => l10n.failureIdentityChanged,
    RemoteFailureReason.authRejected => l10n.failureAuthRejected,
    RemoteFailureReason.unknown => l10n.failureUnknown,
  };
}

/// Statuses a ticket may move through, in display order. Matches the desktop's
/// `TicketStatus` storage strings used by `tickets.list`/`tickets.update`.
const List<String> ticketStatuses = <String>[
  'open',
  'inProgress',
  'blocked',
  'inReview',
  'done',
  'backlog',
];

/// Localized label for a ticket status storage string, falling back to the raw
/// value when unknown.
String ticketStatusLabel(AppLocalizations l10n, String value) {
  return switch (value) {
    'open' => l10n.statusOpen,
    'inProgress' => l10n.statusInProgress,
    'blocked' => l10n.statusBlocked,
    'inReview' => l10n.statusInReview,
    'done' => l10n.statusDone,
    'backlog' => l10n.statusBacklog,
    _ => value,
  };
}
