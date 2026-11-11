/// The identity layer's audit trail for who may be recognised by an email
/// address: one JSON line per event through [CcHostLog]. A line names
/// accounts by user id only, never by address.
library;

import 'dart:convert';

import 'package:cc_host/cc_host.dart' show CcHostLog;

/// Every event [identityAudit] writes.
enum IdentityAuditEvent {
  /// The server owner vouched for an account's current email address
  /// (`users.vouchEmail`). Fields: `actor_user_id`, `user_id`.
  emailVouched('user.email_vouched'),

  /// An identity the provider vouched for (an SSO login, a SCIM push) took
  /// an address that unvouched accounts held, so theirs was cleared.
  /// Fields: `user_id` (the vouched account), `holder_user_id`.
  unvouchedEmailCleared('user.email_unvouched_cleared');

  const IdentityAuditEvent(this.wire);

  /// The event name written in the line.
  final String wire;
}

/// Writes `identity.audit {"event": …, …fields}`. Null fields are left out.
void identityAudit(IdentityAuditEvent event, Map<String, String?> fields) {
  final line = {
    'event': event.wire,
    for (final entry in fields.entries)
      if (entry.value != null) entry.key: entry.value,
  };
  CcHostLog.info('identity.audit ${jsonEncode(line)}');
}
